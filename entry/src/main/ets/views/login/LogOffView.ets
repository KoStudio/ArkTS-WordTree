import { buildNavTitle } from "../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../app/constants/AppDefines";
import { GlobalKey } from "../../app/constants/GlobalKey";
import { BgImage } from "../../app/views/BgImage";
import { TextButton } from "../../app/views/buttons/TextButton";
import { getString } from "../../common/utils/ResourceUtils";
import { Toast } from "../../common/utils/Toast";
import { UserManager } from "../../models/managers/user/UserManager";
import { NavTo } from "../../pages/NavPathManager";

export namespace LogOffViewConfig {

  ///导航key
  export const NavKey = "LogOffView_show"

  ///打开方式
  export function open(){
    NavTo(NavKey, undefined, true)
  }
}

@ComponentV2
export struct LogOffView {
  // 状态变量
  @Local userName: string = UserManager.shared.userName || '';

  @Consumer(GlobalKey.kNavPath) navPath?: NavPathStack

  // 回调
  @Event onDismiss: () => void;

  build() {
    NavDestination() {
      Stack() {

        Column() {
          this.buildLogOffPanel()
        }
        .width('100%')
        .height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .backgroundColor($r('app.color.color_background'))
        .padding({top: 20})
      }

    }
    .title(buildNavTitle($r('app.string.logoff_nav_title')))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.color_nav_bg'))
  }


  @Builder
  buildLogOffPanel() {
    Column({ space: 20 }) {
      Column() {
        // 用户头像区域
        if (this.userName) {
          Text(this.userName.charAt(0).toUpperCase())
            .fontSize(36)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width(100)
            .height(100)
            .backgroundColor($r('app.color.colorAccent'))
            .borderRadius(50)
        } else {
          Image($r('app.media.icon'))
            .width(100)
            .height(100)
            .borderRadius(50)
        }

        // 用户名
        Text(this.userName || $r('app.string.signup_txt_username'))
          .fontSize(18)
          .margin({ top: 10 })

        // 提示信息
        Text($r('app.string.logoff_txt_tip'))
          .fontSize(14)
          .fontColor(Color.Gray)
          .textAlign(TextAlign.Center)
          .margin({ top: 20, bottom: 30 })

        // 注销按钮
        TextButton({
          text: $r('app.string.logoff_btn_logoff'),
          onClickCallBack: () => { this.confirmLogoff() },
          fontColor: $r('app.color.color_white'),
          bgColor: $r('app.color.colorAccent')
        })
      }
      .padding(20)
      .width('99%')
      .backgroundColor(Color.White)
      // .borderRadius(6)
      // .shadow({ radius: 1 })

    }
    .width('90%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .margin({top: 10})
  }


  //确认退出登录
  confirmLogoff(){
    Toast.showAlert({
      title: $r('app.string.alert_title_confirm'),//退出登录
      message: $r('app.string.logoff_msg_logoff'),
      secondaryButton: {value: $r('app.string.cfm_btn_cancel'), fontColor: Color.Gray, action: () => {}},
      primaryButton: {value: $r('app.string.logoff_cfm_yes'), action: () => {
        //注销

        this.logOff()
      }}
    })
  }

  // 注销账户逻辑
  private logOff(): void {
    if ((UserManager.shared.userId ?? -1) === -1) {
      Toast.showMessage($r('app.string.login_not_login'))
      return;
    }

    UserManager.shared.loginOff((succeed: boolean, msg: string | null) => {

      if (succeed) {
        // 退出登录
        UserManager.shared.logout()

        Toast.showMessage($r('app.string.logoff_msg_logoff_succee'))
        this.navPath?.pop(true)
      } else {
        const errorMsg = `${getString($r('app.string.logoff_msg_logoff_fail'))}：${msg ?? ''}`
        Toast.showMessage(errorMsg)
      }
    });
  }
}