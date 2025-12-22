import { Category, CategoryManager } from "../../../models/datas/book/CategoryManager"


@ComponentV2
export struct CategoriesView {


  @Local categories: Category[] = []

  async aboutToAppear() {
    this.loadData()
  }


  private async loadData() {
    await CategoryManager.shared.reload()
    this.categories = CategoryManager.shared.getCategories() ?? []
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


  // 提取课程内容为Builder方法
  @Builder
  buildRowContent(rowIndex: number, category: Category) {

    Row(){
      Text(category.categoryName)
        .fontSize(16)
        .fontColor($r('app.color.color_text'))
        .margin({left: 5})
    }
    .width('100%')
    .padding(16)
    .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
    .backgroundColor($r('app.color.color_background'))
  }

  handleRowClick(rowIndex: number, category: Category){


  }
}

