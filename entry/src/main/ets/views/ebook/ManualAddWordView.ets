//
// ManualAddWordView.ets
// WordTree
//
// 从零添加：仅输入英文拼写 + 选 Part/Unit，保存后生成仅含 titleEn 的词条，内容可在详情中用 EWord 补全。
//

import { buildNavTitle } from '../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../app/constants/AppDefines'
import { getString } from '../../common/utils/ResourceUtils'
import { Toast } from '../../common/utils/Toast'
import { BookManager } from '../../models/datas/book/BookManager'
import { WordDetail } from '../../models/datas/word/WordDetail'
import { PartUnitPickerView } from './PartUnitPickerView'

@ComponentV2
export struct ManualAddWordView {

  @Event onDismiss                  : () => void = () => {}          // 关闭回调
  @Param initialTitleEn             : string     = ''                // 初始英文（来自上一页）
  @Local private titleEnInput       : string     = ''                // 英文输入
  @Local private titleCn1Input      : string     = ''                // 中文输入
  @Local private isShowPartUnitSheet: boolean    = false             // Part/Unit sheet 显示开关
  @Local private sheetDetail        : WordDetail = new WordDetail()  // 传给 Part/Unit 的词条
  @Local private sheetBookId        : number     = 0                 // 传给 Part/Unit 的 bookId

  // 页面出现时预填英文
  aboutToAppear(): void {
    const trimmed = this.initialTitleEn.trim()
    if (trimmed.length > 0 && this.titleEnInput.length < 1) {
      this.titleEnInput = trimmed
    }
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Text($r('app.string.ebook_manual_add_word_hint'))
          .fontSize(13)
          .fontColor($r('app.color.color_list_item_subtitle'))
          .width('100%')
          .textAlign(TextAlign.Start)

        Text($r('app.string.ebook_manual_add_word_title'))
          .fontSize(13)
          .fontColor($r('app.color.color_list_item_subtitle'))
          .width('100%')
          .textAlign(TextAlign.Start)

        TextInput({ text: $$this.titleEnInput, placeholder: $r('app.string.ebook_manual_add_word_placeholder') })
          .height(42)
          .backgroundColor($r('app.color.color_obscure'))
          .borderRadius(8)

        Text($r('app.string.eword_field_titlecn1'))
          .fontSize(13)
          .fontColor($r('app.color.color_list_item_subtitle'))
          .width('100%')
          .textAlign(TextAlign.Start)

        TextInput({ text: $$this.titleCn1Input, placeholder: $r('app.string.ebook_manual_add_titlecn1_placeholder') })
          .height(42)
          .backgroundColor($r('app.color.color_obscure'))
          .borderRadius(8)

        Button() {
          Text($r('app.string.ebook_manual_add_next')).fontColor(Color.White)
        }
          .width('100%')
          .height(40)
          .backgroundColor(this.canGoNext() ? $r('app.color.colorPrimary') : $r('app.color.color_list_item_subtitle'))
          .enabled(this.canGoNext())
          .onClick(() => {
            this.goNext()
          })

        Blank().layoutWeight(1)
      }
        .width('100%')
        .height('100%')
        .padding(20)
        .backgroundColor($r('app.color.color_background'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
      .title(buildNavTitle($r('app.string.ebook_manual_add_nav_title')))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
      .bindSheet($$this.isShowPartUnitSheet, this.buildPartUnitSheet(), {
        detents: [SheetSize.LARGE],
        preferType: SheetType.CENTER,
        backgroundColor: $r('app.color.colorPrimary'),
        showClose: false,
        onDisappear: () => {
          this.isShowPartUnitSheet = false
        }
      })
  }

  private canGoNext(): boolean {
    return this.titleEnInput.trim().length > 0
  }

  // 下一步：构造仅含 titleEn 与可选 titleCn1 的 WordDetail，跳转 Part/Unit 选择
  private goNext(): void {

    const trimmed = this.titleEnInput.trim()

    // 分支：空英文单词不处理
    if (trimmed.length < 1) {
      return
    }

    const book = BookManager.shared.currentBook

    // 分支：当前未选中 EBook 时提示
    if (book === null || !book.isEBook) {
      Toast.showMessage(getString($r('app.string.ebook_msg_select_ebook_first')))
      return
    }

    // 调用：构造最小词条对象
    const minimal      = new WordDetail()
    minimal.titleEn    = trimmed
    minimal.titleCn1   = this.titleCn1Input.trim()

    this.sheetDetail = minimal
    this.sheetBookId = book.bookId ?? 0
    this.isShowPartUnitSheet = true
  }

  @Builder
  // 构建 Part/Unit 选择 Sheet。
  private buildPartUnitSheet() {
    PartUnitPickerView({
      detail       : this.sheetDetail,
      bookId       : this.sheetBookId,
      onAddSucceed : () => {
        this.isShowPartUnitSheet = false
        this.onDismiss()
      },
      onDismiss    : () => {
        this.isShowPartUnitSheet = false
      }
    })
  }
}
