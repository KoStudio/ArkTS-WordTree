//
//  EWordEditingView.ets
//  WordTree
//
//  编辑单个 EWord 字段（与 iOS `EWordEditingView.swift` 行为一致：保存写 EBook Word 表或 learnDb EWordOverride）。
//

import { SimpleEventBus } from '../../common/components/eventbus/SimpleEventBus'
import { BookManager, BookManagerNotification } from '../../models/datas/book/BookManager'
import { EBookManager } from '../../models/managers/ebook/EBookManager'
import { EWordEditManager, EWordEditableField } from '../../models/managers/eword/EWordEditManager'
import { EWordManager } from '../../models/managers/eword/EWordManager'
import { WordDbAccess } from '../../models/datas/word/WordDbAccess'

@ComponentV2
export struct EWordEditingView {

  @Param titleEn      : string              = ''
  @Param field        : EWordEditableField  = EWordEditableField.pronUs
  @Param initialText  : string              = ''
  @Param isEBook      : boolean             = false
  @Param isOnlineWord : boolean             = false
  @Event onCancel     : () => void          = () => {}
  @Event onComplete   : () => void          = () => {}

  @Local editText                    : string  = ''     // 编辑中的文本
  @Local hasOverrideForCurrentField   : boolean = false  // 当前字段是否已有 Override（决定是否显示「恢复」）

  // 在线词或 CBook，且该字段已有 Override 时显示「恢复」
  get canShowRestore(): boolean {
    return (this.isOnlineWord || !this.isEBook) && this.hasOverrideForCurrentField
  }

  // 进入 sheet：同步初始文本并查询是否已有覆盖
  aboutToAppear(): void {
    this.editText = this.initialText

    void this.refreshHasOverride()
  }

  // 读取当前字段在 EWordOverride 中是否已有覆盖（控制「恢复」按钮）
  async refreshHasOverride(): Promise<void> {
    const m   = await EWordManager.shared.loadOverrides(this.titleEn)
    const fk  = EWordEditManager.fieldKey(this.field)
    const val = m[fk]

    this.hasOverrideForCurrentField = val !== undefined && val !== null
  }

  build() {
    Column({ space: 16 }) {

      Row() {
        Button() {
          Text($r('app.string.online_search_btn_cancel'))
            .fontSize(16)
            .fontColor($r('app.color.color_nav_tint'))
        }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.onCancel()
          })

        Blank().layoutWeight(1)

        // 仅可恢复场景展示「恢复」按钮
        if (this.canShowRestore) {
          Button() {
            Text($r('app.string.eword_restore'))
              .fontSize(16)
              .fontColor($r('app.color.color_nav_tint'))
          }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              void this.restoreAndComplete()
            })
        }

        Button() {
          Text($r('app.string.eword_save'))
            .fontSize(16)
            .fontColor($r('app.color.color_nav_tint'))
        }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            void this.saveAndComplete()
          })
      }
        .width('100%')
        .padding({ left: 8, right: 8, top: 8 })

      Text(EWordEditManager.displayName(this.field))
        .fontSize(14)
        .fontColor($r('app.color.color_list_item_subtitle'))
        .width('100%')
        .padding({ left: 16, right: 16 })

      TextArea({ text: this.editText })
        .height(200)
        .margin({ left: 16, right: 16 })
        .padding(12)
        .backgroundColor($r('app.color.color_obscure'))
        .borderRadius(8)
        .border({ width: 1, color: $r('app.color.colorPrimary') })
        // onChange：将输入同步到状态，供保存时使用
        .onChange((v: string) => {
          this.editText = v
        })

      Blank().layoutWeight(1)
    }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .backgroundColor($r('app.color.color_background'))
  }

  // 保存当前编辑内容并结束（写 EBook Word 表或 learnDb Override，并广播 currentBookUpdated）
  async saveAndComplete(): Promise<void> {
    const fk   = EWordEditManager.fieldKey(this.field)
    const book = BookManager.shared.currentBook
    const td   = book?.textDb ?? ''
    const canWriteEbook =
      !this.isOnlineWord &&
      this.isEBook &&
      EWordEditManager.existsInWordTable(this.field) &&
      book !== null &&
      book.isEBook === true &&
      td.length > 0

    // EBook 内词且字段属于 Word 表：写 textDb；否则写 learnDb Override
    if (canWriteEbook) {
      const path = EBookManager.textDbPath(td)

      await WordDbAccess.updateWordField(path, this.titleEn, fk, this.editText)
    } else {
      await EWordManager.shared.saveOverride(this.titleEn, fk, this.editText)
    }

    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)

    this.onComplete()
  }

  // 删除当前字段的 Override 并结束（与 iOS restore 一致）
  async restoreAndComplete(): Promise<void> {
    const fk = EWordEditManager.fieldKey(this.field)

    await EWordManager.shared.deleteOverride(this.titleEn, fk)

    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)

    this.onComplete()
  }
}
