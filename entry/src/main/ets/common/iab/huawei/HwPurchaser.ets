import { iap } from '@kit.IAPKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { preferences } from '@kit.ArkData'
import { getAppContext } from '../../../app/constants/AppContext'
import { DebugLog } from '../../../app/debug/DebugLog'
import { SubscribeItem, SubscribeManager } from '../SubscribeManager'
import { SubscriptionInfoManager } from '../../../models/managers/subscription/SubscriptionInfoManager'
import { HwPurchaseConstants } from './HwPurchaseConstants'
import { FinishStatus, PurchaseData, PurchaseOrderPayload } from './utils/IapDataModel'
import { JWSUtil } from './utils/JWSUtil'


// ---------------------------------------------------------------------------
// 本地 Preferences：按 purchaseToken 记录已发货，避免重复叠加会员（与 DeliverPref 表名一致）
// ---------------------------------------------------------------------------
class DeliverPref {
  static readonly NAME                 : string = 'HwConsumableDeliver'
  static readonly KEY_DELIVERED_TOKENS : string = 'DeliveredTokens'
}


// ---------------------------------------------------------------------------
// HwPurchaser：华为 IAP 消耗型一次性购买（与 HwPurchaseConstants 一致；自动续订用 HwSubscriber）
//
// 类内顺序：① public（初始化 → 购前查商品 → 发起购买 → 恢复）② private 流程（拉单→解析→交付→finish）③ private 工具（Pref）
// 流程：消耗型 queryPurchases(UNFINISHED) → 解码 → 发货（DeliveredTokens）→ finishPurchase(CONSUMABLE)；finish 成功后再刷服务器订阅。
// ---------------------------------------------------------------------------
export class HwPurchaser {
  private static _shared                 : HwPurchaser | null              = null
  private        context                 : common.UIAbilityContext         = {} as common.UIAbilityContext


  private constructor() {

    // 调用：绑定全局 Context
    this.init()
  }


  // ---------------------------------------------------------------------------
  // MARK: - Public（初始化 → 购买 → 恢复）
  // ---------------------------------------------------------------------------

  // 单例 / 初始化入口
  static get shared(): HwPurchaser {

    // 分支：首次创建单例
    if (!HwPurchaser._shared) {

      // 调用：构造 Purchaser 单例
      HwPurchaser._shared = new HwPurchaser()
    }

    return HwPurchaser._shared
  }


  // 购前：查询当前配置的消耗型会员商品（会员页价格区）
  async queryProducts(): Promise<iap.Product[] | null> {
    const param: iap.QueryProductsParameter = {
      productIds  : HwPurchaseConstants.ALL_SKUS,
      productType : iap.ProductType.CONSUMABLE
    }

    try {

      // 调用：IAP Kit 拉取商品详情
      const result: iap.Product[] = await iap.queryProducts(this.context, param)

      return result.sort((a, b) => a.id.localeCompare(b.id)) ?? []
    } catch (err) {
      const e: BusinessError = err as BusinessError

      // 调用：输出查询失败日志
      DebugLog.e(`Failed to query consumable products. Code: ${e.code}, message: ${e.message}`)

      return null
    }
  }


  // 购前：加载消耗型商品列表（与 Android loadAllProducts 命名对齐）
  async loadAllProducts(): Promise<iap.Product[] | null> {

    // 调用：查询消耗型商品
    return await this.queryProducts()
  }


  /**
   * 购买：对外购买入口（内部走 createPurchase）
   * @param productId 华为商品 id
   */
  async purchaseProduct(productId: string): Promise<boolean> {

    // 调用：拉起购买并处理结果
    return await this.createPurchase(productId)
  }


  /**
   * 购买：拉起收银台并处理支付结果（发货 + finish）；购前先恢复未发货单
   * @param productId 华为商品 id
   */
  async createPurchase(productId: string): Promise<boolean> {

    // 调用：购前恢复未发货消耗型单
    await this.queryUnfinishedConsumablesAndProcess()

    const param: iap.PurchaseParameter = {
      productId   : productId,
      productType : iap.ProductType.CONSUMABLE
    }

    try {

      // 调用：拉起 IAP 收银台并完成支付
      const result = await iap.createPurchase(this.context, param)

      // 调用：解析结果并走交付与 finish
      await this.dealPurchaseData(result.purchaseData)

      return true
    } catch (err) {
      const e: BusinessError = err as BusinessError

      // 调用：输出创建购买失败日志
      DebugLog.e(`Failed to create purchase. Code: ${e.code}, message: ${e.message}`)

      // 分支：已拥有或系统异常时补拉未发货单
      if (e.code === iap.IAPErrorCode.PRODUCT_OWNED || e.code === iap.IAPErrorCode.SYSTEM_ERROR) {

        // 调用：消耗型 UNFINISHED 补拉并处理
        await this.queryUnfinishedConsumablesAndProcess()
      }

      return false
    }
  }


  // 恢复：冷启动等场景补处理未发货 IAP 单
  async restore(): Promise<void> {

    // 调用：拉取消耗型 UNFINISHED 并完成交付与 finish
    await this.queryUnfinishedConsumablesAndProcess()
  }


  // 恢复：会员页等入口（方法名保留历史）
  async recoverUnfinishedConsumablePurchases(): Promise<void> {

    // 调用：与 restore 相同
    await this.queryUnfinishedConsumablesAndProcess()
  }


  // ---------------------------------------------------------------------------
  // MARK: - Private / 流程（拉单 → 解析与编排 → 交付 → 消耗）
  // ---------------------------------------------------------------------------

  // 绑定全局 UIAbilityContext，供 IAP Kit 使用
  private init(): void {

    // 调用：取应用全局 Context
    this.context = getAppContext()
  }


  // 仅消耗型：查询 UNFINISHED 订单并逐条 dealPurchaseData
  private async queryUnfinishedConsumablesAndProcess(): Promise<void> {
    const param: iap.QueryPurchasesParameter = {
      productType : iap.ProductType.CONSUMABLE,
      queryType   : iap.PurchaseQueryType.UNFINISHED
    }

    try {

      // 调用：查询已购订单
      const res = await iap.queryPurchases(this.context, param)
      const purchaseDataList: string[] = res.purchaseDataList ?? []

      // 遍历：未完成订单列表
      for (const purchaseData of purchaseDataList) {

        // 调用：单条交付与 finish
        await this.dealPurchaseData(purchaseData)
      }
    } catch (err) {
      const e: BusinessError = err as BusinessError

      // 调用：输出拉单失败日志
      DebugLog.e(`Failed to query consumable UNFINISHED. Code: ${e.code}, message: ${e.message}`)
    }
  }


  /**
   * 解析 purchaseData：先幂等交付，再在 UNFINISHED 时 finishPurchase（固定消耗型）
   * @param purchaseData 华为返回的购买 JSON 字符串
   */
  private async dealPurchaseData(purchaseData: string): Promise<void> {
    try {

      // 调用：解析购买外层 JSON
      const parsed: PurchaseData = JSON.parse(purchaseData)
      const jwsPurchaseOrder: string | undefined = parsed.jwsPurchaseOrder

      // 分支：无订单 JWS
      if (!jwsPurchaseOrder) {
        return
      }

      // 调用：JWS 解码为明文字符串
      const purchaseOrderStr: string | null = JWSUtil.decodeJwsObj(jwsPurchaseOrder)

      // 分支：解码失败
      if (!purchaseOrderStr) {
        return
      }

      // 调用：解析订单载荷 JSON
      const purchaseOrder: PurchaseOrderPayload = JSON.parse(purchaseOrderStr)

      // 调用：幂等交付
      this.deliverIfNotDelivered(purchaseOrder.productId, purchaseOrder.purchaseToken)

      const finishedOnIap: boolean = String(purchaseOrder.finishStatus ?? '') === FinishStatus.FINISHED

      // 分支：IAP 仍标记未发货时需 finish（消耗确认）
      if (!finishedOnIap) {

        // 调用：向华为 IAP 确认发货（消耗）
        const finishedOk: boolean = await this.finishPurchase(purchaseOrder)

        // 分支：finish 成功后再拉一次服务器订阅（发货路径里可能已刷过，此处与 IAP 状态对齐）
        if (finishedOk) {

          // 调用：同步订阅信息到服务器
          SubscriptionInfoManager.shared.asyncRefreshSubscriptionInfo()
        }
      }
    } catch (err) {

      // 调用：输出解析或处理异常日志
      DebugLog.e(`dealPurchaseData error: ${err}`)
    }
  }


  /**
   * 交付：按 purchaseToken 幂等发放会员权益（无 token 时兜底发货一次）
   * @param productId     商品 id
   * @param purchaseToken 订单 token，可为空
   */
  private deliverIfNotDelivered(productId: string | null | undefined, purchaseToken: string | null | undefined): void {

    // 分支：无有效商品 id
    if (productId === null || productId === undefined || productId.length < 1) {
      return
    }

    // 分支：有 token 时做幂等
    if (purchaseToken !== null && purchaseToken !== undefined && purchaseToken.length > 0) {

      // 调用：判断是否已交付
      if (this.isTokenDelivered(purchaseToken)) {

        // 分支：该 token 已交付过，不再发货
        return
      }

      // 调用：写入会员时间与通知
      this.deliverAndSaveMemberTime(productId, purchaseToken)

      // 调用：记录已交付 token
      this.markTokenDelivered(purchaseToken)

      return
    }

    // 分支：无 token 的兜底交付
    // 调用：按 SKU 写入会员（无 token）
    this.deliverAndSaveMemberTime(productId, null)
  }


  /**
   * 交付：按 SKU 叠加会员时长并写入 SubscribeManager，再刷新服务器订阅信息
   * @param productId     商品 id
   * @param purchaseToken 订单 token，可为空
   */
  private deliverAndSaveMemberTime(productId: string, purchaseToken: string | null): void {
    let months: number = 0

    switch (productId) {
      case HwPurchaseConstants.SKU_7  : months = 12; break                               // 包 1 年会员
      case HwPurchaseConstants.SKU_8  : months = 24; break                               // 包 2 年会员
      case HwPurchaseConstants.SKU_9  : months = 36; break                               // 包 3 年会员
      case HwPurchaseConstants.SKU_10 : months = 60; break                               // 包 5 年会员
      default                         : return                                                 // 非本模块 SKU
    }

    const nowMs          : number = Date.now()
    const currentExpires : number = SubscribeManager.shared.currentItem?.expiresDateMs ?? 0
    const baseMs         : number = currentExpires > nowMs ? currentExpires : nowMs
    const expireDate     : Date   = new Date(baseMs)

    // 调用：在基准时间上叠加月份
    expireDate.setMonth(expireDate.getMonth() + months)

    // 调用：构造订阅项
    const newItem: SubscribeItem = new SubscribeItem(
      productId,
      expireDate.getTime(),
      purchaseToken,
      'huawei'
    )

    // 调用：保存本地订阅项并通知 UI
    SubscribeManager.shared.saveNewItemIfNeeds(newItem)

    // 调用：异步刷新服务器订阅信息
    SubscriptionInfoManager.shared.asyncRefreshSubscriptionInfo()
  }


  /**
   * 消耗：向 IAP 确认发货（finishPurchase），本类仅支持消耗型
   * @param purchaseOrder 解码后的订单
   * @returns finishPurchase 是否成功
   */
  private async finishPurchase(purchaseOrder: PurchaseOrderPayload): Promise<boolean> {

    // 分支：缺少 purchaseToken
    if (!purchaseOrder.purchaseToken || purchaseOrder.purchaseToken.length < 1) {

      // 调用：输出参数缺失日志
      DebugLog.e('finishPurchase: purchaseToken missing')

      return false
    }

    // 分支：缺少 purchaseOrderId
    if (!purchaseOrder.purchaseOrderId || purchaseOrder.purchaseOrderId.length < 1) {

      // 调用：输出参数缺失日志
      DebugLog.e('finishPurchase: purchaseOrderId missing')

      return false
    }

    const param: iap.FinishPurchaseParameter = {
      productType     : iap.ProductType.CONSUMABLE,
      purchaseOrderId : purchaseOrder.purchaseOrderId,
      purchaseToken   : purchaseOrder.purchaseToken
    }

    try {

      // 调用：IAP 确认发货（消耗型）
      await iap.finishPurchase(this.context, param)

      // 调用：输出成功日志
      DebugLog.i(`HwPurchaser finishPurchase ok, orderId=${purchaseOrder.purchaseOrderId}`)

      return true
    } catch (err) {
      const e: BusinessError = err as BusinessError

      // 调用：输出 finish 失败日志
      DebugLog.e(`Failed to finish purchase. Code: ${e.code}, message: ${e.message}`)

      return false
    }
  }


  // ---------------------------------------------------------------------------
  // MARK: - Private / 工具（Pref）
  // ---------------------------------------------------------------------------

  // 工具：读取发货幂等（DeliveredTokens）使用的 Preferences
  private getDeliverPref(): preferences.Preferences | null {

    // 调用：同步读取 Preferences
    return preferences.getPreferencesSync(getAppContext(), { name: DeliverPref.NAME })
  }


  /**
   * 工具：判断 purchaseToken 是否已做过权益交付
   * @param purchaseToken 华为订单 token
   */
  private isTokenDelivered(purchaseToken: string): boolean {

    // 调用：打开发货幂等 Pref
    const pref: preferences.Preferences | null = this.getDeliverPref()

    // 分支：无法打开 pref
    if (!pref) {
      return false
    }

    const json: string = pref.getSync(DeliverPref.KEY_DELIVERED_TOKENS, '[]') as string

    try {

      // 调用：解析已交付 token 列表
      const tokens: string[] = JSON.parse(json) as string[]

      return tokens.includes(purchaseToken)
    } catch (_e) {

      return false
    }
  }


  /**
   * 工具：记录已完成权益交付的 token（DeliveredTokens）
   * @param purchaseToken 华为订单 token
   */
  private markTokenDelivered(purchaseToken: string): void {

    // 调用：打开发货幂等 Pref
    const pref: preferences.Preferences | null = this.getDeliverPref()

    // 分支：无法写入
    if (!pref) {
      return
    }

    const json: string = pref.getSync(DeliverPref.KEY_DELIVERED_TOKENS, '[]') as string
    let   tokens: string[] = []

    try {

      // 调用：解析已交付 token 列表
      tokens = JSON.parse(json) as string[]
    } catch (_e) {
      tokens = []
    }

    // 分支：已存在
    if (tokens.includes(purchaseToken)) {
      return
    }

    tokens.push(purchaseToken)

    // 调用：持久化已交付列表
    pref.putSync(DeliverPref.KEY_DELIVERED_TOKENS, JSON.stringify(tokens))

    // 调用：刷盘
    pref.flushSync()
  }
}
