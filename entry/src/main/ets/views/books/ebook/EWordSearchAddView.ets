//
// EWordSearchAddView.ets
// WordTree
//
// 添加单词到当前 EBook：UI 与 OnlineSearch 一致（标题栏/搜索栏/列表/无数据态），列表项中与搜索框相同的英文或中文红色高亮。
//

import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { HighlightText } from '../../../app/views/HighlightText'
import { OnlineWord } from '../../../models/managers/onlinesearch/OnlineWord'
import { OnlineWordManager } from '../../../models/managers/onlinesearch/OnlineWordManager'
import { NavTo } from '../../../pages/NavPathManager'
import { NoDataPanel } from '../../../app/views/NoDataView'
import { LoadingDialog } from '@kit.ArkUI'
import { Toast } from '../../../common/utils/Toast'
import { MemberManager } from '../../../models/managers/member/MemberManager'
import { DailyCountManager, DailyCountType } from '../../../models/managers/member/DailyCountManaer'
import { BookManager } from '../../../models/datas/book/BookManager'
import { getString } from '../../../common/utils/ResourceUtils'
import { NetWorkTool } from '../../../common/utils/NetworkUtils'
import { WordDetail } from '../../../models/datas/word/WordDetail'
import { PartUnitPickerViewConfig } from './PartUnitPickerView'
import { ManualAddWordViewConfig } from './ManualAddWordView'

export namespace EWordSearchAddViewConfig {

  export const NavKey: string = 'EWordSearchAddView_show'

  export function open(): void {

    NavTo(EWordSearchAddViewConfig.NavKey, undefined, true, true)
  }
}

@ComponentV2
export struct EWordSearchAddView {

  @Local searchResults : WordDetail[] = []
  @Local isSearching   : boolean      = false
  @Local searchText    : string       = ''
  @Local addingTitleEn : string       = ''
  @Local hintMessage   : string       = ''

  private searchController: SearchController = new SearchController()

  aboutToAppear(): void {
    // 分支：当前未选中 EBook 时给出提示
    if (BookManager.shared.currentBook?.isEBook !== true) {
      this.hintMessage = getString($r('app.string.ebook_msg_select_ebook_first'))
    }

    setTimeout(() => {
      this.getUIContext().getFocusController().requestFocus('searchText')
    }, 100)
  }

  build() {
    NavDestination() {

      Column() {

        this.SearchPanel()

        if (this.searchResults.length > 0) {
          this.buildList()
        } else {
          this.buildNoDataPanel()
        }
      }
        .backgroundColor($r('app.color.color_background'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
      .title(buildNavTitle($r('app.string.ebook_nav_add_word')))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
  }

  @Builder
  SearchPanel() {

    Row() {

      Search({ placeholder: '', value: $$this.searchText, controller: this.searchController })
        .backgroundColor($r('app.color.color_obscure'))
        .layoutWeight(1)
        .enterKeyType(EnterKeyType.Search)
        .enableHapticFeedback(true)
        .id('searchText')
        .onSubmit((value: string) => {

          this.searchText = value
          void this.runSearch()
        })

      if (this.isSearching) {

        Button() {

          Text($r('app.string.online_search_btn_cancel'))
        }
          .padding(5)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.color_link'))
          .onClick(() => {
            this.clearSearch()
          })
      }
    }
      .width('100%')
      .padding({ top: 2, left: 10, right: 10, bottom: 0 })
      .align(Alignment.Bottom)
      .backgroundColor($r('app.color.colorPrimary'))
  }

  @Builder
  buildList() {

    List({ space: 0 }) {

      ForEach(this.searchResults, (word: WordDetail, rowIndex: number) => {

        ListItem() {
          this.buildRowContent(word, rowIndex)
        }
          .margin({ bottom: 1 })
      }, (word: WordDetail, rowIndex: number) => `${word.titleEn}_${rowIndex}`)
    }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  buildRowContent(word: WordDetail, _rowIndex: number) {

    Row() {

      Column({ space: 10 }) {

        HighlightText({
          content : word.titleEn || '',
          keyword : this.searchText,
          normalColor: $r('app.color.color_title'),
          textStyle: { fontSize: 18, maxLines: 1 }
        })

        HighlightText({
          content    : word.getTitleCnsJoined(),
          keyword    : this.searchText,
          normalColor: $r('app.color.color_detail'),
          textStyle  : { fontSize: 15, maxLines: 3 }
        })
      }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      if (this.addingTitleEn === (word.titleEn ?? '')) {

        LoadingProgress()
          .width(24)
          .height(24)
      } else {

        Button() {

          Text($r('app.string.ebook_add'))
            .fontSize(14)
            .fontColor(Color.White)
        }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor($r('app.color.colorPrimary'))
          .onClick(() => {

            void this.addWord(word.titleEn ?? '')
          })
      }
    }
      .width('100%')
      .padding({ left: 10, top: 8, right: 10, bottom: 8 })
      .justifyContent(FlexAlign.SpaceBetween)
      .backgroundColor($r('app.color.color_clear'))
      .border({ width: { bottom: 1 }, style: BorderStyle.Dashed, color: $r('app.color.color_obscure') })
  }

  @Builder
  private buildNoDataPanel() {
    Column({ space: 12 }) {
      NoDataPanel({ message: this.hintMessage.length > 0 ? this.hintMessage : $r('app.string.online_search_input_tip') })

      if (BookManager.shared.currentBook?.isEBook === true) {
        Button() {
          Text($r('app.string.ebook_not_found_manual_add'))
            .fontColor($r('app.color.colorPrimary'))
        }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            ManualAddWordViewConfig.open({ initialTitleEn: this.searchText })
          })
      }
    }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
  }

  private clearSearch(): void {

    this.searchText    = ''
    this.searchResults = []
    this.hintMessage   = ''
  }

  @Builder
  buildLoadingDialog(msg?: ResourceStr | null): void {

    LoadingDialog({ content: msg ?? 'loading' })
  }

  private async runSearch(): Promise<void> {

    const q = this.searchText.trim()

    if (q.length < 1) {
      this.hintMessage = getString($r('app.string.ebook_msg_input_query'))
      return
    }

    if (!NetWorkTool.checkInternetConnection(true)) {
      return
    }

    if (!MemberManager.shared.checkOnlineDictUsable(true, true)) {
      return
    }

    DailyCountManager.shared.increase(DailyCountType.onlineDict)

    this.isSearching     = true
    this.hintMessage     = ''
    this.searchResults   = []

    Toast.showCustomDialog(() => {
      this.buildLoadingDialog($r('app.string.online_search_loading'))
    }, false)

    OnlineWordManager.shared.searchWords(q, 0, (success: boolean, msg: string | null, words: OnlineWord[] | null) => {

      Toast.closeCustomDialog()
      this.isSearching = false

      if (success && words !== null && words.length > 0) {
        this.searchResults = words.map((v: OnlineWord) => v.asWordDetail())
      } else {
        this.hintMessage = msg ?? getString($r('app.string.online_search_txt_no_found'))
      }
    })
  }

  private async addWord(titleEn: string): Promise<void> {

    if (titleEn.length < 1) {
      return
    }

    const book = BookManager.shared.currentBook

    if (book === null || !book.isEBook || book.textDb === null) {
      Toast.showMessage(getString($r('app.string.ebook_msg_select_ebook_first')))
      return
    }

    this.addingTitleEn = titleEn

    OnlineWordManager.shared.loadWord(titleEn, async (success: boolean, msg: string | null, ow: OnlineWord | null) => {

      this.addingTitleEn = ''

      if (!success || ow === null) {
        Toast.showMessage(msg ?? getString($r('app.string.ebook_get_detail_failed')))
        return
      }

      const detail = ow.asWordDetail()

      // 调用：进入 Part/Unit 选择页，由该页完成覆盖确认与写库
      PartUnitPickerViewConfig.open({
        detail : detail,
        bookId : book.bookId ?? 0
      })
    })
  }
}
