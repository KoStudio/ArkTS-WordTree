//
// BooksLocalView.ets
// 与 iOS `Root/Book2/Sub/BooksLocalView.swift` 对齐（不含 LegacyBookMigrator）。
//

import { TintImage } from '../../../app/views/TintImage'
import { CBookManager } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { EBookManager } from '../../../models/managers/ebook/EBookManager'
import { EBookExportImportManager } from '../../../models/managers/ebook/EBookExportImportManager'
import { getString, getStringF } from '../../../common/utils/ResourceUtils'
import { Toast } from '../../../common/utils/Toast'
import { ShareUtils } from '../../../common/utils/ShareUtils'
import { Book } from '../../../models/datas/book/Book'
import { BookManager, BookManagerNotification } from '../../../models/datas/book/BookManager'
import { SearchManager } from '../../../models/datas/model/SearchManager'
import { WordUserDbAccess } from '../../../models/datas/myData/WordUserDbAccess'
import { MemberManager } from '../../../models/managers/member/MemberManager'
import { UserManager } from '../../../models/managers/user/UserManager'
import { EWordSearchAddViewConfig } from '../ebook/EWordSearchAddView'
import { MyBackedUpEBooksViewConfig } from '../ebook/MyBackedUpEBooksView'
import { EBookImportViewConfig } from '../ebook/EBookImportView'

@ComponentV2
export struct BooksLocalView {

  @Local books                  : Book[]  = []
  @Local listVersion            : number  = 0
  /** 底部表单是否展示 */
  @Local ebookSheetVisible       : boolean = false
  /** 1 菜单，2 新建，3 改名 */
  @Local ebookSheetKind         : number  = 0
  @Local newBookNameInput       : string  = ''
  @Local renameBookNameInput    : string  = ''
  @Local renameTargetBookId     : number  = 0

  private unsubBookList      : (() => void) | undefined = undefined
  private unsubCurrentBook   : (() => void) | undefined = undefined

  aboutToAppear(): void {

    this.loadData()

    this.unsubBookList = SimpleEventBus.on(BookManagerNotification.bookListUpdated, () => {
      this.loadData()
    })

    this.unsubCurrentBook = SimpleEventBus.on(BookManagerNotification.currentBookUpdated, () => {
      this.loadData()
    })
  }

  aboutToDisappear(): void {

    if (this.unsubBookList !== undefined) {
      this.unsubBookList()
      this.unsubBookList = undefined
    }

    if (this.unsubCurrentBook !== undefined) {
      this.unsubCurrentBook()
      this.unsubCurrentBook = undefined
    }
  }

  private loadData(): void {

    this.books = [...BookManager.shared.books]
    this.listVersion++
  }

  private cBooks(): Book[] {
    return this.books.filter((b: Book) => !b.isEBook)
  }

  private eBooks(): Book[] {
    return this.books.filter((b: Book) => b.isEBook)
  }

  build() {
    Column() {

      Column() {
        this.buildList()
      }
        .width('100%')
        .layoutWeight(1)

      Column() {

        Divider().color($r('app.color.color_obscure'))

        Button() {

          Text($r('app.string.ebook_plus_btn'))
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
          .width(200)
          .height(36)
          .backgroundColor($r('app.color.colorAccent'))
          .borderRadius(18)
          .margin({ top: 6, bottom: 6 })
          .onClick(() => {
            this.ebookSheetKind   = 1
            this.ebookSheetVisible = true
          })
      }
        .width('100%')
        .backgroundColor($r('app.color.color_background'))
        .justifyContent(FlexAlign.Center)

    }
      .width('100%')
      .height('100%')
      .bindSheet($$this.ebookSheetVisible, this.buildEbookSheetContent(), {
        detents     : [SheetSize.FIT_CONTENT],
        dragBar     : true,
        showClose   : true,
        title       : { title: this.ebookSheetTitle() },
        onDisappear : () => {
          this.ebookSheetVisible  = false
          this.ebookSheetKind     = 0
          this.renameTargetBookId = 0
        }
      })
  }

  private ebookSheetTitle(): ResourceStr {

    if (this.ebookSheetKind === 2) {
      return $r('app.string.ebook_create_title')
    }

    if (this.ebookSheetKind === 3) {
      return $r('app.string.ebook_rename_title')
    }

    return $r('app.string.ebook_choose_action')
  }

  @Builder
  buildEbookSheetContent() {

    if (this.ebookSheetKind === 1) {
      this.buildEbookMenuContent()
    } else if (this.ebookSheetKind === 2) {
      this.buildCreateSheetContent()
    } else if (this.ebookSheetKind === 3) {
      this.buildRenameSheetContent()
    }
  }

  @Builder
  buildEbookMenuContent() {

    Column({ space: 0 }) {

      Button() {

        Text($r('app.string.ebook_new_book'))
          .fontSize(17)
          .fontColor($r('app.color.color_text'))
      }
        .width('100%')
        .height(48)
        .backgroundColor($r('app.color.color_background'))
        .onClick(() => {
          this.newBookNameInput = ''
          this.ebookSheetKind   = 2
          this.ebookSheetVisible = true
        })

      Divider()

      Button() {

        Text($r('app.string.ebook_import_btn'))
          .fontSize(17)
          .fontColor($r('app.color.color_text'))
      }
        .width('100%')
        .height(48)
        .backgroundColor($r('app.color.color_background'))
        .onClick(() => {
          this.ebookSheetVisible = false
          EBookImportViewConfig.open()
        })

      if (UserManager.shared.isLogin()) {

        Divider()

        Button() {

          Text($r('app.string.ebook_my_backed_up_btn'))
            .fontSize(17)
            .fontColor($r('app.color.color_text'))
        }
          .width('100%')
          .height(48)
          .backgroundColor($r('app.color.color_background'))
          .onClick(() => {
            this.ebookSheetVisible = false
            MyBackedUpEBooksViewConfig.open()
          })
      }
    }
      .width('100%')
      .padding({ bottom: 8 })
  }

  @Builder
  buildCreateSheetContent() {

    Column({ space: 16 }) {

      TextInput({ text: $$this.newBookNameInput, placeholder: $r('app.string.ebook_name_hint') })
        .width('100%')
        .margin({ left: 16, right: 16 })

      Button() {

        Text($r('app.string.confirm_btn_yes'))
          .fontColor(Color.White)
      }
        .width('90%')
        .backgroundColor($r('app.color.colorPrimary'))
        .onClick(() => {
          void this.confirmCreateEbook()
        })
    }
      .padding(16)
  }

  @Builder
  buildRenameSheetContent() {

    Column({ space: 16 }) {

      TextInput({ text: $$this.renameBookNameInput, placeholder: $r('app.string.ebook_name_hint') })
        .width('100%')
        .margin({ left: 16, right: 16 })

      Button() {

        Text($r('app.string.confirm_btn_yes'))
          .fontColor(Color.White)
      }
        .width('90%')
        .backgroundColor($r('app.color.colorPrimary'))
        .onClick(() => {
          this.confirmRenameEbook()
        })
    }
      .padding(16)
  }

  private async confirmCreateEbook(): Promise<void> {

    const trimmed = this.newBookNameInput.trim()

    if (trimmed.length < 1) {
      return
    }

    if (!MemberManager.shared.checkEBookCreatable(true, true)) {
      return
    }

    const book = await EBookManager.shared.createLocalEBook(trimmed, null)

    if (book === null) {
      Toast.showMessage(getString($r('app.string.ebook_save_failed')))
      return
    }

    BookManager.shared.setCurrentBook(book)
    WordUserDbAccess.shared.resetWordTables()
    WordUserDbAccess.shared.refreshDb()
    void SearchManager.shared.refreshData()
    this.ebookSheetVisible = false
    this.loadData()
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
    EWordSearchAddViewConfig.open()
  }

  private confirmRenameEbook(): void {

    const trimmed = this.renameBookNameInput.trim()

    if (trimmed.length < 1) {
      return
    }

    const book = BookManager.shared.books.find((b: Book) => b.bookId === this.renameTargetBookId)

    if (book === undefined) {
      this.ebookSheetVisible = false
      return
    }

    BookManager.shared.renameBook(book, trimmed)
    this.ebookSheetVisible = false
    this.loadData()
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
  }

  private openRenameSheet(book: Book): void {

    this.renameTargetBookId   = book.bookId ?? 0
    this.renameBookNameInput  = book.bookName ?? ''
    this.ebookSheetKind      = 3
    this.ebookSheetVisible   = true
  }

  private actionAddWord(book: Book): void {

    BookManager.shared.setCurrentBook(book)
    WordUserDbAccess.shared.resetWordTables()
    WordUserDbAccess.shared.refreshDb()
    void SearchManager.shared.refreshData()
    this.loadData()
    EWordSearchAddViewConfig.open()
  }

  private actionExportEbook(book: Book): void {

    EBookExportImportManager.shared.exportEBook(book, (ok: boolean, _err: string | null, exportPath: string | null) => {

      if (!ok || exportPath === null) {
        Toast.showMessage(getString($r('app.string.ebook_export_failed_msg')))
        return
      }

      ShareUtils.shareFile(exportPath, book.bookName ?? '词汇本', '')
    })
  }

  @Builder
  buildList() {
    Column() {
      List({ space: 0 }) {

        if (this.cBooks().length > 0) {

          ListItemGroup({
            header : this.buildSectionHeader($r('app.string.books_section_cbook_header')),
            style  : ListItemGroupStyle.NONE
          }) {
            ForEach(this.cBooks(), (book: Book, rowIndex: number) => {
              ListItem() {
                this.buildRowContent(book, false)
              }
                .gesture(
                  LongPressGesture()
                    .onAction(() => {

                      if (!book.isCurrentBook) {
                        this.confirmRemove(book)
                      }
                    })
                )
                .swipeAction({
                  end: book.isCurrentBook ? undefined : {
                    builder: () => {
                      this.buildSwipeButtons(book)
                    },
                    onAction: () => {
                      this.confirmRemove(book)
                    }
                  }
                })
            }, (book: Book, i: number) => `c_${book.bookId}_${i}_${this.listVersion}`)
          }
        }

        if (this.eBooks().length > 0) {

          ListItemGroup({
            header : this.buildSectionHeader($r('app.string.books_section_ebook_header')),
            style  : ListItemGroupStyle.NONE
          }) {
            ForEach(this.eBooks(), (book: Book, rowIndex: number) => {
              ListItem() {
                this.buildRowContent(book, true)
              }
                .gesture(
                  LongPressGesture()
                    .onAction(() => {

                      if (!book.isCurrentBook) {
                        this.confirmRemove(book)
                      }
                    })
                )
                .swipeAction({
                  end: book.isCurrentBook ? undefined : {
                    builder: () => {
                      this.buildSwipeButtonsEbook(book)
                    },
                    onAction: () => {
                      this.confirmRemove(book)
                    }
                  }
                })
            }, (book: Book, i: number) => `e_${book.bookId}_${i}_${this.listVersion}`)
          }
        }
      }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .sticky(StickyStyle.Header)
    }
      .backgroundColor($r('app.color.color_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .width('100%')
      .height('100%')
  }

  @Builder
  buildSectionHeader(title: ResourceStr) {
    Row() {

      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.color_list_item_subtitle'))
    }
      .width('100%')
      .padding({
        left   : 16,
        right  : 16,
        top    : 8,
        bottom : 4
      })
  }

  @Builder
  buildRowContent(book: Book, showEBookActions: boolean) {

    Column({ space: 8 }) {

      Row() {

        Column({ space: 5 }) {

          Text(book.bookName ?? '')
            .fontSize(22)
            .fontColor($r('app.color.color_list_item_title'))

          Text(getStringF($r('app.string.books_txt_info_counts'), book.unitsCount || 0, book.wordsCount || 0))
            .fontSize(16)
            .fontColor($r('app.color.color_list_item_subtitle'))
        }
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

        Column() {

          if (BookManager.shared.currentBook?.bookId === book.bookId) {

            TintImage({ src: $r('app.media.done') })
          }
        }
      }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .onClick(() => {
          this.handleRowClick(book)
        })

      if (showEBookActions) {

        Row() {

          Blank().layoutWeight(1)

          Row({ space: 12 }) {

            Button() {
              Text($r('app.string.ebook_nav_add_word')).fontSize(13)
            }
              .height(32)
              .padding({ left: 8, right: 8 })
              .backgroundColor($r('app.color.color_obscure'))
              .onClick(() => {
                this.actionAddWord(book)
              })

            Button() {
              Text($r('app.string.ebook_rename_label')).fontSize(13)
            }
              .height(32)
              .padding({ left: 8, right: 8 })
              .backgroundColor($r('app.color.color_obscure'))
              .onClick(() => {
                this.openRenameSheet(book)
              })

            Button() {
              Text($r('app.string.ebook_export_btn')).fontSize(13)
            }
              .height(32)
              .padding({ left: 8, right: 8 })
              .backgroundColor($r('app.color.color_obscure'))
              .onClick(() => {
                this.actionExportEbook(book)
              })

            Button() {
              Text($r('app.string.books_btn_title_delete')).fontSize(13)
            }
              .height(32)
              .padding({ left: 8, right: 8 })
              .backgroundColor(book.isCurrentBook ? $r('app.color.color_obscure') : $r('app.color.colorAccent'))
              .enabled(!book.isCurrentBook)
              .onClick(() => {

                if (!book.isCurrentBook) {
                  this.confirmRemove(book)
                }
              })
          }
            .hitTestBehavior(HitTestMode.Block)
        }
          .width('100%')
      }
    }
      .width('100%')
      .padding(16)
      .border({ width: { bottom: 1 }, color: $r('app.color.color_obscure') })
      .backgroundColor($r('app.color.color_background'))
  }

  handleRowClick(book: Book): void {

    if (book.isCurrentBook) {
      return
    }

    BookManager.shared.setCurrentBook(book)

    WordUserDbAccess.shared.resetWordTables()

    WordUserDbAccess.shared.refreshDb()

    void SearchManager.shared.refreshData()

    this.loadData()
  }

  @Builder
  buildSwipeButtons(book: Book) {

    Row() {

      this.buildSwipeButton($r('app.string.confirm_btn_remove'), $r('app.color.colorAccent'), () => {

        this.confirmRemove(book)
      })
    }
      .alignItems(VerticalAlign.Center)
      .height('100%')
  }

  @Builder
  buildSwipeButtonsEbook(book: Book) {

    Row() {

      this.buildSwipeButton($r('app.string.ebook_rename_label'), $r('app.color.colorPrimary'), () => {

        this.openRenameSheet(book)
      })

      this.buildSwipeButton($r('app.string.confirm_btn_remove'), $r('app.color.colorAccent'), () => {

        this.confirmRemove(book)
      })
    }
      .alignItems(VerticalAlign.Center)
      .height('100%')
  }

  @Builder
  buildSwipeButton(text: ResourceStr, bgColor: Resource = $r('app.color.colorPrimary'),
    onCallback: () => void) {
    Button() {

      Text(text)
        .fontSize(16)
        .fontColor(Color.White)
    }
      .borderRadius(0)
      .padding(6)
      .height('100%')
      .width('auto')
      .constraintSize({ minWidth: 44 })
      .type(ButtonType.Normal)
      .backgroundColor(bgColor)
      .onClick(onCallback)
  }

  private confirmRemove(book: Book): void {

    if (book.isCurrentBook) {
      return
    }

    Toast.showAlert({
      title           : $r('app.string.alert_title_confirm'),
      message         : getStringF($r('app.string.alert_msg_confirm_remove'), book.bookName || ''),
      secondaryButton : {
        value     : $r('app.string.confirm_btn_no'),
        fontColor : Color.Gray,
        action    : () => {
        }
      },
      primaryButton   : {
        value  : $r('app.string.confirm_btn_yes'),
        action : async () => {

          BookManager.shared.removeBook(book)

          if (book.isEBook) {

            EBookManager.removeLocalTextDbIfExists(book.textDb || '')
          } else {

            CBookManager.shared.removeBookDb(book.textDb || '')
          }

          this.loadData()
        }
      }
    })
  }
}
