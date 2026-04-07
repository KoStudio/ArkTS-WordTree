//
// CreateEBookView.ets
// WordTree
//
// 简单的 EBook 创建输入界面，通过 sheet 弹出，采用与 EBookImportView 一致的卡片风格。
//

import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { Toast } from '../../../common/utils/Toast'
import { getString } from '../../../common/utils/ResourceUtils'
import { BookManagerNotification } from '../../../models/datas/book/BookManager'
import { EBookManager } from '../../../models/managers/ebook/EBookManager'
import { MemberManager } from '../../../models/managers/member/MemberManager'
import { NavPop, NavTo } from '../../../pages/NavPathManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'

export namespace CreateEBookViewConfig {

  export const NavKey: string = 'CreateEBookView_show'

  export function open(): void {
    NavTo(CreateEBookViewConfig.NavKey, undefined, true, true)
  }
}

@ComponentV2
export struct CreateEBookView {

  @Local private bookName       : string   = ''     // 输入的书名
  @Local private isSaving       : boolean  = false  // 保存中状态
  @Local private maxNameLength  : number   = 20     // 书名最大长度

  // 构建新建词汇本页面：名称输入与保存按钮。
  build() {
    NavDestination() {
      Stack() {
        Column({ space: 16 }) {
          Blank().height(40)

          Column({ space: 12 }) {
            Text($r('app.string.ebook_name_section'))
              .fontSize(13)
              .fontColor($r('app.color.color_list_item_subtitle'))
              .width('100%')
              .textAlign(TextAlign.Start)

            TextInput({ text: $$this.bookName, placeholder: $r('app.string.ebook_name_placeholder') })
              .fontSize(16)
              .height(40)
              .backgroundColor($r('app.color.color_obscure'))
              .borderRadius(6)
              .onChange((value: string) => {
                // 分支：输入超长时截断
                if (value.length > this.maxNameLength) {
                  this.bookName = value.substring(0, this.maxNameLength)
                }
              })
          }
            .padding({ left: 16, right: 16, top: 20, bottom: 20 })
            .width('90%')
            .backgroundColor($r('app.color.color_background'))
            .borderRadius(12)

          Button() {
            Text($r('app.string.confirm_btn_yes')).fontColor(Color.White)
          }
            .width('90%')
            .height(40)
            .enabled(!this.isSaving)
            .backgroundColor($r('app.color.colorPrimary'))
            .onClick(() => {
              void this.save()
            })

          Blank().layoutWeight(1)
        }
          .width('100%')
          .height('100%')
      }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_background'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
      .title(buildNavTitle($r('app.string.ebook_create_nav_title')))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
  }

  // 执行保存逻辑：校验输入、会员权限、创建本地 EBook
  private async save(): Promise<void> {

    // 调用：输入去空白
    const trimmed = this.bookName.trim()

    // 分支：空名称不处理
    if (trimmed.length < 1) {
      return
    }

    // 分支：会员上限不通过时直接返回
    if (!MemberManager.shared.checkEBookCreatable(true, true)) {
      return
    }

    this.isSaving = true

    // 调用：创建本地 EBook
    // 调用：创建本地 EBook
    const book = await EBookManager.shared.createLocalEBook(trimmed, null)

    this.isSaving = false

    // 分支：创建失败时提示
    if (book === null) {
      Toast.showMessage(getString($r('app.string.ebook_save_failed')))
      return
    }

    // 调用：通知列表刷新
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)

    NavPop()
  }
}
