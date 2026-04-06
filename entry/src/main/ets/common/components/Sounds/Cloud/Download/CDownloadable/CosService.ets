//
// CosService.ets
// WordTree (HarmonyOS)
//
// 腾讯云 COS 在鸿蒙侧的入口：初始化 `@tencentcloud/cos` 默认 `CosXmlBaseService`，与上传/下载（如 CosDownloader）共用；
// SecretId/SecretKey 来自 `CosConstants.CosConfig` 解密。
// 数据万象 CI 等 REST 请求不在 COS SDK 文档的高级封装内，签名与 HTTPS 见 `CosUtils`；
// 本类对 `CosUtils` 做薄委托，便于业务继续通过 `CosService.shared` 一条线使用 Host 与 `signedCosRequest`。
//

import { getAppContext } from '../../../../../../app/constants/AppContext';
import { StringEncoder } from '../../../../../utils/strings/StringEncrypt';
import http from '@ohos.net.http';
import { CosXmlBaseService, CosXmlServiceConfig } from '@tencentcloud/cos';
import { QCloudCredential } from '@tencentcloud/cos';

import { CosConfig, CurrentBucket } from './CosConstants';
import { CosUtils } from './CosUtils';

export { CosConfig, CurrentBucket } from './CosConstants';

export class CosService {

  // 进程内唯一实例，与 CosDownloader 等共用一个已初始化的 COS 默认 Service
  private static instance: CosService = new CosService();

  //private credentialFenceQueue: any; // 模拟QCloudCredentailFenceQueue

  // 与初始化完成后 `CosXmlBaseService.default()` 引用一致，便于后续扩展与同 iOS 侧持有 service 习惯对齐
  private cosService: CosXmlBaseService;

  // 构造函数内完成腾讯云默认 Service 注册
  private constructor() {

    this.initTencentCos();

    // 取出全局默认实例，供本类字段持有（与文档示例一致）

    this.cosService = CosXmlBaseService.default();
  }

  // 全局访问点；首次访问时触发私有构造与 initTencentCos
  public static get shared(): CosService {

    return CosService.instance;
  }

  // 按官方鸿蒙文档创建 `CosXmlServiceConfig` 并 `initDefaultService`（需 Application Context）
  private initTencentCos(): void {

    // Cos 鸿蒙文档：https://cloud.tencent.com/document/product/436/112125

    // 地域与 `CosConstants.CosConfig.region` 解密值一致

    let cosXmlServiceConfig = new CosXmlServiceConfig(StringEncoder.removedSalt(CosConfig.region)!!);

    // SDK 要求传入 ApplicationContext，与 EntryAbility 侧 `getAppContext()` 一致

    CosXmlBaseService.initDefaultService(
      getAppContext(),
      cosXmlServiceConfig
    );
  }

  // 与 `initTencentCos` 中 `CosXmlServiceConfig` 使用的地域一致（解密后 region id，如 ap-shanghai）
  resolvedRegion(): string {

    // 委托 `CosUtils`，避免与常量文件重复实现

    return CosUtils.resolvedRegion();
  }

  // 数据万象 CI 接口 Host：`{CurrentBucket}.ci.{region}.myqcloud.com`
  ciAuditingHost(): string {

    return CosUtils.ciAuditingHost();
  }

  // 对象存储 REST Host：`{CurrentBucket}.cos.{region}.myqcloud.com`，与 SDK 默认域名模板一致
  cosBucketHost(): string {

    return CosUtils.cosBucketHost();
  }

  // 使用当前 `getCredential()` 发起 COS V5 签名 HTTPS（CI 文本/图片审核等）；逻辑在 `CosUtils`
  // 参数 method        ：http.RequestMethod.GET / POST
  // 参数 host          ：`ciAuditingHost` 或 `cosBucketHost` 返回的域名，不含协议
  // 参数 pathNoLeading ：如 `text/auditing` 或 `''` 表示 bucket 根路径
  // 参数 queries       ：参与签名的查询参数
  // 参数 body          ：可选 POST 正文
  // 参数 contentType   ：与 body 成对出现，如 `application/xml`
  signedCosRequest(
    method: http.RequestMethod,
    host: string,
    pathNoLeading: string,
    queries: Map<string, string | undefined>,
    body: string | undefined,
    contentType: string | undefined
  ): Promise<string> {

    return CosUtils.signedCosRequest(
      this.getCredential(),
      method,
      host,
      pathNoLeading,
      queries,
      body,
      contentType
    );
  }

  // 构造本次请求用的永久密钥（生产环境建议改为 STS，见 CosConstants / 服务端 STS 文档）
  getCredential(): QCloudCredential {

    let credential: QCloudCredential = new QCloudCredential();

    // 与 iOS / Android 工程内 decodeAfterRemoveSalt 配置同源

    credential.secretID = StringEncoder.decodeAfterRemoveSalt(CosConfig.secretId)!!;

    credential.secretKey = StringEncoder.decodeAfterRemoveSalt(CosConfig.secretKey)!!;

    //TODO: 获取临时密钥
    //Credential.sessionCredential

    return credential;
  }
}
