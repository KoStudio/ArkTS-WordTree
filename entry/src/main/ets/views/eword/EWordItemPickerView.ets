//
//  EWordItemPickerView.ets
//  WordTree
//
//  从详情「编辑」进入：列出可编辑字段，与 iOS `EWordItemPickerView.swift` 一致。
//

import { NavBarView } from '../../app/views/NavBarView'
import { getString } from '../../common/utils/ResourceUtils'
import { Toast } from '../../common/utils/Toast'
import { SimpleEventBus } from '../../common/components/eventbus/SimpleEventBus'
import { NavPop, NavTo } from '../../pages/NavPathManager'
import { CigenWordHelper } from '../../models/datas/cigen/CigenWordHelper'
import { CigenWord } from '../../models/datas/cigen/CigenWord'
import { WordUser } from '../../models/datas/myData/WordUser'
import { WordDetail } from '../../models/datas/word/WordDetail'
import { BookManagerNotification } from '../../models/datas/book/BookManager'
import { EWordEditManager, EWordEditableField } from '../../models/managers/eword/EWordEditManager'
import { EWordManager } from '../../models/managers/eword/EWordManager'
import { EWordEditingView } from './EWordEditingView'

export namespace EWordItemPickerViewConfig {

  export const NavKey = 'EWordItemPickerView_show'

  export interface Param {
    titleEn      : string
    isEBook      : boolean
    isOnlineWord : boolean
  }

  // 打开 EWord 字段选择页（NavPath 由 Index 统一承载）
  export function open(p: Param): void {
    NavTo(NavKey, p)
  }
}

@ComponentV2
export struct EWordItemPickerView {

  @Param titleEn      : string  = ''
  @Param isEBook      : boolean = false
  @Param isOnlineWord : boolean = false

  @Local detail           : WordDetail | null               = null    // 当前词详情（已合并 Override）
  @Local cigenWords       : CigenWord[] | null              = null    // 词根 Cigen 列表（root 展示 fallback 用）
  @Local sameRootDesc     : string | null                   = null    // 同根词库文案（cognates fallback 用）
  @Local overrideMap      : Record<string, string>          = {}      // learnDb 中该词的 [fieldKey: value]
  @Local showEditSheet    : boolean                         = false   // 单字段编辑 sheet 开关
  @Local sheetField       : EWordEditableField | null       = null    // 当前正在编辑的字段
  @Local sheetInitialText  : string                          = ''      // 编辑框初始文本（合并展示值）

  // 在线词或非 EBook 且存在 Override 时可「全部恢复」
  get canRestoreAll(): boolean {
    const keys = Object.keys(this.overrideMap)

    return (this.isOnlineWord || !this.isEBook) && keys.length > 0
  }

  // 进入页面：异步拉取详情与 Override
  aboutToAppear(): void {
    void this.reloadPageData()
  }

  // 加载词条详情、词根/同根 fallback 文案并刷新 Override 映射
  async reloadPageData(): Promise<void> {
    const w = new WordUser()

    w.titleEn = this.titleEn

    this.detail       = await w.getWordDetail()
    this.cigenWords   = await CigenWordHelper.getCigensByWord(w)
    this.sameRootDesc = await CigenWordHelper.getSameRootDescByWord(w)

    await this.refreshOverrides()
  }

  // 从 learnDb 重新加载该 titleEn 的 Override 映射（用于列表副标题与「全部恢复」）
  async refreshOverrides(): Promise<void> {
    this.overrideMap = await EWordManager.shared.loadOverrides(this.titleEn)
  }

  // 判断指定字段是否存在 Override 记录
  private hasOverrideFor(field: EWordEditableField): boolean {
    const fk = EWordEditManager.fieldKey(field)
    const v  = this.overrideMap[fk]

    return v !== undefined && v !== null
  }

  // 取该字段在 Override 表中的展示字符串（列表副标题）
  private overrideTextFor(field: EWordEditableField): string {
    const fk = EWordEditManager.fieldKey(field)

    return this.overrideMap[fk] ?? ''
  }

  // 取合并 EWord 后的当前展示值，作为编辑页初始文本
  private valueForCurrentField(field: EWordEditableField): string {
    // 详情未就绪时无可编辑文本
    if (this.detail === null) {
      return ''
    }

    return this.detail.valueForField(
      field,
      CigenWordHelper.rootDisplayTextFromCigens(this.cigenWords),
      this.sameRootDesc ?? ''
    )
  }

  build() {
    NavDestination() {

      Column() {

        NavBarView({
          title       : this.titleEn,
          leftButtons : [{
            text   : $r('app.string.online_search_btn_cancel'),
            onClick: () => {
              NavPop()
            }
          }],
          rightButtons: this.canRestoreAll ? [{
            text   : $r('app.string.eword_restore_all'),
            onClick: () => {
              this.showRestoreAllDialog()
            }
          }] : []
        })
          .width('100%')

        Text($r('app.string.eword_picker_hint'))
          .fontSize(14)
          .fontColor($r('app.color.color_list_item_subtitle'))
          .width('100%')
          .textAlign(TextAlign.Start)
          .padding({ left: 20, right: 20, top: 12, bottom: 8 })

        List() {
          ForEach(EWordEditManager.availableFields(), (field: EWordEditableField) => {
            ListItem() {
              this.buildFieldRow(field)
            }
          }, (field: EWordEditableField) => field as string)
        }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Auto)
      }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_background'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
      .hideTitleBar(true)
      .backgroundColor($r('app.color.colorPrimary'))
      .bindSheet($$this.showEditSheet, this.buildEditSheet(), {
        detents     : [SheetSize.LARGE],
        preferType  : SheetType.CENTER,
        showClose   : false,
        onDisappear : () => {
          this.showEditSheet = false
          this.sheetField = null

          void this.refreshOverrides()
        }
      })
  }

  // 单行：字段名 + 可选覆盖摘要
  @Builder
  buildFieldRow(field: EWordEditableField) {
    Row() {
      Column({ space: 4 }) {
        Text(EWordEditManager.displayName(field))
          .fontSize(this.hasOverrideFor(field) ? 18 : 16)
          .fontWeight(this.hasOverrideFor(field) ? FontWeight.Medium : FontWeight.Normal)
          .fontColor($r('app.color.color_title'))

        // 与 iOS 一致：仅当有 Override 且非空时展示副标题
        if (this.hasOverrideFor(field) && this.overrideTextFor(field).length > 0) {
          Text(this.overrideTextFor(field))
            .fontSize(13)
            .fontColor($r('app.color.color_list_item_subtitle'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
      }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

      Text('›')
        .fontSize(18)
        .fontColor($r('app.color.color_list_item_subtitle'))
    }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .onClick(() => {
        // 详情未加载完成则不弹出编辑 sheet
        if (this.detail === null) {
          return
        }

        this.sheetInitialText = this.valueForCurrentField(field)
        this.sheetField       = field
        this.showEditSheet    = true
      })
  }

  // 子页：单字段编辑（sheet）
  @Builder
  buildEditSheet() {
    // sheet 内容依赖 sheetField；为空时不构建子组件
    if (this.sheetField !== null) {
      EWordEditingView({
        titleEn      : this.titleEn,
        field        : this.sheetField as EWordEditableField,
        initialText  : this.sheetInitialText,
        isEBook      : this.isEBook,
        isOnlineWord : this.isOnlineWord,
        onCancel     : () => {
          this.showEditSheet = false
          this.sheetField = null
        },
        onComplete   : () => {
          this.showEditSheet = false
          this.sheetField = null

          NavPop()
        }
      })
        .key(`${this.sheetField}_${this.sheetInitialText.length}`)
    }
  }

  // 弹出「全部恢复」二次确认
  showRestoreAllDialog(): void {
    Toast.showConfirm({
      title    : getString($r('app.string.eword_restore_all_confirm_title')),
      msg      : getString($r('app.string.eword_restore_all_confirm_msg')),
      btnNo    : getString($r('app.string.confirm_btn_cancel')),
      btnYes   : getString($r('app.string.eword_restore_all')),
      yesAction: () => {
        void this.confirmRestoreAll()
      }
    })
  }

  // 确认后删除该词全部 Override、广播刷新并关闭选择页
  async confirmRestoreAll(): Promise<void> {
    const t = this.titleEn

    if (!t || t.length < 1) {
      return
    }

    await EWordManager.shared.deleteAllOverrides(t)

    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)

    NavPop()
  }
}
