//
// ManualAddWordView.ets
// WordTree
//
// 从零添加：仅输入英文拼写 + 选 Part/Unit，保存后生成仅含 titleEn 的词条，内容可在详情中用 EWord 补全。
//

import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { getString } from '../../../common/utils/ResourceUtils'
import { Toast } from '../../../common/utils/Toast'
import { BookManager } from '../../../models/datas/book/BookManager'
import { WordDetail } from '../../../models/datas/word/WordDetail'
import { NavTo } from '../../../pages/NavPathManager'
import { PartUnitPickerViewConfig } from './PartUnitPickerView'

export namespace ManualAddWordViewConfig {

  export const NavKey: string = 'ManualAddWordView_show'

  export interface Param {
    initialTitleEn: string
  }

  export function open(param: Param): void {
    NavTo(ManualAddWordViewConfig.NavKey, param, true, true)
  }
}

@ComponentV2
export struct ManualAddWordView {

  @Param initialTitleEn: string = ''

  @Local private titleEnInput  : string = ''
  @Local private titleCn1Input : string = ''

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

        Text($r('app.string.eword_field_title_cn1'))
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
    }
      .title(buildNavTitle($r('app.string.ebook_manual_add_nav_title')))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
  }

  private canGoNext(): boolean {
    return this.titleEnInput.trim().length > 0
  }

  /**
   * 下一步：构造仅含 titleEn 与可选 titleCn1 的 WordDetail，跳转 Part/Unit 选择
   */
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

    const minimal      = new WordDetail()
    minimal.titleEn    = trimmed
    minimal.titleCn1   = this.titleCn1Input.trim()

    PartUnitPickerViewConfig.open({
      detail : minimal,
      bookId : book.bookId ?? 0
    })
  }
}
