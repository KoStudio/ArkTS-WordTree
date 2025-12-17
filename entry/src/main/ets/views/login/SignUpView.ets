import { AppSettings } from "../../app/constants/AppSettings";
import { DebugFlg } from "../../app/debug/DebugFlg";
import { BgImage } from "../../app/views/BgImage";
import { TextButton } from "../../app/views/buttons/TextButton";
import { LinkText } from "../../app/views/LinkText";
import { LinkViewConfig } from "../../app/views/LinkView";
import { getString } from "../../common/utils/ResourceUtils";
import { StringUtils } from "../../common/utils/strings/StringUtils";
import { UserManager } from "../../models/managers/user/UserManager";
import { bounce } from "../../common/components/animation/AnimBounce";
import { LoginViewConfig } from "./LoginConfig";
import { Toast } from "../../common/utils/Toast";


export namespace SignUpViewConfig {

  ///导航key
  export const NavKey = "SignUpView_show"

  ///打开方式
  export function NavTo(navPath: NavPathStack | undefined){
    if (!navPath) { return }
    navPath.pushPathByName(SignUpViewConfig.NavKey, true)
  }

}

@ComponentV2
export struct SignUpView {
  // 状态变量声明
  @Local email: string = '';
  @Local userName: string = '';
  @Local password: string = '';
  @Local confirmPassword: string = '';
  @Local isAgree: boolean = false;
  @Local isLoading: boolean = false;

  /// 动画控制变量
  @Local checkAgreeShakeOffsetX: number = 0;

  // 路由栈管理
  @Consumer(LoginViewConfig.kNavPath) navPath?: NavPathStack

  // 构建UI组件
  build() {
    NavDestination() {
      Stack() {

        Column() {
          // 自定义导航栏
          this.buildNavBar()

          // 注册面板
          this.buildSignUpPanel()
        }
      }
    }
    .hideTitleBar(true)
    .title($r('app.string.signup_nav_title'))
    .backgroundColor($r('app.color.color_background'))
    .onAppear(() => {
      if (DebugFlg.isDebugMode()) {
        this.email = '44663768@163.com';
        this.userName = '测试用户';
        this.password = '111111';
        this.confirmPassword = '111111';
      }
    })
  }

  @Builder
  buildNavBar() {
    Row() {

      Stack(){
        Row() {
          Button($r('app.string.login_nav_title'))
            .fontColor($r('app.color.color_nav_tint'))
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              //返回
              this.navPath?.pop(true)
            })

          Blank()
        }
        .width('100%')

        Text($r('app.string.signup_nav_title'))
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .height(64)
    .backgroundColor($r('app.color.color_nav_bg'))
    .border({width: {bottom: 1}, color: $r('app.color.colorPrimaryDark')})//NavBar底部边线
  }

  @Builder
  buildSignUpPanel() {
    Column({ space: 20 }) {
      Column() {
        // 邮箱输入框
        TextInput({ text: this.email, placeholder: $r('app.string.signup_txt_email') })
          .type(InputType.Email)
          .onChange((value: string) => this.email = value)
          .width('100%')
          .height(50)
          .backgroundColor(Color.White)
          .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
          .margin({ top: 12 })

        // 用户名输入框
        TextInput({ text: this.userName, placeholder: $r('app.string.signup_txt_username') })
          .onChange((value: string) => this.userName = value)
          .width('100%')
          .height(50)
          .backgroundColor(Color.White)
          .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
          .margin({ top: 12 })

        // 密码输入框
        TextInput({ text: this.password, placeholder: $r('app.string.signup_txt_pwd') })
          .type(InputType.Password)
          .onChange((value: string) => this.password = value)
          .width('100%')
          .height(50)
          .backgroundColor(Color.White)
          .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
          .margin({ top: 12 })

        // 确认密码输入框
        TextInput({ text: this.confirmPassword, placeholder: $r('app.string.signup_txt_pwd2') })
          .type(InputType.Password)
          .onChange((value: string) => this.confirmPassword = value)
          .width('100%')
          .height(50)
          .backgroundColor(Color.White)
          .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
          .margin({ top: 12 })

        // 注册按钮
        TextButton({
          text: $r('app.string.signup_btn_signup'),
          onClickCallBack: () => {this.signUp()},
          minWidth: 220
        })
          .height(50)
          .margin({ top: 20 })

        // 协议确认区域
        Row({ space: 5 }) {
          Checkbox()
            .select(this.isAgree)
            .onChange((value: boolean) => this.isAgree = value)

          Text($r('app.string.signup_chk_agree'))
            .fontSize(14)

          //同意链接
          LinkText({
            content: getString($r('app.string.signup_btn_terms')),
            linkTexts: [getString($r('app.string.signup_btn_terms'))],
            onLinkTapped: () => {
              LinkViewConfig.NavTo(this.navPath, { title: $r('app.string.signup_btn_terms'), url: AppSettings.Address.terms })
            }
          })
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .margin({ top: 10 })
        .offset({x: this.checkAgreeShakeOffsetX, y: 0})
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

  // 注册逻辑
  private signUp(): void {
    if (!StringUtils.isValidEmail(this.email)) {
      Toast.showMessage($r('app.string.signup_msg_need_email'))
      return;
    }

    if (this.userName.trim() === '') {
      Toast.showMessage($r('app.string.signup_msg_need_username'))
      return;
    }

    if (this.password === '') {
      Toast.showMessage($r('app.string.signup_msg_need_pwd'))
      return;
    }

    if (this.password !== this.confirmPassword) {
      Toast.showMessage($r('app.string.signup_msg_pwd_different'))
      return;
    }

    if (!this.isAgree) {
      this.shakeCheckAgree();
      Toast.showMessage($r('app.string.signup_msg_need_agree_terms'))
      return;
    }

    this.isLoading = true;
    UserManager.shared.signUp(this.email, this.userName, this.password, (succeed: boolean, msg: string | null) => {
      this.isLoading = false;
      if (succeed) {
        Toast.showMessage($r('app.string.signup_msg_signup_succeed'))
        this.navPath?.pop(true)
      } else {
        const errorMsg = `${getString($r('app.string.signup_msg_signup_failed'))}：${msg ?? ''}`;
        Toast.showMessage(errorMsg)
      }
    });
  }

  private shakeCheckAgree() {
    bounce({
      set: (x) => this.checkAgreeShakeOffsetX = x,
      isHorizontal: true,
      onFinished: () => this.checkAgreeShakeOffsetX = 0
    });
  }
}

