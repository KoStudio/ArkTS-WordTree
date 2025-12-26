import { TintImage } from "../../../app/views/TintImage"
import { CBookManager } from "../../../common/components/Sounds/Cloud/Download/CBook/CBookManager"
import { getStringF } from "../../../common/utils/ResourceUtils"
import { Toast } from "../../../common/utils/Toast"
import { Book } from "../../../models/datas/book/Book"
import { BookManager } from "../../../models/datas/book/BookManager"
import { Category, CategoryManager } from "../../../models/datas/book/CategoryManager"
import { SearchManager } from "../../../models/datas/model/SearchManager"


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
          .gesture(
            LongPressGesture()
              .onAction(() => {
                if (!book.isCurrentBook){
                  // 显示删除确认对话框
                  this.confirmRemove(rowIndex, book);
                }
              })
          )
          .swipeAction({end: book.isCurrentBook ? null : {
            builder: () => {

              this.buildSwipeButtons(rowIndex, book)

            },
            onAction: () => { this.confirmRemove(rowIndex, book)}
          }})

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
      Column({space:5}){
        Text(book.bookName)
          .fontSize(22)
          .fontColor($r('app.color.color_list_item_title'))


        Text(getStringF($r('app.string.books_txt_info_counts'), book.unitsCount || 0, book.wordsCount || 0))
          .fontSize(16)
          .fontColor($r('app.color.color_list_item_subtitle'))


      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)


      //right
      Column(){

        if (BookManager.shared.currentBook?.bookId === book.bookId){
          //选中
          TintImage({
            src: $r('app.media.done')
          })
        }

      }
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(16)
    .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
    .backgroundColor($r('app.color.color_background'))
  }

  handleRowClick(rowIndex: number, book: Book){
    if (!book.isCurrentBook){
      BookManager.shared.setCurrentBook(book)
      SearchManager.shared.refreshData()
      this.loadData()
      //SearchManager.shared.refreshData()
    }

  }

  @Builder buildSwipeButtons(index: number, book: Book){


    Row(){

      ///删除
      this.buildSwipeButton($r('app.string.confirm_btn_remove'), $r('app.color.colorAccent'), ()=>{
        ///确认删除
        this.confirmRemove(index, book)
      })
    }
    .alignItems(VerticalAlign.Center)
    .height('100%')

  }
  @Builder buildSwipeButton(text: ResourceStr, bgColor: Resource = $r('app.color.colorPrimary'), onCallback:()=>void){
    Button() {
      Text(text)
        .fontSize(16)
        .fontColor(Color.White)
    }
    .borderRadius(0)
    .padding(6)
    .height('100%')
    .width('auto')  // 根据内部内容自适应宽度
    .constraintSize({ minWidth: 44 })  // 指定最小宽度为
    .type(ButtonType.Normal)
    .backgroundColor(bgColor)
    .onClick(onCallback)
  }

  private confirmRemove(index: number, book: Book){
    if (book.isCurrentBook){
      return
    }

    Toast.showAlert({
      title: $r('app.string.alert_title_confirm'),
      message: getStringF($r('app.string.alert_msg_confirm_remove'), book.bookName || ''),///确认要删除吗
      secondaryButton: {value: $r('app.string.confirm_btn_no'), fontColor: Color.Gray, action: () => {}},//取消
      primaryButton: {value: $r('app.string.confirm_btn_yes'), action: async () => {
        //删除
        BookManager.shared.removeBook(book)
        CBookManager.shared.removeBookDb(book.textDb || '')
        this.loadData()

      }}//确认

    })
  }
}

