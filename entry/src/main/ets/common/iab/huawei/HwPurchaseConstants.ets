import { AppSettings } from "../../../app/constants/AppSettings";

/**
 * 华为消耗型单次购买商品常量（一次性购买可叠加、不自动续费）
 * 与 Android `HwPurchaseConstants.kt` 对齐。
 */
export class HwPurchaseConstants {

  static readonly SKU_7: string = AppSettings.TEConfigs.SKU_Member7;   // 包1年会员
  static readonly SKU_8: string = AppSettings.TEConfigs.SKU_Member8;  // 包2年会员
  static readonly SKU_9: string = AppSettings.TEConfigs.SKU_Member9;  // 包3年会员
  static readonly SKU_10: string = AppSettings.TEConfigs.SKU_Member10; // 包5年会员

  // 与 Android 当前实现保持一致：首版仅展示前三个单次购买商品。
  static get ALL_SKUS(): string[] {
    return [
      HwPurchaseConstants.SKU_7,
      HwPurchaseConstants.SKU_8,
      HwPurchaseConstants.SKU_9
    ]
  }
}
