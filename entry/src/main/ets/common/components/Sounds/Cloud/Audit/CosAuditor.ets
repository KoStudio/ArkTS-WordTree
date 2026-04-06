//
// CosAuditor.ets
// WordTree (HarmonyOS)
//
// Created by huminghua on 2024/9/2.
//
// 与 iOS `Share/Managers/Sound/CloudSound/Audit/CosAuditor.swift` 行为对齐的目标相同：
//   文本：数据万象「文本内容同步审核」；图片：「图片单次审核」URL 检测。
//
// 为何与 iOS 实现形式不同（需保留，勿与 Swift 强行逐行一致）：
//   iOS 使用 QCloudCOSXML：`QCloudPostTextRecognitionRequest` / `QCloudSyncImageRecognitionRequest`，
//   SDK 在 native 层完成 HTTPS 与 XML 解析，回调里直接得到 state、result、message 等结构化字段。
//   鸿蒙侧 `@tencentcloud/cos` 公开文档与 CHANGELOG 仅覆盖桶/对象/传输等，不提供与 iOS 同级的 CI 审核封装；
//   `@tencentcloud/foundation` 亦未对业务模块暴露，无法在应用内等价调用 SDK 内部请求链。
//   因此本类通过 `CosService.signedCosRequest`（与 `getCredential()`、地域同源）调用 CI REST，
//   响应体为 XML 字符串，需在 ArkTS 内解析后再映射到与 iOS 相同的 `finish(succeed, result, msg)` 语义。
//   解析辅助函数（parseXmlTagContent 等）对应 iOS 侧已由 SDK 完成的步骤，非额外业务分支。
//

import http from '@ohos.net.http';
import { StringEncoder } from '../../../../utils/strings/StringEncrypt';
import { CosService } from '../Download/CDownloadable/CosService';

// 审核结果枚举，与 iOS `CosAuditor.AuditResult` 的 raw 取值一致
export enum CosAuditResult {

  Normal  = 0,
  Reject  = 1,
  Unknown = 2,
}

// 从 XML 片段中取首个简单标签的文本内容（无命名空间场景）；取不到则 null
// 参数 source：XML 字符串；tag：标签名，不含尖括号
function parseXmlTagContent(source: string, tag: string): string | null {

  const open  = `<${tag}>`;
  const close = `</${tag}>`;
  const i     = source.indexOf(open);

  // 未出现开始标签则无法解析
  if (i < 0) {
    return null;
  }

  const j = source.indexOf(close, i + open.length);

  // 有开始无结束则视为截断响应
  if (j < 0) {
    return null;
  }

  return source.substring(i + open.length, j);
}

// 截取首个 outerTag 子树字符串，便于在整块 Response 中缩小 JobsDetail / RecognitionResult 范围
// 参数 source：完整或局部 XML；outerTag：外层标签名
function firstXmlSection(source: string, outerTag: string): string {

  const open  = `<${outerTag}>`;
  const close = `</${outerTag}>`;
  const i     = source.indexOf(open);

  // 没有该节点则返回原文，由上层解析再判失败
  if (i < 0) {
    return source;
  }

  const j = source.indexOf(close, i + open.length);

  // 只有开头没有闭合时返回从开头起的后缀
  if (j < 0) {
    return source.slice(i);
  }

  return source.slice(i, j + close.length);
}

// 将接口 Result 整数值映射为枚举；非法值按 iOS `AuditResult` 的 default 走 Reject
// 参数 raw：JobsDetail.Result / RecognitionResult.Result
function mapCosAuditResult(raw: number): CosAuditResult {

  // 0：审核正常
  if (raw === 0) {
    return CosAuditResult.Normal;
  }

  // 1：判定违规
  if (raw === 1) {
    return CosAuditResult.Reject;
  }

  // 2：疑似，建议人工
  if (raw === 2) {
    return CosAuditResult.Unknown;
  }

  // 与 iOS `AuditResult(rawValue:)` 的 default：未列出的数值一律 Reject

  return CosAuditResult.Reject;
}

// 将 XML 中的数字字符串安全转为 int；空或非数字返回 null
// 参数 s：标签内文本，可为 null
function parseIntOrNull(s: string | null): number | null {

  // 缺字段不参与计算
  if (s === null || s === '') {
    return null;
  }

  // 十进制解析，与 XML 中纯数字 Result 节点一致

  const n = parseInt(s, 10);

  // 非十进制整数则视为解析失败
  if (Number.isNaN(n)) {
    return null;
  }

  return n;
}

export class CosAuditor {

  // 触发 CosService 单例初始化，与同目录下载链路、iOS init 中拉起 Cos 配置一致
  constructor() {

    // 访问单例以执行 CosXmlBaseService.initDefaultService 路径（若尚未执行）

    CosService.shared;
  }

  // 提交文本同步审核（纯文本 Base64 写入 XML Body，对应 iOS content 字段）
  // 参数 text                    ：待审 UTF-8 文本
  // 参数 finish                   ：succeed 表示请求/审核流程是否按文档约定成功返回；result 为判定；msg 为失败说明
  audit(text: string, finish: (succeed: boolean, result: CosAuditResult, msg: string | null) => void): void {

    // 与 iOS 一致：空串不调接口
    if (text === '') {
      return;
    }

    // 按数据万象要求对正文做 Base64（仅 UTF-8 原文参与编码）

    const b64 = StringEncoder.encodedToBase64(text);

    // 编码失败则无法组包，直接视作 unknown
    if (!b64) {
      CosAuditor.dispatchFinish(finish, false, CosAuditResult.Unknown, null);
      return;
    }

    const xmlBody = `<Request><Input><Content>${b64}</Content></Input></Request>`;

    // 与下载共用同一套临时/永久密钥及地域 Host

    const cos     = CosService.shared;
    const queries = new Map<string, string | undefined>();

    // CI 文本同步审核：POST /text/auditing，文档见 cloud.tencent.com/document/product/436/56285

    cos.signedCosRequest(
      http.RequestMethod.POST,
      cos.ciAuditingHost(),
      'text/auditing',
      queries,
      xmlBody,
      'application/xml'
    )
      .then((body: string) => {

        // 以下解析等价于 iOS SDK 已将 XML 解包为 QCloudPostTextRecognitionResult

        const jobs  = firstXmlSection(body, 'JobsDetail');
        const state = parseXmlTagContent(jobs, 'State');
        const msg   = parseXmlTagContent(jobs, 'Message');
        const rtn   = parseIntOrNull(parseXmlTagContent(jobs, 'Result'));

        // State 或 Result 缺失则无法对齐 iOS 回调语义，按失败处理
        if (state === null || rtn === null) {

          CosAuditor.dispatchFinish(finish, false, CosAuditResult.Unknown, msg);
          return;
        }

        // 与 iOS：finish(state == "Success", AuditResult(rawValue: rtn), msg)

        CosAuditor.dispatchFinish(
          finish,
          state === 'Success',
          mapCosAuditResult(rtn),
          msg
        );
      })
      .catch((e: Error) => {

        CosAuditor.dispatchFinish(finish, false, CosAuditResult.Unknown, e?.message ?? null);
      });
  }

  // 图片 URL 同步审核（对应 iOS detectUrl）
  // 参数 addr  ：公网可访问图片链接
  // 参数 finish：同 audit
  auditImage(addr: string, finish: (succeed: boolean, result: CosAuditResult, msg: string | null) => void): void {

    // 与 iOS 一致：空地址不请求
    if (addr === '') {
      return;
    }

    const cos     = CosService.shared;
    const queries = new Map<string, string | undefined>();

    // 与文档图片单次审核参数一致

    queries.set('ci-process', 'sensitive-content-recognition');

    // 对应 iOS request.detectUrl

    queries.set('detect-url', addr);

    // 图片单次审核：GET bucket.cos...，文档见 cloud.tencent.com/document/product/460/37318

    cos.signedCosRequest(
      http.RequestMethod.GET,
      cos.cosBucketHost(),
      '',
      queries,
      undefined,
      undefined
    )
      .then((body: string) => {

        // 以下解析等价于 iOS SDK 已将 XML 解包为 QCloudImageRecognitionResult

        const block = firstXmlSection(body, 'RecognitionResult');
        const state = parseXmlTagContent(block, 'State');
        const msg   = parseXmlTagContent(block, 'Message');
        const rtn   = parseIntOrNull(parseXmlTagContent(block, 'Result'));

        // CI 显式 Failed 时与 iOS 网络/服务失败分支类似，交给上层不通过
        if (state === 'Failed') {

          CosAuditor.dispatchFinish(finish, false, CosAuditResult.Unknown, msg);
          return;
        }

        // 同步结果以 Result 为准；无 State 或 Success 时认为请求层成功（与 iOS SDK 解包后一致）
        if (rtn !== null) {

          // 同步包常见仅有 Result；无 State 或显式 Success 均视为审核通道成功、再解读 Result

          const apiOk = state === null || state === '' || state === 'Success';

          CosAuditor.dispatchFinish(finish, apiOk, mapCosAuditResult(rtn), null);
          return;
        }

        // 无 Result 字段则无法给出与 iOS 一致的 rtn，按失败回调

        CosAuditor.dispatchFinish(finish, false, CosAuditResult.Unknown, null);
      })
      .catch((e: Error) => {

        CosAuditor.dispatchFinish(finish, false, CosAuditResult.Unknown, e?.message ?? null);
      });
  }

  // 统一异步回到与 UI 解耦的下一 tick，类比 iOS `DispatchQueue.main.async` 派发 finish
  // 参数 finish：业务回调；succeed / result / msg：与 iOS 回调参数同义
  private static dispatchFinish(
    finish: (succeed: boolean, result: CosAuditResult, msg: string | null) => void,
    succeed: boolean,
    result: CosAuditResult,
    msg: string | null
  ): void {

    // 下一事件循环再回调，降低与 rcp/http 线程耦合；语义接近回到主线程再通知 UI

    setTimeout((): void => {

      finish(succeed, result, msg);
    }, 0);
  }
}
