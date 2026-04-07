//
// CategoriesView.ets
// 与 iOS `Root/Book2/Sub/CategoriesView.swift` 对齐：分类列表、语言切换与 bookList 更新刷新。
//

import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { LanguageManagerNotification } from '../../../common/components/Language/LanguageManager'
import { Category, CategoryManager } from '../../../models/datas/book/CategoryManager'
import { BookManagerNotification } from '../../../models/datas/book/BookManager'
import { BooksOnlineViewConfig } from '../online/BooksOnlineView'

@ComponentV2
export struct CategoriesView {

  @Local categories: Category[] = []

  private unsubLanguage   : (() => void) | undefined = undefined
  private unsubBookList   : (() => void) | undefined = undefined

  /**
   * 页面出现时：加载分类并注册语言/书库更新监听
   */
  aboutToAppear(): void {

    // 调用：首次进入时加载分类数据
    void this.loadData()

    // 简繁等语言切换后分类名需随资源重载
    // 调用：订阅语言变更事件
    this.unsubLanguage = SimpleEventBus.on(LanguageManagerNotification.languageChanged, () => {

      // 调用：语言切换后重载分类
      void this.loadData()
    })

    // 与 iOS `BookManager2.Notification.bookListUpdated`：BookList 云端库更新后重载分类
    // 调用：订阅书库更新事件
    this.unsubBookList = SimpleEventBus.on(BookManagerNotification.bookListUpdated, () => {

      // 调用：书库更新后重载分类
      void this.loadData()
    })
  }

  /**
   * 页面消失时：注销当前页面注册的监听
   */
  aboutToDisappear(): void {

    // 注销当前组件注册的监听（避免误删其它模块对同名事件的订阅）
    if (this.unsubLanguage !== undefined) {

      // 调用：取消语言变更事件订阅
      this.unsubLanguage()
      this.unsubLanguage = undefined
    }

    if (this.unsubBookList !== undefined) {

      // 调用：取消书库更新事件订阅
      this.unsubBookList()
      this.unsubBookList = undefined
    }
  }

  // 与 iOS `loadData`：`CategoryManager2.reload` 后取列表
  private async loadData(): Promise<void> {

    // 调用：重新加载分类源数据
    await CategoryManager.shared.reload()

    // 调用：读取分类列表并回填页面状态
    this.categories = CategoryManager.shared.getCategories() ?? []
  }

  /**
   * 构建主视图
   */
  build() {
    Stack() {

      // 调用：构建分类列表内容
      this.buildList()
    }
  }

  /**
   * 构建分类列表区域
   */
  @Builder
  buildList() {
    Column() {
      List({ space: 0 }) {
        ForEach(this.categories, (category: Category, rowIndex: number) => {
          ListItem() {

            // 调用：构建分类行内容
            this.buildRowContent(rowIndex, category)
          }
            .onClick(() => {

              // 调用：处理分类行点击
              this.handleRowClick(rowIndex, category)
            })
        }, (category: Category, rowIndex: number) => `${category.categoryName ?? ''}_${rowIndex}`)
      }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Auto)
        .sticky(StickyStyle.Header)
    }
      .backgroundColor($r('app.color.color_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .width('100%')
      .height('100%')
  }

  /**
   * 构建单个分类行内容
   * @param rowIndex 行号
   * @param category 当前分类
   */
  @Builder
  buildRowContent(rowIndex: number, category: Category) {

    Row() {

      Text(category.categoryName ?? '')
        .fontSize(16)
        .fontColor($r('app.color.color_text'))
        .margin({ left: 5 })
    }
      .width('100%')
      .padding(16)
      .border({ width: { bottom: 1 }, color: $r('app.color.color_obscure') })
      .backgroundColor($r('app.color.color_background'))
  }

  /**
   * 处理分类行点击：跳转在线课本列表
   * @param rowIndex 行号
   * @param category 所选分类
   */
  handleRowClick(rowIndex: number, category: Category): void {

    // 与 iOS `onCategorySelected` → 在线书列表；鸿蒙用 NavTo 打开 BooksOnlineView

    // 调用：打开分类对应的在线课本页面
    BooksOnlineViewConfig.open({ category: category })
  }
}
