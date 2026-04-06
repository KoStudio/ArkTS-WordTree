//
// BooksOnlineView.ets
// 与 iOS `Root/Book2/online/BooksOnlineView.swift` 对齐（不含 LegacyBookMigrator）。
//

import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { TextButton } from '../../../app/views/buttons/TextButton'
import { CBookManager } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookManager'
import { getStringF } from '../../../common/utils/ResourceUtils'
import { Toast } from '../../../common/utils/Toast'
import { NetWorkTool } from '../../../common/utils/NetworkUtils'
import { Book } from '../../../models/datas/book/Book'
import { BookDbAccess } from '../../../models/datas/book/BookDbAccess'
import { Category } from '../../../models/datas/book/CategoryManager'
import { NavPopTop, NavTo } from '../../../pages/NavPathManager'
import { LoadingDialog } from '@kit.ArkUI'
import { BookManager } from '../../../models/datas/book/BookManager'
import { BooksDownloadsManager } from '../../../models/datas/book/BooksDownloads/BooksDownloadsManager'
import { MemberManager } from '../../../models/managers/member/MemberManager'
import { GoldManager } from '../../../models/managers/gold/GoldManager'
import { AppCfgManager } from '../../../models/managers/servercfg/AppCfgManager'

export namespace BooksOnlineViewConfig {

  export const NavKey: string = 'BooksOnlineView_show'

  export function open(param: Param): void {

    NavTo(BooksOnlineViewConfig.NavKey, param, true)
  }

  export interface Param {

    category: Category
  }
}

@ComponentV2
export struct BooksOnlineView {

  @Param @Require category: Category

  @Local books     : Book[] = []
  @Local isLoading : boolean = false

  aboutToAppear(): void {

    // 与 iOS：进入页按策略刷新 AppCfg
    AppCfgManager.shared.loadConfigsIfNeeds()

    void this.loadData()
  }

  // 按分类名从 BookList 库取在线课本元数据
  private async loadData(): Promise<void> {

    const name: string = this.category.categoryName || ''

    // 分类名为空则无数据
    if (!name) {
      this.books = []
      return
    }

    this.books = await BookDbAccess.shared.getBooks(name) || []
  }

  // 是否已下载到本地书架
  private isDownloaded(book: Book): boolean {
    return BookManager.shared.books.filter((v: Book) => v.bookId === book.bookId).length > 0
  }

  build() {
    NavDestination() {

      Column() {

        this.buildList()
      }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)

        // 与 iOS `.disabled(isLoading)`：下载过程中禁止列表交互
        .enabled(!this.isLoading)
    }
      .title(buildNavTitle(this.getNavTitle()))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
  }

  getNavTitle(): ResourceStr {
    return this.category.categoryName || ''
  }

  @Builder
  buildList() {
    Column() {

      List({ space: 0 }) {
        ForEach(this.books, (book: Book, rowIndex: number) => {
          ListItem() {
            this.buildRowContent(rowIndex, book)
          }
            .onClick(() => {
              this.handleRowClick(rowIndex, book)
            })
        }, (book: Book, i: number) => `ol_${book.bookId}_${i}`)
      }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Auto)
        .sticky(StickyStyle.Header)
    }
      .backgroundColor($r('app.color.color_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .width('100%')
      .height('100%')
  }

  @Builder
  buildRowContent(rowIndex: number, book: Book) {

    const downloaded: boolean = this.isDownloaded(book)

    Row({ space: 8 }) {

      Column({ space: 5 }) {

        Text(book.bookName ?? '')
          .fontSize(22)
          .fontColor($r('app.color.color_list_item_title'))

        Text(getStringF($r('app.string.books_txt_info_counts'), book.unitsCount || 0, book.wordsCount || 0))
          .fontSize(16)
          .fontColor($r('app.color.color_list_item_subtitle'))

        // 与 iOS：首次安装尚无 currentBook 时不展示金币；非会员且已选书才展示
        if ((!MemberManager.shared.isActive) && (BookManager.shared.currentBook !== null)) {

          Text(getStringF($r('app.string.books_txt_info_golds'), book.golds || 0))
            .fontSize(15)
            .fontColor($r('app.color.color_gold'))
        }
      }
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

      Column() {

        // 已下载：仅文案；未下载：主色按钮（与 iOS 右侧区域一致）
        if (downloaded) {

          Text($r('app.string.books_btn_title_downloaded'))
            .fontSize(16)
            .fontColor($r('app.color.color_list_item_subtitle'))
            .textAlign(TextAlign.Center)
            .constraintSize({ minWidth: 110 })
        } else {

          TextButton({
            text              : $r('app.string.books_btn_title_to_download'),
            bgColor           : $r('app.color.color_btn_bg2'),
            onClickCallBack   : () => {
              this.handleRowClick(rowIndex, book)
            }
          })
            .constraintSize({ minWidth: 110 })
        }
      }
    }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .padding(10)
      .border({ width: { bottom: 1 }, color: $r('app.color.color_obscure') })
      .backgroundColor(
        downloaded ? $r('app.color.color_gray_light') : $r('app.color.color_background'))
  }

  handleRowClick(rowIndex: number, book: Book): void {

    // 已下载则忽略（与 iOS）
    if (this.isDownloaded(book)) {
      return
    }

    // 与 iOS `NetWorkTool.guardNetworkForUserAction`
    if (!NetWorkTool.checkInternetConnection(true)) {
      return
    }

    const isFirstDownload: boolean = BookManager.shared.currentBook === null

    // 非首次下载且金币不足时，非会员需走会员检查（与 iOS）
    if (!isFirstDownload && GoldManager.shared.golds < (book.golds ?? 0)) {

      if (!MemberManager.shared.checkBooksDownloadable(true, true)) {
        return
      }
    }

    if (!book.textDb) {
      return
    }

    this.isLoading = true

    Toast.showCustomDialog(() => {
      this.buildLoadingDialog($r('app.string.books_msg_download_start_word'))
    }, false)

    CBookManager.shared.startUpdateBookCheckIfNeeds(book.textDb, book.bookName, true,
      (percent: number) => {

        Toast.showDebugMessage(`${percent}%..`)
      },
      (succeed: boolean, msg: string | null) => {

        Toast.closeCustomDialog()

        this.isLoading = false

        if (succeed) {

          Toast.showMessage($r('app.string.books_msg_download_succeed'))

          BookManager.shared.saveBook(book)

          BookManager.shared.setCurrentBook(book)

          BooksDownloadsManager.recordDownload(book)

          // 与 iOS：非首次且非会员扣金币
          if (!isFirstDownload && !MemberManager.shared.isActive) {

            GoldManager.shared.incrementGolds(-(book.golds ?? 0))
          }

          NavPopTop()
        } else {

          Toast.showMessage($r('app.string.books_msg_download_failed'))
        }
      })
  }

  @Builder
  buildLoadingDialog(msg?: ResourceStr | null): void {
    LoadingDialog({
      content: msg ?? 'loading..'
    })
  }
}
