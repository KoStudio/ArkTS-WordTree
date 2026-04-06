//
// BookListView.ets
// 与 iOS `Root/Book2/BookListView.swift` 对齐（不含 LegacyBookMigrator）。
//

import { buildNavTitle } from '../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../app/constants/AppDefines'
import { NavTo } from '../../pages/NavPathManager'
import { SegmentButton, SegmentItem } from '../../app/views/SegmentButton'
import { CategoriesView } from './Sub/CategoriesView'
import { BooksLocalView } from './Sub/BooksLocalView'
import { buildStandardMenu, CustomNavigationMenuItem } from '../../app/constants/AppFunctions'
import { ItemOption, Toast } from '../../common/utils/Toast'
import { LanguageManager } from '../../common/components/Language/LanguageManager'
import { AppLanguage } from '../../common/components/Language/AppLanguage'
import { BookManager } from '../../models/datas/book/BookManager'
import { CBookManager } from '../../common/components/Sounds/Cloud/Download/CBook/CBookManager'
import { CBookListName } from '../../common/components/Sounds/Cloud/Download/CBook/CBookPath'
import { CategoryManager } from '../../models/datas/book/CategoryManager'
import { SimpleEventBus } from '../../common/components/eventbus/SimpleEventBus'
import { BookManagerNotification } from '../../models/datas/book/BookManager'

// 导航参数与路由名（与 NavigationTo 注册一致）
export namespace BookListViewConfig {

  export const NavKey: string = 'BookListView_show'

  // param：是否仅展示「所有词汇」分段（首次安装引导场景）
  export function open(param: Param): void {

    // 进入课本列表页
    NavTo(BookListViewConfig.NavKey, param, true)
  }

  export interface Param {

    isShowAllOnly ?: boolean
  }
}

@ComponentV2
export struct BookListView {

  // 首次安装等场景：仅显示「所有词汇」
  @Param isShowAllOnly: boolean = false

  @Local selectedIndex: number = 0

  aboutToAppear(): void {

    // 与 iOS `onAppear` 中 `isShowAllOnly` 时选中「全部课本」一致
    if (this.isShowAllOnly) {
      this.selectedIndex = 1
    }

    void this.loadData()
  }

  // 与 iOS `updateCBookListIfNeeds`：云端 BookList 检查成功后刷新分类并广播
  private async loadData(): Promise<void> {

    // 启动 BookList（CBookListName）增量检查；无网时 CBookManager 内会直接 return
    CBookManager.shared.startUpdateBookCheckIfNeeds(CBookListName, CBookListName, false, null,
      async (succeed: boolean, _msg: string | null) => {

        // 更新失败或无变更则不刷新「所有词汇」分类
        if (!succeed) {
          return
        }

        // 与 iOS `CategoryManager2.shared.reload()` 一致
        await CategoryManager.shared.reload()

        // 与 iOS `BookManager2.Notification.bookListUpdated` 一致
        SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
      })
  }

  build() {
    NavDestination() {

      Column() {

        // 常规入口：分段「我的词汇 | 所有词汇」
        if (!this.isShowAllOnly) {

          SegmentButton({
            items         : this.createSegmentItems(),
            selectedIndex : this.selectedIndex,
            totalWidth    : '100%',
            onSelect      : (index: number) => {
              this.handleSegmentChange(index)
            }
          })
            .margin(20)
        }

        Stack() {

          // 0：本地已下载课本；1：在线分类列表
          if (this.selectedIndex === 1) {
            CategoriesView()
          } else {
            BooksLocalView()
          }
        }
          .layoutWeight(1)
      }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
    }
      .title(buildNavTitle(this.getNavTitle()))
      .backButtonIcon(dNavBackIcon)
      .backgroundColor($r('app.color.colorPrimary'))
      .menus(buildStandardMenu(this.buildMenuItems()))
      .onBackPressed(() => {

        // 尚未选择任何课本时不允许直接返回主界面
        if (BookManager.shared.currentBook === null) {

          Toast.showMessage($r('app.string.main_msg_no_books'))
          return true
        }

        return false
      })
  }

  // 导航栏标题
  getNavTitle(): ResourceStr {
    return $r('app.string.nav_title_books')
  }

  // 「仅全部词汇」模式下右上角更多（简繁切换）
  buildMenuItems(): CustomNavigationMenuItem[] {

    if (!this.isShowAllOnly) {
      return []
    }

    return [
      {
        value  : 'more',
        icon   : $r('app.media.moreh'),
        isSvg  : true,
        action : () => {

          // 弹出语言切换
          this.actionShowLanguages()
        }
      } as CustomNavigationMenuItem
    ]
  }

  createSegmentItems(): SegmentItem[] {

    const items: SegmentItem[] = []

    // 与 iOS `BOOKS_TAB_TITLE_MYBOOKS`
    items.push({ title: $r('app.string.books_tab_title_mybooks'), isEnabled: true })

    // 与 iOS `BOOKS_TAB_TITLE_ALLBOOKS`
    items.push({ title: $r('app.string.books_tab_title_allbooks'), isEnabled: true })

    return items
  }

  handleSegmentChange(index: number): void {
    this.selectedIndex = index
  }

  // 简繁中文切换（仅 isShowAllOnly 菜单入口使用）
  actionShowLanguages(): void {

    const options: ItemOption[] = []

    const isCns: boolean = LanguageManager.getCurrentLanguage() === AppLanguage.Simplified
    const isCnt: boolean = LanguageManager.getCurrentLanguage() === AppLanguage.Traditional

    // 简体中文
    options.push({
      text   : '简体中文',
      color  : isCns ? $r('app.color.color_red') : $r('app.color.color_black'),
      action : () => {

        LanguageManager.switchLanguage(AppLanguage.Simplified)
      }
    })

    // 繁體中文
    options.push({
      text   : '繁體中文',
      color  : isCnt ? $r('app.color.color_red') : $r('app.color.color_black'),
      action : () => {

        LanguageManager.switchLanguage(AppLanguage.Traditional)
      }
    })

    Toast.showSelectOptions('', undefined, options)
  }
}
