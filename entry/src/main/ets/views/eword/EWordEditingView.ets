//
//  EWordEditingView.ets
//  WordTree
//
//  编辑单个字段：保存写 EBook Word 表或 learnDb EWordOverride；CBook/在线词可「恢复」。
//

import { NavBarView, NavButtonItem } from '../../app/views/NavBarView'
import { CSoundHelper } from '../../common/components/Sounds/Cloud/Manager/CSoundHelper'
import { SimpleEventBus } from '../../common/components/eventbus/SimpleEventBus'
import { BookManager, BookManagerNotification } from '../../models/datas/book/BookManager'
import { SearchManager } from '../../models/datas/model/SearchManager'
import { WordDbAccess } from '../../models/datas/word/WordDbAccess'
import { EBookManager } from '../../models/managers/ebook/EBookManager'
import { EWordEditManager, EWordEditableField } from '../../models/managers/eword/EWordEditManager'
import { EWordManager } from '../../models/managers/eword/EWordManager'
import { MemberManager } from '../../models/managers/member/MemberManager'

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

  // 右上角按钮：按 iOS 规则组合「恢复」「保存」
  get rightButtons(): NavButtonItem[] {
    const items: NavButtonItem[] = []

    if (this.canShowRestore) {
      items.push({
        text   : $r('app.string.eword_restore'),
        onClick: () => {
          void this.restoreAndComplete()
        }
      })
    }

    items.push({
      text   : $r('app.string.eword_save'),
      onClick: () => {
        void this.saveAndComplete()
      }
    })

    return items
  }

  build() {
    Column({ space: 16 }) {
      // 顶栏：使用与 EBookImportView 相同的 NavBarView 结构
      NavBarView({
        title       : this.titleEn,
        leftButtons : [{
          text   : $r('app.string.online_search_btn_cancel'),
          onClick: () => {
            this.onCancel()
          }
        }],
        rightButtons: this.rightButtons
      })

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
    const fieldKey = EWordEditManager.fieldKey(this.field)
    const book     = BookManager.shared.currentBook
    const textDb   = book?.textDb ?? ''
    const isExampleField =
      this.field === EWordEditableField.exampleEn1 ||
      this.field === EWordEditableField.exampleEn2 ||
      this.field === EWordEditableField.exampleEn3
    let succeed = false

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

      // 调用：按 iOS saveAndComplete 逻辑，将可写字段直接写回 EBook Word 表。
      succeed = await WordDbAccess.updateWordField(path, this.titleEn, fieldKey, this.editText)
    } else {
      // 调用：按 iOS saveAndComplete 逻辑，将不可直写 Word 表的字段保存到 EWordOverride。
      succeed = await EWordManager.shared.saveOverride(this.titleEn, fieldKey, this.editText)
    }

    // 若保存失败，则不继续触发刷新与关闭，避免 UI 误判为保存成功。
    if (!succeed) {
      return
    }

    // 若修改的是例句英文，则与 iOS 一样在保存成功后触发云发音下载/生成。
    if (
      isExampleField &&
      MemberManager.shared.checkExamplePronUsable(false, false) &&
      this.editText.length > 0
    ) {
      // 调用：优先尝试下载缓存，若缓存不存在则继续走云端生成。
      void CSoundHelper.startDownloadOrGenerateSound(this.editText)
    }

    // 保存后先把内存中的同词对象同步到最新值，避免 Detail/Quiz 仍持有旧引用。
    await SearchManager.shared.syncWordMemoryByTitleEn(this.titleEn)

    // 调用：通知详情页刷新（对齐 iOS currentBookUpdated）
    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)

    this.onComplete()
  }

  /**
   * 恢复：删除当前字段覆盖并退出。
   * @returns Promise<void>
   */
  async restoreAndComplete(): Promise<void> {
    const fieldKey = EWordEditManager.fieldKey(this.field)

    // 调用：删除单字段覆盖（与 iOS restoreAndComplete 一致）。
    const succeed = await EWordManager.shared.deleteOverride(this.titleEn, fieldKey)

    // 若删除覆盖失败，则不继续触发刷新与关闭，避免 UI 误判为恢复成功。
    if (!succeed) {
      return
    }

    // 恢复后同样同步内存对象，确保移除覆盖后的原值立即生效。
    await SearchManager.shared.syncWordMemoryByTitleEn(this.titleEn)

    // 调用：通知详情页刷新（对齐 iOS currentBookUpdated）
    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)

    this.onComplete()
  }
}
