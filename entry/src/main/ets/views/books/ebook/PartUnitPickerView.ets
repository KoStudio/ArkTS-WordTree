//
// PartUnitPickerView.ets
// WordTree
//
// 选择 Part/Unit 后，直接把结果保存到目标 EBook。
// 这个页面不再依赖外部 dataSource，而是根据传入的 book 自己读取目标 textDb。
//

import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { buildStandardMenu } from '../../../app/constants/AppFunctions'
import { getString, getStringF } from '../../../common/utils/ResourceUtils'
import { Toast } from '../../../common/utils/Toast'
import { Book } from '../../../models/datas/book/Book'
import { BookManager, BookManagerNotification } from '../../../models/datas/book/BookManager'
import { SearchManager } from '../../../models/datas/model/SearchManager'
import { WordUserDbAccess } from '../../../models/datas/myData/WordUserDbAccess'
import { WordDetail } from '../../../models/datas/word/WordDetail'
import { EBookManager } from '../../../models/managers/ebook/EBookManager'
import { NavPop, NavTo } from '../../../pages/NavPathManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { EBookPartItem, EBookPartUnitDbHelper, EBookUnitItem } from './EBookPartUnitDbHelper'

export namespace PartUnitPickerViewConfig {

  export const NavKey: string = 'PartUnitPickerView_show'

  export interface Param {
    detail: WordDetail
    bookId: number
  }

  export function open(param: Param): void {
    NavTo(PartUnitPickerViewConfig.NavKey, param, true, true)
  }
}

@ComponentV2
export struct PartUnitPickerView {

  @Param @Require detail: WordDetail
  @Param @Require bookId: number

  @Local private parts             : EBookPartItem[] = []
  @Local private units             : EBookUnitItem[] = []
  @Local private selectedPartIndex : number          = 0
  @Local private selectedUnitIndex : number          = 0
  @Local private newPartName       : string          = ''
  @Local private newUnitName       : string          = ''
  @Local private maxPartId         : number          = 0
  @Local private maxUnitId         : number          = 0
  @Local private loading           : boolean         = true

  private readonly maxPartNameLength: number = 10
  private readonly maxUnitNameLength: number = 20

  private get targetBook(): Book | null {
    return BookManager.shared.books.find((it: Book) => it.bookId === this.bookId) ?? null
  }

  private get textDbPath(): string {
    const textDb = this.targetBook?.textDb ?? ''
    return EBookManager.textDbPath(textDb)
  }

  aboutToAppear(): void {
    void this.loadInitialData()
  }

  build() {
    NavDestination() {
      if (this.loading) {
        Column() { LoadingProgress() }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        List() {
          ListItemGroup({ header: this.sectionHeader($r('app.string.ebook_part_header')) }) {
            ForEach(this.parts, (part: EBookPartItem, index: number) => {
              ListItem() { this.partRow(part, index) }
            }, (part: EBookPartItem) => `p_${part.partId}`)
            ListItem() { this.newPartRow() }
          }

          ListItemGroup({ header: this.sectionHeader($r('app.string.ebook_unit_header')) }) {
            ForEach(this.units, (unit: EBookUnitItem, index: number) => {
              ListItem() { this.unitRow(unit, index) }
            }, (unit: EBookUnitItem) => `u_${unit.unitId}`)
            ListItem() { this.newUnitRow() }
          }
        }
          .width('100%')
          .height('100%')
      }
    }
      .title(buildNavTitle($r('app.string.ebook_save_to_nav_title')))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
      .menus(buildStandardMenu(this.buildMenuItems()))
  }

  @Builder
  private sectionHeader(title: ResourceStr) {
    Text(title)
      .fontSize(13)
      .fontColor($r('app.color.color_list_item_subtitle'))
      .padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private partRow(part: EBookPartItem, index: number) {
    Row() {
      Text(part.partName).fontSize(16)
      Blank().layoutWeight(1)
      if (this.newPartName.trim().length < 1 && this.selectedPartIndex === index) {
        Text('✓').fontSize(16).fontColor($r('app.color.colorPrimary'))
      }
    }
      .width('100%')
      .padding(12)
      .onClick(() => {
        // 分支：选择已有 Part 时清空新 Part 输入
        this.newPartName = ''
        this.selectedPartIndex = index
        void this.reloadUnitsForSelectedPart()
      })
  }

  @Builder
  private unitRow(unit: EBookUnitItem, index: number) {
    Row() {
      Text(unit.unitName).fontSize(16)
      Blank().layoutWeight(1)
      if (this.newUnitName.trim().length < 1 && this.selectedUnitIndex === index) {
        Text('✓').fontSize(16).fontColor($r('app.color.colorPrimary'))
      }
    }
      .width('100%')
      .padding(12)
      .onClick(() => {
        // 分支：选择已有 Unit 时清空新 Unit 输入
        this.newUnitName = ''
        this.selectedUnitIndex = index
      })
  }

  @Builder
  private newPartRow() {
    Row() {
      TextInput({
        text: $$this.newPartName,
        placeholder: `Part${this.maxPartId + 1}`
      })
        .height(36)
        .backgroundColor($r('app.color.color_obscure'))
        .onChange((value: string) => {
          if (value.length > this.maxPartNameLength) {
            this.newPartName = value.substring(0, this.maxPartNameLength)
          }
        })
      Blank().layoutWeight(1)
      if (this.newPartName.trim().length > 0 || this.parts.length < 1) {
        Text('✓').fontSize(16).fontColor($r('app.color.colorPrimary'))
      }
    }
      .width('100%')
      .padding(12)
  }

  @Builder
  private newUnitRow() {
    Row() {
      TextInput({
        text: $$this.newUnitName,
        placeholder: `Unit${this.maxUnitId + 1}`
      })
        .height(36)
        .backgroundColor($r('app.color.color_obscure'))
        .onChange((value: string) => {
          if (value.length > this.maxUnitNameLength) {
            this.newUnitName = value.substring(0, this.maxUnitNameLength)
          }
        })
      Blank().layoutWeight(1)
      if (this.newUnitName.trim().length > 0 || this.units.length < 1 || this.isUsingNewPart()) {
        Text('✓').fontSize(16).fontColor($r('app.color.colorPrimary'))
      }
    }
      .width('100%')
      .padding(12)
  }

  private buildMenuItems(): NavigationMenuItem[] {
    return [
      {
        value  : getString($r('app.string.ebook_add')),
        action : () => {
          void this.saveSelectedDetail()
        }
      }
    ]
  }

  private isUsingNewPart(): boolean {
    return this.newPartName.trim().length > 0 || this.parts.length < 1
  }

  private isUsingNewUnit(): boolean {
    return this.newUnitName.trim().length > 0 || this.units.length < 1 || this.isUsingNewPart()
  }

  /**
   * 初始加载目标书的 Part/Unit 列表，并设置默认选中项。
   */
  private async loadInitialData(): Promise<void> {

    this.loading   = true
    this.maxPartId = await EBookPartUnitDbHelper.getMaxPartId(this.textDbPath)
    this.maxUnitId = await EBookPartUnitDbHelper.getMaxUnitId(this.textDbPath)
    this.parts     = await EBookPartUnitDbHelper.getAllParts(this.textDbPath)

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

  /**
   * 根据当前 Part 选择刷新 Unit 列表。
   */
  private async reloadUnitsForSelectedPart(): Promise<void> {

    if (this.selectedPartIndex < 0 || this.selectedPartIndex >= this.parts.length) {
      this.units             = []
      this.selectedUnitIndex = 0
      return
    }

    const part = this.parts[this.selectedPartIndex]
    this.units = await EBookPartUnitDbHelper.getUnitsByPartId(this.textDbPath, part.partId)

    if (this.units.length < 1) {
      this.selectedUnitIndex = 0
      if (this.newUnitName.trim().length < 1) {
        this.newUnitName = `Unit${this.maxUnitId + 1}`
      }
    } else {
      this.selectedUnitIndex = this.units.length - 1
    }
  }

  /**
   * 执行保存前的查重确认，并决定是弹窗还是直接保存。
   */
  private async saveSelectedDetail(): Promise<void> {

    const finalDetail = await this.buildFinalDetail()
    const titleEn     = finalDetail.titleEn ?? ''

    if (titleEn.length < 1) {
      Toast.showMessage(getString($r('app.string.ebook_add_failed')))
      return
    }

    // 先查重，再保存，避免重复覆盖提示和实际写入目标不一致。
    const existing = await EBookPartUnitDbHelper.getWordPartUnitIfExists(this.textDbPath, titleEn)

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

  /**
   * 真正把词条写入目标 EBook。
   */
  private async performSave(detail: WordDetail): Promise<void> {

    const ok = await EBookPartUnitDbHelper.insertWordDetail(this.textDbPath, detail)

    if (!ok) {
      Toast.showMessage(getString($r('app.string.ebook_add_failed')))
      return
    }

    const titleEnShown = detail.titleEn ?? ''
    Toast.showMessage(getStringF($r('app.string.ebook_added'), titleEnShown))
    await BookManager.shared.refreshBookCounts(this.textDbPath)
    WordUserDbAccess.shared.resetWordTables()
    WordUserDbAccess.shared.refreshDb()
    void SearchManager.shared.refreshData()
    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
    NavPop()
  }

  /**
   * 组合原始词条与当前选择，生成最终待保存的 WordDetail。
   */
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
    const unitNo             = (await EBookPartUnitDbHelper.getWordsCountByUnitId(this.textDbPath, unitId)) + 1

    detail.partId            = partId
    detail.partName          = partName
    detail.unitId            = unitId
    detail.unitName          = unitName
    detail.unitNo            = unitNo

    return detail
  }

  /**
   * 复制词条对象（避免使用受限标准库 `Object.assign`）
   * @param src 源词条
   * @returns 新词条副本
   */
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
