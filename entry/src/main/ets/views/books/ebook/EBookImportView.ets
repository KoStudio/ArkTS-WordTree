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
import { FileUtility } from '../../../common/utils/FileUtility'
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
  /** 文档选择器返回的 URI（须用 fileIo 打开；不可当本地 path 直接 fs.access） */
  @Local pickedUri: string = ''
  @Local pickedFileName: string = ''
  @Local message: string = ''

  build() {
    NavDestination() {

      Column() {
        NavBarView({
          title: $r('app.string.ebook_import_title'),
          leftButtons: [{
            text: $r('app.string.online_search_btn_cancel'),
            onClick: () => {
              NavPop()
            }
          }],
          rightButtons: [{
            text: $r('app.string.confirm_btn_import'),
            enabled: this.pickedUri.length > 0 && !this.busy,
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
            Text($r('app.string.ebook_import_pick_btn'))
              .fontSize(16)
              .fontColor(this.busy ? $r('app.color.color_black') : Color.White)
          }
            .width('100%')
            .height(44)
            .enabled(!this.busy)
            .backgroundColor(this.busy ? $r('app.color.color_gray_light') : $r('app.color.color_btn_bg'))
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

  // 从 URI 解析展示用文件名（去 query/fragment，与系统路径最后一段对齐）
  private fileNameHintFromUri(uri: string): string {

    let s = uri
    const qi = s.indexOf('?')

    // 分支：去掉 query
    if (qi >= 0) {
      s = s.substring(0, qi)
    }

    const hi = s.indexOf('#')

    // 分支：去掉 fragment
    if (hi >= 0) {
      s = s.substring(0, hi)
    }

    // 分支：file:// 前缀转为路径再取末段
    if (s.indexOf('file://') === 0) {
      s = s.substring('file://'.length)
    }

    const last = s.lastIndexOf('/')
    return last >= 0 ? s.substring(last + 1) : s
  }

  private async onPick(): Promise<void> {

    this.busy = true

    try {
      const ctx     = getContext(this) as common.UIAbilityContext
      const docPick = new picker.DocumentViewPicker(ctx)

      // 调用：与 iOS UTType(filenameExtension: "wte") 一致，仅可选 .wte
      const uris    = await docPick.select({
        maxSelectNumber   : 1,
        fileSuffixFilters : [`.${EBookExportImportManager.fileExtension}`]
      })

      if (uris === undefined || uris.length < 1) {
        this.busy = false
        return
      }

      const uri  = uris[0]
      const hint = this.fileNameHintFromUri(uri)

      // 分支：后缀校验（fileSuffixFilters 在部分系统上对自定义后缀仅弱提示，此处再挡一层）
      if (!hint.toLowerCase().endsWith(`.${EBookExportImportManager.fileExtension}`)) {
        this.busy = false
        this.message = getString($r('app.string.ebook_import_failed_msg'))
        return
      }

      this.pickedUri = uri
      this.pickedFileName = hint
      this.message = ''
      this.busy = false
    } catch (e) {
      this.busy = false
      this.message = `${e}`
    }
  }

  private async startImport(): Promise<void> {

    if (this.pickedUri.length < 1 || this.busy) {
      return
    }

    this.busy = true
    this.message = ''

    // 调用：将用户所选文件从 URI 复制到应用沙箱可读路径（与 iOS asCopy 一致），再执行 zip/sqlite 导入
    let tempPath = await FileUtility.copyToTempDir(this.pickedUri)

    // 分支：部分 URI 末段无 .wte 后缀时，复制为固定扩展名以满足 importEBookAtPath 校验
    if (tempPath !== null && tempPath.length > 0 && !tempPath.toLowerCase().endsWith(`.${EBookExportImportManager.fileExtension}`)) {

      const parent = FileUtility.deleteLastPathComponent(tempPath)
      const fixed  = FileUtility.appendPathComponent(parent, `ebook_import_${Date.now()}.${EBookExportImportManager.fileExtension}`)

      // 分支：重命名式复制成功则替换路径并删旧临时文件
      if (FileUtility.copyFile(tempPath, fixed)) {
        FileUtility.deleteFileAt(tempPath)
        tempPath = fixed
      }
    }

    if (tempPath === null || !FileUtility.isFileExistAt(tempPath)) {
      this.busy = false
      this.message = getString($r('app.string.ebook_import_failed_msg'))
      return
    }

    try {
      await EBookExportImportManager.shared.importEBookAtPath(tempPath,
        (ok: boolean, errMsg: string | null, newBook: Book | null) => {

          // 调用：导入流程结束即删除沙箱临时副本
          FileUtility.deleteFileAt(tempPath!)

          this.busy = false

          if (!ok) {
            this.message = errMsg ?? getString($r('app.string.ebook_import_failed_msg'))
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

      FileUtility.deleteFileAt(tempPath)
      this.busy = false
      this.message = `${e}`
    }
  }
}
