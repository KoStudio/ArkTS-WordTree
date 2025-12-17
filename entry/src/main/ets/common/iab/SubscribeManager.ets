import { preferences } from "@kit.ArkData";
import { getAppContext } from "../../app/constants/AppContext";
import { SimpleEventBus } from "../components/eventbus/SimpleEventBus";


/** SubscribeManager Pref Key 常量 */
class SubscribeManagerPref {
  static readonly Name               : string = "SubscriptionItem";
  static readonly kSku               : string = "SubKey_Sku";
  static readonly kExpiresDate       : string = "SubKey_ExpiresDate";
  static readonly kPurchaseToken     : string = "SubKey_PurchaseToken";
  static readonly kPurchasedPlatform : string = "SubKey_PurchasePlatform";


}

// 定义通知相关的常量
export class SubscribeManagerNotification {

  static readonly expireDateUpdated = "SubscribeManager.subscribeItem.expiresDateMs.updated"

}
/** 订阅项数据模型 */
export class SubscribeItem {
  sku:               string | null;
  expiresDateMs:     number | null;        // 毫秒
  purchaseToken:     string | null;
  purchasedPlatform: string | null;

  constructor(sku: string | null, expiresDateMs: number | null, purchaseToken: string | null = null, purchasedPlatform: string | null = null) {
    this.sku               = sku;
    this.expiresDateMs     = expiresDateMs;
    this.purchaseToken     = purchaseToken;
    this.purchasedPlatform = purchasedPlatform;
  }

  /** 是否有效 */
  get isActive(): boolean {
    return this.calculateCurrentSubscriptionActive();
  }

  /** 获取 Date 对象 */
  get expireDate(): Date | null {
    return this.expiresDateMs ? new Date(Number(this.expiresDateMs)) : null;
  }

  /** 内部计算订阅是否有效 */
  private calculateCurrentSubscriptionActive(): boolean {
    if (!this.expiresDateMs) return false;
    const nowMs = new Date().getTime();
    return this.expiresDateMs > nowMs;
  }
}

/** 订阅管理器 */
export class SubscribeManager {

  /** 单例 */
  static shared: SubscribeManager = new SubscribeManager();

  /** 当前订阅项 */
  currentItem?: SubscribeItem;

  private constructor() {
    this.loadCurrentItem();
  }
  /** 内部同步获取 Preferences */
  getPrefs(): preferences.Preferences | null {
    return preferences.getPreferencesSync(getAppContext(), { name: SubscribeManagerPref.Name });
  }

  // -------------------------
  // 本地偏好读取/保存
  // -------------------------

  /** 加载当前订阅项 */
  private loadCurrentItem(): void {
    const pref = this.getPrefs();
    if (!pref) return;

    const sku        = pref.getSync(SubscribeManagerPref.kSku, null) as string | null;
    const expDate    = pref.getSync(SubscribeManagerPref.kExpiresDate, 0) as number;
    const token      = pref.getSync(SubscribeManagerPref.kPurchaseToken, null) as string | null;
    const platform   = pref.getSync(SubscribeManagerPref.kPurchasedPlatform, null) as string | null;

    if (sku) {
      this.currentItem = new SubscribeItem(sku, expDate, token, platform);
    }
  }

  /** 保存当前订阅项到本地 */
  saveCurrentItem(item?: SubscribeItem): void {
    if (item) {
      this.currentItem = item;

      // 发送订阅项已改变通知，让UI刷新
      SimpleEventBus.emit(SubscribeManagerNotification.expireDateUpdated)
    }

    const pref = this.getPrefs();
    if (!pref || !this.currentItem) return;

    pref.putSync(SubscribeManagerPref.kSku,               this.currentItem!.sku);
    pref.putSync(SubscribeManagerPref.kExpiresDate,       this.currentItem!.expiresDateMs ?? 0);
    pref.putSync(SubscribeManagerPref.kPurchaseToken,     this.currentItem!.purchaseToken ?? "");
    pref.putSync(SubscribeManagerPref.kPurchasedPlatform, this.currentItem!.purchasedPlatform ?? "");
    pref.flushSync();
  }

  // -------------------------
  // 条件保存新订阅项
  // -------------------------

  saveNewItemIfNeeds(newItem: SubscribeItem): void {
    if (!newItem.expiresDateMs) return;

    const currentItem = this.currentItem;
    if (!currentItem || !currentItem.expiresDateMs) {
      // 本地为空时直接保存
      SubscribeManager.shared.saveCurrentItem(newItem);
      return;
    }

    // 更新本地为最新，只更新时间
    if (currentItem.expiresDateMs <= newItem.expiresDateMs) {
      currentItem.sku           = newItem.sku //更换订阅方案时，这里会变。Android版这里没这行，可能有问题,暂时不修改。by ko 2025.12.06
      currentItem.expiresDateMs = newItem.expiresDateMs;
      SubscribeManager.shared.saveCurrentItem(currentItem);
    }
    // 否则不更新
  }
}