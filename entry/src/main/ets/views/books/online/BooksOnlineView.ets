import { buildNavTitle } from "../../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../../app/constants/AppDefines"
import { TextButton } from "../../../app/views/buttons/TextButton"
import { CBookManager } from "../../../common/components/Sounds/Cloud/Download/CBook/CBookManager"
import { getStringF } from "../../../common/utils/ResourceUtils"
import { Toast } from "../../../common/utils/Toast"
import { Book } from "../../../models/datas/book/Book"
import { BookDbAccess } from "../../../models/datas/book/BookDbAccess"
import { Category } from "../../../models/datas/book/CategoryManager"
import { NavPopTop, NavTo } from "../../../pages/NavPathManager"
import { LoadingDialog } from "@kit.ArkUI"
import { BookManager } from "../../../models/datas/book/BookManager"
import { MemberManager } from "../../../models/managers/member/MemberManager"


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

    Row({space: 8}){
      Column({space:5}){
        Text(book.bookName)
          .fontSize(22)
          .fontColor($r('app.color.color_list_item_title'))


        Text(getStringF($r('app.string.books_txt_info_counts'), book.unitsCount || 0, book.wordsCount || 0))
          .fontSize(16)
          .fontColor($r('app.color.color_list_item_subtitle'))



        // Text(getStringF($r('app.string.books_txt_info_golds'), book.golds || 0))
        //   .fontSize(15)
        //   .fontColor($r('app.color.color_gold'))


      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)


      //right
      Column(){

        TextButton({
          text: BookManager.shared.books.filter(v => v.bookId === book.bookId).length > 0 ? $r('app.string.books_btn_title_downloaded') :  $r('app.string.books_btn_title_to_download'), //点击下载/已下载
          bgColor: $r('app.color.color_btn_bg2'),
          onClickCallBack: ()=>{
            this.handleRowClick(rowIndex, book)
          }
        })
      }
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .padding(10)
    .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
    .backgroundColor(BookManager.shared.books.filter(v => v.bookId === book.bookId).length > 0 ? $r('app.color.color_gray_light') : $r('app.color.color_background'))
  }

  handleRowClick(rowIndex: number, book: Book){

    if (BookManager.shared.books.filter(v => v.bookId === book.bookId).length > 0) {
      //已经下载
      return
    }

    //会员检查
    if (!MemberManager.shared.checkBooksDownloadable()) {
      return
    }
    Toast.showCustomDialog(()=> { this.buildLoadingDialog($r('app.string.books_msg_download_start_word'))}, false)
    CBookManager.shared.startUpdateBookCheckIfNeeds(book.textDb, book.bookName, true, (percent: number)=>{
      Toast.showDebugMessage(`${percent}%..`)
    },(succeed: boolean, msg: string | null)=>{
      Toast.closeCustomDialog()

      if (succeed) {
        Toast.showMessage($r('app.string.books_msg_download_succeed'))
        BookManager.shared.saveBook(book)
        BookManager.shared.setCurrentBook(book)
        NavPopTop()
      }else{
        Toast.showMessage($r('app.string.books_msg_download_failed'))
      }

    })

  }


  @Builder
  buildLoadingDialog(msg?: ResourceStr | null): void {
    LoadingDialog({
      content: msg ?? 'loading..'
    })
  }
}

