//
// EBookImportView.ets
// 与 iOS `EBookImportView.swift` 对齐：选择 .wte 并导入为本地 EBook。
//

import { common } from '@kit.AbilityKit'
import { picker } from '@kit.CoreFileKit'
import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { NavPop, NavTo } from '../../../pages/NavPathManager'
import { EBookExportImportManager } from '../../../models/managers/ebook/EBookExportImportManager'
import { BookManager } from '../../../models/datas/book/BookManager'
import { Book } from '../../../models/datas/book/Book'
import { Toast } from '../../../common/utils/Toast'
import { getString, getStringF } from '../../../common/utils/ResourceUtils'
import { EBookHelpViewConfig } from './EBookHelpView'

export namespace EBookImportViewConfig {

  export const NavKey: string = 'EBookImportView_show'

  export function open(): void {

    NavTo(EBookImportViewConfig.NavKey, undefined, true, true)
  }
}

@ComponentV2
export struct EBookImportView {

  @Local busy: boolean = false

  build() {
    NavDestination() {

      Column({ space: 24 }) {

        Text($r('app.string.ebook_import_title'))
          .fontSize(18)
          .fontColor($r('app.color.color_text'))
          .margin({ top: 32 })

        Button() {

          Text(this.busy ? '…' : $r('app.string.ebook_import_pick_btn'))
            .fontColor(Color.White)
        }
          .width('80%')
          .padding(12)
          .enabled(!this.busy)
          .backgroundColor($r('app.color.colorPrimary'))
          .onClick(() => {
            void this.onPick()
          })

        Button() {
          Text($r('app.string.ebook_import_help_link'))
            .fontColor($r('app.color.colorPrimary'))
        }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            EBookHelpViewConfig.open()
          })
      }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.color_background'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
      .title(buildNavTitle($r('app.string.ebook_import_title')))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
  }

  private async onPick(): Promise<void> {

    this.busy = true

    try {
      const ctx     = getContext(this) as common.UIAbilityContext
      const docPick = new picker.DocumentViewPicker(ctx)
      const uris    = await docPick.select({ maxSelectNumber: 1 })

      if (uris === undefined || uris.length < 1) {
        this.busy = false
        return
      }

      const uri = uris[0]
      let path    = uri

      if (uri.indexOf('file://') === 0) {
        path = uri.substring('file://'.length)
      }

      await EBookExportImportManager.shared.importEBookAtPath(path,
        (ok: boolean, errMsg: string | null, newBook: Book | null) => {

          this.busy = false

          if (!ok) {
            Toast.showMessage(errMsg ?? getString($r('app.string.ebook_import_failed_msg')))
            return
          }

          if (newBook !== null) {
            EBookExportImportManager.applyImportSuccess(newBook)

            const raw     = (newBook.bookName ?? '').trim()
            const display = raw.length < 1 ? getString($r('app.string.ebook_default_book_name')) : raw

            Toast.showMessage(getStringF($r('app.string.ebook_import_success_fmt'), display))
          }

          NavPop()
        })
    } catch (e) {
      this.busy = false
      Toast.showMessage(`${e}`)
    }
  }
}
