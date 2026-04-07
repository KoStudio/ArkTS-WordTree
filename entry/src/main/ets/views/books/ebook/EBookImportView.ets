//
// EBookImportView.ets
// 与 iOS `EBookImportView.swift` 对齐：选择 .wte 并导入为本地 EBook。
//

import { common } from '@kit.AbilityKit'
import { picker } from '@kit.CoreFileKit'
import { NavPop, NavTo } from '../../../pages/NavPathManager'
import { EBookExportImportManager } from '../../../models/managers/ebook/EBookExportImportManager'
import { Book } from '../../../models/datas/book/Book'
import { Toast } from '../../../common/utils/Toast'
import { getString, getStringF } from '../../../common/utils/ResourceUtils'
import { EBookHelpViewConfig } from './EBookHelpView'
import { NavBarView } from '../../../app/views/NavBarView'

export namespace EBookImportViewConfig {

  export const NavKey: string = 'EBookImportView_show'

  export function open(): void {

    NavTo(EBookImportViewConfig.NavKey, undefined, true, true)
  }
}

@ComponentV2
export struct EBookImportView {

  @Local busy: boolean = false
  @Local pickedPath: string = ''
  @Local pickedFileName: string = ''
  @Local message: string = ''

  build() {
    NavDestination() {

      Column() {
        NavBarView({
          title: $r('app.string.ebook_import_nav_title'),
          leftButtons: [{
            text: $r('app.string.online_search_btn_cancel'),
            onClick: () => {
              NavPop()
            }
          }],
          rightButtons: [{
            text: $r('app.string.confirm_btn_import'),
            onClick: () => {
              void this.startImport()
            }
          }]
        })

        Column({ space: 16 }) {
          Text($r('app.string.ebook_import_hint'))
            .fontSize(15)
            .fontColor($r('app.color.color_detail'))
            .textAlign(TextAlign.Center)

          Button() {
            Text($r('app.string.ebook_import_choose_btn'))
              .fontSize(16)
              .fontColor(Color.White)
          }
            .width('100%')
            .height(44)
            .enabled(!this.busy)
            .backgroundColor($r('app.color.color_btn_bg'))
            .borderRadius(8)
            .onClick(() => {
              void this.onPick()
            })

          Text(this.pickedFileName.length > 0 ? this.pickedFileName : '')
            .fontSize(13)
            .fontColor($r('app.color.color_detail'))
            .textAlign(TextAlign.Center)
            .maxLines(2)

          Divider()
            .color($r('app.color.color_obscure'))
            .margin({ top: 4, bottom: 4 })

          Button() {
            Text($r('app.string.ebook_import_help_link'))
              .fontSize(14)
              .fontColor($r('app.color.color_nav_bg'))
              .decoration({ type: TextDecorationType.Underline })
          }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              EBookHelpViewConfig.open()
            })
        }
          .width('88%')
          .constraintSize({ maxWidth: 420 })
          .padding({ top: 20, bottom: 20, left: 16, right: 16 })
          .margin({ top: 40 })
          .backgroundColor($r('app.color.color_white'))
          .borderRadius(12)
          .shadow({ radius: 8, color: '#26000000', offsetX: 0, offsetY: 4 })

        if (this.message.length > 0) {
          Text(this.message)
            .fontSize(13)
            .fontColor(Color.Red)
            .textAlign(TextAlign.Center)
            .margin({ top: 12, left: 24, right: 24 })
        }

        Blank()
      }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.color_background'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
      .hideTitleBar(true)
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
      const pathNodes = path.split('/')
      const name = pathNodes.length > 0 ? pathNodes[pathNodes.length - 1] : path
      this.pickedPath = path
      this.pickedFileName = name
      this.message = ''
      this.busy = false
    } catch (e) {
      this.busy = false
      this.message = `${e}`
    }
  }

  private async startImport(): Promise<void> {
    if (this.pickedPath.length < 1 || this.busy) {
      return
    }

    this.busy = true
    this.message = ''

    try {
      await EBookExportImportManager.shared.importEBookAtPath(this.pickedPath,
        (ok: boolean, errMsg: string | null, newBook: Book | null) => {

          this.busy = false

          if (!ok) {
            this.message = errMsg ?? getString($r('app.string.ebook_import_failed_msg'))
            return
          }

          if (newBook !== null) {
            EBookExportImportManager.applyImportSuccess(newBook)

            const raw     = (newBook.bookName ?? '').trim()
            const display = raw.length < 1 ? '词汇本' : raw

            Toast.showMessage(getStringF($r('app.string.ebook_import_success_msg'), display))
          }

          NavPop()
        })
    } catch (e) {
      this.busy = false
      this.message = `${e}`
    }
  }
}
