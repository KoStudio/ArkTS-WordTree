import { Book } from "../../../models/datas/book/Book"
import { BookManager } from "../../../models/datas/book/BookManager"
import { Category, CategoryManager } from "../../../models/datas/book/CategoryManager"


@ComponentV2
export struct BooksLocalView {


  @Local books: Book[] = []

  async aboutToAppear() {
    this.loadData()
  }


  private async loadData() {

    this.books = BookManager.shared.books
  }

  build() {
    Stack(){


      //构建列表
      this.buildList()
    }

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

