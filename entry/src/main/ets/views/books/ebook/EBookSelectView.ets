//
// EBookSelectView.ets
// WordTree
//
// 从学习详情页将当前单词保存到任意本地 EBook：选 EBook 或新建 → 选 Part/Unit → 若已存在则确认覆盖后写入。
//

import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { getStringF } from '../../../common/utils/ResourceUtils'
import { Book } from '../../../models/datas/book/Book'
import { BookManager, BookManagerNotification } from '../../../models/datas/book/BookManager'
import { WordDetail } from '../../../models/datas/word/WordDetail'
import { NavTo } from '../../../pages/NavPathManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { CreateEBookViewConfig } from './CreateEBookView'
import { PartUnitPickerViewConfig } from './PartUnitPickerView'

export namespace EBookSelectViewConfig {

  export const NavKey: string = 'EBookSelectView_show'

  export interface Param {
    originalDetail: WordDetail
  }

  export function open(param: Param): void {
    NavTo(EBookSelectViewConfig.NavKey, param, true, true)
  }
}

@ComponentV2
export struct EBookSelectView {

  @Param @Require originalDetail: WordDetail

  @Local private eBooks: Book[] = []
  private unsubBookList: (() => void) | undefined = undefined

  aboutToAppear(): void {
    this.loadData()
    this.unsubBookList = SimpleEventBus.on(BookManagerNotification.bookListUpdated, () => {
      this.loadData()
    })
  }

  aboutToDisappear(): void {
    if (this.unsubBookList !== undefined) {
      this.unsubBookList()
      this.unsubBookList = undefined
    }
  }

  build() {
    NavDestination() {
      List() {
        ListItemGroup({ header: this.sectionHeader($r('app.string.ebook_select_title')) }) {
          ListItem() {
            Row({ space: 8 }) {
              Text('+').fontSize(18).fontColor($r('app.color.colorPrimary'))
              Text($r('app.string.ebook_new_book')).fontSize(18).fontColor($r('app.color.colorPrimary'))
            }
              .width('100%')
              .padding(12)
              .onClick(() => {
                CreateEBookViewConfig.open()
              })
          }

          if (this.eBooks.length < 1) {
            ListItem() {
              Text($r('app.string.ebook_no_other'))
                .fontSize(13)
                .fontColor($r('app.color.color_list_item_subtitle'))
                .padding(12)
            }
          } else {
            ForEach(this.eBooks, (book: Book) => {
              ListItem() { this.bookRow(book) }
            }, (book: Book) => `${book.bookId}`)
          }
        }
      }
        .width('100%')
        .height('100%')
    }
      .title(buildNavTitle(this.originalDetail.titleEn ?? ''))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
  }

  @Builder
  private sectionHeader(title: ResourceStr) {
    Text(title)
      .fontSize(13)
      .fontColor($r('app.color.color_list_item_subtitle'))
      .padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private bookRow(book: Book) {
    Row() {
      Column({ space: 4 }) {
        Text(book.bookName ?? '').fontSize(18).fontColor($r('app.color.color_list_item_title'))
        Text(getStringF($r('app.string.books_txt_info_counts'), book.unitsCount ?? 0, book.wordsCount ?? 0))
          .fontSize(12)
          .fontColor($r('app.color.color_list_item_subtitle'))
      }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
    }
      .width('100%')
      .padding(12)
      .onClick(() => {
        PartUnitPickerViewConfig.open({
          detail : this.originalDetail,
          bookId : book.bookId ?? 0
        })
      })
  }

  /**
   * 读取当前所有本地 EBook（BookManager.eBooks），排除当前选中的 EBook
   */
  private loadData(): void {
    const currentId = BookManager.shared.currentBook?.bookId
    this.eBooks = BookManager.shared.eBooks.filter((it: Book) => it.bookId !== currentId)
  }
}
