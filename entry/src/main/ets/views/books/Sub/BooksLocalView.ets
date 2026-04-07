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

  /**
   * 页面出现时：加载数据并注册列表/当前书刷新监听
   */
  aboutToAppear(): void {

    // 调用：首次进入时加载列表
    this.loadData()

    // 调用：订阅书单更新事件
    this.unsubBookList = SimpleEventBus.on(BookManagerNotification.bookListUpdated, () => {

      // 调用：书单更新后重载列表
      this.loadData()
    })

    // 调用：订阅当前书更新事件
    this.unsubCurrentBook = SimpleEventBus.on(BookManagerNotification.currentBookUpdated, () => {

      // 调用：当前书更新后重载列表
      this.loadData()
    })
  }

  /**
   * 页面消失时：注销页面内注册的事件监听
   */
  aboutToDisappear(): void {

    if (this.unsubBookList !== undefined) {

      // 调用：取消书单更新监听
      this.unsubBookList()
      this.unsubBookList = undefined
    }

    if (this.unsubCurrentBook !== undefined) {

      // 调用：取消当前书更新监听
      this.unsubCurrentBook()
      this.unsubCurrentBook = undefined
    }
  }

  /**
   * 读取并刷新本地书单
   */
  private loadData(): void {

    // 调用：同步全局书单到页面状态
    this.books = [...BookManager.shared.books]
    this.listVersion++
  }

  /**
   * 获取非 EBook 列表（CBook）
   */
  private cBooks(): Book[] {
    return this.books.filter((b: Book) => !b.isEBook)
  }

  /**
   * 获取 EBook 列表
   */
  private eBooks(): Book[] {
    return this.books.filter((b: Book) => b.isEBook)
  }

  /**
   * 构建页面主视图
   */
  build() {
    Column() {

      Column() {

        // 调用：构建书单列表区域
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

  /**
   * 返回底部 Sheet 的标题文案
   */
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
  /**
   * 构建底部 Sheet 内容
   */
  buildEbookSheetContent() {

    if (this.ebookSheetKind === 1) {

      // 调用：构建操作菜单
      this.buildEbookMenuContent()
    } else if (this.ebookSheetKind === 2) {

      // 调用：构建新建 EBook 面板
      this.buildCreateSheetContent()
    } else if (this.ebookSheetKind === 3) {

      // 调用：构建重命名面板
      this.buildRenameSheetContent()
    }
  }

  @Builder
  /**
   * 构建「新建/导入/我的备份」菜单面板
   */
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

          // 调用：打开导入 EBook 页面
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

            // 调用：打开我的备份 EBook 页面
            MyBackedUpEBooksViewConfig.open()
          })
      }
    }
      .width('100%')
      .padding({ bottom: 8 })
  }

  @Builder
  /**
   * 构建新建 EBook 面板
   */
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

          // 调用：确认新建 EBook
          void this.confirmCreateEbook()
        })
    }
      .padding(16)
  }

  @Builder
  /**
   * 构建重命名 EBook 面板
   */
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

          // 调用：确认重命名 EBook
          this.confirmRenameEbook()
        })
    }
      .padding(16)
  }

  /**
   * 确认新建 EBook：校验输入、会员限制、创建后刷新并进入加词页
   */
  private async confirmCreateEbook(): Promise<void> {

    const trimmed = this.newBookNameInput.trim()

    if (trimmed.length < 1) {
      return
    }

    if (!MemberManager.shared.checkEBookCreatable(true, true)) {
      return
    }

    // 调用：创建本地 EBook
    const book = await EBookManager.shared.createLocalEBook(trimmed, null)

    if (book === null) {

      // 调用：提示创建失败
      Toast.showMessage(getString($r('app.string.ebook_save_failed')))
      return
    }

    // 调用：切换当前书
    BookManager.shared.setCurrentBook(book)

    // 调用：重置用户词表
    WordUserDbAccess.shared.resetWordTables()

    // 调用：刷新用户词表连接
    WordUserDbAccess.shared.refreshDb()

    // 调用：刷新搜索索引
    void SearchManager.shared.refreshData()
    this.ebookSheetVisible = false

    // 调用：刷新页面列表
    this.loadData()

    // 调用：广播书单更新
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)

    // 调用：打开 EBook 加词页面
    EWordSearchAddViewConfig.open()
  }

  /**
   * 确认重命名 EBook
   */
  private confirmRenameEbook(): void {

    const trimmed = this.renameBookNameInput.trim()

    if (trimmed.length < 1) {
      return
    }

    // 调用：按目标 bookId 查找书本
    const book = BookManager.shared.books.find((b: Book) => b.bookId === this.renameTargetBookId)

    if (book === undefined) {
      this.ebookSheetVisible = false
      return
    }

    // 调用：执行重命名
    BookManager.shared.renameBook(book, trimmed)
    this.ebookSheetVisible = false

    // 调用：刷新页面列表
    this.loadData()

    // 调用：广播书单更新
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
  }

  /**
   * 打开重命名面板并预填当前书名
   * @param book 目标 EBook
   */
  private openRenameSheet(book: Book): void {

    this.renameTargetBookId   = book.bookId ?? 0
    this.renameBookNameInput  = book.bookName ?? ''
    this.ebookSheetKind      = 3
    this.ebookSheetVisible   = true
  }

  /**
   * 切换当前书并进入加词页
   * @param book 目标 EBook
   */
  private actionAddWord(book: Book): void {

    // 调用：切换当前书
    BookManager.shared.setCurrentBook(book)

    // 调用：重置用户词表
    WordUserDbAccess.shared.resetWordTables()

    // 调用：刷新用户词表连接
    WordUserDbAccess.shared.refreshDb()

    // 调用：刷新搜索索引
    void SearchManager.shared.refreshData()

    // 调用：刷新页面列表
    this.loadData()

    // 调用：打开 EBook 加词页
    EWordSearchAddViewConfig.open()
  }

  /**
   * 导出并分享指定 EBook
   * @param book 目标 EBook
   */
  private actionExportEbook(book: Book): void {

    // 调用：导出 EBook
    EBookExportImportManager.shared.exportEBook(book, (ok: boolean, _err: string | null, exportPath: string | null) => {

      if (!ok || exportPath === null) {

        // 调用：提示导出失败
        Toast.showMessage(getString($r('app.string.ebook_export_failed_msg')))
        return
      }

      // 调用：弹出系统分享
      ShareUtils.shareFile(exportPath, book.bookName ?? '词汇本', '')
    })
  }

  @Builder
  /**
   * 构建 CBook/EBook 分组列表
   */
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

                // 调用：构建列表行内容（CBook）
                this.buildRowContent(book, false)
              }
                .gesture(
                  LongPressGesture()
                    .onAction(() => {

                      if (!book.isCurrentBook) {

                        // 调用：弹出删除确认
                        this.confirmRemove(book)
                      }
                    })
                )
                .swipeAction({
                  end: book.isCurrentBook ? undefined : {
                    builder: () => {

                      // 调用：构建 CBook 右滑按钮
                      this.buildSwipeButtons(book)
                    },
                    onAction: () => {

                      // 调用：右滑动作删除
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

                // 调用：构建列表行内容（EBook）
                this.buildRowContent(book, true)
              }
                .gesture(
                  LongPressGesture()
                    .onAction(() => {

                      if (!book.isCurrentBook) {

                        // 调用：弹出删除确认
                        this.confirmRemove(book)
                      }
                    })
                )
                .swipeAction({
                  end: book.isCurrentBook ? undefined : {
                    builder: () => {

                      // 调用：构建 EBook 右滑按钮
                      this.buildSwipeButtonsEbook(book)
                    },
                    onAction: () => {

                      // 调用：右滑动作删除
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
  /**
   * 构建分组头部
   * @param title 分组标题
   */
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
  /**
   * 构建书本行内容
   * @param book 当前书本
   * @param showEBookActions 是否显示 EBook 操作按钮
   */
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

          // 调用：处理行点击切换当前书
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

                // 调用：进入加词流程
                this.actionAddWord(book)
              })

            Button() {
              Text($r('app.string.ebook_rename_label')).fontSize(13)
            }
              .height(32)
              .padding({ left: 8, right: 8 })
              .backgroundColor($r('app.color.color_obscure'))
              .onClick(() => {

                // 调用：打开重命名面板
                this.openRenameSheet(book)
              })

            Button() {
              Text($r('app.string.ebook_export_btn')).fontSize(13)
            }
              .height(32)
              .padding({ left: 8, right: 8 })
              .backgroundColor($r('app.color.color_obscure'))
              .onClick(() => {

                // 调用：导出并分享 EBook
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

                  // 调用：弹出删除确认
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

  /**
   * 处理书本行点击：切换当前书并刷新相关缓存
   * @param book 目标书本
   */
  handleRowClick(book: Book): void {

    if (book.isCurrentBook) {
      return
    }

    // 调用：切换当前书
    BookManager.shared.setCurrentBook(book)

    // 调用：重置用户词表
    WordUserDbAccess.shared.resetWordTables()

    // 调用：刷新用户词表连接
    WordUserDbAccess.shared.refreshDb()

    // 调用：刷新搜索索引
    void SearchManager.shared.refreshData()

    // 调用：刷新页面列表
    this.loadData()
  }

  @Builder
  /**
   * 构建 CBook 右滑按钮区
   * @param book 当前书本
   */
  buildSwipeButtons(book: Book) {

    Row() {

      // 调用：构建删除按钮
      this.buildSwipeButton($r('app.string.confirm_btn_remove'), $r('app.color.colorAccent'), () => {

        // 调用：执行删除确认
        this.confirmRemove(book)
      })
    }
      .alignItems(VerticalAlign.Center)
      .height('100%')
  }

  @Builder
  /**
   * 构建 EBook 右滑按钮区
   * @param book 当前书本
   */
  buildSwipeButtonsEbook(book: Book) {

    Row() {

      // 调用：构建重命名按钮
      this.buildSwipeButton($r('app.string.ebook_rename_label'), $r('app.color.colorPrimary'), () => {

        // 调用：执行打开重命名
        this.openRenameSheet(book)
      })

      // 调用：构建删除按钮
      this.buildSwipeButton($r('app.string.confirm_btn_remove'), $r('app.color.colorAccent'), () => {

        // 调用：执行删除确认
        this.confirmRemove(book)
      })
    }
      .alignItems(VerticalAlign.Center)
      .height('100%')
  }

  @Builder
  /**
   * 构建单个右滑按钮
   * @param text 按钮文本
   * @param bgColor 按钮背景色
   * @param onCallback 点击回调
   */
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

  /**
   * 删除确认弹窗与实际删除流程
   * @param book 待删除书本
   */
  private confirmRemove(book: Book): void {

    if (book.isCurrentBook) {
      return
    }

    // 调用：弹出确认框
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

          // 调用：从书单移除
          BookManager.shared.removeBook(book)

          if (book.isEBook) {

            // 调用：删除本地 EBook 数据库
            EBookManager.removeLocalTextDbIfExists(book.textDb || '')
          } else {

            // 调用：删除 CBook 数据库
            CBookManager.shared.removeBookDb(book.textDb || '')
          }

          // 调用：刷新页面列表
          this.loadData()
        }
      }
    })
  }
}
