import { TextButton } from '../../app/views/buttons/TextButton';
import { LinkText } from '../../app/views/LinkText';
import { getString } from '../../common/utils/ResourceUtils';
import { LinkView, LinkViewConfig } from '../../app/views/LinkView';
import { DebugFlg } from '../../app/debug/DebugFlg';
import { bounce } from '../../common/components/animation/AnimBounce';
import { AppSettings } from '../../app/constants/AppSettings';
import { StringUtils } from '../../common/utils/strings/StringUtils';
import { UserManager } from '../../models/managers/user/UserManager';
import { BgImage } from '../../app/views/BgImage';
import { SignUpView, SignUpViewConfig } from './SignUpView';
import { SendCodeView, SendCodeViewConfig } from './SendCodeView';
import { ResetPasswordView, ResetPasswordViewConfig } from './ResetPasswordView';
import { LoginViewConfig } from './LoginConfig';
import { Toast } from '../../common/utils/Toast';
import { IconButton } from '../../app/views/buttons/IconButton';
import { LoginType } from '../../models/managers/user/User';
import { logEvent } from '../../common/components/Logger/Logger';
import { SubscriptionInfoManager } from '../../models/managers/subscription/SubscriptionInfoManager';
import { QQLoginManager } from '../../models/managers/sns/qq/QQLoginManager';


@ComponentV2
export struct LoginView {

  //回调
  @Event onDismiss: (loginSucceed: boolean) => void;

  // 状态变量声明
  @Local email: string = '';
  @Local password: string = '';
  @Local isAgree: boolean = false;


  ///动画控制变量
  @Local checkAgreeShakeOffsetX: number = 0

  // 路由栈管理
  @Provider(LoginViewConfig.kNavPath) navPath: NavPathStack = new NavPathStack()


  // 构建UI组件
  build() {
    // 导航容器（对应NavigationStack）
    Navigation(this.navPath) {
      Stack(){

        ///背景图
        //BgImage()

        Column(){
          ///自定义 导航
          this.buildNavBar()

          ///登录panel
          this.buildLoginPanel()

        }


      }
    }
    .navDestination(this.navigationTo)
    .navBarPosition(NavBarPosition.Start)
    .hideTitleBar(true) //navBar上的menu按钮只能使用图标，暂时不用导航栏
    .title($r('app.string.login_nav_title')) // 导航标题
    .backgroundColor($r('app.color.color_background'))
    .onAppear(() => {
      if (DebugFlg.isDebugMode()) {
        this.email = '44663768@163.com';
        this.password = '111111';
      }
    })
  }
  @Builder
  navigationTo<T>(name: string, param: T){
    if (name === LinkViewConfig.NavKey)                 { LinkView({ title: (param as LinkViewConfig.Param).title, url: (param as LinkViewConfig.Param).url })
    }else  if (name === SignUpViewConfig.NavKey)        { SignUpView()
    }else  if (name === SendCodeViewConfig.NavKey)      { SendCodeView()
    }else  if (name === ResetPasswordViewConfig.NavKey) { ResetPasswordView({email: (param as ResetPasswordViewConfig.Param).email})
    // }else  if (name === WXQRLoginViewConfig.NavKey)     { WXQRLoginView({image: (param as WXQRLoginViewConfig.Param).image})
    }else{ NavDestination(){Text(`<LoginView.ets>未配置navigationTo: ${name}`)}
    }
  }

  @Builder
  buildNavBar() {

    Row(){
      Button('取消')
        .fontColor($r('app.color.color_nav_tint'))
        .backgroundColor(Color.Transparent)
        .onClick(()=>{

          ///取消
          this.onDismiss(false)
        })

      Blank()
      Text($r('app.string.login_nav_title'))
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
      Blank()

      Button('注册')
        .fontColor($r('app.color.color_nav_tint'))
        .backgroundColor(Color.Transparent)
        .onClick(()=>{

          //注册
          SignUpViewConfig.NavTo(this.navPath)
        })
    }
    .width('100%')
    .height(64)
    .backgroundColor($r('app.color.color_nav_bg'))
    .border({width: {bottom: 1}, color: $r('app.color.colorPrimaryDark')})//NavBar底部边线

  }

  @Builder
  buildLoginPanel(){
    Column({ space: 20 }) {
      // 登录表单区域
      Column() {
        Column() {
          // 邮箱输入框
          TextInput({ text: this.email, placeholder: $r('app.string.login_txt_email') })
            .type(InputType.Email)
            .onChange((value: string) => {
              this.email = value;
            })
            .width('100%')
            .height(50)
            .backgroundColor(Color.White)
            .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
            .margin({ top: 12 })

          // 密码输入框
          TextInput({ text: this.password, placeholder: $r('app.string.login_txt_pwd') })
            .type(InputType.Password)
            .onChange((value: string) => {
              this.password = value;
            })
            .width('100%')
            .height(50)
            .backgroundColor(Color.White)
            .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
            .margin({ top: 12 })


          //按钮
          Column() {
            // 登录按钮
            TextButton({
              text: $r('app.string.login_btn_login'), onClickCallBack: () => {
                this.login()
              },
              minWidth: 220
            })
              .height(50)
              .margin({ top: 20 })

           Row(){
              Blank().layoutWeight(1)

             // 忘记密码按钮
             Button($r('app.string.login_btn_forget'))// 使用资源引用
               .onClick(() => {
                 SendCodeViewConfig.NavTo(this.navPath)
               })
               .fontColor($r('app.color.color_link'))
               .backgroundColor(Color.Transparent)
               .margin({ top: 1, left: 50 })
           }

          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(6)
        // .borderWidth(0)
        // .shadow({ radius: 1, color: Color.White })

        Divider().color(Color.Gray).margin({ top: 20, bottom: 20 })

        // 社交登录文本
        Text($r('app.string.login_sns_txt_other')) // 使用资源引用
          .fontSize(16)
          .fontColor(Color.Gray)
          .opacity(0.6)
          .textAlign(TextAlign.Center)

        Blank().height(10)
        // 社交登录按钮区域
        Row({ space: 20 }) {

          //华为
          IconButton({icon: $r('app.media.huawei_1'), iconSize: 44, onClickCallBack:()=>{
            this.actionLoginHuawei()
          }})

          //微信


          //QQ
          IconButton({icon: $r('app.media.qq'), iconSize: 44, onClickCallBack:()=>{
            this.actionLoginQQ()
          }})
        }

      }
      // .padding(20)
      // .width('99%')
      // .backgroundColor(Color.White)
      // .borderRadius(6)
      // .shadow({ radius: 1 })


      // 协议确认区域
      Row({ space: 0 }) {
        Checkbox()
          .select(this.isAgree)
          .onChange((value: boolean) => {
            this.isAgree = value;
          })

        LinkText({
          content: getString($r('app.string.login_agree_txt')),
          linkTexts: [getString($r('app.string.login_agree_link_terms')), getString($r('app.string.login_agree_link_privacy'))],
          onLinkTapped: (text) => {
            if (text === getString($r('app.string.login_agree_link_terms'))) {
              ///服务协议
              LinkViewConfig.NavTo(this.navPath, {title: text, url: AppSettings.Address.terms })
            }else if (text === getString($r('app.string.login_agree_link_privacy'))){
              ///隐私政策
              LinkViewConfig.NavTo(this.navPath, {title: text, url: AppSettings.Address.privacy })
            }
          }
        })

      }
      .justifyContent(FlexAlign.Start)
      .width('90%')
      .offset({x: this.checkAgreeShakeOffsetX, y:  0})
    }
    .width('90%')
    .height('100%')
    .margin({top: 10})
  }

  // MARK: - 登录相关方法
  private shakeCheckAgree(){
    bounce({set:(x,y) => { this.checkAgreeShakeOffsetX = x },isHorizontal: true, onFinished: () => {  }})
  }
  // 登录方法
  private login(): void {
    if (!StringUtils.isValidEmail(this.email)) {
      Toast.showMessage($r('app.string.login_msg_invalid_email'))
      return;
    }

    if (this.password === '') {
      Toast.showMessage($r('app.string.login_msg_need_pwd'))
      return;
    }

    if (!this.checkAggree()) {
      return;
    }


    //email登录
    UserManager.shared.login(this.email, this.password, (succeed: boolean, msg:string |null)=>{
      this.handleLoginCompletion(succeed, msg);
    })

  }

  actionLoginHuawei(){
    this.loginBySns(LoginType.huawei)
  }

  actionLoginQQ(){
    ///qq 已安装
    if (QQLoginManager.shared.isQQAppInstalled()) {
      this.loginBySns(LoginType.qq)
    }else{
      Toast.showMessage('未安装QQ')
    }
  }
  actionLoginWeChat(){
    ///微信 已安装
    // if (WXLoginManager.shared.isWxAppInstalled()) {
    //   this.loginBySns(LoginType.wechat)
    // }else{
    //   if (!this.checkAggree()) return;
    //
    //   UserManager.shared.loginBySns(LoginType.wechat_qr, (base64stringImage: string )=>{
    //
    //     //转向 QR扫码页面
    //     WXQRLoginViewConfig.NavTo(this.navPath, {image: base64stringImage})
    //
    //   }, (succeed: boolean, msg:string|null)=>{
    //     this.handleLoginCompletion(succeed, msg);
    //   })
    // }
  }

  // sns登录方法
  private loginBySns(type: LoginType): void {
    if (!this.checkAggree()) return;

    UserManager.shared.loginBySns(type, undefined, (succeed: boolean, msg:string |null)=>{
      this.handleLoginCompletion(succeed, msg);
    })

  }

  // 检查是否同意协议
  private checkAggree(): boolean {
    if (!this.isAgree) {
      this.shakeCheckAgree()
      Toast.showMessage($r('app.string.login_agree_tip'))
      return false;
    }
    return true;
  }

  // 处理登录结果
  private handleLoginCompletion(succeed: boolean, msg?: string | null): void {
    if (succeed) {
      Toast.showMessage($r('app.string.login_msg_login_succeed'))
      this.navPath.pop(true)
      this.onDismiss(true) //登录成功回调

      /// 登录时，只从Server读取，不写入
      SubscriptionInfoManager.shared.asyncRefreshSubscriptionInfo(true) //只读取

      logEvent("login_succeed") //日志
    } else {
      // 使用字符串模板拼接本地化消息
      const errorMsg = `${getString($r('app.string.login_msg_login_failed'))}：${msg ?? ''}`
      Toast.showMessage(errorMsg)
      logEvent("login_failed") //日志
    }
  }
}