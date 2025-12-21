import { buildNavTitle } from "../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../app/constants/AppDefines";
import {  NavTo } from "../../pages/NavPathManager";
import { TEUtility } from "../../common/utils/TEUtility";

import { Category, CategoryManager } from "../../models/datas/book/CategoryManager";


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




  @Local categories: Category[] = []

  async aboutToAppear() {

    this.loadData()

  }


  // 更新全局数据
  private async loadData() {
    await CategoryManager.shared.reload()
    this.categories = CategoryManager.shared.getCategories() ?? []
  }

  build() {
    NavDestination(){
      Stack(){

        //通用 背景
        // BgImage()

        //构建列表
        this.buildList()
      }
      .onAppear(() => {
        this.loadData()
      })
    }
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色

  }

  getNavTitle(): ResourceStr {
    return  $r('app.string.nav_title_books')

  }
  @Builder buildList(){
    Column() {
      List({ space: 0}) {
        ForEach(this.categories, (category: Category, rowIndex: number) => {
          ListItem() {
            this.buildRowContent(rowIndex, category)
          }
          .onClick(()=>{
            this.handleRowClick(rowIndex, category)
          })
          //.margin({ bottom: 1 })
        })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .sticky(StickyStyle.Header)

    }
    //.padding({ top: 0 })
    .backgroundColor($r('app.color.color_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
  }


  getSectionIcon(sectionIndex: number): Resource {
    return TEUtility.getCategorySectionIcon(sectionIndex)
  }

  getSectionBgColor(section: string): ResourceColor {
    return TEUtility.getCategorySectionBgColor(section)
  }


  // 提取课程内容为Builder方法
  @Builder
  buildRowContent(rowIndex: number, category: Category) {

    Row(){
  Text(category.categoryName)
    .fontSize(16)
    .fontColor($r('app.color.color_text'))
    .margin({left: 5})
    }
    .padding(16)
    .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
    .backgroundColor($r('app.color.color_background'))
  }

  handleRowClick(rowIndex: number, category: Category){


  }
}

