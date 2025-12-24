import { buildNavTitle } from "../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../app/constants/AppDefines";
import {  NavTo } from "../../pages/NavPathManager";
import { TEUtility } from "../../common/utils/TEUtility";

import { Category, CategoryManager } from "../../models/datas/book/CategoryManager";
import { SegmentButton, SegmentItem } from "../../app/views/SegmentButton";
import { CategoriesView } from "./Sub/CategoriesView";
import { BooksLocalView } from "./Sub/BooksLocalView";
import { buildStandardMenu, CustomNavigationMenuItem } from "../../app/constants/AppFunctions";
import { ItemOption, Toast } from "../../common/utils/Toast";
import { LanguageManager } from "../../common/components/Language/LanguageManager";
import { AppLanguage } from "../../common/components/Language/AppLanguage";
import { BookManager } from "../../models/datas/book/BookManager";


export namespace BookListViewConfig {

  ///导航key
  export const NavKey = "BookListView_show"

  ///打开方式
  export function open(param: Param){
    NavTo(BookListViewConfig.NavKey, param, true)
  }

  export interface Param {
    isShowAllOnly?: boolean
  }
}

@ComponentV2
export struct BookListView {


  @Param isShowAllOnly: boolean = false//首次下载时，只显示 所有词汇

  @Local selectedIndex: number = 0

  async aboutToAppear() {

    if (this.isShowAllOnly ) {
      this.selectedIndex = 1
    }

    this.loadData()

  }


  // 更新全局数据
  private async loadData() {

  }

  build() {
    NavDestination(){

      Column(){

        if (!this.isShowAllOnly){
          SegmentButton({
            items:         this.createSegmentItems(),
            selectedIndex: this.selectedIndex,
            totalWidth:    '100%',
            onSelect:      (index: number) => this.handleSegmentChange(index)
          })
            .margin(20)
        }



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
    .menus(buildStandardMenu(this.buildMenuItems()))
    .onBackPressed(()=>{
      if (BookManager.shared.currentBook === null) {
        Toast.showMessage($r('app.string.main_msg_no_books'))
        return true
      }

      return false
    })

  }

  getNavTitle(): ResourceStr {
    return  $r('app.string.nav_title_books')

  }
  buildMenuItems(): CustomNavigationMenuItem[] {
    return !this.isShowAllOnly ? [] : [
      {value: "more", icon: $r('app.media.moreh'), isSvg: true, action: () => {

        ///显示语言选择
        this.actionShowLanguages()
      }
      }
    ]
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



  ///切换 语言
  actionShowLanguages(){
    let options: ItemOption[] = [];

    let isCns = LanguageManager.getCurrentLanguage() === AppLanguage.Simplified
    let isCnt = LanguageManager.getCurrentLanguage() === AppLanguage.Traditional

    ///简体中文
    options.push(
      {text: `简体中文`, color: isCns ? $r('app.color.color_red') : $r('app.color.color_black') , action: ()=>{

        LanguageManager.switchLanguage(AppLanguage.Simplified)

      }})


    ///繁體中文
    options.push(
      {text: `繁體中文`, color: isCnt ? $r('app.color.color_red') : $r('app.color.color_black'),action: ()=>{
        LanguageManager.switchLanguage(AppLanguage.Traditional)
      }})

    // 显示
    Toast.showSelectOptions('', undefined, options)
  }
}

