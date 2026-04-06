import { StringEncoder } from '../../../../../utils/strings/StringEncrypt';

// MARK: - COS 配置常量（需保密），供 CosService / CosUtils 共用，避免与 CosService 循环依赖

export namespace CosConfig {
  export const region    : string = "STap-shanghai";
  export const secretKey : string = "C8Q0F1VG53cFRxMnloRmZtZktpd2F4NzBlM0Iwa1N1NjM="; // 已加密
  export const secretId  : string = "P0QUtJRFQ4ZTBERTFhc0lPSTFlaUZEYWhlTXE3OGgyOHpja1Jz"; // 已加密 ko_app
  export const appId     : string = "ST1256782283";
  export const zkBucket  : string = "STwordtreebucket";
}

// 当前 Bucket 名称，格式 bucket-appId
export const CurrentBucket: string = `${StringEncoder.removedSalt(CosConfig.zkBucket)}-${StringEncoder.removedSalt(CosConfig.appId)}`;
