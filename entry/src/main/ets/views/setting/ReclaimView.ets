import { image } from '@kit.ImageKit';
import { Toast } from '../../common/utils/Toast';
import { DataModel } from '../../models/datas/model/DataModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalKey } from '../../app/constants/GlobalKey';
import { BundleUtils } from '../../common/utils/BundleUtils';
import { LoginView } from '../login/LoginView';
import { AdviceSender } from '../../models/managers/advice/AdviceSender';
import { UserManager } from '../../models/managers/user/UserManager';
import { TextButton } from '../../app/views/buttons/TextButton';
import { buildNavTitle } from '../../app/constants/AppBuilders';
import { dNavBackIcon } from '../../app/constants/AppDefines';
import { NavTo } from '../../pages/NavPathManager';

export namespace ReclaimViewConfig {

  ///导航key
  export const NavKey = "ReclaimView_show"
  ///打开方式
  export function open(){
    NavTo(NavKey, undefined, true)
  }
}

@ComponentV2
export struct ReclaimView {


  @Local content: string = '';              // 用户输入内容
  @Local contact: string = '';              // 联系方式
  @Local isSendButtonEnabled: boolean = false; // 发送按钮状态
  @Local characterCount: number = 0;       // 字符计数
  @Local attachImage: image.PixelMap | null = null; // 附加图片
  @Local isLoading: boolean = false;        // 加载状态


  // === 常量 ===
  private readonly MAX_COUNT: number = 500; // 最大字符数
  private readonly MIN_COUNT: number = 5;   // 最小字符数


  @Local isShowLoginView: boolean = false

  @Consumer(GlobalKey.kNavPath) navPath?: NavPathStack

  // === UI 构建 ===
  build() {

    NavDestination() {
      Stack() {

        ///背景图片
        // BgImage()

        Column({ space: 16 }) {
          // 文本编辑区域
          this.buildTextEditor();


          ///发送按钮
          TextButton({
            text: $r('app.string.reclaim_btn_send'),

            onClickCallBack: () => {
              this.sendReclaim()
            },
            isEnabled: this.isSendButtonEnabled,
            minWidth: 220
          })
            .height(50)
            .margin({ top: 20 })
            .bindSheet($$this.isShowLoginView, this.buildLoginView(), { //登录
              detents: [SheetSize.LARGE],
              preferType: SheetType.CENTER,
              backgroundColor: $r('app.color.colorPrimary'),
              showClose: false,
              onDisappear: () => {
                this.isShowLoginView = false
              }

            })

          Blank()
        }
        .padding(16)
        .width('100%')
        .height('100%')
        .onAppear(() => this.refreshUIState()) // 视图显示时初始化
      }
      .backgroundColor($r('app.color.color_obscure'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

    }
    .title(buildNavTitle($r('app.string.reclaim_nav_title')))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary'))

  }

  /// 构建文本编辑区域
  @Builder buildTextEditor() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 文本输入框
      TextArea({ text: this.content })
        .height(180)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .border({ width: 1, color: '#DDDDDD' })
        .onChange((value: string) => {
          this.content = value;
          this.refreshUIState();
        });

      // 字符计数器
      Text(`${this.characterCount}/${this.MAX_COUNT}`)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ right: 10, bottom: 5 });
    }
  }


  /** 刷新UI状态 */
  private refreshUIState() {
    const trimmedContent = this.content.trim();
    this.characterCount = trimmedContent.length;
    this.isSendButtonEnabled =
      this.characterCount > this.MIN_COUNT &&
        this.characterCount <= this.MAX_COUNT;
  }


  /** 发送反馈 */
  private async sendReclaim() {
    // 1. 检查登录状态
    if (!UserManager.shared.isLogin()) {
      Toast.showMessage($r('app.string.login_not_login'))

      setTimeout(()=>{
        this.isShowLoginView = true
      }, 1000)
      return;
    }

    this.isLoading = true;

    // 2. 构建反馈内容
    const adviceStr = await this.buildReclaimContent();

    // 3. 上传图片或直接发送
    if (this.attachImage) {
      //await this.uploadImage(adviceStr);
    } else {
      await this.sendToServer(adviceStr);
    }

    this.isLoading = false;
  }

  /** 构建反馈内容字符串 */
  private async buildReclaimContent(): Promise<string> {
    let content = `【投诉】${this.content.trim()}\n\n--------------\n`;
    content += `应用版本: ${BundleUtils.getBundleInfoSync().versionName}\n`;
    content += `用户ID: ${UserManager.shared.userId}\n`;
    content += `用户名: ${UserManager.shared.userName}`;

    return content;
  }


  /** 发送反馈到服务器 */
  private async sendToServer(content: string) {
    AdviceSender.sendAdvice(content, this.contact, (succeed: boolean, msg: string | null)=> {
      if (succeed) {
        Toast.showMessage($r('app.string.advice_msg_send_suceed'))
        this.isSendButtonEnabled = false
        setTimeout(() => {
          this.navPath?.pop(true)
        }, 500)
      }else{
        Toast.showMessage($r('app.string.advice_msg_send_failed') + (msg ?? ""))
      }
    })
  }


  @Builder buildLoginView(){
    LoginView({onDismiss:(loginSucceed: boolean)=>{
      this.isShowLoginView = false
    }})
  }
}