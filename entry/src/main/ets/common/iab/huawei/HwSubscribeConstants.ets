import { AppSettings } from "../../../app/constants/AppSettings";

/**
 * Harmony OS 5, HWS 5.0 IAP 应用内支付 说明文档
 * https://developer.huawei.com/consumer/cn/doc/app/non-subscription-0000001959074885
 * https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/iap-integrate-subscription-V5
 *
 * API 参考
 * https://developer.huawei.com/consumer/cn/doc/development/HMSCore-References/iapclient-0000001050137587
 */
export class HwSubscribeConstants {

  static readonly SKU_1: string = AppSettings.TEConfigs.SKU_Member1;//'com.or.toeic.vocabulary.member1';
  static readonly SKU_2: string = AppSettings.TEConfigs.SKU_Member2;//'com.or.toeic.vocabulary.member2';
  static readonly SKU_3: string = AppSettings.TEConfigs.SKU_Member3;//'com.or.toeic.vocabulary.member3';
}