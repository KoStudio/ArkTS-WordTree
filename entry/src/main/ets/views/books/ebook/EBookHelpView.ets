//
// EBookHelpView.ets
// WordTree
//
// 导入/导出词汇本帮助页（本地 HTML）。
//

import webview from '@ohos.web.webview'
import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { LanguageManager } from '../../../common/components/Language/LanguageManager'
import { AppLanguage } from '../../../common/components/Language/AppLanguage'
import { NavTo } from '../../../pages/NavPathManager'

export namespace EBookHelpViewConfig {

  export const NavKey: string = 'EBookHelpView_show'

  export function open(): void {
    NavTo(EBookHelpViewConfig.NavKey, undefined, true, true)
  }
}

@ComponentV2
export struct EBookHelpView {

  @Local private webController : webview.WebviewController = new webview.WebviewController()  // Web 控制器

  // 根据当前语言返回帮助页本地 HTML 地址。
  private helpUrl(): string {
    const lang = LanguageManager.getCurrentLanguage()
    // 分支：繁体中文使用 zh-Hant 资源
    if (lang === AppLanguage.Traditional) {
      return 'resource://rawfile/html/EBookImportExportHelp_zh-Hant.html'
    }
    // 分支：其余语言回退简体资源
    return 'resource://rawfile/html/EBookImportExportHelp.html'
  }

  // 构建帮助页：顶栏 + Web 内容。
  build() {
    NavDestination() {
      Column() {
        // 调用：加载本地帮助 html
        Web({
          src        : this.helpUrl(),
          controller : this.webController
        })
          .width('100%')
          .height('100%')
      }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.color_background'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
      .title(buildNavTitle($r('app.string.ebook_import_help_link')))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
  }
}
