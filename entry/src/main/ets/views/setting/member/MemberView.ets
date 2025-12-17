import { AppSettings } from "../../../app/constants/AppSettings";
import { GlobalKey } from "../../../app/constants/GlobalKey";
import { TextStyleButton } from "../../../app/views/buttons/TextStyleButton";
import { LinkText } from "../../../app/views/LinkText";
import { LinkView, LinkViewConfig } from "../../../app/views/LinkView";
import { NavBarView } from "../../../app/views/NavBarView";
import { getString, getStringF } from "../../../common/utils/ResourceUtils";
import { TextStyleButtonStyle } from "../../../app/views/buttons/TextStyleButton"
import { HwSubscriber } from "../../../common/iab/huawei/HwSubscriber";
import { SubscribeManager, SubscribeManagerNotification } from "../../../common/iab/SubscribeManager";
import { MemberManager } from "../../../models/managers/member/MemberManager";
import iap from "@hms.core.iap";
import { SubscriptionInfoManager } from "../../../models/managers/subscription/SubscriptionInfoManager";
import { Toast } from "../../../common/utils/Toast";
import { bounce } from "../../../common/extentions/AnimBounce";
import { TextButton } from "../../../app/views/buttons/TextButton";
import { HwSubscribeConstants } from "../../../common/iab/huawei/HwSubscribeConstants";
import { isDebugMode } from "../../../app/constants/AppDefines";
import { SimpleEventBus } from "../../../common/components/eventbus/SimpleEventBus";

export namespace MemberViewConfig {

  ///导航key
  export const kNavPath = "Member_kNavPath"

}

/**
 * 会员订阅页面组件
 * 实现会员订阅功能，包含价格选择、订阅操作等
 * 使用@ComponentV2注解和声明式UI范式
 */
@ComponentV2
export struct MemberView {

  // MARK: - 参数和状态定义
  @Param   @Require isShowing        : boolean
  @Event   $isShowing                : (val: boolean) => void    = (val: boolean) => {}
  @Event   onClose                   : (changed: boolean) => void

  @Local private memberExpiryDate    : string = ''; // 会员到期时间
  @Local private memberExpiryDateColor: ResourceColor = Color.White;

  @Local private isAgree: boolean = false;
  @Local private isBuyButtonEnabled: boolean = true; // 购买按钮是否可用
  @Local private isSubscribeEnable: boolean = false

  @Local private products: iap.Product[] = []
  @Local private selectedPriceIndex: number = -1; // 选中的价格索引

  @Local private isShowConfirmSubscribe: boolean = false //显示确认订阅窗口视图

  @Local private checkAgreeShakeOffsetX: number = 0  ///动画控制变量

  // 路由栈管理
  @Provider(MemberViewConfig.kNavPath) navPath: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    //刷新buy按钮状态
    this.refreshBtnBuy()

    ///加载Products
    this.loadData()

    //显示会员
    this.onChangeOfShowing()

    ///监听会员时间改变通知
    SimpleEventBus.on(SubscribeManagerNotification.expireDateUpdated, () => {
      this.showMemberInfo()
    })

  }


  aboutToDisappear(): void {
    ///移除 监听会员时间改变通知
    SimpleEventBus.off(SubscribeManagerNotification.expireDateUpdated)
  }

  onChangeOfShowing(){
    ///自动 恢复已经有的订阅(重新安装应用后)
    HwSubscriber.shared.restore()

    ///判断时间间隔，自动刷新订阅时间 6小时， Android版和iOS没有这个功能
    SubscriptionInfoManager.shared.autoRefreshSubscriptionInfoIfNeeds()

    ///显示会员信息
    this.showMemberInfo()
  }

  build() {
    // 导航容器（对应NavigationStack）
    Navigation(this.navPath) {
      this.buildMain()
    }
    .navDestination(this.navigationTo)
    .navBarPosition(NavBarPosition.Start)
    .hideTitleBar(true)
    .backgroundColor($r('app.color.color_background'))

  }
  @Builder
  navigationTo<T>(name: string, param: T){
    if (name === LinkViewConfig.NavKey)                 { LinkView({ title: (param as LinkViewConfig.Param).title, url: (param as LinkViewConfig.Param).url })
    }else{ NavDestination(){Text(`<MemberView.ets>未配置navigationTo: ${name}`)}
    }
  }
  // MARK: - 组件构建方法

  @Builder buildMain(){
    Column() {

      Scroll() {

        Column() {
          Stack() {
            Column(){
              // 导航栏
              this.buildNavBar()

              // 主要内容区域
              this.buildContentSection()

              // 底部操作区域
              this.buildActionSection()
            }

            ///确认 开通自动续费
            if (this.isShowConfirmSubscribe){
              this.buildConfirmDialogView(()=>{ this.doSubscribe()})
            }

          }

        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.colorPrimary'))
  }

  /**
   * 构建导航栏
   * 包含取消按钮和管理订阅按钮
   */
  @Builder
  buildNavBar() {
    NavBarView({
      title: $r('app.string.member_title'),

      // 左侧按钮数组
      leftButtons: [
        {
          text: $r('app.string.member_btn_cancel'),
          onClick: () => { this.$isShowing(false) }
        }
      ],

      // 右侧按钮数组
      rightButtons: [
        {
          text: $r('app.string.member_btn_manage_subs'),
          onClick: () => { this.showViewSubscription() }
        }
      ]
    })
      .backgroundColor(Color.Blue)
      .margin(10)

  }


  /**
   * 构建主要内容区域
   * 包含描述文本、价格选项、提示信息等
   */
  @Builder
  buildContentSection() {
    Column() {
      // 描述文本
      Text($r('app.string.member_desc'))
        .id('tvContent')
        .fontColor(Color.White)
        .fontSize(18)
        .textAlign(TextAlign.Start)
        .width('100%')
        .margin({ bottom: 20 })

      if (this.products.length > 0){
        // 价格选项区域
        this.buildPriceOptions()
      }else{
        // 加载中
        this.buildLoading()
      }



      // 附加信息文本
      Text($r('app.string.member_txt_info'))
        .id('tvInfo')
        .fontColor($r('app.color.color_obscure'))
        .fontSize(12)
        .textAlign(TextAlign.Start)
        .width('100%')
        .margin({ top: 5 })
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建价格选项区域
   * 三个价格按钮水平排列
   */
  @Builder
  buildPriceOptions() {
    Column(){
      Row() {
        ForEach(this.products, (product: iap.Product, index: number) => {


          Button({ type: ButtonType.Normal }) {
            Column() {
              Text(product.localPrice)
                .fontColor(this.selectedPriceIndex === index ? $r('app.color.colorPrimary') : Color.White)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)

              Text(this.getPriceText(product))
                .fontColor(this.selectedPriceIndex === index ? $r('app.color.colorPrimary') : Color.White)
                .fontSize(12)
            }
          }
          .id(`btnPrice${index + 1}`)
          .width(96)
          .height(60)
          .backgroundColor(this.selectedPriceIndex === index ? Color.White : Color.Transparent)
          .border({
            width: this.selectedPriceIndex === index ? 2 : 1,
            color: this.selectedPriceIndex === index ? $r('app.color.color_white') : Color.White,
            radius: 4
          })
          .onClick(() => {
            this.handlePriceSelection(index);
          })
          //.margin({ left: index > 0 ? 15 : 0, right: index < this.priceOptions.length - 1 ? 15 : 0 })
        }, (option: PriceOption) => option.price)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)

      // 提示信息区域（默认隐藏）
      Column() {
        Text(this.getPriceTip())//'连续包年会员，168元/年，相当于12元/月'
          .id('tvTip')
          .fontColor($r('app.color.colorAccent'))
          .fontSize(12)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .margin({ top: 10 })
      .visibility(Visibility.Visible) // 对应 android:visibility="gone"
    }
    .width('100%')
    .margin({ top: 10 })

  }

  @Builder buildLoading(){
    Row() {
      LoadingProgress()
        .height(32)
        .width(48)
    }
    .height(100)
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .margin({ top: 10 })
  }

  getPriceText(product?: iap.Product | null): string {
    return `${product?.subscriptionInfo?.periodCount ?? 0}${this.getPeriodUnitText(product?.subscriptionInfo?.periodUnit)}`
  }

  ///沙盒环境中的订阅换算时间为10秒/天。比如订阅周期为1周，商品将在首次购买成功70秒后发生续期。1月则是300秒(5分钟)。
  getPeriodUnitText(unit?: iap.PeriodUnit | null): string {
    switch (unit) {
      case iap.PeriodUnit.DAY:    return '日';
      case iap.PeriodUnit.WEEK:   return '周';
      case iap.PeriodUnit.MONTH:  return '月';
      case iap.PeriodUnit.YEAR:   return '年';
      case iap.PeriodUnit.MINUTE: return '分钟';
      default:                return '';
    }
  }

  ///获取价格提示
  getPriceTip(): string {

    ///把整数显示为不带小数，小数保留一位
    const format = (value: number): string => {
      return value % 1 === 0 ? `${value | 0}` : value.toFixed(1);
    };

    const product = this.products[this.selectedPriceIndex]
    if (!product) {
      return ''
    }

    const sku: string        = product.id
    const priceFloat: number = product.microPrice / 1000000 //microPrice:商品实际价格乘以1,000,000后的微单位价格

    const price              = format(priceFloat);
    const pricePerMonth_3    = format(priceFloat / 3);
    const pricePerMonth_12   = format(priceFloat / 12);

    switch (sku) {
      case HwSubscribeConstants.SKU_1:
        // return `连续包月会员，${price}元/月`;
        return getStringF($r('app.string.member_sub_tip_month'), price)

      case HwSubscribeConstants.SKU_2:
        //return `连续包季会员，${price}元/季，相当于${pricePerMonth_3}元/月`;
        return getStringF($r('app.string.member_sub_tip_quarter'), price, pricePerMonth_3)

      case HwSubscribeConstants.SKU_3:
        //return `连续包年会员，${price}元/年，相当于${pricePerMonth_12}元/月`;
        return getStringF($r('app.string.member_sub_tip_year'), price, pricePerMonth_12)

      default:
        return "";
    }
  }
  /**
   * 构建底部操作区域
   * 包含订阅按钮、会员日期显示、协议链接等
   */
  @Builder
  buildActionSection() {
    Column() {
      // 订阅按钮和会员日期
      this.buildSubscribeSection()

      // 协议链接区域
      //this.buildAgreementSection()

      // 同意协议区域（默认隐藏）
      this.buildAgreementCheckSection()
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建订阅按钮和会员日期区域
   */
  @Builder
  buildSubscribeSection() {
    Column() {
      // 订阅按钮
      TextStyleButton({
        text:$r('app.string.member_btn_subscribe'),
        style: TextStyleButtonStyle.LIGHT,
        minWidth: 220,
        isEnabled:this.isBuyButtonEnabled,
        onClickCallBack:()=>{
          this.actionSubscribe()
        }
      })
      // 会员到期日期
      Text(this.memberExpiryDate)
        .id('tvMemberDate')
        .fontColor(this.memberExpiryDateColor)
        .fontSize(12)
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 5 })
    }
    .width('100%')
    .margin({ top: 10 })
  }

  /**
   * 构建协议链接区域
   */
  @Builder
  buildAgreementSection() {
    Row() {
      // 服务条款按钮
      Button($r('app.string.member_btn_terms'), { type: ButtonType.Normal })
        .id('btnTerms')
        .fontColor($r('app.color.color_link'))
        .backgroundColor(Color.Transparent)
        .fontSize(12)
        .onClick(() => {
          this.actionTerm()
        })

      // 分隔符
      Text('|')
        .id('tvSep')
        .fontColor($r('app.color.color_obscure'))
        .fontSize(12)
        .margin({ left: 10, right: 10 })

      // 隐私政策按钮
      Button($r('app.string.member_btn_privacy'), { type: ButtonType.Normal })
        .id('btnPrivacy')
        .fontColor($r('app.color.color_link'))
        .backgroundColor(Color.Transparent)
        .fontSize(12)
        .onClick(() => {
          this.actionPrivacy()
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .margin({ top: 10 })
  }

  /**
   * 构建同意协议区域（复选框+文本）
   */
  @Builder
  buildAgreementCheckSection() {
    Row() {

      // 同意文本
      // 协议确认区域
      Row({ space: 0 }) {
        Checkbox()
          .select(this.isAgree)
          .onChange((value: boolean) => {
            this.isAgree = value;
          })

        LinkText({
          content: getString($r('app.string.member_agree_txt')),
          linkTexts: [getString($r('app.string.member_agree_link_terms')), getString($r('app.string.member_agree_link_terms_subscription')), getString($r('app.string.member_agree_link_privacy'))],
          textStyle: {
            maxLines: 2,
            fontSize: 12,
          },
          onLinkTapped: (text) => {
            if (text === getString($r('app.string.member_agree_link_terms'))) {
              ///会员服务
              LinkViewConfig.NavTo(this.navPath, { title: text, url: AppSettings.Address.terms })
            } else if (text === getString($r('app.string.member_agree_link_privacy'))) {
              ///隐私政策
              LinkViewConfig.NavTo(this.navPath, { title: text, url: AppSettings.Address.privacy })
            } else if (text === getString($r('app.string.member_agree_link_terms_subscription'))) {
              ///自动续费协议
              LinkViewConfig.NavTo(this.navPath, { title: text, url: AppSettings.Address.terms_subscription })
            }
          }
        })
      }
      .offset({x: this.checkAgreeShakeOffsetX, y:  0})
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .visibility(Visibility.Visible) // 对应 android:visibility="gone"
    .margin({ top: 10, bottom: 60 })
  }

  // MARK: - 业务逻辑方法

  async loadData(){
    this.isSubscribeEnable = await HwSubscriber.shared.queryEnvironmentStatus() === 0
    this.products          = await HwSubscriber.shared.queryProducts() || []

    //刷新buy按钮状态
    this.refreshBtnBuy()

  }

  showViewSubscription(){
    HwSubscriber.shared.showManagedSubscriptions()
  }

  async actionSubscribe(){
    if (!this.checkAgree()) return;

    ///确认 开通自动续费
    this.isShowConfirmSubscribe = true
  }

  private async doSubscribe(){

    const product = this.products[this.selectedPriceIndex]

    const succeed = await HwSubscriber.shared.createPurchase(product.id)

    //刷新购买按钮
    this.refreshBtnBuy()

    ///显示会员期限
    this.showMemberInfo()

    if (succeed) {//购买成功

      //关闭当前页面
      this.$isShowing(false)

      //显示消息
      Toast.showMessage($r('app.string.member_btn_subscribe_done'))

      //刷新订阅信息
      SubscriptionInfoManager.shared.asyncRefreshSubscriptionInfo() //写入server
    }

  }

  // 检查是否同意协议
  private checkAgree(): boolean {
    if (!this.isAgree) {
      this.shakeCheckAgree()
      Toast.showMessage($r('app.string.member_agree_tip'))
      return false;
    }
    return true;
  }

  // MARK: - 登录相关方法
  private shakeCheckAgree(){
    bounce({set:(x,y) => { this.checkAgreeShakeOffsetX = x },isHorizontal: true, onFinished: () => {  }})
  }

  showMemberInfo(){
    const expireDate = MemberManager.shared.expireDate;

    if (expireDate) {
      if (MemberManager.shared.isActive) {
        // 会员还在有效期
        this.memberExpiryDate       = getStringF($r('app.string.member_txt_will_expire'), MemberManager.shared.expireDateString);
        this.memberExpiryDateColor  = $r('app.color.color_white')
      } else {
        // 会员已过期
        this.memberExpiryDate       = getStringF($r('app.string.member_txt_was_expired'), MemberManager.shared.expireDateString);
        this.memberExpiryDateColor  = $r('app.color.colorAccent')
      }
    } else {
      this.memberExpiryDate         = ''
    }
  }

  /**
   * 处理价格选择
   * @param index 选中的价格索引
   */
  private handlePriceSelection(index: number): void {
    this.selectedPriceIndex = index;
    this.refreshBtnBuy();
  }

  /**
   * 更新购买按钮状态
   * 根据选中状态和协议同意状态更新按钮可用性
   */
  private refreshBtnBuy(): void {

    if (this.products.length === 0) {
      this.isBuyButtonEnabled = false
    }else{

      ///初次 未选择时
      if (this.selectedPriceIndex === -1) {
        this.selectedPriceIndex = this.products.length - 1 //选中最后一个
      }

      if(SubscribeManager.shared.currentItem?.isActive
        && this.products.length > this.selectedPriceIndex
        && SubscribeManager.shared.currentItem?.sku === this.products[this.selectedPriceIndex].id) {

        //选中的是当前项，且还在会员期间
        this.isBuyButtonEnabled = false
      }else{
        this.isBuyButtonEnabled = this.isSubscribeEnable && this.selectedPriceIndex >= 0 //&& this.isAgree;
      }
    }

  }


  actionTerm(){
    ///会员服务/服务协议
    LinkViewConfig.NavTo(this.navPath, { title: getString($r('app.string.member_btn_terms')), url: AppSettings.Address.terms })

  }
  actionPrivacy(){
    ///隐私政策
    LinkViewConfig.NavTo(this.navPath, { title: getString($r('app.string.member_btn_privacy')), url: AppSettings.Address.privacy })
  }

  ////
  @Builder
  buildConfirmDialogView(yesAction: ()=>void) {
    Stack({ alignContent: Alignment.Center }) {
      // 半透明遮罩层（捕获点击，不会让底下组件响应）
      Rect()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .fillOpacity(0.45)



      Column({space: 15}) {

        //title
        Column(){
          Text($r('app.string.member_buy_cfm_msg_title')) //确认
            .fontWeight(FontWeight.Bold)
            .fontSize(22)
            .fontColor(Color.Black)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({space: 10}){
          LinkText({
            content: getString($r('app.string.member_buy_cfm_msg_info')),
            linkTexts: [getString($r('app.string.member_buy_cfm_txt_terms_link'))],
            normalColor: $r('app.color.color_text'),
            linkColor: $r('app.color.colorAccent'),
            textStyle: {
              maxLines: 2,
              fontSize: 16,
            },
            onLinkTapped: (text) => {
              if (text === getString($r('app.string.member_buy_cfm_txt_terms_link'))) {
                ///自动续费协议
                LinkViewConfig.NavTo(this.navPath, { title: text, url: AppSettings.Address.terms_subscription })
              }
            }
          })

          ///msg2
          Text($r('app.string.member_buy_cfm_msg_info2'))
            .fontSize(15)
            .fontColor(Color.Gray)
        }
        .alignItems(HorizontalAlign.Start)

        Row({space: 20}){

          ///取消
          TextButton({text: $r('app.string.member_buy_cfm_btn_no'), bgColor: $r('app.color.color_gray'), onClickCallBack: ()=>{
            this.isShowConfirmSubscribe = false
            //Toast.closeCustomDialog()
          }})

          ///确认
          TextButton({text: $r('app.string.member_buy_cfm_btn_yes'), onClickCallBack: async ()=>{
            this.isShowConfirmSubscribe = false
            ///回调
            yesAction()

            //Toast.closeCustomDialog()
          }})

        }
        .margin({top: 20})
        .justifyContent(FlexAlign.Center)
      }
      .justifyContent(FlexAlign.Center)
      .width('auto')
      .margin(10)
      .height('auto')
      .padding(20)
      .borderRadius(5)
      .backgroundColor(Color.White)
      .shadow({ radius: 10,type: ShadowType.COLOR, color: Color.Gray, offsetX: 5, offsetY: 5 })

    }
    .width('100%')
    .height('100%')
    .zIndex(999)                            // 置于最上层

  }

}
/**
 * 价格选项数据模型
 */
interface PriceOption {
  price: string;      // 价格显示文本
  period: string;     // 周期显示文本
  value: number;      // 实际价格数值
}

/**
 * 会员订阅配置接口
 */
interface MemberSubscriptionConfig {
  priceOptions?: PriceOption[];      // 价格选项配置
  showRestoreButton?: boolean;       // 是否显示恢复按钮
  showAgreementCheck?: boolean;       // 是否显示协议复选框
  memberExpiryDate?: string;          // 会员到期日期
}