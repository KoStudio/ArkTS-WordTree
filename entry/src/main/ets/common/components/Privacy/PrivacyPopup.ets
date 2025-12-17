import { AppSettings } from "../../../app/constants/AppSettings";
import { GlobalKey } from "../../../app/constants/GlobalKey";
import { BgImage } from "../../../app/views/BgImage";
import { LinkText } from "../../../app/views/LinkText";
import { LinkView, LinkViewConfig } from "../../../app/views/LinkView";
import { NavTitleView } from "../../../app/views/NavTitleView";
import { getString } from "../../utils/ResourceUtils";
import { PrivacyManager } from "./PrivacyManager";


@ComponentV2
export struct PrivacyPopup {

  @Param htmlContent: string                  = ''
  @Param onAgree    : () => void              = () => {}
  // @Param onDisagree : () => void              = () => {};
  // @Param onLinkClick: (url: string) => void  = () => {};

  @Provider(GlobalKey.kNavPath) navPath: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.navPath){

      Stack(){

        Stack(){
          //splash
          Image($r('app.media.splash'))
            .width('139')
            .height('424')
            .objectFit(ImageFit.Contain)
            .margin({ top: 20, bottom: 20 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

        this.buildContent()
      }
      .width('100%')
      .height('100%')

    }
    .width('100%')
    .padding({bottom: 0})
    .margin(0)
    .backgroundColor($r('app.color.colorPrimary'))
    //.title($r('app.string.app_name'))
    .title(this.buildNavTitle($r('app.string.app_name')))
    .mode(NavigationMode.Stack)
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true)
    .navBarWidth('100%') // 导航栏宽度
    .navDestination(this.navigationTo)
    .navBarPosition(NavBarPosition.Start)

  }

  @Builder buildNavTitle(title: ResourceStr){
    NavTitleView({title: title})
  }

  @Builder
  buildContent(){

    Column({ space: 5 }) {


      // 内容区域
      Scroll() {
        Column({space: 5}){
          // 标题
          Text($r('app.string.privacy_pop_txt_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)


          Blank()

          LinkText({
            content: getString($r('app.string.privacy_pop_content')),
            linkColor: Color.Red,
            normalColor: Color.Gray,
            linkTexts: [getString($r('app.string.privacy_pop_link_terms')), getString($r('app.string.privacy_pop_link_privacy')), getString($r('app.string.privacy_pop_link_privacy_kid'))],
            onLinkTapped: (text) => {
              if (text === getString($r('app.string.privacy_pop_link_terms'))) {
                ///服务协议
                LinkViewConfig.NavTo(this.navPath, {title: text, url: AppSettings.Address.terms })
              }else if (text === getString($r('app.string.privacy_pop_link_privacy'))){
                ///隐私政策
                LinkViewConfig.NavTo(this.navPath, {title: text, url: AppSettings.Address.privacy })
              }else if (text === getString($r('app.string.privacy_pop_link_privacy_kid'))){
                ///儿童隐私政策
                LinkViewConfig.NavTo(this.navPath, {title: text, url: AppSettings.Address.privacy_kid })
              }
            },
            textStyle: {
              maxLines: 1000,
              fontSize: 16,
              fontFamily: 'HarmonyOS Sans'
            }
          })
        }
        .justifyContent(FlexAlign.Start)
        .padding(16)

      }
      .width('90%')
      .height(400)
      .borderRadius(6) // 设置圆角半径（单位vp）[2,5](@ref)
      .backgroundColor(Color.White) // 必须设置背景色，阴影才能生效[5](@ref)
      .shadow({
        radius: 16,      // 阴影模糊半径，值越大越柔和
        color: 0x1A000000, // 半透明黑色（透明度10%）
        offsetX: 0,      // 水平偏移量
        offsetY: 4       // 垂直偏移量，模拟悬浮效果[5](@ref)
      })
      .scrollable(ScrollDirection.Vertical) // 仅允许垂直滚动

      // 按钮组
      Row({ space: 20 }) {
        Button($r('app.string.privacy_pop_btn_disagree'))
          .backgroundColor(0xffeeeeee)
          .fontColor(Color.Black)
          .onClick(() => {
            //不同意，退出应用
            PrivacyManager.shared.handleAgree(false)

            //回调
            //this.onDisagree()
          })
          .layoutWeight(1)
          .height(50)

        Button($r('app.string.privacy_pop_btn_agree'))
          .backgroundColor(0xff007aff)
          .fontColor(Color.White)
          .onClick(() => {
            //同意
            PrivacyManager.shared.handleAgree(true)

            //回调
            this.onAgree()
          })
          .layoutWeight(1)
          .height(50)
      }
      .backgroundColor(Color.Transparent)
      .width('90%')
      .margin({ top: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .borderRadius(0)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#cc333333')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }


  @Builder
  navigationTo<T>(name: string, param: T){
    if (name === LinkViewConfig.NavKey)        { LinkView({title: (param as LinkViewConfig.Param).title, url: (param as LinkViewConfig.Param).url})
    }else{ NavDestination(){Text(`<PrivacyPopup.ets>未配置navigationTo: ${name}`)}
    }
  }
}