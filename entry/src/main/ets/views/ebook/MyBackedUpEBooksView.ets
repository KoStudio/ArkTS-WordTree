//
// MyBackedUpEBooksView.ets
// 与 iOS `MyBackedUpEBooksView.swift` 对齐：云端备份列表、下载、空态与导航样式一致。
//

import { NavBarView } from '../../app/views/NavBarView'
import { Toast } from '../../common/utils/Toast'
import { getString, getStringF } from '../../common/utils/ResourceUtils'
import { NetWorkTool } from '../../common/utils/NetworkUtils'
import { Book } from '../../models/datas/book/Book'
import { BookManager, BookManagerNotification } from '../../models/datas/book/BookManager'
import { EBookManager } from '../../models/managers/ebook/EBookManager'
import { UserData, UserDataJson } from '../../models/managers/userdata/UserData'
import { UserDataManager } from '../../models/managers/userdata/UserDataManager'
import { UserDataEBook } from '../../models/managers/userdata/UserDataEBook'
import { CUserDataManager } from '../../models/managers/userdata/CUserData/CUserDataManager'
import { WordUserDbAccess } from '../../models/datas/myData/WordUserDbAccess'
import { SearchManager } from '../../models/datas/model/SearchManager'
import { SimpleEventBus } from '../../common/components/eventbus/SimpleEventBus'

@ComponentV2
export struct MyBackedUpEBooksView {

  @Event onDismiss          : () => void      = () => {}     // 关闭回调
  @Local items              : UserDataEBook[] = []           // 云端备份列表
  @Local loading            : boolean         = true         // 加载中
  @Local errorMessage       : string          = ''           // 错误信息
  @Local downloadingId      : number | null   = null         // 当前下载中的服务器书 id
  @Local hasShownEmptyToast : boolean         = false        // 空态 toast 是否已提示

  // 页面出现加载列表
  aboutToAppear(): void {

    this.loadList()
  }

  private isAlreadyDownloaded(serverBookId: number | null): boolean {

    if (serverBookId === null) {
      return false
    }

    return BookManager.shared.books.some((b: Book) => b.serverEBookId === serverBookId)
  }

  private finishAfterRestoreSuccess(): void {

    WordUserDbAccess.shared.refreshDb()
    void SearchManager.shared.refreshData()
    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
    this.onDismiss()
  }

  private loadList(): void {

    if (!NetWorkTool.checkInternetConnection(true)) {
      this.loading      = false
      this.errorMessage = getString($r('app.string.network_not_available'))
      return
    }

    this.loading       = true
    this.errorMessage  = ''

    UserDataManager.loadUserDataEBookList((succeed: boolean, msg: string | null, list: UserDataEBook[] | null) => {

      this.loading = false

      if (succeed && list !== null) {
        this.items         = list
        this.errorMessage  = ''
      } else {
        this.items         = []
        this.errorMessage  = msg ?? getString($r('app.string.ebook_my_backed_up_empty_hint'))
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

    // 调用：提取 server book id
    const serverEBookId = serverItem.bookId

    if (serverEBookId === null || serverEBookId === undefined) {
      return
    }

    if (this.isAlreadyDownloaded(serverEBookId)) {
      return
    }

    this.downloadingId = serverEBookId

    let rawName     = (serverItem.bookName ?? '').trim()
    const bookName  = rawName.length < 1 ? `EBook ${serverEBookId}` : rawName

    void EBookManager.shared.createLocalEBook(bookName, null).then((book: Book | null) => {

      if (book === null) {
        this.downloadingId = null
        Toast.showMessage(getString($r('app.string.ebook_save_failed')))
        return
      }

      book.serverEBookId = serverEBookId
      book.unitsCount    = serverItem.unitsCount
      book.wordsCount    = serverItem.wordsCount
      BookManager.shared.saveBook(book)

      // 调用：计算本地 textDb 目标路径
      const textDbPath = EBookManager.textDbPath(book.textDb ?? '')
      const ebookAddr  = serverItem.textDbAddr ?? ''

      const onContentDone = (succeed: boolean, msg: string | null) => {

        if (!succeed) {
          this.downloadingId = null
          Toast.showMessage(msg ?? getString($r('app.string.books_msg_download_failed')))
          return
        }

        BookManager.shared.setCurrentBook(book)

        UserDataManager.loadUserData((succeed2: boolean, _msg: string | null, userDatas: UserDataJson[] | null) => {

          if (!succeed2 || userDatas === null || userDatas.length < 1) {
            this.downloadingId = null
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

            this.downloadingId = null

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

      Column() {

        Column() {

          NavBarView({
            title      : $r('app.string.ebook_my_backed_up_title'),
            leftButtons: [{
              text   : $r('app.string.online_search_btn_cancel'),
              onClick: () => {
                this.onDismiss()
              }
            }],
            rightButtons: []
          })
        }
          .width('100%')
          .backgroundColor($r('app.color.colorPrimary'))

        Column() {

          // 分支：首屏拉取列表中
          if (this.loading) {
            Column() {
              LoadingProgress()
            }
              .width('100%')
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
          } else if (this.items.length < 1) {

            // 分支：无备份或接口失败提示
            Column({ space: 12 }) {
              Text(this.errorMessage.length > 0
                ? this.errorMessage
                : getString($r('app.string.ebook_my_backed_up_empty_hint')))
                .fontSize(16)
                .fontColor($r('app.color.color_list_item_subtitle'))
                .textAlign(TextAlign.Center)
                .padding(16)
            }
              .width('100%')
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
          } else {

            // 分支：有云端备份条目，列表展示
            List({ space: 0 }) {

              ForEach(this.items, (item: UserDataEBook, idx: number) => {

                ListItem() {
                  this.buildRow(item)
                }
                  .backgroundColor($r('app.color.color_list_item_bg'))
              }, (item: UserDataEBook, idx: number) => `${item.bookId}_${idx}`)
            }
              .width('100%')
              .layoutWeight(1)
              .scrollBar(BarState.Auto)
              .divider({ strokeWidth: 1, color: $r('app.color.color_line') })
          }
        }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.color_background'))
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      }
        .width('100%')
        .height('100%')
    }
      .hideTitleBar(true)
      .backgroundColor($r('app.color.colorPrimary'))
  }

  @Builder
  buildRow(item: UserDataEBook) {

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

      // 分支：本地已有同 serverEBookId 的词汇本
      if (this.isAlreadyDownloaded(item.bookId ?? null)) {

        Text($r('app.string.ebook_already_downloaded'))
          .fontSize(14)
          .fontColor($r('app.color.color_list_item_subtitle'))
      } else if (this.downloadingId !== null && this.downloadingId === item.bookId) {

        // 分支：当前行正在下载内容 / learnDb
        LoadingProgress()
          .width(28)
          .height(28)
      } else {

        // 分支：可点击下载按钮
        Button() {

          Text($r('app.string.ebook_download_btn'))
            .fontSize(14)
            .fontColor(Color.White)
        }
          .type(ButtonType.Normal)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor($r('app.color.color_btn_bg'))
          .borderRadius(6)
          .onClick(() => {
            this.download(item)
          })
      }
    }
      .width('100%')
      .padding({ top: 8, bottom: 8, left: 16, right: 16 })
      .onClick(() => {

        const sid = item.bookId

        // 分支：无有效服务端 id
        if (sid === null || sid === undefined) {
          return
        }

        // 分支：已下载或下载中则整行不重复触发（与 iOS onTapGesture 一致）
        if (this.isAlreadyDownloaded(sid)) {
          return
        }

        if (this.downloadingId !== null && this.downloadingId === sid) {
          return
        }

        this.download(item)
      })
  }
}
