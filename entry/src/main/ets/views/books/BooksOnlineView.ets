import { buildNavTitle } from "../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../app/constants/AppDefines"
import { Book } from "../../models/datas/book/Book"
import { BookDbAccess } from "../../models/datas/book/BookDbAccess"
import { Category } from "../../models/datas/book/CategoryManager"
import { NavTo } from "../../pages/NavPathManager"


export namespace BooksOnlineViewConfig {

  ///导航key
  export const NavKey = "BooksOnlineView_show"

  ///打开方式
  export function open(param: Param){
    NavTo(BooksOnlineViewConfig.NavKey, param, true)
  }

  export interface Param {
    category: Category
  }
}


@ComponentV2
export struct BooksOnlineView {


  @Param @Require category: Category

  @Local books: Book[] = []

  async aboutToAppear() {
    this.loadData()
  }


  private async loadData() {

    this.books = await BookDbAccess.shared.getBooks(this.category.categoryName || '') || []
  }


  build() {
    NavDestination(){

      Column(){
        this.buildList()

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
    return  this.category.categoryName || ''//$r('app.string.nav_title_books')

  }



  @Builder buildList(){
    Column() {
      List({ space: 0}) {
        ForEach(this.books, (book: Book, rowIndex: number) => {
          ListItem() {
            this.buildRowContent(rowIndex, book)
          }
          .onClick(()=>{
            this.handleRowClick(rowIndex, book)
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


  // 提取课程内容为Builder方法
  @Builder
  buildRowContent(rowIndex: number, book: Book) {

    Row(){
      Text(book.bookName)
        .fontSize(16)
        .fontColor($r('app.color.color_text'))
        .margin({left: 5})
    }
    .padding(16)
    .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
    .backgroundColor($r('app.color.color_background'))
  }

  handleRowClick(rowIndex: number, book: Book){


  }
}

