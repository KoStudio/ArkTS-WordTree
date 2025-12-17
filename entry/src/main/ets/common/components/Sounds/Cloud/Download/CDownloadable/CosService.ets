import { getAppContext } from '../../../../../../app/constants/AppContext';
import { StringEncoder } from '../../../../../utils/strings/StringEncrypt';
import { CosXmlBaseService, CosXmlServiceConfig } from '@tencentcloud/cos';
import { CredentialCallBack, QCloudCredential } from '@tencentcloud/cos';



// MARK: - COS配置常量（需保密）
export namespace CosConfig {
  export const region    : string = "STap-shanghai";
  export const secretKey : string = "C8Q0F1VG53cFRxMnloRmZtZktpd2F4NzBlM0Iwa1N1NjM="; // 已加密
  export const secretId  : string = "P0QUtJRFQ4ZTBERTFhc0lPSTFlaUZEYWhlTXE3OGgyOHpja1Jz"; // 已加密 ko_app
  export const appId     : string = "ST1256782283";
  export const zkBucket  : string = "STwordtreebucket";
}

// 当前Bucket名称
export const CurrentBucket: string = `${StringEncoder.removedSalt(CosConfig.zkBucket)}-${StringEncoder.removedSalt(CosConfig.appId)}`;

// MARK: - 腾讯云服务类
export class CosService {
  // MARK: - 单例实例
  private static instance: CosService = new CosService();

  // MARK: - 私有属性
  //private credentialFenceQueue: any; // 模拟QCloudCredentailFenceQueue
  private cosService: CosXmlBaseService; // 模拟QCloudCOSXMLService

  // MARK: - 构造函数
  private constructor() {
    this.initTencentCos();

    this.cosService = CosXmlBaseService.default()
  }

  // 获取单例实例
  public static get shared(): CosService {
    return this.instance;
  }

  // MARK: - 初始化腾讯云COS
  private initTencentCos(): void {

    ////////////////////////////////////////////////////////////
    ///Cos配置鸿蒙版: https://cloud.tencent.com/document/product/436/112125
    ////////////////////////////////////////////////////////////

    // 服务配置
    let cosXmlServiceConfig = new CosXmlServiceConfig(StringEncoder.removedSalt(CosConfig.region)!!);

    // 初始化默认的 Service
    CosXmlBaseService.initDefaultService(
      getAppContext(),
      cosXmlServiceConfig
      // 可以不设置临时密钥回调
    )
  }




  // /**
  //  * 获取固定密钥 仅在测试时使用
  //  */
  // public static constCredential: CredentialCallBack = (request)=>{
  //
  //   return new Promise((resolve, reject) => {
  //     let credential : QCloudCredential= new QCloudCredential();
  //
  //     // 用户的 SecretId，建议使用子账号密钥，授权遵循最小权限指引，降低使用风险。子账号密钥获取可参见 https://cloud.tencent.com/document/product/598/37140
  //     credential.secretID = "SECRETID";
  //     // 用户的 SecretKey，建议使用子账号密钥，授权遵循最小权限指引，降低使用风险。子账号密钥获取可参见 https://cloud.tencent.com/document/product/598/37140
  //     credential.secretKey = "SECRETKEY";
  //     resolve(credential);
  //   })
  // }

  ///获取密钥
  getCredential(): QCloudCredential {
    let credential : QCloudCredential= new QCloudCredential();

    // 用户的 SecretId
    credential.secretID  = StringEncoder.decodeAfterRemoveSalt(CosConfig.secretId)!! //"SECRETID";

    // 用户的 SecretKey
    credential.secretKey = StringEncoder.decodeAfterRemoveSalt(CosConfig.secretKey)!! //"SECRETKEY";

    //TODO: 获取临时密钥
    //Credential.sessionCredential

    return credential
  }

}

