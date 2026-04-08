//
// EWordSearchAddView.ets
// WordTree
//
// 添加单词到当前 EBook：顶栏与搜索区排版参考 iOS「添加单词」；列表项中与搜索框相同的英文或中文红色高亮。
//

import { HighlightText } from '../../app/views/HighlightText'
import { NavBarView } from '../../app/views/NavBarView'
import { OnlineWord } from '../../models/managers/onlinesearch/OnlineWord'
import { OnlineWordManager } from '../../models/managers/onlinesearch/OnlineWordManager'
import { NavPop } from '../../pages/NavPathManager'
import { NoDataPanel } from '../../app/views/NoDataView'
import { LoadingDialog } from '@kit.ArkUI'
import { Toast } from '../../common/utils/Toast'
import { MemberManager } from '../../models/managers/member/MemberManager'
import { DailyCountManager, DailyCountType } from '../../models/managers/member/DailyCountManaer'
import { BookManager } from '../../models/datas/book/BookManager'
import { getString } from '../../common/utils/ResourceUtils'
import { NetWorkTool } from '../../common/utils/NetworkUtils'
import { WordDetail } from '../../models/datas/word/WordDetail'
import { PartUnitPickerView } from './PartUnitPickerView'
import { ManualAddWordView } from './ManualAddWordView'

// 统一管理 EWordSearchAddView 中单一 bindSheet 的内容类型，避免多个 bindSheet 同层互相抢占。
enum EWordSearchSubSheetType {
  None       = 0, // 不显示子 Sheet
  ManualAdd  = 1, // 手动添加页（ManualAddWordView）
  PartUnit   = 2  // Part/Unit 选择页（PartUnitPickerView）
}

@ComponentV2
export struct EWordSearchAddView {

  @Param closeBySheet        : boolean                  = false                          // 是否由 sheet 承载
  @Event onDismiss           : () => void               = () => {}                       // 关闭回调
  @Local searchResults       : WordDetail[]             = []                             // 搜索结果
  @Local searchText          : string                   = ''                             // 搜索输入文本
  @Local addingTitleEn       : string                   = ''                             // 添加中的英文标题
  @Local hintMessage         : string                   = ''                             // 空态提示文本
  @Local isShowSubSheet      : boolean                  = false                          // 子 sheet 显示开关
  @Local subSheetType        : EWordSearchSubSheetType  = EWordSearchSubSheetType.None   // 子 sheet 类型
  @Local sheetInitialTitleEn : string                   = ''                             // 手动添加初始英文
  @Local sheetDetail         : WordDetail               = new WordDetail()               // 传给 Part/Unit 的词条
  @Local sheetBookId         : number                   = 0                              // 传给 Part/Unit 的 bookId

  // 页面即将显示：校验当前词汇本并聚焦搜索框
  aboutToAppear(): void {
    // 分支：当前未选中 EBook 时给出提示
    if (BookManager.shared.currentBook?.isEBook !== true) {
      this.hintMessage = getString($r('app.string.ebook_msg_select_ebook_first'))
    }

    setTimeout(() => {
      this.getUIContext().getFocusController().requestFocus('searchText')
    }, 100)
  }

  // 构建整页：主题色顶栏 + 白底内容区
  build() {
    NavDestination() {

      Column() {

        Column() {

          NavBarView({
            title       : $r('app.string.ebook_nav_add_word'),
            leftButtons : [{
              text   : $r('app.string.online_search_btn_cancel'),
              onClick: () => {
                this.closeSelf()
              }
            }],
            rightButtons: []
          })

          this.buildSearchRow()
        }
          .width('100%')
          .backgroundColor($r('app.color.colorPrimary'))

        Column() {

          // 分支：有结果时显示列表
          if (this.searchResults.length > 0) {
            this.buildList()
          } else {
            this.buildNoDataPanel()
          }
        }
          .layoutWeight(1)
          .width('100%')
          .backgroundColor($r('app.color.color_background'))
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      }
        .width('100%')
        .height('100%')
    }
      .hideTitleBar(true)
      .backgroundColor($r('app.color.colorPrimary'))
      .bindSheet($$this.isShowSubSheet, this.buildSubSheet(), {
        detents: [SheetSize.LARGE],
        preferType: SheetType.CENTER,
        backgroundColor: $r('app.color.colorPrimary'),
        showClose: false,
        onDisappear: () => {
          this.isShowSubSheet = false
          this.subSheetType = EWordSearchSubSheetType.None
        }
      })
  }

  // 顶栏下方：圆角灰底输入框 + 描边「搜索」按钮
  @Builder
  buildSearchRow() {

    Row({ space: 10 }) {

      TextInput({
        placeholder: $r('app.string.ebook_search_placeholder'),
        text       : $$this.searchText
      })
        .id('searchText')
        .layoutWeight(1)
        .height(40)
        .backgroundColor($r('app.color.color_obscure'))
        .borderRadius(10)
        .placeholderColor($r('app.color.color_text2'))
        .fontColor($r('app.color.color_title'))
        .enterKeyType(EnterKeyType.Search)
        .onSubmit(() => {
          void this.runSearch()
        })

      Button() {

        Text($r('app.string.ebook_search_btn'))
          .fontColor($r('app.color.color_nav_tint'))
          .fontSize(16)
      }
        .height(40)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.color_transparent'))
        .border({ width: 1, color: $r('app.color.color_nav_tint') })
        .borderRadius(10)
        .onClick(() => {
          void this.runSearch()
        })
    }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 14 })
  }

  // 在线查询结果列表
  @Builder
  buildList() {

    List({ space: 0 }) {

      ForEach(this.searchResults, (word: WordDetail, rowIndex: number) => {

        ListItem() {
          this.buildRowContent(word, rowIndex)
        }
          .onClick(() => {
            const titleEn: string = word.titleEn ?? ''

            // 分支：无英文标题或已有添加请求进行中时不响应
            if (titleEn.length < 1 || this.addingTitleEn.length > 0) {
              return
            }

            void this.addWord(titleEn)
          })
          .margin({ bottom: 1 })
      }, (word: WordDetail, rowIndex: number) => `${word.titleEn}_${rowIndex}`)
    }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  // 单行词条：高亮关键字 + 绿色「添加」胶囊（整行点击触发添加；绿色用 `color_btn_bg2`）
  @Builder
  buildRowContent(word: WordDetail, _rowIndex: number) {

    Row() {

      Column({ space: 10 }) {

        HighlightText({
          content     : word.titleEn || '',
          keyword     : this.searchText,
          normalColor : $r('app.color.color_title'),
          textStyle   : { fontSize: 18, maxLines: 1 }
        })

        HighlightText({
          content     : word.getTitleCnsJoined(),
          keyword     : this.searchText,
          normalColor : $r('app.color.color_detail'),
          textStyle   : { fontSize: 15, maxLines: 3 }
        })
      }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      // 分支：当前行正在提交添加时显示进度（与 iOS ProgressView 一致）
      if (this.addingTitleEn === (word.titleEn ?? '')) {

        LoadingProgress()
          .width(24)
          .height(24)
      } else {

        Text($r('app.string.ebook_add'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_white'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor($r('app.color.color_btn_bg2'))
          .borderRadius(8)
      }
    }
      .width('100%')
      .padding({ left: 10, top: 8, right: 10, bottom: 8 })
      .justifyContent(FlexAlign.SpaceBetween)
      .backgroundColor($r('app.color.color_clear'))
      .border({ width: { bottom: 1 }, style: BorderStyle.Dashed, color: $r('app.color.color_obscure') })
  }

  // 无结果：水印空态 + 绿色「手动输入」链（与同应用 `color_btn_bg2` 积极操作色一致）
  @Builder
  private buildNoDataPanel() {
    Column() {

      NoDataPanel({
        message      : this.hintMessage.length > 0 ? this.hintMessage : $r('app.string.online_search_input_tip'),
        expandHeight : false
      })

      // 分支：已选自建本时显示「手动输入」入口（置于空态下方略偏下、水平居中）
      if (BookManager.shared.currentBook?.isEBook === true) {
        Text($r('app.string.ebook_not_found_manual_add'))
          .fontSize(16)
          .fontColor($r('app.color.color_btn_bg2'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 20 })
          .onClick(() => {
            this.sheetInitialTitleEn = this.searchText
            this.subSheetType = EWordSearchSubSheetType.ManualAdd
            this.isShowSubSheet = true
          })
      }
    }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
  }

  // 加载中弹层内容
  @Builder
  buildLoadingDialog(msg?: ResourceStr | null): void {

    LoadingDialog({ content: msg ?? 'loading' })
  }

  // 执行在线搜索；q 取自搜索框 trim 后文本
  private async runSearch(): Promise<void> {

    const q = this.searchText.trim()

    if (q.length < 1) {
      this.hintMessage = getString($r('app.string.ebook_msg_input_query'))
      return
    }

    // 调用：检查网络
    if (!NetWorkTool.checkInternetConnection(true)) {
      return
    }

    // 调用：会员在线词典可用性（与 iOS `checkOnlineDictUsable(showMemberPurchasePage: false)` 一致：此处不直接拉起购买页）
    if (!MemberManager.shared.checkOnlineDictUsable(true, false)) {
      return
    }

    DailyCountManager.shared.increase(DailyCountType.onlineDict)

    this.hintMessage     = ''
    this.searchResults   = []

    Toast.showCustomDialog(() => {
      this.buildLoadingDialog($r('app.string.online_search_loading'))
    }, false)

    // 调用：在线搜索
    OnlineWordManager.shared.searchWords(q, 0, (success: boolean, msg: string | null, words: OnlineWord[] | null) => {

      Toast.closeCustomDialog()

      // 分支：有结果时填充列表
      if (success && words !== null && words.length > 0) {
        this.searchResults = words.map((v: OnlineWord) => v.asWordDetail())
      } else {
        this.hintMessage = msg ?? getString($r('app.string.online_search_txt_no_found'))
      }
    })
  }

  // 按英文标题拉详情并打开 Part/Unit 选择；titleEn 为词条英文
  private async addWord(titleEn: string): Promise<void> {

    if (titleEn.length < 1) {
      return
    }

    const book = BookManager.shared.currentBook

    // 分支：未选自建本则不提交
    if (book === null || !book.isEBook || book.textDb === null) {
      Toast.showMessage(getString($r('app.string.ebook_msg_select_ebook_first')))
      return
    }

    this.addingTitleEn = titleEn

    // 调用：拉取词条详情后进入 Part/Unit 选择
    OnlineWordManager.shared.loadWord(titleEn, async (success: boolean, msg: string | null, ow: OnlineWord | null) => {

      this.addingTitleEn = ''

      if (!success || ow === null) {
        Toast.showMessage(msg ?? getString($r('app.string.ebook_get_detail_failed')))
        return
      }

      const detail = ow.asWordDetail()

      this.sheetDetail = detail
      this.sheetBookId = book.bookId ?? 0
      this.subSheetType = EWordSearchSubSheetType.PartUnit
      this.isShowSubSheet = true
    })
  }

  @Builder
  private buildSubSheet() {
    if (this.subSheetType === EWordSearchSubSheetType.ManualAdd) {
      ManualAddWordView({
        initialTitleEn: this.sheetInitialTitleEn,
        closeBySheet: true,
        onDismiss: () => {
          this.isShowSubSheet = false
          this.subSheetType = EWordSearchSubSheetType.None
        }
      })
    } else {
      PartUnitPickerView({
        detail       : this.sheetDetail,
        bookId       : this.sheetBookId,
        closeBySheet : true,
        onDismiss    : () => {
          this.isShowSubSheet = false
          this.subSheetType = EWordSearchSubSheetType.None
        },
        onAddSucceed : () => {
          this.isShowSubSheet = false
          this.subSheetType = EWordSearchSubSheetType.None
        }
      })
    }
  }

  private closeSelf(): void {
    // 分支：Sheet 模式回调关闭；导航模式执行 NavPop
    if (this.closeBySheet) {
      this.onDismiss()
    } else {
      NavPop()
    }
  }
}
