import { iap } from '@kit.IAPKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { preferences } from '@kit.ArkData'
import { getAppContext } from '../../../app/constants/AppContext'
import { DebugLog } from '../../../app/debug/DebugLog'
import { SubscribeItem, SubscribeManager } from '../SubscribeManager'
import { Toast } from '../../utils/Toast'
import { SubscriptionInfoManager } from '../../../models/managers/subscription/SubscriptionInfoManager'
import { HwPurchaseConstants } from './HwPurchaseConstants'
import { FinishStatus, PurchaseData, PurchaseOrderPayload } from './utils/IapDataModel'
import { JWSUtil } from './utils/JWSUtil'

class DeliverPref {
  static readonly NAME                 : string = 'HwConsumableDeliver'
  static readonly KEY_DELIVERED_TOKENS : string = 'DeliveredTokens'
}

/**
 * 华为消耗型单次购买
 * 代码结构、方法命名与 Android `HwPurchaser.kt` 尽量保持一致。
 */
export class HwPurchaser {
  private static _shared: HwPurchaser | null = null

  static get shared(): HwPurchaser {
    if (!HwPurchaser._shared) {
      HwPurchaser._shared = new HwPurchaser()
    }

    return HwPurchaser._shared
  }

  private context: common.UIAbilityContext = {} as common.UIAbilityContext // 当前 ability context

  private constructor() {
    this.init()
  }

  // 初始化 context
  private init(): void {
    this.context = getAppContext()
  }

  // 获取交付幂等 pref
  private getDeliverPref(): preferences.Preferences | null {
    return preferences.getPreferencesSync(getAppContext(), { name: DeliverPref.NAME })
  }

  /**
   * 判断某个 purchaseToken 是否已经发货过
   * @param purchaseToken 华为订单 token
   */
  private isTokenDelivered(purchaseToken: string): boolean {
    const pref = this.getDeliverPref()

    if (!pref) {
      return false
    }

    const json = pref.getSync(DeliverPref.KEY_DELIVERED_TOKENS, '[]') as string

    try {
      const tokens = JSON.parse(json) as string[]
      return tokens.includes(purchaseToken)
    } catch (_e) {
      return false
    }
  }

  /**
   * 记录某个 purchaseToken 已经成功发货
   * @param purchaseToken 华为订单 token
   */
  private markTokenDelivered(purchaseToken: string): void {
    const pref = this.getDeliverPref()

    if (!pref) {
      return
    }

    const json = pref.getSync(DeliverPref.KEY_DELIVERED_TOKENS, '[]') as string
    let tokens: string[] = []

    try {
      tokens = JSON.parse(json) as string[]
    } catch (_e) {
      tokens = []
    }

    // 分支：已记录时不重复写入
    if (tokens.includes(purchaseToken)) {
      return
    }

    tokens.push(purchaseToken)
    pref.putSync(DeliverPref.KEY_DELIVERED_TOKENS, JSON.stringify(tokens))
    pref.flushSync()
  }

  /**
   * 查询消耗型商品信息列表
   */
  async queryProducts(): Promise<iap.Product[] | null> {
    const param: iap.QueryProductsParameter = {
      productType : iap.ProductType.CONSUMABLE,
      productIds  : HwPurchaseConstants.ALL_SKUS
    }

    try {
      const result: iap.Product[] = await iap.queryProducts(this.context, param)
      return result.sort((a, b) => a.id.localeCompare(b.id)) ?? []
    } catch (err) {
      const e = err as BusinessError
      DebugLog.e(`Failed to query consumable products. Code: ${e.code}, message: ${e.message}`)
      return null
    }
  }

  // 加载消耗型商品信息列表，与 Android `loadAllProducts(...)` 对齐
  async loadAllProducts(): Promise<iap.Product[] | null> {
    return await this.queryProducts()
  }

  /**
   * 启动消耗型商品购买流程
   * @param productId 商品 id
   */
  async createPurchase(productId: string): Promise<boolean> {

    // 调用：在每次新的购买前，先尝试恢复并清理历史未完成的消耗型订单
    await this.autoConsumeUnfinishedPurchases()

    const param: iap.PurchaseParameter = {
      productId   : productId,
      productType : iap.ProductType.CONSUMABLE
    }

    try {
      const result = await iap.createPurchase(this.context, param)

      // 调用：支付成功后立即处理购买数据（发货 + finishPurchase）
      await this.dealPurchaseData(result.purchaseData)
      return true
    } catch (err) {
      const e = err as BusinessError
      DebugLog.e(`Failed to create consumable purchase. Code: ${e.code}, message: ${e.message}`)

      // 分支：已拥有或系统异常时，额外走一次恢复流程，兼容遗留未完成订单
      if (e.code === iap.IAPErrorCode.PRODUCT_OWNED || e.code === iap.IAPErrorCode.SYSTEM_ERROR) {
        await this.queryPurchases(iap.PurchaseQueryType.ALL)
      }

      return false
    }
  }

  /**
   * 启动消耗型商品购买流程
   * @param productId 商品 id
   */
  async purchaseProduct(productId: string): Promise<boolean> {
    return await this.createPurchase(productId)
  }

  // 启动时执行一次自动恢复
  async restore(): Promise<void> {

    // 调用：恢复当前账号下所有已购买未完成的消耗型订单
    await this.autoConsumeUnfinishedPurchases()
  }

  /**
   * 查询已购买/未完成的消耗型订单
   * @param queryType 查询类型
   */
  async queryPurchases(queryType: iap.PurchaseQueryType): Promise<void> {
    const param: iap.QueryPurchasesParameter = {
      productType : iap.ProductType.CONSUMABLE,
      queryType   : queryType
    }

    try {
      const res = await iap.queryPurchases(this.context, param)
      const purchaseDataList: string[] = res.purchaseDataList ?? []

      for (const purchaseData of purchaseDataList) {

        // 调用：逐条补发货并 finish，保证恢复流程与 Android 一致
        await this.dealPurchaseData(purchaseData)
      }
    } catch (err) {
      const e = err as BusinessError
      DebugLog.e(`Failed to query consumable purchases. Code: ${e.code}, message: ${e.message}`)
    }
  }

  /**
   * 处理 purchaseData
   * @param purchaseData 华为购买结果原始 JSON
   */
  private async dealPurchaseData(purchaseData: string): Promise<void> {
    try {
      const parsed: PurchaseData = JSON.parse(purchaseData)
      const jwsPurchaseOrder = parsed.jwsPurchaseOrder

      if (!jwsPurchaseOrder) {
        return
      }

      const purchaseOrderStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder)

      if (!purchaseOrderStr) {
        return
      }

      const purchaseOrder: PurchaseOrderPayload = JSON.parse(purchaseOrderStr)

      // 调用：先按需补发货，避免 finish 之前遗漏会员时间
      this.deliverIfNotDelivered(purchaseOrder.productId, purchaseOrder.purchaseToken)

      // 分支：未完成订单需调用 finishPurchase 收口
      if (purchaseOrder.finishStatus !== FinishStatus.FINISHED) {
        await this.finishPurchase(purchaseOrder)
      }
    } catch (err) {
      DebugLog.e(`dealPurchaseData error: ${err}`)
    }
  }

  /**
   * 成功支付后的幂等发货逻辑
   * @param productId 商品 id
   * @param purchaseToken 华为订单 token
   */
  private deliverIfNotDelivered(productId: string | null | undefined, purchaseToken: string | null | undefined): void {

    // 分支：无有效商品 id 时无法发货
    if (productId === null || productId === undefined || productId.length < 1) {
      return
    }

    // 分支：有 token 时按 token 做幂等控制
    if (purchaseToken !== null && purchaseToken !== undefined && purchaseToken.length > 0) {
      if (this.isTokenDelivered(purchaseToken)) {
        return
      }

      this.deliverAndSaveMemberTime(productId, purchaseToken)
      this.markTokenDelivered(purchaseToken)
      return
    }

    // 分支：极端场景没有 token 时，退化为直接发货一次
    this.deliverAndSaveMemberTime(productId, null)
  }

  /**
   * 根据消耗型 SKU 对应时长交付会员时间并保存到 SubscribeManager
   * @param productId 商品 id
   * @param purchaseToken 华为订单 token
   */
  private deliverAndSaveMemberTime(productId: string, purchaseToken: string | null): void {
    let months = 0

    switch (productId) {
      case HwPurchaseConstants.SKU_7:  months = 12; break
      case HwPurchaseConstants.SKU_8:  months = 24; break
      case HwPurchaseConstants.SKU_9:  months = 36; break
      case HwPurchaseConstants.SKU_10: months = 60; break
      default: return
    }

    const nowMs = Date.now()
    const currentExpires = SubscribeManager.shared.currentItem?.expiresDateMs ?? 0
    const baseMs = currentExpires > nowMs ? currentExpires : nowMs
    const expireDate = new Date(baseMs)

    expireDate.setMonth(expireDate.getMonth() + months)

    const newItem = new SubscribeItem(
      productId,
      expireDate.getTime(),
      purchaseToken,
      'huawei'
    )

    // 调用：保存本地最新会员时间，并同步触发会员状态刷新通知
    SubscribeManager.shared.saveNewItemIfNeeds(newItem)

    // 调用：与 Android 一致，发货后异步刷新服务器订阅信息
    SubscriptionInfoManager.shared.asyncRefreshSubscriptionInfo()
  }

  // 自动恢复并清理所有未完成消耗型订单
  private async autoConsumeUnfinishedPurchases(): Promise<void> {

    // 调用：恢复并清理所有未完成消耗型订单
    await this.queryPurchases(iap.PurchaseQueryType.ALL)
  }

  /**
   * 提供给外部调用的恢复入口
   */
  async recoverUnfinishedConsumablePurchases(): Promise<void> {

    // 调用：恢复并清理所有未完成消耗型订单
    await this.autoConsumeUnfinishedPurchases()
  }

  /**
   * 完成购买（确认发货）
   * @param purchaseOrder 华为订单对象
   */
  private async finishPurchase(purchaseOrder: PurchaseOrderPayload): Promise<void> {
    if (!purchaseOrder.productType) {
      DebugLog.e('finishPurchase: productType missing')
      return
    }

    const param: iap.FinishPurchaseParameter = {
      productType     : Number(purchaseOrder.productType),
      purchaseToken   : purchaseOrder.purchaseToken,
      purchaseOrderId : purchaseOrder.purchaseOrderId
    }

    try {
      await iap.finishPurchase(this.context, param)
    } catch (err) {
      const e = err as BusinessError
      DebugLog.e(`Failed to finish consumable purchase. Code: ${e.code}, message: ${e.message}`)
    }
  }
}
