import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DebugLog } from '../../../app/debug/DebugLog';
import { FinishStatus, PurchaseData, PurchaseOrderPayload, SubGroupStatusPayload } from './utils/IapDataModel';
import { JWSUtil } from './utils/JWSUtil';
import { getAppContext } from '../../../app/constants/AppContext';
import { SubscribeItem, SubscribeManager } from '../SubscribeManager';
import { HwSubscribeConstants } from './HwSubscribeConstants';
import { Toast } from '../../utils/Toast';
import { DeviceUtil } from '../../utils/DeviceUtils';
import { AppSettings } from '../../../app/constants/AppSettings';
import { SubscriptionInfoManager } from '../../../models/managers/subscription/SubscriptionInfoManager';
import { isDebugMode } from '../../../app/constants/AppDefines';

export class HwSubscriber {
  private static _shared: HwSubscriber | null = null;

  static get shared(): HwSubscriber {
    if (!HwSubscriber._shared) {
      HwSubscriber._shared = new HwSubscriber();
    }
    return HwSubscriber._shared;
  }

  private context: common.UIAbilityContext = {} as common.UIAbilityContext;   // 当前 ability context

  private constructor() {
    this.init();
  }

  /** 初始化 context */
  private init() {
    this.context = getAppContext();
  }

  /** 检查 IAP 环境 */
  async queryEnvironmentStatus(): Promise<number> {
    try {
      await iap.queryEnvironmentStatus(this.context);
      DebugLog.i('Succeeded in querying environment status.');
      return 0;
    } catch (err) {
      const e = err as BusinessError;
      DebugLog.e(`Failed to query environment status. Code: ${e.code}, message: ${e.message}`);
      return e.code;
    }
  }

  /** 查询产品信息 */
  async queryProducts(): Promise<iap.Product[] | null> {
    const productIds: string[] = [
      HwSubscribeConstants.SKU_1,
      HwSubscribeConstants.SKU_2,
      HwSubscribeConstants.SKU_3
    ];

    const param: iap.QueryProductsParameter = {
      productType : iap.ProductType.AUTORENEWABLE,
      productIds  : productIds
    };

    try {
      const result: iap.Product[] = await iap.queryProducts(this.context, param);
      DebugLog.i('Succeeded in querying products.');
      return result.sort((a, b) => a.id.localeCompare(b.id)) ?? []; //按id排序
    } catch (err) {
      const e = err as BusinessError;
      DebugLog.e(`Failed to query products. Code: ${e.code}, message: ${e.message}`);
      return null;
    }
  }

  /** 创建购买 */
  async createPurchase(productId: string): Promise<boolean> {
    const param: iap.PurchaseParameter = {
      productId   : productId,
      productType : iap.ProductType.AUTORENEWABLE
    };

    try {
      const result = await iap.createPurchase(this.context, param);
      DebugLog.i('Succeeded in creating purchase.');
      await this.dealPurchaseData(result.purchaseData);
      return true;
    } catch (err) {
      const e = err as BusinessError;
      DebugLog.e(`Failed to create purchase. Code: ${e.code}, message: ${e.message}`);

      // 查询未完成订单
      if (e.code === iap.IAPErrorCode.PRODUCT_OWNED || e.code === iap.IAPErrorCode.SYSTEM_ERROR) {
        await this.queryPurchases(iap.PurchaseQueryType.ALL);
      }

      if (e.code === iap.IAPErrorCode.PRODUCT_OWNED ) {
        //已经购买过，并且正在生效
        Toast.showMessage('您已经购买过此项目，无需要再次购买。')
      }
      return false;
    }
  }

  ///启动时，默认执行一次自动恢复
  async restore(){
    // 查询当前有效的订阅订单
    ///已购买但未交付的消耗型商品、非消耗型商品、自动续期订阅商品和非续期订阅商品。
    await this.queryPurchases(iap.PurchaseQueryType.ALL);
  }

  /** 查询已购买/未完成订单 */
  async queryPurchases(queryType: iap.PurchaseQueryType): Promise<void> {
    const param: iap.QueryPurchasesParameter = {
      productType : iap.ProductType.AUTORENEWABLE,
      queryType   : queryType
    };

    try {
      const res = await iap.queryPurchases(this.context, param);
      const purchaseDataList: string[] = res.purchaseDataList ?? [];
      for (const purchaseData of purchaseDataList) {
        await this.dealPurchaseData(purchaseData);
      }
    } catch (err) {
      const e = err as BusinessError;
      DebugLog.e(`Failed to query purchases. Code: ${e.code}, message: ${e.message}`);
    }
  }

  /** 处理 purchaseData */
  private async dealPurchaseData(purchaseData: string): Promise<void> {
    try {
      const parsed: PurchaseData                   = JSON.parse(purchaseData);
      const jwsSubscriptionStatus                 = parsed.jwsSubscriptionStatus;
      if (!jwsSubscriptionStatus) return;

      const subscriptionStatusStr                 = JWSUtil.decodeJwsObj(jwsSubscriptionStatus);
      if (!subscriptionStatusStr) return;

      const subGroupStatus: SubGroupStatusPayload = JSON.parse(subscriptionStatusStr);
      const lastSubscriptionStatus                = subGroupStatus.lastSubscriptionStatus;
      if (!lastSubscriptionStatus) return;

      let isNeedWriteToServer                     = false //是否需要同步到Server

      // 发货逻辑
      const purchaseOrder                         = lastSubscriptionStatus.lastPurchaseOrder;
      if (purchaseOrder && purchaseOrder.finishStatus !== FinishStatus.FINISHED) {
        await this.finishPurchase(purchaseOrder);

        //续期时，需要在这里再刷新订阅信息到server
        isNeedWriteToServer = true
      }

      let expiresTimeMs =  lastSubscriptionStatus.expiresTime
      if (isDebugMode) {
        //expiresTimeMs = this.getSandboxExpireTimeMS(expiresTimeMs, purchaseOrder?.purchaseTime)
      }

      // 保存到 SubscribeManager
      const newSubscribeItem = new SubscribeItem(
        lastSubscriptionStatus.renewalInfo?.productId ?? purchaseOrder?.productId ?? null,
        expiresTimeMs ?? null,
        purchaseOrder?.purchaseToken ?? null,
        'huawei'
      );
      SubscribeManager.shared.saveNewItemIfNeeds(newSubscribeItem);

      //续期时，需要在这里再刷新订阅信息到server
      if (isNeedWriteToServer) {
        //放在最后，才能同步最新时间到Server
        SubscriptionInfoManager.shared.asyncRefreshSubscriptionInfo()//写入
      }

    } catch (err) {
      DebugLog.e('dealPurchaseData error');
    }
  }


  /// 沙盒环境中的订阅换算时间为10秒/天。比如订阅周期为1周，商品将在首次购买成功70秒后发生续期。
  private getSandboxExpireTimeMS(expiresTimeMs: number, purchaseTime?: number): number {

    const nowMS = purchaseTime ?? Date.now()
    const delta = expiresTimeMs - nowMS

    // 沙盒：10秒 = 1天 → 加速倍率
    const SANDBOX_ACCELERATION = 86400 / 10;

    // sandbox expiresTime 是加速后的毫秒，需要“还原”为真实世界时间
    const realWorldMs: number = (delta / SANDBOX_ACCELERATION)

    return Math.ceil((nowMS + realWorldMs))
  }

  /** 完成购买（确认发货） */
  private async finishPurchase(purchaseOrder: PurchaseOrderPayload): Promise<void> {
    if (!purchaseOrder.productType) {
      DebugLog.e('finishPurchase: productType missing');
      return;
    }

    const param: iap.FinishPurchaseParameter = {
      productType     : Number(purchaseOrder.productType),
      purchaseToken   : purchaseOrder.purchaseToken,
      purchaseOrderId : purchaseOrder.purchaseOrderId
    };

    try {
      await iap.finishPurchase(this.context, param);
      DebugLog.i('Succeeded in finishing purchase.');
    } catch (err) {
      const e = err as BusinessError;
      DebugLog.e(`Failed to finish purchase. Code: ${e.code}, message: ${e.message}`);
    }
  }

  ///打开华为订阅管理页面（订阅列表 + 详情）
  async showManagedSubscriptions() {
    try {
      let context = getAppContext()

      // 跳转到用户已购订阅管理列表页
      await iap.showManagedSubscriptions(context, {windowScreenMode:  iap.WindowScreenMode.DIALOG_BOX});//是否全屏

      // 或者，跳转到某个特定订阅的详情页（需要传入订阅的PurchaseToken）
      //iap.showManagedSubscriptions(context, {windowScreenMode:  iap.WindowScreenMode.FULLSCREEN}, 'groupId');

    } catch (err) {
      const e = err as BusinessError;
      Toast.showMessage(`Failed to open subscription page: ${e.message}`)
    }
  }

}