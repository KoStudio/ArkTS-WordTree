//
// EBookSelectView.ets
// WordTree
//
// 从学习详情页将当前单词保存到任意本地 EBook：选 EBook 或新建 → 选 Part/Unit → 若已存在则确认覆盖后写入。
// 由外层 `.bindSheet` 弹出（与 `EWordItemPickerView`、EBook 相关 Sheet 一致），不使用独立导航 Config。
//

import { TextButton } from '../../app/views/buttons/TextButton'
import { NavBarView } from '../../app/views/NavBarView'
import { TintImage } from '../../app/views/TintImage'
import { getString, getStringF } from '../../common/utils/ResourceUtils'
import { Toast } from '../../common/utils/Toast'
import { SimpleEventBus } from '../../common/components/eventbus/SimpleEventBus'
import { Book } from '../../models/datas/book/Book'
import { BookManager, BookManagerNotification } from '../../models/datas/book/BookManager'
import { SearchManager } from '../../models/datas/model/SearchManager'
import { WordDetail } from '../../models/datas/word/WordDetail'
import { EBookManager } from '../../models/managers/ebook/EBookManager'
import { MemberManager } from '../../models/managers/member/MemberManager'
import { NavPop } from '../../pages/NavPathManager'
import { PartUnitPickerView } from './PartUnitPickerView'

@ComponentV2
export struct EBookSelectView {

  @Param @Require originalDetail      : WordDetail                // 来源词条
  @Param closeBySheet                 : boolean                   = true       // true：取消走 onDismiss（Sheet）；false：NavPop
  @Event onDismiss                    : () => void                = () => {}   // 关闭整页（Sheet 或导航）
  @Local private eBooks               : Book[]                    = []         // 可选 EBook 列表
  @Local private isShowPartUnitSheet  : boolean                   = false      // Part/Unit sheet 显示开关
  @Local private sheetBookId          : number                    = 0          // sheet 目标书 id
  @Local private selectedBookId       : number | null             = null       // 与 iOS selectedBook 一致，用于行末对勾
  @Local private newBookNameInput     : string                    = ''         // 新建词汇本弹窗输入，与 createEbookDialogView 双向绑定
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

  // 与 `EWordItemPickerView`：Column + NavBarView，无 NavDestination
  build() {

    Column() {

      NavBarView({
        title       : this.originalDetail.titleEn ?? '',
        leftButtons : [{
          text   : $r('app.string.online_search_btn_cancel'),
          onClick: () => {
            this.closeSelf()
          }
        }],
        rightButtons: []
      })

      // 与 iOS `List` + `listRowSeparatorTint(theme.color.line)` 一致：白底行间 #EBEBEB 分隔线（Scroll+Divider 保证每条可见）
      Scroll() {

        Column() {

          Text($r('app.string.ebook_select_title'))
            .fontSize(15)
            .fontColor($r('app.color.color_list_item_subtitle'))
            .width('100%')
            .textAlign(TextAlign.Start)
            .padding({ left: 16, top: 8, right: 16, bottom: 8 })
            .backgroundColor($r('app.color.color_obscure'))

          Column() {

            Column() {
              this.buildNewBookRow()
            }
              .width('100%')

            Divider()
              .strokeWidth(1)
              .color($r('app.color.color_list_row_separator'))

            if (this.eBooks.length < 1) {

              Text($r('app.string.ebook_no_other'))
                .fontSize(13)
                .fontColor($r('app.color.color_list_item_subtitle'))
                .width('100%')
                .padding({ top: 8, bottom: 8, left: 16, right: 16 })
            } else {

              ForEach(this.eBooks, (book: Book, index: number) => {

                Column() {

                  this.buildBookRow(book)

                  if (index < this.eBooks.length - 1) {

                    Divider()
                      .strokeWidth(1)
                      .color($r('app.color.color_list_row_separator'))
                  }
                }
                  .width('100%')
              }, (book: Book) => `${book.bookId}`)
            }
          }
            .width('100%')
            .backgroundColor($r('app.color.color_list_item_bg'))
        }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
      }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .align(Alignment.TopStart)
        .backgroundColor($r('app.color.color_obscure'))
    }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_obscure'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .bindSheet($$this.isShowPartUnitSheet, this.buildPartUnitSheet(), {
        detents         : [SheetSize.LARGE],
        preferType      : SheetType.CENTER,
        backgroundColor : $r('app.color.colorPrimary'),
        showClose       : false,
        onDisappear     : () => {
          this.isShowPartUnitSheet = false
          this.selectedBookId = null
        }
      })
  }

  // Sheet 关闭或导航返回
  private closeSelf(): void {

    if (this.closeBySheet) {
      this.onDismiss()
    } else {
      NavPop()
    }
  }

  @Builder
  private buildNewBookRow() {

    Row({ space: 8 }) {

      TintImage({
        src      : $r('app.media.plus_circle'),
        isSvg    : true,
        iconSize : 22,
        colorStr : '#FF66CD40'
      })

      Text($r('app.string.ebook_new_book'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.color_btn_bg2'))
    }
      .width('100%')
      .padding({ top: 8, bottom: 8, left: 16, right: 16 })
      .onClick(() => {

        // 调用：与 BooksLocalView.openCreateEbookDialog 一致，本页内 Toast 弹窗创建，不压独立导航页
        this.openCreateEbookDialog()
      })
  }

  // 打开新建词汇本弹窗：清空输入后 Toast.showCustomDialog（对齐 BooksLocalView）
  private openCreateEbookDialog(): void {

    this.newBookNameInput = ''

    Toast.showCustomDialog(() => {
      this.createEbookDialogView()
    })
  }

  // 新建词汇本 UI：Toast.showCustomDialog 的 builder（与 BooksLocalView.createEbookDialogView 同构；id 独立避免与书单页冲突）
  @Builder
  private createEbookDialogView() {

    Column({ space: 10 }) {

      Column() {

        Text($r('app.string.ebook_create_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_text'))
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      Divider()

      Column({ space: 5 }) {

        TextInput({ placeholder: $r('app.string.ebook_name_hint'), text: $$this.newBookNameInput })
          .width('100%')
          .id('ebookSelectCreateTitleInput')
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

      setTimeout(() => {

        try {

          this.getUIContext().getFocusController().requestFocus('ebookSelectCreateTitleInput')
        } catch (_e) {

          // 忽略：部分环境无 FocusController 或 id 未就绪
        }
      }, 120)
    })
  }

  // 确认新建：校验与写库后关弹窗、刷新列表并打开 Part/Unit（不切当前学习书，与「保存到词汇本」场景一致）
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

    Toast.closeCustomDialog()

    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
    void SearchManager.shared.refreshData()
    this.loadData()

    this.selectedBookId = book.bookId ?? null
    this.sheetBookId = book.bookId ?? 0
    this.isShowPartUnitSheet = true
  }

  @Builder
  private buildBookRow(book: Book) {

    Row() {

      Column({ space: 4 }) {

        Text(book.bookName ?? '')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_list_item_title'))

        Text(getStringF($r('app.string.books_txt_info_counts'), book.unitsCount ?? 0, book.wordsCount ?? 0))
          .fontSize(12)
          .fontColor($r('app.color.color_list_item_subtitle'))
      }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      if (this.selectedBookId !== null && this.selectedBookId === book.bookId) {

        Text('✓')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_btn_bg2'))
      }
    }
      .width('100%')
      .padding({ top: 8, bottom: 8, left: 16, right: 16 })
      .onClick(() => {

        this.selectedBookId = book.bookId ?? null
        this.sheetBookId = book.bookId ?? 0
        this.isShowPartUnitSheet = true
      })
  }

  @Builder
  private buildPartUnitSheet() {

    PartUnitPickerView({
      detail        : this.originalDetail,
      bookId        : this.sheetBookId,
      closeBySheet  : true,
      onDismiss     : () => {
        this.isShowPartUnitSheet = false
        this.selectedBookId = null
      },
      onAddSucceed  : () => {

        // 与 iOS 保存成功后 dismiss 整页一致：关闭外层「保存到」Sheet
        this.closeSelf()
      }
    })
  }

  private loadData(): void {

    const currentId = BookManager.shared.currentBook?.bookId

    this.eBooks = BookManager.shared.eBooks.filter((it: Book) => it.bookId !== currentId)
  }
}
