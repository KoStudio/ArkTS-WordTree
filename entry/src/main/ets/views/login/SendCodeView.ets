import { BgImage } from "../../app/views/BgImage";
import { TextButton } from "../../app/views/buttons/TextButton";
import { StringUtils } from "../../common/utils/strings/StringUtils";
import { UserManager } from "../../models/managers/user/UserManager";
import { DebugFlg } from "../../app/debug/DebugFlg";
import { LoginViewConfig } from "./LoginConfig";
import { Toast } from "../../common/utils/Toast";
import { ResetPasswordViewConfig } from "./ResetPasswordView";
import { getString } from "../../common/utils/ResourceUtils";


export namespace SendCodeViewConfig {

  ///导航key
  export const NavKey = "SendCodeView_show"

  ///打开方式
  export function NavTo(navPath: NavPathStack | undefined){
    if (!navPath) { return }
    navPath.pushPathByName(SendCodeViewConfig.NavKey, true)
  }

}

@ComponentV2
export struct SendCodeView {
  // 状态变量
  @Local email: string = '';
  @Local isLoading: boolean = false;

  // 路由栈管理
  @Consumer(LoginViewConfig.kNavPath) navPath?: NavPathStack

  // 回调
  @Event onDismiss: () => void;

  build() {
    NavDestination(){
      Stack() {
        Column() {
          this.buildNavBar()
          this.buildSendCodePanel()
        }
      }
    }
    .hideTitleBar(true)
    .title($r('app.string.sendcode_nav_title'))
    .backgroundColor($r('app.color.color_background'))
    .onAppear(() => {
      if (DebugFlg.isDebugMode()) {
        this.email = '44663768@163.com';
      }
    })
  }

  @Builder
  buildNavBar() {
    Row() {
      Stack(){
        Row(){
          Text($r('app.string.sendcode_nav_title'))
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

       Row(){
         Button($r('app.string.login_nav_title'))
           .fontColor($r('app.color.color_nav_tint'))
           .backgroundColor(Color.Transparent)
           .onClick(() => {
             this.navPath?.pop(true)
           })
       }
       .width('100%')
       .justifyContent(FlexAlign.Start)

      }

    }
    .width('100%')
    .height(64)
    .backgroundColor($r('app.color.color_nav_bg'))
    .border({width: {bottom: 1}, color: $r('app.color.colorPrimaryDark')})//NavBar底部边线
  }

  @Builder
  buildSendCodePanel() {
    Column({ space: 20 }) {
      Column() {
        // 邮箱输入框
        TextInput({ text: this.email, placeholder: $r('app.string.sendcode_txt_email') })
          .type(InputType.Email)
          .onChange((value: string) => this.email = value)
          .width('100%')
          .height(50)
          .backgroundColor(Color.White)
          .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
          .margin({ top: 12 })

        // 发送验证码按钮
        TextButton({
          text: $r('app.string.sendcode_btn_send'),
          onClickCallBack: () => this.sendCode(),
          minWidth: 220
        })
          .height(50)
          .margin({ top: 20 })
      }
      .padding(20)
      .width('99%')
      .backgroundColor(Color.White)
      // .borderRadius(6)
      // .shadow({ radius: 1 })
    }
    .width('90%')
    .height('100%')
    .margin({top: 10})
  }

  // 发送验证码逻辑
  private sendCode(): void {
    if (!StringUtils.isValidEmail(this.email)) {
      Toast.showMessage($r('app.string.sendcode_msg_need_email'))
      return;
    }

    this.isLoading = true;
    UserManager.shared.sendSafeCode(this.email, (succeed: boolean, msg: string | null) => {
      this.isLoading = false;
      if (succeed) {
        Toast.showMessage($r('app.string.sendcode_msg_send_done'))
        // 导航到重置密码页面
        ResetPasswordViewConfig.NavTo(this.navPath, {email: this.email})
      } else {
        const errorMsg = `${getString($r('app.string.sendcode_msg_send_failed'))}：${msg ?? ''}`;
        Toast.showMessage(errorMsg)
      }
    });
  }
}