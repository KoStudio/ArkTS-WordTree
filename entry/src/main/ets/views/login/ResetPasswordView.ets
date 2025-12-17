import { DebugFlg } from "../../app/debug/DebugFlg";
import { BgImage } from "../../app/views/BgImage";
import { TextButton } from "../../app/views/buttons/TextButton";
import { getString } from "../../common/utils/ResourceUtils";
import { Toast } from "../../common/utils/Toast";
import { UserManager } from "../../models/managers/user/UserManager";
import { LoginViewConfig } from './LoginConfig';

export namespace ResetPasswordViewConfig {

  ///导航key
  export const NavKey = "ResetPasswordView_show"

  ///打开方式
  export function NavTo(navPath: NavPathStack | undefined, param: ResetPasswordViewConfig.Param){
    if (!navPath) { return }

    if (param.email.length > 0) {
      navPath.pushPathByName(ResetPasswordViewConfig.NavKey, param, true)
    }
  }

  /// 参数类型
  export interface Param {
    email: string
  }

}

@ComponentV2
export struct ResetPasswordView {
  // 参数
  @Param @Require email: string

  // 状态变量
  @Local safeCode: string = '';
  @Local password: string = '';
  @Local confirmPassword: string = '';
  @Local isLoading: boolean = false;

  // 路由栈管理
  @Consumer(LoginViewConfig.kNavPath) navPath?: NavPathStack

  build() {

    NavDestination() {
      Stack() {

        Column() {
          this.buildNavBar()
          this.buildResetPasswordPanel()
        }
      }
    }
    .hideTitleBar(true)
    .title($r('app.string.resetpwd_nav_title'))
    .backgroundColor($r('app.color.color_background'))
    .onAppear(() => {
      if (DebugFlg.isDebugMode()) {
        this.password = '111111';
        this.confirmPassword = '111111';
      }
    })
  }

  @Builder
  buildNavBar() {
    Row() {
      Stack(){
        Row(){
          Text($r('app.string.resetpwd_nav_title'))
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        Row(){
          Button($r('app.string.sendcode_nav_title'))
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
  buildResetPasswordPanel() {
    Column({ space: 20 }) {
      Column() {
        // 邮箱显示（只读）
        TextInput({ text: this.email, placeholder: '' })
          .enabled(false)
          .width('100%')
          .height(50)
          .backgroundColor(Color.White)
          .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
          .margin({ top: 12 })

        // 验证码输入框
        TextInput({ text: this.safeCode, placeholder: $r('app.string.resetpwd_txt_code') })
          .type(InputType.Number)
          .onChange((value: string) => this.safeCode = value)
          .width('100%')
          .height(50)
          .backgroundColor(Color.White)
          .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
          .margin({ top: 12 })

        // 新密码输入框
        TextInput({ text: this.password, placeholder: $r('app.string.resetpwd_txt_pwd') })
          .type(InputType.Password)
          .onChange((value: string) => this.password = value)
          .width('100%')
          .height(50)
          .backgroundColor(Color.White)
          .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
          .margin({ top: 12 })

        // 确认密码输入框
        TextInput({ text: this.confirmPassword, placeholder: $r('app.string.resetpwd_txt_pwd2') })
          .type(InputType.Password)
          .onChange((value: string) => this.confirmPassword = value)
          .width('100%')
          .height(50)
          .backgroundColor(Color.White)
          .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
          .margin({ top: 12 })

        // 重置密码按钮
        TextButton({
          text: $r('app.string.resetpwd_btn_excute'),
          onClickCallBack: () => this.resetPassword(),
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

  // 重置密码逻辑
  private resetPassword(): void {
    if (this.safeCode.trim() === '') {
      Toast.showMessage($r('app.string.resetpwd_msg_need_code'))
      return;
    }

    if (this.password === '') {
      Toast.showMessage($r('app.string.resetpwd_msg_need_pwd'))
      return;
    }

    if (this.password !== this.confirmPassword) {
      Toast.showMessage($r('app.string.resetpwd_msg_pwd_different'))
      return;
    }

    this.isLoading = true;
    UserManager.shared.resetPassword(
      this.email,
      this.safeCode,
      this.password,
      (succeed: boolean, msg: string | null) => {
        this.isLoading = false;
        if (succeed) {
          Toast.showMessage($r('app.string.resetpwd_msg_reset_succeed'))
          this.navPath?.pop(true)
        } else {
          const errorMsg = `${getString($r('app.string.resetpwd_msg_reset_failed'))}：${msg ?? ''}`;
          Toast.showMessage(errorMsg)
        }
      }
    );
  }
}
