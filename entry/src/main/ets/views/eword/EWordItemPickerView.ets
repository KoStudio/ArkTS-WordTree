//
//  EWordItemPickerView.ets
//  WordTree
//
//  从详情「编辑」进入：列出可编辑字段，点击进入 EWordEditingView（对齐 iOS EWordItemPickerView）。
//

import { NavBarView } from '../../app/views/NavBarView'
import { getString } from '../../common/utils/ResourceUtils'
import { Toast } from '../../common/utils/Toast'
import { SimpleEventBus } from '../../common/components/eventbus/SimpleEventBus'
import { BookManagerNotification } from '../../models/datas/book/BookManager'
import { SearchManager } from '../../models/datas/model/SearchManager'
import { CigenWord } from '../../models/datas/cigen/CigenWord'
import { CigenWordHelper } from '../../models/datas/cigen/CigenWordHelper'
import { Word } from '../../models/datas/word/Word'
import { WordDetail } from '../../models/datas/word/WordDetail'
import { EWordEditManager, EWordEditableField } from '../../models/managers/eword/EWordEditManager'
import { EWordManager } from '../../models/managers/eword/EWordManager'
import { EWordEditingView } from './EWordEditingView'

@ComponentV2
export struct EWordItemPickerView {

  @Param @Require originalDetail : WordDetail
  @Param isEBook                 : boolean = false
  @Param isOnlineWord            : boolean = false
  @Event onDismiss               : (changed: boolean) => void = (_changed: boolean) => {}

  @Local selectedField           : EWordEditableField | null = null  // 当前选中字段
  @Local showEditing             : boolean                   = false  // 内层编辑页 sheet 开关
  @Local overrideMap             : Record<string, string>    = {}     // 该词覆盖值 [fieldKey: value]
  @Local cigenWords              : CigenWord[] | null        = null   // root fallback 数据
  @Local sameRootDesc            : string | null             = null   // cognates fallback 数据

  // 当前编辑词 title（与 iOS currentTitleEn 对齐）
  get currentTitleEn(): string {
    return this.originalDetail.titleEn ?? ''
  }

  // 是否可全部恢复：仅在线词或非 EBook 且存在覆盖时可恢复
  get canRestoreAll(): boolean {
    return (this.isOnlineWord || !this.isEBook) && Object.keys(this.overrideMap).length > 0
  }

  // 进入页面后拉取覆盖与 fallback 文案
  aboutToAppear(): void {
    void this.refreshOverrides()
    void this.refreshFallbackTexts()
  }

  // 读取该词覆盖 map（与 iOS refreshOverrides 对齐）
  async refreshOverrides(): Promise<void> {
    this.overrideMap = await EWordManager.shared.loadOverrides(this.currentTitleEn)
  }

  // 读取 root / cognates fallback 文案（用于编辑初始值）
  async refreshFallbackTexts(): Promise<void> {
    const w = new Word()

    w.titleEn = this.currentTitleEn

    // 调用：查询 Cigen 列表（root fallback）
    this.cigenWords = await CigenWordHelper.getCigensByWord(w)

    // 调用：查询 sameRoot 文案（cognates fallback）
    this.sameRootDesc = await CigenWordHelper.getSameRootDescByWord(w)
  }

  // 计算当前字段编辑初始值（与 iOS originalDetail.value(for:) 语义一致）
  currentValueForField(field: EWordEditableField): string {
    return this.originalDetail.valueForField(
      field,
      CigenWordHelper.rootDisplayTextFromCigens(this.cigenWords),
      this.sameRootDesc ?? ''
    )
  }

  build() {
    Column() {
      // 顶栏：使用与 EBookImportView 相同的 NavBarView 结构
      NavBarView({
        title       : this.currentTitleEn,
        leftButtons : [{
          text   : $r('app.string.online_search_btn_cancel'),
          onClick: () => {
            this.onDismiss(false)
          }
        }],
        rightButtons: this.canRestoreAll ? [{
          text   : $r('app.string.eword_restore_all'),
          onClick: () => {
            this.showRestoreAllConfirmDialog()
          }
        }] : []
      })

      // 列表提示语：与 iOS section header 对齐
      Text($r('app.string.eword_picker_hint'))
        .fontSize(13)
        .fontColor($r('app.color.color_list_item_subtitle'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: 20, right: 20, top: 10, bottom: 6 })

      // 字段列表
      List() {
        ForEach(EWordEditManager.availableFields(), (field: EWordEditableField) => {
          ListItem() {
            this.buildFieldRow(field)
          }
          .backgroundColor(Color.Transparent)
        }, (field: EWordEditableField) => field as string)
      }
        .layoutWeight(1)
        .width('100%')
        .listDirection(Axis.Vertical)
        .scrollBar(BarState.Auto)
        .backgroundColor($r('app.color.color_obscure'))
    }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_obscure'))
      .bindSheet($$this.showEditing, this.buildEditingSheet(), {
        detents: [SheetSize.LARGE],
        preferType: SheetType.CENTER,
        backgroundColor: $r('app.color.colorPrimary'),
        showClose: false,
        onDisappear: () => {
          this.showEditing = false
          this.selectedField = null

          // 调用：刷新该词覆盖 map，确保列表中的“已修改”状态立即与 iOS 一致。
          void this.refreshOverrides()

          // 调用：刷新 root / cognates 的 fallback 文案，确保再次进入编辑页时初始值为最新展示值。
          void this.refreshFallbackTexts()
        }
      })
  }

  // 判断字段是否有覆盖值（供 @Builder 使用，避免在 @Builder 内写局部 const）
  hasOverrideForField(field: EWordEditableField): boolean {
    const fk = EWordEditManager.fieldKey(field)

    return this.overrideMap[fk] !== undefined
  }

  // 获取字段覆盖文本（供 @Builder 使用）
  overrideTextForField(field: EWordEditableField): string {
    const fk = EWordEditManager.fieldKey(field)

    return this.overrideMap[fk] ?? ''
  }

  // 列表行：标题 + 覆盖副标题 + 右箭头
  @Builder
  buildFieldRow(field: EWordEditableField) {
    Row() {
      Column({ space: 4 }) {
        Text(EWordEditManager.displayName(field))
          .fontSize(this.hasOverrideForField(field) ? 17 : 16)
          .fontWeight(this.hasOverrideForField(field) ? FontWeight.Medium : FontWeight.Regular)
          .fontColor($r('app.color.color_title'))

        if (this.hasOverrideForField(field) && this.overrideTextForField(field).length > 0) {
          Text(this.overrideTextForField(field))
            .fontSize(13)
            .fontColor($r('app.color.color_list_item_subtitle'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
      }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      Text('›')
        .fontSize(17)
        .fontColor($r('app.color.color_list_item_subtitle'))
    }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor($r('app.color.color_list_item_bg'))
      .borderRadius(10)
      .margin({ left: 12, right: 12, top: 4, bottom: 4 })
      .onClick(() => {
        this.selectedField = field
        this.showEditing   = true
      })
  }

  // 内层单字段编辑页（sheet）
  @Builder
  buildEditingSheet() {
    if (this.selectedField !== null) {
      EWordEditingView({
        titleEn      : this.currentTitleEn,
        field        : this.selectedField as EWordEditableField,
        currentValue : this.currentValueForField(this.selectedField as EWordEditableField),
        isEBook      : this.isEBook,
        isOnlineWord : this.isOnlineWord,
        onComplete   : () => {
          this.showEditing = false

          this.onDismiss(true)
        },
        onCancel     : () => {
          this.showEditing = false
        }
      })
    }
  }

  // 弹出「全部恢复」确认框
  showRestoreAllConfirmDialog(): void {
    Toast.showConfirm({
      title    : getString($r('app.string.eword_restore_all_confirm_title')),
      msg      : getString($r('app.string.eword_restore_all_confirm_msg')),
      btnNo    : getString($r('app.string.confirm_btn_cancel')),
      btnYes   : getString($r('app.string.eword_restore_all')),
      yesAction: () => {
        void this.restoreAllAndDismiss()
      }
    })
  }

  // 执行全部恢复并关闭当前 picker
  async restoreAllAndDismiss(): Promise<void> {
    if (this.currentTitleEn.length < 1) {
      return
    }

    // 调用：删除该词所有覆盖
    await EWordManager.shared.deleteAllOverrides(this.currentTitleEn)

    // 先同步内存对象（同词条旧引用立即更新），再统一发刷新通知。
    await SearchManager.shared.syncWordMemoryByTitleEn(this.currentTitleEn)

    // 调用：通知详情页刷新
    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)

    this.onDismiss(true)
  }
}
