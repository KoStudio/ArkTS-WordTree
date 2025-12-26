import { Toast } from '../../common/utils/Toast';
import { GlobalKey } from '../../app/constants/GlobalKey';
import { ReclaimWordSender } from '../../models/managers/ReclaimWord/ReclaimWordSender';
import { LoginView } from '../login/LoginView';
import { TextButton } from '../../app/views/buttons/TextButton';
import { buildNavTitle } from '../../app/constants/AppBuilders';
import { dNavBackIcon } from '../../app/constants/AppDefines';
import { NavPop, NavTo } from '../../pages/NavPathManager';
import { BookManager } from '../../models/datas/book/BookManager';
import { SearchManager } from '../../models/datas/model/SearchManager';
import { UserManager } from '../../models/managers/user/UserManager';
import { getString } from '../../common/utils/ResourceUtils';

export namespace ReclaimWordViewConfig {

  export const NavKey = 'ReclaimWordView_show'

  export function open(param: Param) {
    NavTo(NavKey, param)
  }

  export interface Param {
    titleEn: string
  }
}

@ComponentV2
export struct ReclaimWordView {

  @Param titleEn: string = ''

  // ================= 状态 =================
  @Local content: string = ''
  @Local isSendButtonEnabled: boolean = false
  @Local characterCount: number = 0
  @Local isLoading: boolean = false
  @Local isShowLoginView: boolean = false

  @Local isBtnPreClaim1: boolean = false
  @Local isBtnPreClaim2: boolean = false
  @Local isBtnPreClaim3: boolean = false
  @Local isBtnPreClaim4: boolean = false
  @Local isBtnPreClaim5: boolean = false
  @Local isBtnPreClaim6: boolean = false


  // ================= 常量 =================
  private readonly MAX_COUNT: number = 500
  private readonly MIN_COUNT: number = 1

  /** 纠错按钮文本（ResourceStr 常量数组） */
  private readonly PRE_CLAIM_TEXTS: ResourceStr[] = [
    getString($r('app.string.learn_detail_reclaim_txt_pre1')),   // 单词翻译有误
    getString($r('app.string.learn_detail_reclaim_txt_pre2')),        // 单词音标有误
    getString($r('app.string.learn_detail_reclaim_txt_pre3')),       // 单词发音有误
    getString($r('app.string.learn_detail_reclaim_txt_pre4')), // 例句翻译有误
    getString($r('app.string.learn_detail_reclaim_txt_pre5')),     // 例句和单词不匹配
    getString($r('app.string.learn_detail_reclaim_txt_pre6'))      // 例句发音有误
  ]


  // ================= UI =================
  build() {
    NavDestination() {
      Column() {
        this.buildWordDisplay()
        this.buildCheckButtons()
        this.buildTextEditor()
        this.buildSendButton()
        this.buildInfoText()
        Blank().layoutWeight(1)
      }
      .padding(10)
      .backgroundColor($r('app.color.color_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .title(buildNavTitle($r('app.string.nav_title_reclaim')))
    .backButtonIcon(dNavBackIcon)
    .backgroundColor($r('app.color.colorPrimary'))
  }

  @Builder
  buildWordDisplay() {
    Row() {
      Text(this.titleEn)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.color_title'))

    }
    .width('100%')
    .padding(8)
    .backgroundColor($r('app.color.color_obscure'))
  }

  @Builder
  buildCheckButtons() {
    Column({ space: 8 }) {

      Row({ space: 10 }) {
        this.buildCheckButton(this.PRE_CLAIM_TEXTS[0], () => this.isBtnPreClaim1, v => {
          this.isBtnPreClaim1 = v; this.refreshUIState()
        })
        this.buildCheckButton(this.PRE_CLAIM_TEXTS[3], () =>  this.isBtnPreClaim4, v => {
          this.isBtnPreClaim4 = v; this.refreshUIState()
        })
      }

      Row({ space: 10 }) {
        this.buildCheckButton(this.PRE_CLAIM_TEXTS[1], () =>  this.isBtnPreClaim2, v => {
          this.isBtnPreClaim2 = v; this.refreshUIState()
        })
        this.buildCheckButton(this.PRE_CLAIM_TEXTS[4], () =>  this.isBtnPreClaim5, v => {
          this.isBtnPreClaim5 = v; this.refreshUIState()
        })
      }

      Row({ space: 10 }) {
        this.buildCheckButton(this.PRE_CLAIM_TEXTS[2], () =>  this.isBtnPreClaim3, v => {
          this.isBtnPreClaim3 = v; this.refreshUIState()
        })
        this.buildCheckButton(this.PRE_CLAIM_TEXTS[5], () =>  this.isBtnPreClaim6, v => {
          this.isBtnPreClaim6 = v; this.refreshUIState()
        })
      }
    }
    .margin({top: 10, left: 10, right: 10 })
  }

  @Builder
  buildTextEditor() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      TextArea({ text: this.content })
        .height(180)
        .onChange(v => {
          this.content = v
          this.refreshUIState()
        })
        .borderRadius(6)

      Text(`${this.characterCount}/${this.MAX_COUNT}`)
        .fontSize(11)
        .margin({ right: 10, bottom: 5 })
    }
    .margin({top: 10, left: 10, right: 10 })
  }

  @Builder
  buildSendButton() {
    Row() {
      TextButton({
        text: $r('app.string.advice_btn_send'),
        bgColor: $r('app.color.color_btn_bg2'),
        isEnabled: this.isSendButtonEnabled,
        onClickCallBack: () => this.sendReclaimWord()
      })
        .bindSheet($$this.isShowLoginView, this.buildLoginView())
    }
    .justifyContent(FlexAlign.Center)
    .margin({ top: 10 })
  }

  @Builder
  buildInfoText() {
    Text($r('app.string.learn_detail_reclaim_txt_info'))
      .fontSize(14)
      .fontColor($r('app.color.color_list_item_subtitle'))
      .margin({ left: 10, right: 10, top: 10 })
  }

  @Builder
  buildCheckButton(text: ResourceStr, isSelected: ()=> boolean, onToggle: (v: boolean) => void) {
    Row() {
      Text(text)
        .fontSize(14)
        .fontColor(isSelected() ? $r('app.color.color_white') : $r('app.color.color_link'))
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .padding(5)
    .width('45%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(isSelected() ? $r('app.color.colorPrimary') : $r('app.color.color_obscure'))
    .border({ width: 1, radius: 6 , color: $r('app.color.colorPrimary')})
    .onClick(() => onToggle(!isSelected()))

  }

  // ================= 逻辑 =================
  private refreshUIState() {
    const hasSelected =
      this.isBtnPreClaim1 || this.isBtnPreClaim2 || this.isBtnPreClaim3 ||
      this.isBtnPreClaim4 || this.isBtnPreClaim5 || this.isBtnPreClaim6

    this.characterCount = this.content.trim().length

    this.isSendButtonEnabled = hasSelected ||
      (this.characterCount > this.MIN_COUNT && this.characterCount <= this.MAX_COUNT)
  }

  private async sendReclaimWord(): Promise<void> {
    if (!UserManager.shared.isLogin()) {
      Toast.showMessage($r('app.string.login_not_login'))
      this.isShowLoginView = true
      return
    }

    let selectedClaimTxt = ''

    if (this.isBtnPreClaim1) selectedClaimTxt += `${this.PRE_CLAIM_TEXTS[0]}, `
    if (this.isBtnPreClaim2) selectedClaimTxt += `${this.PRE_CLAIM_TEXTS[1]}, `
    if (this.isBtnPreClaim3) selectedClaimTxt += `${this.PRE_CLAIM_TEXTS[2]}, `
    if (this.isBtnPreClaim4) selectedClaimTxt += `${this.PRE_CLAIM_TEXTS[3]}, `
    if (this.isBtnPreClaim5) selectedClaimTxt += `${this.PRE_CLAIM_TEXTS[4]}, `
    if (this.isBtnPreClaim6) selectedClaimTxt += `${this.PRE_CLAIM_TEXTS[5]}, `

    const  content = selectedClaimTxt +"\n"+ this.content.trim()

    const bookId = BookManager.shared.currentBook?.bookId ?? 0
    const bookName = BookManager.shared.currentBook?.bookName ?? ''
    ReclaimWordSender.sendReclaimWord(bookId, bookName, this.titleEn, content, (succeed: boolean, msg: string | null) => {

        if (succeed) {
          Toast.showMessage($r('app.string.advice_msg_send_suceed'))
          NavPop()

        }else{
          Toast.showMessage(getString($r('app.string.advice_msg_send_failed')) + ":" + msg ?? '')
        }
      }
    )
  }

  @Builder
  buildLoginView() {
    LoginView({ onDismiss: () => this.isShowLoginView = false })
  }
}