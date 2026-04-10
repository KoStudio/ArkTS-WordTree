import { Toast } from '../../common/utils/Toast';
import { DataModel } from '../../models/datas/model/DataModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalKey } from '../../app/constants/GlobalKey';
import { AdviceSender } from '../../models/managers/advice/AdviceSender';
import { BundleUtils } from '../../common/utils/BundleUtils';
import { LoginView } from '../login/LoginView';
import { UserManager } from '../../models/managers/user/UserManager';
import { TextButton } from '../../app/views/buttons/TextButton';
import { ImagePickerButton } from '../../app/views/picker/PhotoPicker/PhotoPickerButton';
import { CosDownloaderAdviceData } from '../../models/managers/advice/CosDownloaderAdviceData';
import { PathUtility } from '../../common/utils/PathUtility';
import { buildNavTitle } from '../../app/constants/AppBuilders';
import { dNavBackIcon } from '../../app/constants/AppDefines';
import { MemberManager } from '../../models/managers/member/MemberManager';
import { NavTo } from '../../pages/NavPathManager';
import { IconButton } from '../../app/views/buttons/IconButton';
import { BookManager } from '../../models/datas/book/BookManager';

export namespace AdviceViewConfig {

  ///导航key
  export const NavKey = "AdviceView_show"

  ///打开方式
  export function open(){
    NavTo(NavKey, undefined, true)
  }
}

@ComponentV2
export struct AdviceView {


  @Local content: string = '';              // 用户输入内容
  @Local contact: string = '';              // 联系方式
  @Local isSendButtonEnabled: boolean = false; // 发送按钮状态
  @Local characterCount: number = 0;       // 字符计数
  //@Local attachImage: image.PixelMap | null = null; // 附加图片
  @Local isLoading: boolean = false;        // 加载状态


  // === 常量 ===
  private readonly MAX_COUNT: number = 500; // 最大字符数
  private readonly MIN_COUNT: number = 2;   // 最小字符数（与 iOS `minCount = 2` 一致）

  @Local isShowLoginView: boolean = false

  @Local pickedUri: string | null = null

  @Consumer(GlobalKey.kNavPath) navPath?: NavPathStack

  // === UI 构建 ===
  build() {

    NavDestination() {
      Stack() {

        Column({ space: 16 }) {
          // 文本编辑区域
          this.buildTextEditor();

          // 联系方式输入框
          TextInput({ placeholder:$r('app.string.advice_txt_tip') })
            .width('100%')
            .height(40)
            .onChange((value: string) => {
              this.contact = value;
            })
            .backgroundColor($r('app.color.color_white'))
            .border({width: 1, color: $r('app.color.color_obscure'), radius: 5})

          // 图片选择区域
          this.buildImagePicker();

          ///发送按钮
          TextButton({
            text: $r('app.string.advice_btn_send'), onClickCallBack: () => {
              this.sendAdvice()
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
        .backgroundColor($r('app.color.color_obscure'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .padding(16)
        .width('100%')
        .height('100%')
        .onAppear(() => this.refreshUIState()) // 视图显示时初始化
      }

    }
    .title(buildNavTitle($r('app.string.advice_nav_title')))
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

  /// 构建图片选择器
  @Builder
  buildImagePicker() {
    Row() {
      Stack({ alignContent: Alignment.TopEnd }) {

        // 分支：已选择图片时显示预览图；与 iOS `btnImg1.setImage(...)` 的单图入口一致
        if (this.pickedUri !== null) {
          Image(this.pickedUri)
            .width(66)
            .height(66)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .backgroundColor($r('app.color.color_obscure'))
            .clip(true)

          IconButton({
            icon             : $r('app.media.trash'),
            iconSize         : 18,
            iconColor        : Color.White,
            bgColor          : Color.Red,
            buttonType       : ButtonType.Circle,
            onClickCallBack  : () => {

              // 调用：删除已选择图片，恢复为未选择状态
              this.removePickedImage()
            }
          })
            .width(20)
            .height(20)
            .margin({ top: 0, right: 0 })
        } else {
          ImagePickerButton({
            onImagePicked: (uri: string | null) => {

              // 调用：保存所选图片 URI，用于预览与后续上传
              this.setPickedImage(uri)
            },
            btnWidth     : 66,
            btnHeight    : 66,
            cornerRadius : 8
          })
        }
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)

  }

  /**
   * 保存已选择的图片 URI
   * @param uri 图片 URI；为 null 时表示未选择
   */
  private setPickedImage(uri: string | null): void {

    this.pickedUri = uri

    // 调用：图片状态变化后刷新发送按钮状态与计数显示
    this.refreshUIState()
  }

  // 删除当前已选择图片
  private removePickedImage(): void {

    this.pickedUri = null

    // 调用：图片状态变化后刷新发送按钮状态与计数显示
    this.refreshUIState()
  }

  // === 功能方法 ===

  /** 刷新UI状态 */
  private refreshUIState() {
    const trimmedContent = this.content.trim();
    this.characterCount  = trimmedContent.length;

    // 分支：发送按钮启用规则与 iOS 一致，仅按正文长度判断
    this.isSendButtonEnabled =
      this.characterCount > this.MIN_COUNT &&
        this.characterCount <= this.MAX_COUNT;

  }



  /** 发送反馈 */
  private async sendAdvice() {
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
    const adviceStr = await this.buildAdviceContent();

    // 3. 上传图片或直接发送
    if (this.pickedUri) {
      await this.uploadImage(adviceStr);
    } else {
      await this.sendToServer(adviceStr);
    }

    this.isLoading = false;
  }

  /** 构建反馈内容字符串 */
  private async buildAdviceContent(): Promise<string> {
    let content = `${this.content.trim()}\n\n--------------\n`;
    content += `应用版本: ${BundleUtils.getBundleInfoSync().versionName}\n`;
    content += `用户ID: ${UserManager.shared.userId}\n`;
    content += `用户名: ${UserManager.shared.userName}`;
    
    const book = BookManager.shared.currentBook

    // 分支：当前书存在时，将书名附加到反馈正文；与 iOS `bookName` 拼接一致
    if (book !== null) {
      content += `\n书名: ${book.bookName ?? ''}`
    }

    content += `\nMember: ${MemberManager.shared.isActive ? 'Yes' : 'No'}`
    return content;
  }

  /** 上传图片到服务器 */
  private async uploadImage(adviceStr: string) {

    if (this.pickedUri) {

      let ext      = PathUtility.getExtension(this.pickedUri)
      let fileName = `${UserManager.shared.userId}_${this.getDateNowString()}.${ext}`
      CosDownloaderAdviceData.shared.uploadUserData(this.pickedUri, fileName, (progress: number) => {}, async (success: boolean, filePath?: string, error?: string)=>{

        let str = adviceStr
        str += "\n\n\n图片： \n" + filePath
        if (success) {
          await this.sendToServer(str)
        }else{
          Toast.showMessage('上传图片失败: ' + error)
        }

      })
    }

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

  getDateNowString(): string {
    const date = new Date()

    // 获取各个部分
    const year   = date.getFullYear()
    const month  = (date.getMonth() + 1).toString().padStart(2, '0')
    const day    = date.getDate().toString().padStart(2, '0')
    const hour   = date.getHours().toString().padStart(2, '0')
    const minute = date.getMinutes().toString().padStart(2, '0')
    const second = date.getSeconds().toString().padStart(2, '0')

    return `${year}${month}${day}${hour}${minute}${second}`
  }
}
