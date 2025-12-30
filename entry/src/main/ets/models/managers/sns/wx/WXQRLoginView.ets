// import { BgImage } from "../../../../app/views/BgImage";
// import { UserManager } from "../../user/UserManager";
// import { WXLoginManager } from "./WxLoginManager";
// import { LoginViewConfig } from "../../../../views/login/LoginConfig";
//
// export namespace WXQRLoginViewConfig {
//
//   ///导航key
//   export const NavKey = "WXQRLoginView_show"
//
//   ///打开方式
//   export function NavTo(navPath: NavPathStack | undefined, param: WXQRLoginViewConfig.Param){
//     if (!navPath) { return }
//
//     if (param.image.length > 0) {
//       navPath.pushPathByName(WXQRLoginViewConfig.NavKey, param, true)
//     }
//   }
//
//   /// 参数类型
//   export interface Param {
//     image: string //base64JpegImageBuffer
//   }
//
// }
//
// @Entry
// @ComponentV2
// export struct WXQRLoginView {
//
//   //参数
//   @Param image: string = "" // 使用Resource类型管理图片资源
//
//   @Local timerRunning: boolean = false;
//   private timerID: number = 0; // 用于保存定时器ID
//
//   // 路由栈管理
//   @Consumer(LoginViewConfig.kNavPath) navPath?: NavPathStack
//
//   // 确保字符串有正确的前缀
//   ensureDataUrlPrefix(base64String: string): string {
//   if (base64String.startsWith('data:image/jpeg;base64,')) {
//     return base64String; // 已有前缀，直接返回
//   }
//   // 若无前缀，则添加
//   return `data:image/jpeg;base64,${base64String}`;
// }
//
//   build() {
//     NavDestination() {
//       Stack() {
//         BgImage()
//
//         Column() {
//           this.buildNavBar()
//           this.buildQRPanel()
//
//           Blank().layoutWeight(1)
//         }
//         .width('100%')
//         .height('100%')
//
//       }
//     }
//     .title($r('app.string.login_qr_nav_title'))
//     .backgroundColor($r('app.color.colorPrimary'))
//     .width('100%')
//     .height('100%')
//     .hideTitleBar(true)
//     .backgroundColor('#F5F5F5') // 整体背景色
//     .onAppear(() => {
//       this.startTimer();
//     })
//     .onDisAppear(() => {
//       this.stopTimer();
//       this.checkUnauthorizedLogin();
//     })
//   }
//
//   @Builder
//   buildNavBar() {
//     Row() {
//       //返回
//       Button(){
//         Image($r('app.media.arrow_left'))
//           .width(26)
//           .height(26)
//           .fillColor(Color.Red)
//
//       }
//       .margin(15)
//         .fontColor($r('app.color.colorAccent'))
//         .backgroundColor(Color.Transparent)
//         .onClick(() => {
//           this.navPath?.pop(true)
//         })
//
//       Blank()
//       Text($r('app.string.login_qr_nav_title'))
//         .fontWeight(FontWeight.Bold)
//         .fontColor(Color.White)
//       Blank()
//     }
//     .width('100%')
//     .height(64)
//     .border({width: {bottom: 1}, color: $r('app.color.colorPrimaryDark')})
//   }
//
//   // 页面构建
//   @Builder
//   buildQRPanel(){
//     Column() {
//
//
//       // 内容层
//       Column() {
//         // 二维码图片区域
//         if (this.image) {
//           Image(this.ensureDataUrlPrefix(this.image))
//             .width(200)
//             .height(200)
//             .objectFit(ImageFit.Contain)
//         } else {
//           LoadingProgress() // 加载指示器
//             .width(200)
//             .height(200)
//         }
//
//         // 提示文字区域
//         Row() {
//           Image($r('app.media.wx_icon')) // 微信图标
//             .width(20)
//             .height(20)
//             .margin({ right: 8 })
//
//           Text('请使用微信扫码登录')
//             .fontSize(16)
//             .fontColor(Color.Black)
//         }
//         .margin({ top: 12 })
//
//       }
//       .padding(20)
//       .backgroundColor(Color.White)
//       .borderRadius(12)
//       .shadow({ radius: 8, color: Color.Gray })
//       .margin(20) // 与屏幕边缘保持距离
//
//     }
//   }
//
//
//   // 开始定时器
//   private startTimer(): void {
//     this.timerRunning = true;
//     this.timerID = setInterval(() => {
//       if (!this.timerRunning) {
//         clearInterval(this.timerID);
//         return;
//       }
//       this.checkLoginStatus();
//     }, 1000); // 每秒检查一次
//   }
//
//   // 停止定时器
//   private stopTimer(): void {
//     this.timerRunning = false;
//     if (this.timerID) {
//       clearInterval(this.timerID);
//     }
//   }
//
//   // 检查登录状态
//   private checkLoginStatus(): void {
//
//     if (UserManager.shared.isLogin()) {
//       this.stopTimer();
//       // 关闭当前页面，假设通过路由返回
//       this.navPath?.pop(true)
//     }
//   }
//
//   // 检查未授权登录
//   private checkUnauthorizedLogin(): void {
//
//     if (!UserManager.shared.isLogin()) {
//       // 停止二维码登录流程
//       WXLoginManager.shared.stopQrLogin();
//     }
//   }
// }