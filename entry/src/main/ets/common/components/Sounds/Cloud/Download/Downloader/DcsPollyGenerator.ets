//
// DcsPollyGenerator.ets
//
// 云端发音兜底：POST /polly/，响应与 Instruction、ServerCfg 等相同，为 Dcs 通用 JSON（code / msg / data[]）。
// data[0].audioBase64 为 MP3 的 Base64 字符串；本类用 Http.requestPromise 拉取并解码为 Uint8Array 后交给 CSoundManager。
//

import util from '@ohos.util';
import { HttpUtils } from '../../../../../../models/networks/HttpUtils';
import { Http } from '../../../../../../models/networks/Http';
import { Servers, Route } from '../../../../../../models/networks/Server_Routes';
import { NetWorkTool } from '../../../../../utils/NetworkUtils';
import { DebugLog } from '../../../../../../app/debug/DebugLog';
import { logEvent } from '../../../../Logger/Logger';

/** 与 PollyController.generate 成功时 data 数组元素字段一致（JSON 仅便于传输，客户端再转为 Uint8Array） */
interface PollyGenerateDataItem {
  audioBase64?: string;
}

/**
 * 经 Dcs 转调的 Polly 语音生成（请求路径为 Route.polly）。
 * 与 CosDownloader 相同：按 language+title 去重，避免并发重复请求。
 */
export class DcsPollyGenerator {
  private static instance: DcsPollyGenerator = new DcsPollyGenerator();

  /** 进行中任务的 tag，防重复点击或并发重复拉取 */
  private downloadingSet: Set<string> = new Set();

  private constructor() {}

  static get shared(): DcsPollyGenerator {
    return DcsPollyGenerator.instance;
  }

  /**
   * 向 Dcs 请求合成语音；成功则得到 MP3 的 Uint8Array。
   * @param title   发给服务端的朗读文本（须已由调用方去掉 `_ti_u` 等 cloud key 后缀）
   * @param finished 成功时 data 为解码后的 MP3；失败时 error 为说明（与 COS 下载回调形态一致）
   */
  public async startDownloadSoundIfNeeds(
    title: string,
    finished: (data: Uint8Array | null, error: string | null) => void
  ): Promise<void> {
    // 无文本则不请求
    if (!title || title.trim().length === 0) {
      finished(null, 'title is empty');
      return;
    }
    // 无网络则与 CosDownloader 行为一致
    if (!NetWorkTool.checkInternetConnection()) {
      finished(null, 'Network is not connectable.');
      return;
    }

    const language = 'en_us';
    const tag        = `language:${language}, title:${title}`;

    // 同一文本已在合成中则不再入队
    if (this.downloadingSet.has(tag)) {
      DebugLog.i(`DcsPolly: ${tag} already in progress`);
      finished(null, 'Download is already in progress.');
      return;
    }

    this.downloadingSet.add(tag);
    logEvent('Audio_DcsPolly_Request');

    const url  = `${Servers.getRouteUrl(Route.polly)}/`;
    const params: HttpUtils.HttpParams = {};
    params['text']    = title;
    params['voiceId'] = 'Joey';

    try {
      // 与工程内其它模块一致使用 Http.requestPromise；Polly 较慢故加长读超时
      const resp = await Http.requestPromise<PollyGenerateDataItem>(url, HttpUtils.Method.POST, params,
        { connectTimeout: 30000, readTimeout: 120000 });

      // 业务失败或 data 为空
      if (!resp.succeed || !resp.data || resp.data.length === 0) {
        finished(null, resp.msg ?? 'Polly request failed');
        return;
      }
      const b64 = resp.data[0].audioBase64;
      // 成功帧但缺音频字段
      if (!b64 || b64.length === 0) {
        finished(null, 'Polly: empty audio');
        return;
      }
      const helper = new util.Base64Helper();
      const bin    = helper.decodeSync(b64);
      // 解码结果无效
      if (!bin || bin.length === 0) {
        finished(null, 'Polly: base64 decode failed');
        return;
      }
      finished(new Uint8Array(bin), null);
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : `${e}`;
      DebugLog.e(`DcsPolly error: ${errMsg}`);
      finished(null, errMsg);
    } finally {
      this.downloadingSet.delete(tag);
    }
  }
}
