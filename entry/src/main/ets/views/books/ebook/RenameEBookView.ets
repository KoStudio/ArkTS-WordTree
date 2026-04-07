//
// RenameEBookView.ets
// WordTree
//
// 修改本地 EBook 名称的页面，采用与 EBookImportView 一致的卡片风格。
//

import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { Book } from '../../../models/datas/book/Book'
import { BookManager, BookManagerNotification } from '../../../models/datas/book/BookManager'
import { NavPop, NavTo } from '../../../pages/NavPathManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'

export namespace RenameEBookViewConfig {

  export const NavKey: string = 'RenameEBookView_show'

  export interface Param {
    bookId: number
  }

  export function open(param: Param): void {
    NavTo(RenameEBookViewConfig.NavKey, param, true, true)
  }
}

@ComponentV2
export struct RenameEBookView {

  @Param @Require bookId: number

  @Local private bookName       : string  = ''
  @Local private maxNameLength  : number  = 20

  aboutToAppear(): void {
    const book = BookManager.shared.books.find((it: Book) => it.bookId === this.bookId)
    this.bookName = book?.bookName ?? ''
  }

  build() {
    NavDestination() {
      Stack() {
        Column({ space: 16 }) {
          Blank().height(40)

          Column({ space: 12 }) {
            Text($r('app.string.ebook_name_section'))
              .fontSize(13)
              .fontColor($r('app.color.color_list_item_subtitle'))
              .width('100%')
              .textAlign(TextAlign.Start)

            TextInput({ text: $$this.bookName, placeholder: $r('app.string.ebook_name_placeholder') })
              .fontSize(16)
              .height(40)
              .backgroundColor($r('app.color.color_obscure'))
              .borderRadius(6)
              .onChange((value: string) => {
                // 分支：输入超长时截断
                if (value.length > this.maxNameLength) {
                  this.bookName = value.substring(0, this.maxNameLength)
                }
              })
          }
            .padding({ left: 16, right: 16, top: 20, bottom: 20 })
            .width('90%')
            .backgroundColor($r('app.color.color_background'))
            .borderRadius(12)

          Button() {
            Text($r('app.string.confirm_btn_yes')).fontColor(Color.White)
          }
            .width('90%')
            .height(40)
            .backgroundColor($r('app.color.colorPrimary'))
            .onClick(() => {
              this.save()
            })

          Blank().layoutWeight(1)
        }
          .width('100%')
          .height('100%')
      }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_background'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
      .title(buildNavTitle($r('app.string.ebook_rename_nav_title')))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
  }

  /**
   * 保存新名称
   */
  private save(): void {
    const trimmed = this.bookName.trim()

    // 分支：空值不处理
    if (trimmed.length < 1) {
      return
    }

    const book = BookManager.shared.books.find((it: Book) => it.bookId === this.bookId)

    // 分支：目标书不存在时返回
    if (book === undefined) {
      NavPop()
      return
    }

    // 调用：重命名并通知刷新
    BookManager.shared.renameBook(book, trimmed)
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
    NavPop()
  }
}
