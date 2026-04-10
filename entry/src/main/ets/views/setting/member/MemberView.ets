import { iap } from '@kit.IAPKit'
import { AppSettings } from "../../../app/constants/AppSettings"
import { TextStyleButton } from "../../../app/views/buttons/TextStyleButton"
import { TextStyleButtonStyle } from "../../../app/views/buttons/TextStyleButton"
import { LinkText } from "../../../app/views/LinkText"
import { LinkView, LinkViewConfig } from "../../../app/views/LinkView"
import { NavBarView } from "../../../app/views/NavBarView"
import { getString, getStringF } from "../../../common/utils/ResourceUtils"
import { HwSubscriber } from "../../../common/iab/huawei/HwSubscriber"
import { SubscribeManager, SubscribeManagerNotification } from "../../../common/iab/SubscribeManager"
import { MemberManager } from "../../../models/managers/member/MemberManager"
import { SubscriptionInfoManager } from "../../../models/managers/subscription/SubscriptionInfoManager"
import { Toast } from "../../../common/utils/Toast"
import { bounce } from "../../../common/extentions/AnimBounce"
import { TextButton } from "../../../app/views/buttons/TextButton"
import { HwSubscribeConstants } from "../../../common/iab/huawei/HwSubscribeConstants"
import { SimpleEventBus } from "../../../common/components/eventbus/SimpleEventBus"
import { AppCfgManager } from "../../../models/managers/servercfg/AppCfgManager"
import { HwPurchaser } from "../../../common/iab/huawei/HwPurchaser"
import { HwPurchaseConstants } from "../../../common/iab/huawei/HwPurchaseConstants"
import { PriceButtonView } from "./PriceButtonView"
import { UserManager } from "../../../models/managers/user/UserManager"
import { dScreenWidth } from "../../../app/constants/AppDefines"

export namespace MemberViewConfig {
  export const kNavPath = "Member_kNavPath" // 会员页内部协议页面导航栈 key
}

interface PriceDisplayItem {
  tag          : number       // 价格按钮序号：0~2 为订阅，3+ 为一次性购买
  product      : iap.Product  // 华为商品信息
  isConsumable : boolean      // 是否为一次性购买商品
}

interface PriceCompareItem {
  productId    : string  // 商品 id
  microsPrice  : number  // 商品总价（微单位）
  months       : number  // 对应会员月数
}

@ComponentV2
export struct MemberView {
  private static readonly PRICE_BUTTON_WIDTH_VP      : number = 90  // 单个价格按钮宽度
  private static readonly PRICE_SCROLL_PADDING_VP    : number = 20  // 横向滚动区左右总留白
  private static readonly PRICE_BUTTON_SPACING_VP    : number = 15  // 价格按钮之间的间距
  private static readonly CONTENT_HORIZONTAL_PAD_VP  : number = 40  // 内容区左右内边距总和

  @Param   @Require isShowing                        : boolean                            // 当前会员页是否显示
  @Event   $isShowing                                : (val: boolean) => void             = (_val: boolean) => {}
  @Event   onClose                                   : (changed: boolean) => void         = (_changed: boolean) => {}

  @Local private memberExpiryDate                    : string                             = ''           // 顶部会员到期时间文案
  @Local private memberExpiryDateColor               : ResourceColor                      = Color.White  // 顶部会员到期时间颜色
  @Local private isAgree                             : boolean                            = false        // 是否已勾选协议
  @Local private isBuyButtonEnabled                  : boolean                            = false        // 购买按钮是否可点击
  @Local private isSubscribeEnable                   : boolean                            = false        // 华为 IAP 环境是否可用

  @Local private showConsumablePriceButtons          : boolean                            = true         // 是否显示一次性购买按钮
  @Local private subscriptionProducts                : iap.Product[]                      = []           // 订阅商品列表
  @Local private consumableProducts                  : iap.Product[]                      = []           // 一次性购买商品列表
  @Local private selectedPriceTag                    : number                             = -1           // 当前选中的价格按钮 tag

  @Local private isShowConfirmSubscribe              : boolean                            = false        // 是否显示订阅确认弹层
  @Local private checkAgreeShakeOffsetX              : number                             = 0            // 协议区域抖动偏移量
  @Local private isRestoringConsumablePurchases      : boolean                            = false        // 是否正在恢复一次性购买订单

  @Provider(MemberViewConfig.kNavPath) navPath       : NavPathStack                       = new NavPathStack() // 内部协议页导航栈

  aboutToAppear(): void {

    // 调用：进入页面时同步恢复订阅、本地会员信息与价格区
    this.onChangeOfShowing()

    // 调用：加载价格、显隐控制与当前默认选中项
    void this.loadPriceAndShowInfoIfNeeds()

    // 调用：监听会员时间变化通知，及时刷新顶部文案与购买按钮状态
    SimpleEventBus.on(SubscribeManagerNotification.expireDateUpdated, () => {
      this.showMememberInfo()
      this.refreshBtnBuy()
    })
  }

  aboutToDisappear(): void {

    // 调用：页面销毁时移除会员时间通知监听
    SimpleEventBus.off(SubscribeManagerNotification.expireDateUpdated)
  }

  // 与 Android `onStart` / `onChangeOfShowing` 对齐：恢复订阅并刷新会员信息
  private onChangeOfShowing(): void {

    // 调用：自动恢复已经有的订阅
    void HwSubscriber.shared.restore()

    // 调用：判断时间间隔，自动刷新订阅信息
    SubscriptionInfoManager.shared.autoRefreshSubscriptionInfoIfNeeds()

    // 调用：显示会员信息
    this.showMememberInfo()
  }

  build() {
    Navigation(this.navPath) {
      this.buildMain()
    }
      .navDestination(this.navigationTo)
      .navBarPosition(NavBarPosition.Start)
      .hideTitleBar(true)
      .backgroundColor($r('app.color.color_background'))
  }

  /**
   * 路由到内部协议页面
   * @param name 目标路由名
   * @param param 路由参数
   */
  @Builder
  navigationTo<T>(name: string, param: T) {
    if (name === LinkViewConfig.NavKey) {
      LinkView({
        title : (param as LinkViewConfig.Param).title,
        url   : (param as LinkViewConfig.Param).url
      })
    } else {
      NavDestination() {
        Text(`<MemberView.ets>未配置navigationTo: ${name}`)
      }
    }
  }

  @Builder
  private buildMain() {
    Column() {
      Scroll() {
        Stack() {
          Column() {

            // 调用：构建顶部导航栏
            this.buildNavBar()

            // 调用：构建标题栏（标题 + 恢复按钮）
            this.buildTitleBar()

            // 调用：构建主要内容区
            this.buildContentSection()

            // 调用：构建底部购买区与协议区
            this.buildActionSection()
          }
            .width('100%')

          if (this.isShowConfirmSubscribe) {
            this.buildConfirmDialogView(() => {
              void this.doSubscribe()
            })
          }
        }
      }
        .scrollBar(BarState.Off)
    }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.colorPrimary'))
  }

  // 构建导航栏
  @Builder
  private buildNavBar() {
    NavBarView({
      title       : $r('app.string.member_title'),
      leftButtons : [{
        text   : $r('app.string.member_btn_cancel'),
        onClick: () => {
          this.$isShowing(false)
        }
      }],
      rightButtons: this.isSelectedConsumablePrice() ? [] : [{
        text   : $r('app.string.member_btn_manage_subs'),
        onClick: () => {

          // 调用：打开华为已购订阅管理页面
          this.showViewSubscription()
        }
      }]
    })
      .margin(10)
  }

  // 构建标题栏（标题 + 恢复按钮）
  @Builder
  private buildTitleBar() {
    Row() {
      Text($r('app.string.member_title'))
        .fontSize(20)
        .fontColor(Color.White)
        .layoutWeight(1)

      if (this.isSelectedConsumablePrice()) {
        TextButton({
          text            : $r('app.string.member_btn_restore'),
          onClickCallBack : () => {

            // 调用：恢复可能遗留的未完成单次购买订单
            void this.actionRestoreConsumablePurchases()
          }
        })
      }
    }
      .width('100%')
      .padding({ left: 10, right: 10 })
      .margin({ top: 10 })
      .alignItems(VerticalAlign.Center)
  }

  // 构建主要内容区域
  @Builder
  private buildContentSection() {
    Column() {
      Text($r('app.string.member_desc'))
        .fontColor(Color.White)
        .fontSize(18)
        .textAlign(TextAlign.Start)
        .width('100%')

      if (this.visiblePriceItems().length > 0) {

        // 调用：构建价格卡片区域
        this.buildPriceOptions()

        Text(this.getPriceTip())
          .fontColor($r('app.color.colorAccent'))
          .fontSize(12)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 10 })
      } else {

        // 调用：构建价格加载态
        this.buildLoading()
      }

      Text(this.currentInfoText())
        .fontColor($r('app.color.color_obscure'))
        .fontSize(12)
        .textAlign(TextAlign.Start)
        .width('100%')
        .margin({ top: 5 })

    }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20 })
      .alignItems(HorizontalAlign.Start)
  }

  // 构建价格选项区域
  @Builder
  private buildPriceOptions() {
    Scroll() {
      Row({ space: 15 }) {
        ForEach(this.visiblePriceItems(), (item: PriceDisplayItem) => {
          PriceButtonView({
            title           : this.loadPriceTitle(item.product.id),
            price           : item.product.localPrice,
            term            : this.localizedPeriod(item.product.id),
            tagText         : this.loadPriceTagText(item),
            perMonth        : this.calcPerMonthText(item.product),
            isSelected      : this.selectedPriceTag === item.tag,
            onClickCallBack : () => {

              // 调用：选中当前价格卡片，联动刷新文案、按钮与协议区
              this.selectPrice(item.tag)
            }
          })
        }, (item: PriceDisplayItem) => `${item.tag}_${item.product.id}`)
      }
        .width(this.shouldCenterPriceButtons() ? '100%' : 'auto')
        .justifyContent(this.shouldCenterPriceButtons() ? FlexAlign.Center : FlexAlign.Start)
        .margin({ top: 10 })
    }
      .width('100%')
      .padding({ left: 10, right: 10 })
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
  }

  // 构建价格加载态
  @Builder
  private buildLoading() {
    Row() {
      LoadingProgress()
        .height(32)
        .width(48)
    }
      .height(100)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 10 })
  }

  // 构建底部购买区与协议区
  @Builder
  private buildActionSection() {
    Column() {

      // 调用：构建购买按钮与会员有效期区域
      this.buildSubscribeSection()

      // 调用：构建协议确认区域
      this.buildAgreementCheckSection()
    }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Center)
  }

  // 构建购买按钮与会员日期区域
  @Builder
  private buildSubscribeSection() {
    Column() {
      TextStyleButton({
        text            : $r('app.string.member_btn_subscribe'),
        style           : TextStyleButtonStyle.LIGHT,
        minWidth        : 220,
        isEnabled       : this.isBuyButtonEnabled,
        onClickCallBack : () => {

          // 调用：执行订阅或单次购买入口
          this.actionSubscribe()
        }
      })

      Text(this.memberExpiryDate)
        .fontColor(this.memberExpiryDateColor)
        .fontSize(12)
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 5 })
    }
      .width('100%')
      .margin({ top: 10 })
  }

  // 构建协议确认区域
  @Builder
  private buildAgreementCheckSection() {
    Row() {
      Row({ space: 0 }) {
        Checkbox()
          .select(this.isAgree)
          .onChange((value: boolean) => {
            this.isAgree = value
          })

        LinkText({
          content    : this.currentAgreeText(),
          linkTexts  : this.currentAgreeLinks(),
          textStyle  : {
            maxLines : 2,
            fontSize : 12
          },
          onLinkTapped: (text: string) => {

            // 调用：按当前点击的链接打开对应协议页
            this.openAgreeLink(text)
          }
        })
      }
        .offset({ x: this.checkAgreeShakeOffsetX, y: 0 })
    }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 10, bottom: 60 })
  }

  // 加载价格并显示会员信息
  private async loadPriceAndShowInfoIfNeeds(): Promise<void> {

    // 调用：读取服务器配置，决定是否显示后三个单次购买按钮
    this.showConsumablePriceButtons = false //AppCfgManager.shared.isHwMember_Show_ConsumablePriceButtons_is_ON()

    // 调用：进入页面时，先恢复一次可能遗留的未完成单次购买订单。
    // 这里是一次性购买的恢复逻辑，和订阅恢复要区分开。
    await HwPurchaser.shared.recoverUnfinishedConsumablePurchases()

    // 调用：检查华为订阅购买环境。
    // 当前页面的购买区共用同一套华为 IAP 环境检查结果。
    this.isSubscribeEnable = await HwSubscriber.shared.queryEnvironmentStatus() === 0

    // 调用：加载订阅商品。
    // 订阅商品是连续包月 / 连续包季 / 连续包年。
    this.subscriptionProducts = await HwSubscriber.shared.loadAllProducts() || []

    // 分支：开启一次性购买按钮时，再加载消耗型商品。
    // 一次性购买是固定时长会员，不会自动续期。
    if (this.showConsumablePriceButtons) {
      this.consumableProducts = await HwPurchaser.shared.loadAllProducts() || []
    } else {
      this.consumableProducts = []
    }

    // 调用：显示顶部会员信息
    this.showMememberInfo()

    // 调用：根据当前会员状态与商品列表，设置默认选中项
    this.selectDefaultPriceIfNeeds()

    // 调用：刷新购买按钮状态
    this.refreshBtnBuy()
  }

  // 打开华为订阅管理页面
  private showViewSubscription(): void {

    // 调用：打开已购订阅管理页
    void HwSubscriber.shared.showManagedSubscriptions()
  }

  // 执行购买入口
  private actionSubscribe(): void {

    // 分支：未勾选协议时给出提示并抖动
    if (!this.checkAgree()) {
      return
    }

    // 分支：一次性购买需先登录，便于后续把会员时间写回当前登录账户。
    if (this.isSelectedConsumablePrice() && !UserManager.shared.isLogin()) {
      Toast.showMessage($r('app.string.login_not_login'))
      return
    }

    // 分支：订阅购买前弹确认框；一次性购买直接进入购买。
    // 这里必须区分两个概念：
    // 1. 订阅：华为账户自动续费
    // 2. 一次性购买：登录账户固定时长会员，不自动续期
    if (this.isSelectedConsumablePrice()) {

      // 调用：直接发起一次性购买
      void this.doSubscribe()
    } else {
      this.isShowConfirmSubscribe = true
    }
  }

  // 执行订阅或单次购买
  private async doSubscribe(): Promise<void> {
    const item = this.selectedPriceItem()

    // 分支：无选中商品时直接返回
    if (item === null) {
      return
    }

    let succeed = false

    // 分支：一次性购买走 HwPurchaser；订阅走 HwSubscriber。
    // 订阅与一次性购买的订单处理、发货与恢复逻辑都不同，不能混用。
    if (item.isConsumable) {
      succeed = await HwPurchaser.shared.purchaseProduct(item.product.id)
    } else {
      succeed = await HwSubscriber.shared.purchaseProduct(item.product.id)
    }

    // 调用：购买流程结束后刷新按钮状态
    this.refreshBtnBuy()

    // 调用：显示最新会员时间
    this.showMememberInfo()

    if (succeed) {

      // 调用：通知外层当前会员状态已经发生变化
      this.onClose(true)

      this.$isShowing(false)
      Toast.showMessage($r('app.string.member_btn_subscribe_done'))

      // 调用：购买成功后刷新服务器订阅信息
      SubscriptionInfoManager.shared.asyncRefreshSubscriptionInfo()
    }
  }

  // 恢复未完成的一次性购买订单
  private async actionRestoreConsumablePurchases(): Promise<void> {

    // 分支：避免重复触发恢复流程
    if (this.isRestoringConsumablePurchases) {
      return
    }

    this.isRestoringConsumablePurchases = true
    Toast.showMessage($r('app.string.member_msg_restoring'))

    // 调用：恢复并清理历史未完成的一次性购买订单。
    // 当前恢复按钮只针对一次性购买；订阅不显示这个按钮。
    await HwPurchaser.shared.recoverUnfinishedConsumablePurchases()

    this.isRestoringConsumablePurchases = false

    // 调用：恢复完成后刷新会员状态和购买按钮
    this.showMememberInfo()
    this.refreshBtnBuy()
    Toast.showMessage($r('app.string.member_msg_restore_done'))
  }

  // 校验是否已同意协议
  private checkAgree(): boolean {
    if (!this.isAgree) {
      this.shakeCheckAgree()
      Toast.showMessage(this.isSelectedConsumablePrice()
        ? $r('app.string.member_agree_consume_tip')
        : $r('app.string.member_agree_tip'))
      return false
    }

    return true
  }

  // 抖动协议确认区域
  private shakeCheckAgree(): void {
    bounce({
      set        : (x: number, _y: number) => { this.checkAgreeShakeOffsetX = x },
      isHorizontal : true,
      onFinished : () => {}
    })
  }

  // 显示顶部会员有效期文案
  private showMememberInfo(): void {
    const expireDate = MemberManager.shared.expireDate

    if (expireDate) {

      // 分支：当前仍在会员有效期内
      if (MemberManager.shared.isActive) {
        this.memberExpiryDate = getStringF($r('app.string.member_txt_will_expire'), MemberManager.shared.expireDateString)
        this.memberExpiryDateColor = $r('app.color.color_white')
      } else {

        // 分支：会员已过期
        this.memberExpiryDate = getStringF($r('app.string.member_txt_was_expired'), MemberManager.shared.expireDateString)
        this.memberExpiryDateColor = $r('app.color.colorAccent')
      }
    } else {
      this.memberExpiryDate = ''
    }
  }

  /**
   * 选中某个价格按钮，并联动刷新说明区与购买按钮
   * @param tag 价格按钮序号；0~2 为订阅，3~5 为一次性购买
   */
  private selectPrice(tag: number): void {
    this.selectedPriceTag = tag

    // 调用：价格选中变化后刷新购买按钮状态
    this.refreshBtnBuy()
  }

  // 默认选中当前会员项或最后一个订阅项
  private selectDefaultPriceIfNeeds(): void {
    const currentSku = SubscribeManager.shared.currentItem?.sku

    if (currentSku !== null && currentSku !== undefined) {
      const matched = this.visiblePriceItems().find((item: PriceDisplayItem) => item.product.id === currentSku)

      // 分支：当前会员 sku 在可见商品中时，默认选中该项
      if (matched !== undefined) {
        this.selectedPriceTag = matched.tag
        return
      }
    }

    // 分支：否则默认选中第三个订阅项；若不存在，则退化为最后一个可见项
    if (this.subscriptionProducts.length >= 3) {
      this.selectedPriceTag = 2
      return
    }

    const visibleItems = this.visiblePriceItems()
    const lastVisible = visibleItems.length > 0 ? visibleItems[visibleItems.length - 1] : null
    this.selectedPriceTag = lastVisible ? lastVisible.tag : -1
  }

  // 刷新购买按钮状态
  private refreshBtnBuy(): void {
    const item = this.selectedPriceItem()

    // 分支：未加载到可选商品或环境不可用时禁用购买按钮
    if (item === null || !this.isSubscribeEnable) {
      this.isBuyButtonEnabled = false
      return
    }

    // 分支：订阅型若当前已是同 sku 的有效会员，则禁用购买按钮
    if (!item.isConsumable) {
      const currentItem = SubscribeManager.shared.currentItem

      if ((currentItem?.isActive ?? false) && currentItem?.sku === item.product.id) {
        this.isBuyButtonEnabled = false
        return
      }
    }

    this.isBuyButtonEnabled = true
  }

  // 获取当前价格提示文案
  private getPriceTip(): string {
    const item = this.selectedPriceItem()

    if (item === null) {
      return ''
    }

    const priceFloat = item.product.microPrice / 1_000_000
    const price = this.formatFloat(priceFloat)

    switch (item.product.id) {
      case HwSubscribeConstants.SKU_1:
        return getStringF($r('app.string.member_sub_tip_month'), price)
      case HwSubscribeConstants.SKU_2:
        return getStringF($r('app.string.member_sub_tip_quarter'), price, this.formatFloat(priceFloat / 3))
      case HwSubscribeConstants.SKU_3:
        return getStringF($r('app.string.member_sub_tip_year'), price, this.formatFloat(priceFloat / 12))
      case HwPurchaseConstants.SKU_7:
        return `12个月会员，${price}元，相当于${this.formatFloat(priceFloat / 12)}元/月`
      case HwPurchaseConstants.SKU_8:
        return `24个月会员，${price}元，相当于${this.formatFloat(priceFloat / 24)}元/月`
      case HwPurchaseConstants.SKU_9:
        return `36个月会员，${price}元，相当于${this.formatFloat(priceFloat / 36)}元/月`
      case HwPurchaseConstants.SKU_10:
        return `60个月会员，${price}元，相当于${this.formatFloat(priceFloat / 60)}元/月`
      default:
        return ''
    }
  }

  // 构建价格卡片主标题
  private loadPriceTitle(sku: string): string {
    switch (sku) {
      case HwSubscribeConstants.SKU_1: return '连续包月'
      case HwSubscribeConstants.SKU_2: return '连续包季'
      case HwSubscribeConstants.SKU_3: return '连续包年'
      case HwPurchaseConstants.SKU_7:  return '12个月会员'
      case HwPurchaseConstants.SKU_8:  return '24个月会员'
      case HwPurchaseConstants.SKU_9:  return '36个月会员'
      case HwPurchaseConstants.SKU_10: return '60个月会员'
      default: return ''
    }
  }

  // 生成按钮周期文案
  private localizedPeriod(sku: string): string {
    switch (sku) {
      case HwSubscribeConstants.SKU_1: return '1' + getString($r('app.string.member_subscribe_txt_unit_month'))
      case HwSubscribeConstants.SKU_2: return '3' + getString($r('app.string.member_subscribe_txt_unit_months'))
      case HwSubscribeConstants.SKU_3: return '1' + getString($r('app.string.member_subscribe_txt_unit_year'))
      case HwPurchaseConstants.SKU_7:  return '1' + getString($r('app.string.member_subscribe_txt_unit_year'))
      case HwPurchaseConstants.SKU_8:  return '2' + getString($r('app.string.member_subscribe_txt_unit_year'))
      case HwPurchaseConstants.SKU_9:  return '3' + getString($r('app.string.member_subscribe_txt_unit_year'))
      case HwPurchaseConstants.SKU_10: return '5' + getString($r('app.string.member_subscribe_txt_unit_year'))
      default: return ''
    }
  }

  // 生成月均价文案
  private calcPerMonthText(product: iap.Product): string | null {
    const months = this.monthsFor(product.id)

    // 分支：按月购买不显示月均价
    if (months === null || months <= 1) {
      return null
    }

    const per = product.microPrice / 1_000_000 / months
    return `${this.formatFloat(per)}元/月`
  }

  // 将 sku 映射到对应月数
  private monthsFor(productId: string): number | null {
    switch (productId) {
      case HwSubscribeConstants.SKU_1: return 1
      case HwSubscribeConstants.SKU_2: return 3
      case HwSubscribeConstants.SKU_3: return 12
      case HwPurchaseConstants.SKU_7:  return 12
      case HwPurchaseConstants.SKU_8:  return 24
      case HwPurchaseConstants.SKU_9:  return 36
      case HwPurchaseConstants.SKU_10: return 60
      default: return null
    }
  }

  // 生成价格卡片角标文案
  private loadPriceTagText(item: PriceDisplayItem): string | null {
    const bestValueProductIds = this.bestValueProductIds()
    const isBestValue = bestValueProductIds.has(item.product.id)

    // 分支：SKU_3 保留主推位；若不是最低月均价，则显示“推荐”
    if (item.product.id === HwSubscribeConstants.SKU_3) {
      return isBestValue ? '最划算' : getString($r('app.string.member_txt_recommend'))
    }

    // 分支：其他商品只有在自身为最低月均价时显示“最划算”
    return isBestValue ? '最划算' : null
  }

  // 计算所有可见商品中月均价最低的 sku 集合
  private bestValueProductIds(): Set<string> {
    const pairs: PriceCompareItem[] = []

    this.visiblePriceItems().forEach((item: PriceDisplayItem) => {
      const months = this.monthsFor(item.product.id)

      // 分支：无法换算成月数的商品，不参与“最划算”比较
      if (months === null) {
        return
      }

      pairs.push({
        productId    : item.product.id,
        microsPrice  : item.product.microPrice,
        months       : months
      })
    })

    // 分支：通过交叉相乘比较月均价，避免浮点除法带来的精度误差。
    // 只要存在其它商品满足：
    // other.microsPrice / other.months < current.microsPrice / current.months
    // 当前商品就不是“最划算”。
    const ids = pairs.filter((current) => {
      return !pairs.some((other) => {
        return other.microsPrice * current.months < current.microsPrice * other.months
      })
    }).map((item) => item.productId)

    return new Set(ids)
  }

  // 当前选中时是否为一次性购买
  private isSelectedConsumablePrice(): boolean {
    return this.selectedPriceTag >= 3
  }

  // 当前价格区说明文案
  private currentInfoText(): string {

    // 分支：一次性购买显示“计入登录账户”的说明
    return this.isSelectedConsumablePrice()
      ? getString($r('app.string.member_txt_info2'))
      : getString($r('app.string.member_txt_info'))
  }

  // 当前协议说明正文
  private currentAgreeText(): string {

    // 分支：一次性购买不显示“自动续费协议”
    return this.isSelectedConsumablePrice()
      ? getString($r('app.string.member_agree_consume_txt'))
      : getString($r('app.string.member_agree_txt'))
  }

  // 当前协议中可点击的链接列表
  private currentAgreeLinks(): string[] {

    // 分支：一次性购买只有“会员服务 / 隐私政策”两个链接
    if (this.isSelectedConsumablePrice()) {
      return [
        getString($r('app.string.member_agree_link_terms')),
        getString($r('app.string.member_agree_link_privacy'))
      ]
    }

    return [
      getString($r('app.string.member_agree_link_terms')),
      getString($r('app.string.member_agree_link_terms_subscription')),
      getString($r('app.string.member_agree_link_privacy'))
    ]
  }

  /**
   * 打开协议链接
   * @param text 当前点击的协议文本
   */
  private openAgreeLink(text: string): void {
    if (text === getString($r('app.string.member_agree_link_terms'))) {
      LinkViewConfig.NavTo(this.navPath, { title: text, url: AppSettings.Address.terms })
    } else if (text === getString($r('app.string.member_agree_link_privacy'))) {
      LinkViewConfig.NavTo(this.navPath, { title: text, url: AppSettings.Address.privacy })
    } else if (text === getString($r('app.string.member_agree_link_terms_subscription'))) {
      LinkViewConfig.NavTo(this.navPath, { title: text, url: AppSettings.Address.terms_subscription })
    }
  }

  // 当前可见价格列表
  private visiblePriceItems(): PriceDisplayItem[] {
    const items: PriceDisplayItem[] = []

    // 调用：先加入订阅商品，tag 0~2 固定对应订阅区
    this.subscriptionProducts.forEach((product: iap.Product, index: number) => {
      items.push({
        tag          : index,
        product      : product,
        isConsumable : false
      })
    })

    // 分支：配置允许显示一次性购买按钮时，追加单次购买商品。
    // 单次购买的 tag 从 3 开始，和前面的订阅商品明确区分。
    if (this.showConsumablePriceButtons) {
      this.consumableProducts.forEach((product: iap.Product, index: number) => {
        items.push({
          tag          : 3 + index,
          product      : product,
          isConsumable : true
        })
      })
    }

    return items
  }

  // 当前价格按钮是否应居中显示
  private shouldCenterPriceButtons(): boolean {
    const visibleCount = this.visiblePriceItems().length

    // 分支：无价格项时不需要居中布局判断
    if (visibleCount < 1) {
      return false
    }

    const totalButtonsWidth = visibleCount * MemberView.PRICE_BUTTON_WIDTH_VP
    const totalSpacingWidth = (visibleCount - 1) * MemberView.PRICE_BUTTON_SPACING_VP
    const contentWidth      = totalButtonsWidth + totalSpacingWidth
    const availableWidth    = dScreenWidth
      - MemberView.CONTENT_HORIZONTAL_PAD_VP
      - MemberView.PRICE_SCROLL_PADDING_VP

    // 分支：只有当全部按钮总宽度能放进当前内容区时，才居中显示。
    // 放不下时保持左对齐，并通过横向 Scroll 允许继续滚动查看。
    return contentWidth <= availableWidth
  }

  // 当前选中的价格项
  private selectedPriceItem(): PriceDisplayItem | null {
    const item = this.visiblePriceItems().find((it: PriceDisplayItem) => it.tag === this.selectedPriceTag)
    return item ?? null
  }

  // 格式化价格
  private formatFloat(value: number): string {
    return value % 1 === 0 ? `${value | 0}` : value.toFixed(1)
  }

  /**
   * 构建订阅确认弹层
   * @param yesAction 点击确认后的购买动作
   */
  @Builder
  private buildConfirmDialogView(yesAction: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      Rect()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .fillOpacity(0.45)

      Column({ space: 15 }) {
        Column() {
          Text($r('app.string.member_buy_cfm_msg_title'))
            .fontWeight(FontWeight.Bold)
            .fontSize(22)
            .fontColor(Color.Black)
        }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

        Column({ space: 10 }) {
          LinkText({
            content     : getString($r('app.string.member_buy_cfm_msg_info')),
            linkTexts   : [getString($r('app.string.member_buy_cfm_txt_terms_link'))],
            normalColor : $r('app.color.color_text'),
            linkColor   : $r('app.color.colorAccent'),
            textStyle   : {
              maxLines : 3,
              fontSize : 16
            },
            onLinkTapped: (text: string) => {
              if (text === getString($r('app.string.member_buy_cfm_txt_terms_link'))) {
                LinkViewConfig.NavTo(this.navPath, { title: text, url: AppSettings.Address.terms_subscription })
              }
            }
          })

          Text($r('app.string.member_buy_cfm_msg_info2'))
            .fontSize(15)
            .fontColor(Color.Gray)
        }
          .alignItems(HorizontalAlign.Start)

        Row({ space: 20 }) {
          TextButton({
            text            : $r('app.string.member_buy_cfm_btn_no'),
            bgColor         : $r('app.color.color_gray'),
            onClickCallBack : () => {
              this.isShowConfirmSubscribe = false
            }
          })

          TextButton({
            text            : $r('app.string.member_buy_cfm_btn_yes'),
            onClickCallBack : () => {
              this.isShowConfirmSubscribe = false
              yesAction()
            }
          })
        }
          .margin({ top: 20 })
          .justifyContent(FlexAlign.Center)
      }
        .justifyContent(FlexAlign.Center)
        .width('auto')
        .margin(10)
        .height('auto')
        .padding(20)
        .borderRadius(5)
        .backgroundColor(Color.White)
        .shadow({ radius: 10, type: ShadowType.COLOR, color: Color.Gray, offsetX: 5, offsetY: 5 })
    }
      .width('100%')
      .height('100%')
      .zIndex(999)
  }
}
