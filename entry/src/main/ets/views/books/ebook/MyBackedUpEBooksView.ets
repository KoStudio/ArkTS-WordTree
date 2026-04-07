//
// MyBackedUpEBooksView.ets
// 与 iOS `MyBackedUpEBooksView.swift` 对齐：拉取云端 EBook 备份列表并下载到本地。
//

import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { Toast } from '../../../common/utils/Toast'
import { getString, getStringF } from '../../../common/utils/ResourceUtils'
import { NetWorkTool } from '../../../common/utils/NetworkUtils'
import { Book } from '../../../models/datas/book/Book'
import { BookManager, BookManagerNotification } from '../../../models/datas/book/BookManager'
import { EBookManager } from '../../../models/managers/ebook/EBookManager'
import { UserData, UserDataJson } from '../../../models/managers/userdata/UserData'
import { UserDataManager } from '../../../models/managers/userdata/UserDataManager'
import { UserDataEBook } from '../../../models/managers/userdata/UserDataEBook'
import { CUserDataManager } from '../../../models/managers/userdata/CUserData/CUserDataManager'
import { WordUserDbAccess } from '../../../models/datas/myData/WordUserDbAccess'
import { SearchManager } from '../../../models/datas/model/SearchManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { NavPop, NavTo } from '../../../pages/NavPathManager'

export namespace MyBackedUpEBooksViewConfig {

  export const NavKey: string = 'MyBackedUpEBooksView_show'

  export function open(): void {

    NavTo(MyBackedUpEBooksViewConfig.NavKey, undefined, true, true)
  }
}

@ComponentV2
export struct MyBackedUpEBooksView {

  @Local items           : UserDataEBook[] = []
  @Local loading          : boolean         = true
  @Local errorMessage     : string          = ''
  @Local downloadingId    : number          = 0
  @Local hasShownEmptyToast: boolean        = false

  aboutToAppear(): void {

    this.loadList()
  }

  // 与 iOS `isAlreadyDownloaded`
  private isAlreadyDownloaded(serverBookId: number | null): boolean {

    if (serverBookId === null) {
      return false
    }

    return BookManager.shared.books.some((b: Book) => b.serverEBookId === serverBookId)
  }

  // 备份恢复成功后重连 learnDb 并刷新首页数据（每书独立库，无须 resetWordTables）
  private finishAfterRestoreSuccess(): void {

    WordUserDbAccess.shared.refreshDb()
    void SearchManager.shared.refreshData()
    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
    NavPop()
  }

  private loadList(): void {

    if (!NetWorkTool.checkInternetConnection(true)) {
      this.loading       = false
      this.errorMessage  = getString($r('app.string.network_not_available'))
      return
    }

    this.loading         = true
    this.errorMessage    = ''

    UserDataManager.loadUserDataEBookList((succeed: boolean, msg: string | null, list: UserDataEBook[] | null) => {

      this.loading = false

      if (succeed && list !== null) {
        this.items          = list
        this.errorMessage   = ''
      } else {
        this.items          = []
        this.errorMessage   = msg ?? getString($r('app.string.ebook_my_backed_up_empty_hint'))
      }

      if (this.items.length < 1 && !this.hasShownEmptyToast) {
        this.hasShownEmptyToast = true
        Toast.showMessage(this.errorMessage.length > 0
          ? this.errorMessage
          : getString($r('app.string.ebook_my_backed_up_empty_hint')))
      }
    })
  }

  private download(serverItem: UserDataEBook): void {

    if (!NetWorkTool.checkInternetConnection(true)) {
      return
    }

    const serverEBookId = serverItem.bookId

    if (serverEBookId === null || serverEBookId === undefined) {
      return
    }

    if (this.isAlreadyDownloaded(serverEBookId)) {
      return
    }

    this.downloadingId = serverEBookId

    let rawName      = (serverItem.bookName ?? '').trim()
    const bookName   = rawName.length < 1 ? `EBook ${serverEBookId}` : rawName

    void EBookManager.shared.createLocalEBook(bookName, null).then((book: Book | null) => {

      if (book === null) {
        this.downloadingId = 0
        Toast.showMessage(getString($r('app.string.ebook_save_failed')))
        return
      }

      book.serverEBookId = serverEBookId
      book.unitsCount    = serverItem.unitsCount
      book.wordsCount    = serverItem.wordsCount
      BookManager.shared.saveBook(book)

      const textDbPath = EBookManager.textDbPath(book.textDb ?? '')
      const ebookAddr  = serverItem.textDbAddr ?? ''

      const onContentDone = (succeed: boolean, msg: string | null) => {

        if (!succeed) {
          this.downloadingId = 0
          Toast.showMessage(msg ?? getString($r('app.string.books_msg_download_failed')))
          return
        }

        BookManager.shared.setCurrentBook(book)

        UserDataManager.loadUserData((succeed2: boolean, _msg: string | null, userDatas: UserDataJson[] | null) => {

          if (!succeed2 || userDatas === null || userDatas.length < 1) {
            this.downloadingId = 0
            this.finishAfterRestoreSuccess()
            return
          }

          let latest = UserData.fromJson(userDatas[0])

          for (let i = 1; i < userDatas.length; i++) {
            const u    = UserData.fromJson(userDatas[i])
            const ut   = u.updateDate?.getTime() ?? u.createDate?.getTime() ?? 0
            const best = latest.updateDate?.getTime() ?? latest.createDate?.getTime() ?? 0

            if (ut > best) {
              latest = u
            }
          }

          UserDataManager.download(latest, (_p: number) => {
          }, (succeed3: boolean, msg3: string | null) => {

            this.downloadingId = 0

            if (succeed3) {
              this.finishAfterRestoreSuccess()
            } else {
              Toast.showMessage(msg3 ?? getString($r('app.string.books_msg_download_failed')))
            }
          })
        })
      }

      if (ebookAddr.length > 0) {
        CUserDataManager.downloadEBookContentFromCOS(ebookAddr, textDbPath, onContentDone)
      } else {
        CUserDataManager.downloadEBookContent(serverEBookId, textDbPath, onContentDone)
      }
    })
  }

  build() {
    NavDestination() {

      if (this.loading) {
        Column() {
          LoadingProgress()
        }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      } else if (this.items.length < 1) {

        Column() {
          Text(this.errorMessage.length > 0
            ? this.errorMessage
            : getString($r('app.string.ebook_my_backed_up_empty_hint')))
            .fontSize(16)
            .fontColor($r('app.color.color_list_item_subtitle'))
            .textAlign(TextAlign.Center)
            .padding(24)
        }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      } else {

        List({ space: 0 }) {

          ForEach(this.items, (item: UserDataEBook, idx: number) => {

            ListItem() {
              this.buildRow(item, idx)
            }
          }, (item: UserDataEBook, idx: number) => `${item.bookId}_${idx}`)
        }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Auto)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      }
    }
      .title(buildNavTitle($r('app.string.ebook_my_backed_up_title')))
      .backgroundColor($r('app.color.colorPrimary'))
      .backButtonIcon(dNavBackIcon)
  }

  @Builder
  buildRow(item: UserDataEBook, _idx: number) {

    Row() {

      Column({ space: 4 }) {

        Text(item.bookName ?? '')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_list_item_title'))

        Text(getStringF($r('app.string.books_txt_info_counts'), item.unitsCount ?? 0, item.wordsCount ?? 0))
          .fontSize(14)
          .fontColor($r('app.color.color_list_item_subtitle'))
      }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

      if (this.isAlreadyDownloaded(item.bookId ?? null)) {

        Text($r('app.string.ebook_already_downloaded'))
          .fontSize(14)
          .fontColor($r('app.color.color_list_item_subtitle'))
      } else if (this.downloadingId === (item.bookId ?? 0) && (item.bookId ?? 0) > 0) {

        LoadingProgress()
          .width(28)
          .height(28)
      } else {

        Button() {

          Text($r('app.string.ebook_download_btn'))
            .fontSize(14)
            .fontColor(Color.White)
        }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor($r('app.color.colorPrimary'))
          .onClick(() => {

            this.download(item)
          })
      }
    }
      .width('100%')
      .padding(16)
      .onClick(() => {

        if (!this.isAlreadyDownloaded(item.bookId ?? null)
          && !(this.downloadingId === (item.bookId ?? 0) && (item.bookId ?? 0) > 0)) {
          this.download(item)
        }
      })
  }
}
