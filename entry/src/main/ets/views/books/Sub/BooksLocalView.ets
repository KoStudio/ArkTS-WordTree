//
// BooksLocalView.ets
// 与 iOS `Root/Book2/Sub/BooksLocalView.swift` 对齐（不含 LegacyBookMigrator）。
//

import { CBookManager } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { EBookManager } from '../../../models/managers/ebook/EBookManager'
import { EBookExportImportManager } from '../../../models/managers/ebook/EBookExportImportManager'
import { getString, getStringF } from '../../../common/utils/ResourceUtils'
import { ItemOption, Toast } from '../../../common/utils/Toast'
import { ShareUtils } from '../../../common/utils/ShareUtils'
import { Book } from '../../../models/datas/book/Book'
import { BookManager, BookManagerNotification } from '../../../models/datas/book/BookManager'
import { SearchManager } from '../../../models/datas/model/SearchManager'
import { WordUserDbAccess } from '../../../models/datas/myData/WordUserDbAccess'
import { MemberManager } from '../../../models/managers/member/MemberManager'
import { UserManager } from '../../../models/managers/user/UserManager'
import { EWordSearchAddView } from '../../ebook/EWordSearchAddView'
import { MyBackedUpEBooksView } from '../../ebook/MyBackedUpEBooksView'
import { EBookImportView } from '../../ebook/EBookImportView'
import { TextButton } from '../../../app/views/buttons/TextButton'

// 统一管理 BooksLocalView 中单一 bindSheet 的内容类型，避免多个 bindSheet 同层互相抢占。
enum EBookSheetType {
  None         = 0, // 不显示任何词汇本相关 Sheet
  Import       = 1, // 导入词汇本页（EBookImportView）
  MyBackedUp   = 2, // 我备份的词汇本页（MyBackedUpEBooksView）
  AddWord      = 3  // 添加单词页（EWordSearchAddView）
}

@ComponentV2
export struct BooksLocalView {

  @Local books                  : Book[]                    = []         // 从 BookManager 同步，供列表与分组展示
  @Local listVersion            : number                    = 0          // 变更时递增，驱动 ForEach 列表键刷新
  @Local newBookNameInput       : string                    = ''         // 新建词汇本弹窗输入，与 createEbookDialogView 双向绑定
  @Local renameBookNameInput    : string                    = ''         // 重命名弹窗输入，与 renameEbookDialogView 双向绑定
  @Local renameTargetBookId     : number                    = 0          // 重命名目标 bookId，打开重命名弹窗时写入
  @Local isShowEBookSheet       : boolean                   = false
  @Local eBookSheetType         : EBookSheetType            = EBookSheetType.None
  private unsubBookList         : (() => void) | undefined  = undefined  // 取消书单更新事件的 SimpleEventBus 订阅
  private unsubCurrentBook      : (() => void) | undefined  = undefined  // 取消当前书更新事件的 SimpleEventBus 订阅

  // 页面出现时：拉取本地书单并注册全局书单/当前书变更，便于列表与 iOS 一致实时刷新
  aboutToAppear(): void {

    // 调用：首次进入时加载列表
    this.loadData()

    // 调用：订阅书单更新事件（其它页改书库后会 broadcast）
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

  // 页面消失时：注销本页注册的 SimpleEventBus 监听，避免泄漏与重复回调
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

  // 从 BookManager.shared 同步 books 到 @Local，并 bump listVersion 以刷新 ForEach 键
  private loadData(): void {

    // 调用：同步全局书单到页面状态
    this.books = [...BookManager.shared.books]
    this.listVersion++
  }

  // 过滤出内置教材（非用户词汇本）
  private cBooks(): Book[] {
    return this.books.filter((b: Book) => !b.isEBook)
  }

  // 过滤出用户词汇本（EBook）
  private eBooks(): Book[] {
    return this.books.filter((b: Book) => b.isEBook)
  }

  build() {

    Column() {

      Column() {

        // 调用：构建书单列表区域（与 iOS `.background(Color(theme.color.obscure))` + grouped 卡片一致）
        this.buildList()
      }
        .width('100%')
        .layoutWeight(1)

      Column() {

        // 与 iOS `Rectangle().fill(Color(theme.color.line)).frame(height: 1)` 一致
        Divider()
          .strokeWidth(1)
          .color($r('app.color.color_line'))

        Row() {

          Button() {

            // 与 iOS 导航栏主色一致：`color_nav_bg` / `theme` 主色底 + 白字
            Text($r('app.string.ebook_plus_btn'))
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.color_nav_text'))
          }
            .width(200)
            .height(36)
            .backgroundColor($r('app.color.color_nav_bg'))
            .borderRadius(18)
            .type(ButtonType.Normal)
            .stateEffect(true)
            .onClick(() => {

              // 调用：与 Zhika DayOfsView.actionPopMenu 相同，使用系统选项对话框
              this.actionPopEbookMenu()
            })
        }
          .width('100%')
          .height(44)
          .justifyContent(FlexAlign.Center)
      }
        .width('100%')
        .backgroundColor($r('app.color.color_detail_footer_bg'))

    }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_obscure'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .bindSheet($$this.isShowEBookSheet, this.buildEBookSheet(), {
        detents: [SheetSize.LARGE],
        preferType: SheetType.CENTER,
        backgroundColor: $r('app.color.colorPrimary'),
        showClose: false,
        onDisappear: () => {
          this.isShowEBookSheet = false
          this.eBookSheetType = EBookSheetType.None
        }
      })
  }

  // 底部「+」：`ItemOption` 列表 + `Toast.showSelectOptions`（对齐 Zhika DayOfsView.actionPopMenu）
  private actionPopEbookMenu(): void {

    let options: ItemOption[] = []

    options.push({
      text   : $r('app.string.ebook_new_book'),
      action : () => {

        this.openCreateEbookDialog()
      }
    })

    options.push({
      text   : $r('app.string.ebook_import_btn'),
      action : () => {

        this.eBookSheetType = EBookSheetType.Import
        this.isShowEBookSheet = true
      }
    })

    if (UserManager.shared.isLogin()) {

      options.push({
        text   : $r('app.string.ebook_my_backed_up_btn'),
        action : () => {

          this.eBookSheetType = EBookSheetType.MyBackedUp
          this.isShowEBookSheet = true
        }
      })
    }

    // 调用：第四参省略时使用默认「取消」按钮（见 Toast.showSelectOptions 实现）
    Toast.showSelectOptions('', undefined, options)
  }

  // 打开新建词汇本弹窗：清空输入后 `Toast.showCustomDialog`（对齐 Zhika BookListView.addOrEditBook）
  private openCreateEbookDialog(): void {

    this.newBookNameInput = ''

    Toast.showCustomDialog(() => {
      this.createEbookDialogView()
    })
  }

  // 新建词汇本 UI：`Toast.openCustomDialog` 的 builder；标题 + 边框输入框 + 取消/保存（与 Zhika createBookDialogView 同构，仅无描述栏）
  @Builder
  createEbookDialogView() {

    Column({ space: 10 }) {

      // 标题区：居中说明当前为「新建词汇本」
      Column() {

        Text($r('app.string.ebook_create_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_text'))
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      Divider()

      // 输入区：双边绑定 newBookNameInput，聚焦 id 供 requestFocus 拉起键盘
      Column({ space: 5 }) {

        TextInput({ placeholder: $r('app.string.ebook_name_hint'), text: $$this.newBookNameInput })
          .width('100%')
          .id('createEbookTitleInput')
          .border({ width: 1, color: $r('app.color.color_obscure'), radius: 5 })
          .backgroundColor(Color.White)
      }

      // 底部操作：灰底取消 + 导航色保存（与 renameEbookDialogView 一致）
      Row({ space: 20 }) {

        TextButton({
          text             : $r('app.string.confirm_btn_cancel'),
          bgColor          : $r('app.color.color_gray'),
          onClickCallBack  : () => {

            Toast.closeCustomDialog()
          }
        })

        TextButton({
          text             : $r('app.string.memo_compose_btn_save'),
          bgColor          : $r('app.color.color_nav_bg'),
          fontColor        : $r('app.color.color_nav_text'),
          onClickCallBack  : async () => {

            await this.confirmCreateEbook()
          }
        })
      }
      .justifyContent(FlexAlign.Center)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('auto')
    .padding(20)
    .onAppear(() => {

      // 延迟聚焦：避免与弹窗首帧布局竞争导致焦点失败
      setTimeout(() => {

        try {

          this.getUIContext().getFocusController().requestFocus('createEbookTitleInput')
        } catch (_e) {

          // 忽略：部分环境无 FocusController 或 id 未就绪
        }
      }, 120)
    })
  }

  // 打开重命名弹窗：写入 renameTargetBookId / 预填 renameBookNameInput，再 `Toast.showCustomDialog`
  // book：被重命名的词汇本行对应数据
  private openRenameSheet(book: Book): void {

    this.renameTargetBookId  = book.bookId ?? 0
    this.renameBookNameInput = book.bookName ?? ''

    Toast.showCustomDialog(() => {
      this.renameEbookDialogView()
    })
  }

  // 重命名词汇本 UI：与 createEbookDialogView 同布局风格（标题 / Divider / 边框输入 / 取消+保存）
  @Builder
  renameEbookDialogView() {

    Column({ space: 10 }) {

      Column() {

        Text($r('app.string.ebook_rename_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_text'))
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      Divider()

      Column({ space: 5 }) {

        TextInput({ placeholder: $r('app.string.ebook_name_hint'), text: $$this.renameBookNameInput })
          .width('100%')
          .id('renameEbookTitleInput')
          .border({ width: 1, color: $r('app.color.color_obscure'), radius: 5 })
          .backgroundColor(Color.White)
      }

      Row({ space: 20 }) {

        TextButton({
          text             : $r('app.string.confirm_btn_cancel'),
          bgColor          : $r('app.color.color_gray'),
          onClickCallBack  : () => {

            Toast.closeCustomDialog()
          }
        })

        TextButton({
          text             : $r('app.string.memo_compose_btn_save'),
          bgColor          : $r('app.color.color_nav_bg'),
          fontColor        : $r('app.color.color_nav_text'),
          onClickCallBack  : () => {

            this.confirmRenameEbook()
          }
        })
      }
      .justifyContent(FlexAlign.Center)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('auto')
    .padding(20)
    .onAppear(() => {

      // 延迟聚焦：与 createEbookDialogView 相同，避免首帧抢焦点失败
      setTimeout(() => {

        try {

          this.getUIContext().getFocusController().requestFocus('renameEbookTitleInput')
        } catch (_e) {

          // 忽略：同 createEbookDialogView
        }
      }, 120)
    })
  }

  // 确认新建：校验非空与会员、写库、关弹窗、刷新并进入加词页
  private async confirmCreateEbook(): Promise<void> {

    const trimmed = this.newBookNameInput.trim()

    if (trimmed.length < 1) {

      // 空名：保持弹窗，不打扰用户（亦可后续改为 Toast 提示）
      return
    }

    if (!MemberManager.shared.checkEBookCreatable(true, true)) {

      // 会员/配额不足：MemberManager 内已提示
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

    // 调用：每书独立 learnDb，仅需重连；勿 resetWordTables（Online 已在该书库内，切换书不必清）
    WordUserDbAccess.shared.refreshDb()

    // 调用：刷新搜索索引
    void SearchManager.shared.refreshData()

    // 调用：关闭自定义弹窗后再跳转，避免层叠遮挡
    Toast.closeCustomDialog()

    // 调用：刷新页面列表
    this.loadData()

    // 调用：广播书单更新
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)

    // 调用：打开 EBook 加词页面
    this.eBookSheetType = EBookSheetType.AddWord
    this.isShowEBookSheet = true
  }

  // 确认重命名：trim 后非空则按 renameTargetBookId 查找并 renameBook，关弹窗并刷新列表
  private confirmRenameEbook(): void {

    const trimmed = this.renameBookNameInput.trim()

    if (trimmed.length < 1) {

      return
    }

    // 调用：按目标 bookId 查找书本
    const book = BookManager.shared.books.find((b: Book) => b.bookId === this.renameTargetBookId)

    if (book === undefined) {

      // 列表已变或 id 无效：关闭弹窗并结束
      Toast.closeCustomDialog()
      return
    }

    // 调用：执行重命名
    BookManager.shared.renameBook(book, trimmed)

    // 调用：关闭自定义弹窗
    Toast.closeCustomDialog()

    // 调用：刷新页面列表
    this.loadData()

    // 调用：广播书单更新
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
  }

  // 切换当前书并进入词汇本「加词」页
  // book：要设为当前书的词汇本
  private actionAddWord(book: Book): void {

    // 调用：切换当前书
    BookManager.shared.setCurrentBook(book)

    // 调用：每书独立 learnDb，仅需重连
    WordUserDbAccess.shared.refreshDb()

    // 调用：刷新搜索索引
    void SearchManager.shared.refreshData()

    // 调用：刷新页面列表
    this.loadData()

    // 调用：打开 EBook 加词页
    this.eBookSheetType = EBookSheetType.AddWord
    this.isShowEBookSheet = true
  }

  @Builder
  private buildEBookSheet() {
    if (this.eBookSheetType === EBookSheetType.Import) {
      EBookImportView({
        closeBySheet: true,
        onDismiss: () => {
          this.isShowEBookSheet = false
          this.eBookSheetType = EBookSheetType.None
        }
      })
    } else if (this.eBookSheetType === EBookSheetType.MyBackedUp) {
      MyBackedUpEBooksView({
        closeBySheet: true,
        onDismiss: () => {
          this.isShowEBookSheet = false
          this.eBookSheetType = EBookSheetType.None
        }
      })
    } else {
      EWordSearchAddView({
        closeBySheet: true,
        onDismiss: () => {
          this.isShowEBookSheet = false
          this.eBookSheetType = EBookSheetType.None
        }
      })
    }
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

                Column() {

                  // 调用：构建列表行内容（CBook）
                  this.buildRowContent(book, false)
                }
                  .margin({ left: 16, right: 16, top: 8, bottom: 8 })
              }
                // parallelGesture：长按与行内 Button 点击并行识别，避免 .gesture 独占导致图标无响应
                .parallelGesture(
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

                Column() {

                  // 调用：构建列表行内容（EBook）
                  this.buildRowContent(book, true)
                }
                  .margin({ left: 16, right: 16, top: 8, bottom: 8 })
              }
                .parallelGesture(
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
        .divider({ strokeWidth: 0 })
    }
      .backgroundColor($r('app.color.color_obscure'))
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
        top    : 4,
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

          // 与 iOS `Image(systemName: "checkmark").foregroundColor(.green)` 一致
          if (BookManager.shared.currentBook?.bookId === book.bookId) {

            Text('\u2713')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#34C759')
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

          // 与 iOS：行内图标着 Navigation 主色（与 `color_nav_bg` 一致）
          Row({ space: 16 }) {

            this.buildEbookToolbarIcon($r('app.media.plus'), () => {

              this.actionAddWord(book)
            })

            this.buildEbookToolbarIcon($r('app.media.pencil'), () => {

              this.openRenameSheet(book)
            })

            this.buildEbookToolbarIcon($r('app.media.share'), () => {

              this.actionExportEbook(book)
            })

            Button() {

              Image($r('app.media.trash'))
                .width(18)
                .height(18)
                .fillColor(book.isCurrentBook ?
                  $r('app.color.color_list_tint') : $r('app.color.color_nav_bg'))
            }
              .type(ButtonType.Normal)
              .backgroundColor(Color.Transparent)
              .stateEffect(!book.isCurrentBook)
              .enabled(!book.isCurrentBook)
              .onClick(() => {

                if (!book.isCurrentBook) {

                  this.confirmRemove(book)
                }
              })
          }
        }
          .width('100%')
      }
    }
      .width('100%')
      .padding(16)
      .borderRadius(8)
      .backgroundColor($r('app.color.color_list_item_bg'))
      .clip(true)
  }

  @Builder
  /**
   * 自建词汇本工具栏图标（与 iOS 一致：着导航主色 `color_nav_bg`）
   * @param src  矢量图标资源
   * @param act  点击回调
   */
  buildEbookToolbarIcon(src: Resource, act: () => void) {

    Button() {

      Image(src)
        .width(18)
        .height(18)
        .fillColor($r('app.color.color_nav_bg'))
    }
      .type(ButtonType.Normal)
      .backgroundColor(Color.Transparent)
      .stateEffect(true)
      .onClick(act)
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

    // 调用：每书独立 learnDb，仅需重连
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
