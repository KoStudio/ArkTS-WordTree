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

  aboutToAppear(): void {

    void this.loadData()

    // 简繁等语言切换后分类名需随资源重载
    this.unsubLanguage = SimpleEventBus.on(LanguageManagerNotification.languageChanged, () => {
      void this.loadData()
    })

    // 与 iOS `BookManager2.Notification.bookListUpdated`：BookList 云端库更新后重载分类
    this.unsubBookList = SimpleEventBus.on(BookManagerNotification.bookListUpdated, () => {
      void this.loadData()
    })
  }

  aboutToDisappear(): void {

    // 注销当前组件注册的监听（避免误删其它模块对同名事件的订阅）
    if (this.unsubLanguage !== undefined) {
      this.unsubLanguage()
      this.unsubLanguage = undefined
    }

    if (this.unsubBookList !== undefined) {
      this.unsubBookList()
      this.unsubBookList = undefined
    }
  }

  // 与 iOS `loadData`：`CategoryManager2.reload` 后取列表
  private async loadData(): Promise<void> {

    await CategoryManager.shared.reload()

    this.categories = CategoryManager.shared.getCategories() ?? []
  }

  build() {
    Stack() {
      this.buildList()
    }
  }

  @Builder
  buildList() {
    Column() {
      List({ space: 0 }) {
        ForEach(this.categories, (category: Category, rowIndex: number) => {
          ListItem() {
            this.buildRowContent(rowIndex, category)
          }
            .onClick(() => {
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

  // rowIndex：行号；category：所选分类（跳转在线课本列表）
  handleRowClick(rowIndex: number, category: Category): void {

    // 与 iOS `onCategorySelected` → 在线书列表；鸿蒙用 NavTo 打开 BooksOnlineView
    BooksOnlineViewConfig.open({ category: category })
  }
}
