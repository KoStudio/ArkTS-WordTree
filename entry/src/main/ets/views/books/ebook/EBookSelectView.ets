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
import { PartUnitPickerView } from './PartUnitPickerView'

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

  @Param @Require originalDetail      : WordDetail                // 来源词条
  @Local private eBooks               : Book[]                    = []         // 可选 EBook 列表
  @Local private isShowPartUnitSheet  : boolean                   = false      // Part/Unit sheet 显示开关
  @Local private sheetBookId          : number                    = 0          // sheet 目标书 id
  private unsubBookList               : (() => void) | undefined  = undefined  // 书单更新事件解绑

  // 页面显示时加载 EBook 列表并监听列表更新。
  aboutToAppear(): void {
    this.loadData()
    this.unsubBookList = SimpleEventBus.on(BookManagerNotification.bookListUpdated, () => {
      this.loadData()
    })
  }

  // 页面离开时注销监听，避免重复订阅。
  aboutToDisappear(): void {
    if (this.unsubBookList !== undefined) {
      this.unsubBookList()
      this.unsubBookList = undefined
    }
  }

  // 构建「选择词汇本」页面主体。
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
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
      .title(buildNavTitle(this.originalDetail.titleEn ?? ''))
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

  @Builder
  private sectionHeader(title: ResourceStr) {
    // 调用：绘制分组标题
    Text(title)
      .fontSize(13)
      .fontColor($r('app.color.color_list_item_subtitle'))
      .padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private bookRow(book: Book) {
    // 调用：绘制单行书本
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
        // 分支：点击书本行后打开 Part/Unit 选择 Sheet
        this.sheetBookId = book.bookId ?? 0
        this.isShowPartUnitSheet = true
      })
  }

  @Builder
  // 构建 Part/Unit 选择 Sheet。
  private buildPartUnitSheet() {
    // 调用：显示保存到 Part/Unit 的下一级页面
    PartUnitPickerView({
      detail: this.originalDetail,
      bookId: this.sheetBookId,
      closeBySheet: true,
      onDismiss: () => {
        this.isShowPartUnitSheet = false
      }
    })
  }

  // 读取当前所有本地 EBook（BookManager.eBooks），排除当前选中的 EBook
  private loadData(): void {
    // 调用：读取当前书 id，用于过滤
    const currentId = BookManager.shared.currentBook?.bookId
    this.eBooks = BookManager.shared.eBooks.filter((it: Book) => it.bookId !== currentId)
  }
}
