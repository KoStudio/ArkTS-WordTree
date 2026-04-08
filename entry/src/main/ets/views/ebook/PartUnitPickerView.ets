//
// PartUnitPickerView.ets
// WordTree
//
// 选择 Part/Unit 后，直接把结果保存到目标 EBook。
// 这个页面不再依赖外部 dataSource，而是根据传入的 book 自己读取目标 textDb。
// 导航与列表视觉、勾选与输入框逻辑对齐 iOS `PartUnitPickerView.swift`（分组列表、绿勾、新 Part 时隐藏已有 Unit 行等）。
//

import { NavBarView } from '../../app/views/NavBarView'
import { getString, getStringF } from '../../common/utils/ResourceUtils'
import { Toast } from '../../common/utils/Toast'
import { Book } from '../../models/datas/book/Book'
import { BookManager, BookManagerNotification } from '../../models/datas/book/BookManager'
import { Part, Unit } from '../../models/datas/model/Part_Unit'
import { SearchManager } from '../../models/datas/model/SearchManager'
import { WordUserDbAccess } from '../../models/datas/myData/WordUserDbAccess'
import { WordDetail } from '../../models/datas/word/WordDetail'
import { WordDbAccess } from '../../models/datas/word/WordDbAccess'
import { EBookManager } from '../../models/managers/ebook/EBookManager'
import { SimpleEventBus } from '../../common/components/eventbus/SimpleEventBus'

@ComponentV2
export struct PartUnitPickerView {

  @Event onDismiss                   : () => void = () => {}  // 关闭回调
  @Event onAddSucceed                : () => void = () => {}  // 添加成功回调（用于联动关闭上一层）
  @Param @Require detail             : WordDetail             // 待保存词条
  @Param @Require bookId             : number                 // 目标书 id
  @Local private parts               : Part[]     = []        // Part 列表
  @Local private units               : Unit[]     = []        // Unit 列表
  @Local private selectedPartIndex   : number     = 0         // 选中的 Part 索引
  @Local private selectedUnitIndex   : number     = 0         // 选中的 Unit 索引
  @Local private newPartName         : string     = ''        // 新建 Part 名称输入
  @Local private newUnitName         : string     = ''        // 新建 Unit 名称输入
  @Local private maxPartId           : number     = 0         // 当前最大 PartId
  @Local private maxUnitId           : number     = 0         // 当前最大 UnitId
  @Local private loading             : boolean    = true      // 加载状态
  @Local private isNewPartFieldFocused: boolean   = false     // 新 Part 输入焦点态
  @Local private isNewUnitFieldFocused: boolean   = false     // 新 Unit 输入焦点态
  private readonly maxPartNameLength : number     = 10        // 新 Part 名最大长度
  private readonly maxUnitNameLength : number     = 20        // 新 Unit 名最大长度

  // 目标书对象
  private get targetBook(): Book | null {
    return BookManager.shared.books.find((it: Book) => it.bookId === this.bookId) ?? null
  }

  // 目标 textDb 完整路径
  private get textDbPath(): string {
    const textDb = this.targetBook?.textDb ?? ''
    return EBookManager.textDbPath(textDb)
  }

  // 页面出现时加载初始化数据
  aboutToAppear(): void {
    void this.loadInitialData()
  }

  build() {
    NavDestination() {

      Column() {

        NavBarView({
          title       : $r('app.string.ebook_save_to_nav_title'),
          leftButtons : [{
            text   : $r('app.string.online_search_btn_cancel'),
            onClick: () => {
              this.onDismiss()
            }
          }],
          rightButtons: [{
            text   : $r('app.string.ebook_add'),
            onClick: () => {
              void this.saveSelectedDetail()
            }
          }]
        })

        // 分支：加载中仅显示进度（白底与 iOS List 区域一致）
        if (this.loading) {
          Column() {
            LoadingProgress()
          }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .backgroundColor($r('app.color.color_background'))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        } else {
          // List space：两个 ListItemGroup（Part / Unit）之间的垂直间距
          List({ space: 12 }) {
            ListItemGroup({ header: this.sectionHeader($r('app.string.ebook_part_header')) }) {
              ForEach(this.parts, (part: Part, index: number) => {
                ListItem() {
                  this.partRow(part, index)
                }
              }, (part: Part) => `p_${part.partId}`)
              ListItem() {
                this.newPartRow()
              }
            }

            ListItemGroup({ header: this.sectionHeader($r('app.string.ebook_unit_header')) }) {
              ForEach(this.unitsForDisplay(), (unit: Unit, index: number) => {
                ListItem() {
                  this.unitRow(unit, index)
                }
              }, (unit: Unit) => `u_${unit.unitId}`)
              ListItem() {
                this.newUnitRow()
              }
            }
          }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor($r('app.color.color_background'))
            .scrollBar(BarState.Auto)
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        }
      }
        .width('100%')
        .height('100%')
    }
      .hideTitleBar(true)
      .backgroundColor($r('app.color.colorPrimary'))
  }

  @Builder
  private sectionHeader(title: ResourceStr) {
    Text(title)
      .fontSize(15)
      .fontColor($r('app.color.color_list_item_subtitle'))
      .width('100%')
      .padding({ left: 16, top: 8, right: 16, bottom: 8 })
      .backgroundColor($r('app.color.color_background'))
  }

  @Builder
  private partRow(part: Part, index: number) {
    Row() {
      // 与 iOS `part.partName ?? "Part\(id)"` 一致：名为空时显示占位
      Text(part.partName.length > 0 ? part.partName : `Part${part.partId}`)
        .fontSize(17)
        .fontColor($r('app.color.color_list_item_title'))
      Blank()
        .layoutWeight(1)
      // 分支：与 iOS 一致，仅在不处于「新 Part」模式且本行选中时显示绿色勾
      if (!this.isUsingNewPart() && this.selectedPartIndex === index) {
        Text('✓')
          .fontSize(16)
          .fontColor($r('app.color.color_btn_bg2'))
      }
    }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.color_list_item_bg'))
      .border({ width: { bottom: 1 }, color: $r('app.color.color_obscure') })
      .onClick(() => {
        // 分支：选中已有 Part 时收起新 Part 输入、清空新 Unit，并重载 Unit 列表（对齐 iOS onTapGesture）
        this.getUIContext().getFocusController().clearFocus()
        this.isNewPartFieldFocused = false
        this.newPartName           = ''
        this.selectedPartIndex     = index
        this.isNewUnitFieldFocused = false
        this.newUnitName           = ''
        void this.reloadUnitsForSelectedPart()
      })
  }

  @Builder
  private unitRow(unit: Unit, index: number) {
    Row() {
      // 与 iOS `unit.unitName ?? "Unit\(id)"` 一致：名为空时显示占位
      Text(unit.unitName.length > 0 ? unit.unitName : `Unit${unit.unitId}`)
        .fontSize(17)
        .fontColor($r('app.color.color_list_item_title'))
      Blank()
        .layoutWeight(1)
      // 分支：与 iOS 一致，仅在不处于「新 Unit」模式且本行选中时显示绿色勾
      if (!this.isUsingNewUnit() && this.selectedUnitIndex === index) {
        Text('✓')
          .fontSize(16)
          .fontColor($r('app.color.color_btn_bg2'))
      }
    }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.color_list_item_bg'))
      .border({ width: { bottom: 1 }, color: $r('app.color.color_obscure') })
      .onClick(() => {
        // 分支：选中已有 Unit 时收起新 Unit 输入（对齐 iOS）
        this.getUIContext().getFocusController().clearFocus()
        this.isNewUnitFieldFocused = false
        this.newUnitName           = ''
        this.selectedUnitIndex     = index
      })
  }

  @Builder
  private newPartRow() {
    Row() {
      TextInput({
        text        : $$this.newPartName,
        placeholder : `Part${this.maxPartId + 1}`
      })
        .id('ebookNewPartInput')
        .width(200)
        .height(36)
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor($r('app.color.color_obscure'))
        .borderRadius(6)
        .border({ width: 1, color: $r('app.color.colorPrimary') })
        .fontColor($r('app.color.color_text'))
        .fontSize(16)
        .onChange((value: string) => {
          if (value.length > this.maxPartNameLength) {
            this.newPartName = value.substring(0, this.maxPartNameLength)
          }
        })
        .onFocus(() => {
          this.isNewPartFieldFocused = true
        })
        .onBlur(() => {
          this.isNewPartFieldFocused = false
        })
      Blank()
        .layoutWeight(1)
      // 分支：与 iOS `isUsingNewPart` 时显示绿色勾
      if (this.isUsingNewPart()) {
        Text('✓')
          .fontSize(16)
          .fontColor($r('app.color.color_btn_bg2'))
      }
    }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.color_list_item_bg'))
      .border({ width: { bottom: 1 }, color: $r('app.color.color_obscure') })
      .onClick(() => {
        // 分支：点击行聚焦新 Part 输入框（对齐 iOS contentShape + onTapGesture）
        this.getUIContext().getFocusController().requestFocus('ebookNewPartInput')
      })
  }

  @Builder
  private newUnitRow() {
    Row() {
      TextInput({
        text        : $$this.newUnitName,
        placeholder : `Unit${this.maxUnitId + 1}`
      })
        .id('ebookNewUnitInput')
        .width(200)
        .height(36)
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor($r('app.color.color_obscure'))
        .borderRadius(6)
        .border({ width: 1, color: $r('app.color.colorPrimary') })
        .fontColor($r('app.color.color_text'))
        .fontSize(16)
        .onChange((value: string) => {
          if (value.length > this.maxUnitNameLength) {
            this.newUnitName = value.substring(0, this.maxUnitNameLength)
          }
        })
        .onFocus(() => {
          this.isNewUnitFieldFocused = true
        })
        .onBlur(() => {
          this.isNewUnitFieldFocused = false
        })
      Blank()
        .layoutWeight(1)
      // 分支：与 iOS `isUsingNewUnit` 时显示绿色勾
      if (this.isUsingNewUnit()) {
        Text('✓')
          .fontSize(16)
          .fontColor($r('app.color.color_btn_bg2'))
      }
    }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.color_list_item_bg'))
      .border({ width: { bottom: 1 }, color: $r('app.color.color_obscure') })
      .onClick(() => {
        // 分支：点击行聚焦新 Unit 输入框（对齐 iOS）
        this.getUIContext().getFocusController().requestFocus('ebookNewUnitInput')
      })
  }

  // 与 iOS 一致：`isUsingNewPart` 为 true 时不展示已有 Unit 行，仅保留新建 Unit 行
  private unitsForDisplay(): Unit[] {
    if (this.isUsingNewPart()) {
      return []
    }
    return this.units
  }

  // 对齐 iOS `isUsingNewPart`：焦点在非空新 Part 名、或书本尚无 Part
  private isUsingNewPart(): boolean {
    return this.isNewPartFieldFocused || this.newPartName.trim().length > 0 || this.parts.length < 1
  }

  // 对齐 iOS `isUsingNewUnit`：新 Part 模式下视为使用新 Unit，或焦点/空列表等
  private isUsingNewUnit(): boolean {
    return this.isNewUnitFieldFocused || this.newUnitName.trim().length > 0 || this.units.length < 1 ||
      this.isUsingNewPart()
  }

  // 初始加载目标书的 Part/Unit 列表，并设置默认选中项。
  private async loadInitialData(): Promise<void> {

    this.loading   = true

    // 访问 WordDbAccess：与 iOS `WordManager` 指定 textDb 路径 API 一致
    this.maxPartId = await WordDbAccess.getMaxPartId(this.textDbPath)
    this.maxUnitId = await WordDbAccess.getMaxUnitId(this.textDbPath)
    this.parts     = await WordDbAccess.getAllParts(this.textDbPath)

    if (this.parts.length < 1) {
      this.selectedPartIndex = 0
      this.newPartName       = `Part${this.maxPartId + 1}`
      this.units             = []
      this.newUnitName       = `Unit${this.maxUnitId + 1}`
    } else {
      this.selectedPartIndex = this.parts.length - 1
      await this.reloadUnitsForSelectedPart()
    }

    this.loading = false
  }

  // 根据当前 Part 选择刷新 Unit 列表。
  private async reloadUnitsForSelectedPart(): Promise<void> {

    if (this.selectedPartIndex < 0 || this.selectedPartIndex >= this.parts.length) {
      this.units             = []
      this.selectedUnitIndex = 0
      return
    }

    const part = this.parts[this.selectedPartIndex]

    // 访问 WordDbAccess
    this.units = await WordDbAccess.getUnitsByPartId(part.partId, this.textDbPath)

    if (this.units.length < 1) {
      this.selectedUnitIndex = 0
      if (this.newUnitName.trim().length < 1) {
        this.newUnitName = `Unit${this.maxUnitId + 1}`
      }
    } else {
      this.selectedUnitIndex = this.units.length - 1
    }
  }

  // 执行保存前的查重确认，并决定是弹窗还是直接保存。
  private async saveSelectedDetail(): Promise<void> {

    const finalDetail = await this.buildFinalDetail()
    const titleEn     = finalDetail.titleEn ?? ''

    if (titleEn.length < 1) {
      Toast.showMessage(getString($r('app.string.ebook_add_failed')))
      return
    }

    // 先查重，再保存，避免重复覆盖提示和实际写入目标不一致。
    // 访问 WordDbAccess
    const existing = await WordDbAccess.getWordPartUnitIfExists(titleEn, this.textDbPath)

    if (existing !== null) {
      const overwriteMessage = getStringF($r('app.string.ebook_overwrite_msg'), existing.partName, existing.unitName)

      Toast.showAlert({
        title           : $r('app.string.ebook_overwrite_confirm_title'),
        message         : overwriteMessage,
        secondaryButton : { value: $r('app.string.confirm_btn_cancel'), action: () => {} },
        primaryButton   : {
          value  : $r('app.string.ebook_overwrite_btn'),
          action : () => { void this.performSave(finalDetail) }
        }
      })
      return
    }

    await this.performSave(finalDetail)
  }

  // 真正把词条写入目标 EBook。
  private async performSave(detail: WordDetail): Promise<void> {

    // 访问 WordDbAccess（内部成功后会 `refreshBookCounts`，与 iOS `WordManager.insertWordDetail(_:intoTextDbAt:)` 一致）
    const ok = await WordDbAccess.insertWordDetail(detail, this.textDbPath)

    if (!ok) {
      Toast.showMessage(getString($r('app.string.ebook_add_failed')))
      return
    }

    const titleEnShown = detail.titleEn ?? ''
    Toast.showMessage(getStringF($r('app.string.ebook_added'), titleEnShown))

    // 每书独立 learnDb；加词后不须清空 Online 表
    WordUserDbAccess.shared.refreshDb()
    void SearchManager.shared.refreshData()
    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)

    // 成功路径不调用 `closeSelf()`：嵌套 `bindSheet` 下先子 `closeSelf` 再 `@Event` 易导致外层只剩纯色底。由父在 `onAddSucceed` 关内层状态并关外层；`await` 后下一任务再派发，避免事件未触达父组件
    setTimeout(() => {
      this.onAddSucceed()
    }, 0)
  }

  // 组合原始词条与当前选择，生成最终待保存的 WordDetail。
  private async buildFinalDetail(): Promise<WordDetail> {

    const detail: WordDetail = this.copyWordDetail(this.detail)
    const partIsNew          = this.isUsingNewPart()
    const unitIsNew          = this.isUsingNewUnit()
    const partId             = partIsNew ? this.maxPartId + 1 : (this.parts[this.selectedPartIndex]?.partId ?? this.maxPartId + 1)
    const unitId             = unitIsNew ? this.maxUnitId + 1 : (this.units[this.selectedUnitIndex]?.unitId ?? this.maxUnitId + 1)
    const partNameRaw        = this.newPartName.trim()
    const unitNameRaw        = this.newUnitName.trim()
    const partName           = partIsNew ? (partNameRaw.length > 0 ? partNameRaw : `Part${partId}`) : (this.parts[this.selectedPartIndex]?.partName ?? `Part${partId}`)
    const unitName           = unitIsNew ? (unitNameRaw.length > 0 ? unitNameRaw : `Unit${unitId}`) : (this.units[this.selectedUnitIndex]?.unitName ?? `Unit${unitId}`)
    // 访问 WordDbAccess
    const unitNo             = (await WordDbAccess.getWordsCountByUnitId(unitId, this.textDbPath)) + 1

    detail.partId            = partId
    detail.partName          = partName
    detail.unitId            = unitId
    detail.unitName          = unitName
    detail.unitNo            = unitNo

    return detail
  }

  // 复制词条对象（避免使用受限标准库 `Object.assign`）
  // 参数 src：源词条
  // 返回值：新词条副本
  private copyWordDetail(src: WordDetail): WordDetail {

    const detail = new WordDetail()

    detail.idx          = src.idx
    detail.partId       = src.partId
    detail.partName     = src.partName
    detail.unitId       = src.unitId
    detail.unitNo       = src.unitNo
    detail.unitName     = src.unitName
    detail.titleEn      = src.titleEn
    detail.titleCn1     = src.titleCn1
    detail.titleCn2     = src.titleCn2
    detail.titleCn3     = src.titleCn3
    detail.pronEn       = src.pronEn
    detail.pronUs       = src.pronUs
    detail.exampleEn1   = src.exampleEn1
    detail.exampleCn1   = src.exampleCn1
    detail.wordImage    = src.wordImage
    detail.wordChange   = src.wordChange
    detail.synWords     = src.synWords
    detail.asynWords    = src.asynWords
    detail.exampleEn2   = src.exampleEn2
    detail.exampleCn2   = src.exampleCn2
    detail.exampleEn3   = src.exampleEn3
    detail.exampleCn3   = src.exampleCn3
    detail.usedPhrase   = src.usedPhrase
    detail.en2En        = src.en2En
    detail.discriminate = src.discriminate
    detail.root         = src.root
    detail.cognates     = src.cognates

    return detail
  }
}
