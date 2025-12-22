import { buildNavTitle } from "../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../app/constants/AppDefines";
import {  NavTo } from "../../pages/NavPathManager";
import { TEUtility } from "../../common/utils/TEUtility";

import { Category, CategoryManager } from "../../models/datas/book/CategoryManager";
import { SegmentButton, SegmentItem } from "../../app/views/SegmentButton";
import { CategoriesView } from "./Sub/CategoriesView";
import { BooksLocalView } from "./Sub/BooksLocalView";


export namespace BookListViewConfig {

  ///导航key
  export const NavKey = "BookListView_show"

  ///打开方式
  export function open(){
    NavTo(BookListViewConfig.NavKey, undefined, true)
  }

}

@ComponentV2
export struct BookListView {



  @Local selectedIndex: number = 0

  async aboutToAppear() {

    this.loadData()

  }


  // 更新全局数据
  private async loadData() {

  }

  build() {
    NavDestination(){

      Column(){
        SegmentButton({
          items:         this.createSegmentItems(),
          selectedIndex: this.selectedIndex,
          totalWidth:    '100%',
          onSelect:      (index: number) => this.handleSegmentChange(index)
        })
          .margin(20)


        Stack(){
          if (this.selectedIndex){
            CategoriesView()
          }else{
            BooksLocalView()
          }
        }
        .layoutWeight(1)

      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)

    }
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色

  }

  getNavTitle(): ResourceStr {
    return  $r('app.string.nav_title_books')

  }

  createSegmentItems(): SegmentItem[] {
    let items: SegmentItem[] = []

    items.push({ title: $r('app.string.books_tab_title_mybooks'),    isEnabled: true });
    items.push({ title: $r('app.string.books_tab_title_allbooks'),    isEnabled: true });
    return items;
  }

  handleSegmentChange(index: number): void {
    this.selectedIndex = index
  }
}

