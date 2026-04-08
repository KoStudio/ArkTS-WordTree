//
//  EWordEditingView.ets
//  WordTree
//
//  编辑单个字段：保存写 EBook Word 表或 learnDb EWordOverride；CBook/在线词可「恢复」。
//

import { SimpleEventBus } from '../../common/components/eventbus/SimpleEventBus'
import { BookManager, BookManagerNotification } from '../../models/datas/book/BookManager'
import { WordDbAccess } from '../../models/datas/word/WordDbAccess'
import { EBookManager } from '../../models/managers/ebook/EBookManager'
import { EWordEditManager, EWordEditableField } from '../../models/managers/eword/EWordEditManager'
import { EWordManager } from '../../models/managers/eword/EWordManager'

@ComponentV2
export struct EWordEditingView {

  @Param titleEn      : string              = ''
  @Param field        : EWordEditableField  = EWordEditableField.pronUs
  @Param currentValue : string              = ''
  @Param isEBook      : boolean             = false
  @Param isOnlineWord : boolean             = false
  @Event onComplete   : () => void          = () => {}
  @Event onCancel     : () => void          = () => {}

  @Local editText                   : string  = ''     // 编辑区文本（与 iOS currentValue 对齐）
  @Local hasOverrideForCurrentField : boolean = false  // 当前字段是否已有覆盖（决定恢复按钮显隐）

  // 仅在可恢复且当前字段已有覆盖时展示「恢复」
  get canShowRestore(): boolean {
    return (this.isOnlineWord || !this.isEBook) && this.hasOverrideForCurrentField
  }

  // 页面出现：同步编辑初始值并检查覆盖状态
  aboutToAppear(): void {
    this.editText = this.currentValue

    void this.refreshHasOverrideForCurrentField()
  }

  // 读取当前字段覆盖状态
  async refreshHasOverrideForCurrentField(): Promise<void> {
    const fk = EWordEditManager.fieldKey(this.field)

    // 调用：读取该词的全部覆盖 map
    const map = await EWordManager.shared.loadOverrides(this.titleEn)

    this.hasOverrideForCurrentField = map[fk] !== undefined
  }

  build() {
    Column({ space: 16 }) {

      // 顶栏：取消 / 恢复 / 保存（配色对齐 iOS 导航栏）
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
        .padding({ left: 8, right: 8, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.colorPrimary'))

      Text(this.titleEn)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.color_white'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ left: 16, right: 16, bottom: 8 })
        .backgroundColor($r('app.color.colorPrimary'))

      Text(EWordEditManager.displayName(this.field))
        .fontSize(14)
        .fontColor($r('app.color.color_list_item_subtitle'))
        .width('100%')
        .padding({ left: 16, right: 16 })

      TextArea({ text: this.editText })
        .height(220)
        .margin({ left: 16, right: 16 })
        .padding(12)
        .backgroundColor($r('app.color.color_obscure'))
        .borderRadius(8)
        .border({ width: 1, color: $r('app.color.colorPrimary') })
        .fontColor($r('app.color.color_text'))
        // 调用：同步输入内容，保存时直接使用
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

  /**
   * 保存：在线词一律写 EWordOverride；EBook 且字段在 Word 表时写 textDb。
   * @returns Promise<void>
   */
  async saveAndComplete(): Promise<void> {
    const fk     = EWordEditManager.fieldKey(this.field)
    const book   = BookManager.shared.currentBook
    const textDb = book?.textDb ?? ''

    const canWriteWordTable =
      !this.isOnlineWord &&
      this.isEBook &&
      EWordEditManager.existsInWordTable(this.field) &&
      book !== null &&
      book.isEBook === true &&
      textDb.length > 0

    if (canWriteWordTable) {
      // 调用：EBook 字段写回 textDb Word 表
      const path = EBookManager.textDbPath(textDb)

      await WordDbAccess.updateWordField(path, this.titleEn, fk, this.editText)
    } else {
      // 调用：写入 learnDb EWordOverride
      await EWordManager.shared.saveOverride(this.titleEn, fk, this.editText)
    }

    // 调用：通知详情页刷新（对齐 iOS currentBookUpdated）
    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)

    this.onComplete()
  }

  /**
   * 恢复：删除当前字段覆盖并退出。
   * @returns Promise<void>
   */
  async restoreAndComplete(): Promise<void> {
    const fk = EWordEditManager.fieldKey(this.field)

    // 调用：删除单字段覆盖
    await EWordManager.shared.deleteOverride(this.titleEn, fk)

    // 调用：通知详情页刷新（对齐 iOS currentBookUpdated）
    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)

    this.onComplete()
  }
}
