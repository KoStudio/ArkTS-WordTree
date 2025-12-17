import { buildNavTitle } from "../../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../../app/constants/AppDefines";
import { Category, Unit } from "../../../models/datas/model/Category_Unit";
import { SearchConstants, SearchManager } from "../../../models/datas/model/SearchManager";
import { NavTo } from "../../../pages/NavPathManager";
import { BgImage } from "../../../app/views/BgImage";
import { IndexPath } from "../../../common/interface/IndexPath";
import { QuizScopeFooter } from "./QuizScope";
import { TEUtility } from "../../../common/utils/TEUtility";
import { QuizManager } from "../../../models/datas/model/QuizManager";
import { Toast } from "../../../common/utils/Toast";
import { QuizStartViewConfig } from "../start/QuizStartView";

export namespace QuizScopeCategoryViewConfig {

  ///导航key
  export const NavKey = "QuizScopeCategoryView_show"

  ///打开方式
  export function open(){
    NavTo(QuizScopeCategoryViewConfig.NavKey, undefined, true)
  }


}

@ComponentV2
export struct QuizScopeCategoryView {


  @Local categories    :Category[] = []

  private refreshKey   : number                     = 0
  @Local private selectedItemIndex: IndexPath[] = []
  @Local private isSelectdAll: boolean = false


  async aboutToAppear() {
    this.loadData()
  }


  // 更新全局数据
  private async loadData() {
    this.categories = SearchManager.shared.getAliveCategories()
  }

  build() {
    NavDestination(){
      Stack(){

        //通用 背景
        BgImage()

        Column(){

          //构建列表
          this.buildList()

          //footer
          this.buildFooter()
        }

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
    return $r('app.string.nav_title_quiz_scope_category')

  }

  @Builder
  buildList() {
    Column() {
      Scroll() {
        Column() {

          // Flex 内容区域
          Flex({
            direction: FlexDirection.Row,
            wrap: FlexWrap.Wrap,
            justifyContent: FlexAlign.Start,
            alignItems: ItemAlign.Start
          }) {

            ForEach(this.categories, (category: Category, index: number) => {

              Column() {
                this.buildRowContent(index, category)
              }
              .onClick(() => this.handleRowClick(0, index))
              .margin({ right: 12, bottom: 12 })

            })
          }
          .width('auto')
          .padding(16)

        }
      }
      .scrollBar(BarState.Auto)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

  }


  @Builder
  buildRowContent(index: number, category: Category) {
    Stack(){

      Image(TEUtility.getCategoryScopeButtonIcon(index))
        .width(146)
        .height(117)
        .objectFit(ImageFit.Fill)

      Column() {
        // 勾选图标
        Row(){
          Image(this.isSelected(0, index)? $r('app.media.quiz_check_yes') : $r('app.media.quiz_check_no'))
            .width(22)
            .height(22)
        }
        .justifyContent(FlexAlign.End)
        .width('100%')


        Row(){

          Text(category.categoryName)
            .fontSize(16)
            .fontColor($r('app.color.colorPrimary'))

        }
        .width('100%')
        .justifyContent(FlexAlign.Start)


      }
      .width('100%')
      .height('100%')
      .padding(5)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width(146)
    .height(117)
    // .backgroundImage(TEUtility.getCategoryScopeButtonIcon(index))
    //.padding({ left: 5, right: 5, top: 5, bottom: 5 })
    // .border({ width: 1, color: $r('app.color.colorPrimary') })
    // .borderRadius(2)
  }

  @Builder buildFooter(){
    QuizScopeFooter({isSelected: this.isSelectdAll, onSelect: (selected: boolean) => {this.actionSelectAll(selected)}, onNext: ()=>{this.actionNext()}})
  }

  isSelected(section: number = 0, row: number): boolean {
    return this.selectedItemIndex.some(item => item.section === section && item.row === row)
  }

  actionSelectAll(selected: boolean){
    this.isSelectdAll = selected
    if (this.isSelectdAll) {
      for (let r = 0; r < this.categories.length; r++) {
        this.selectedItemIndex.push({section: 0, row: r})
        this.selectedItemIndex = [...this.selectedItemIndex]
      }
    }else{
      this.selectedItemIndex = []
    }

  }

  handleRowClick(section: number, row: number){

    // 编辑状态下点击单元格
    if (this.isSelected(section, row)) {
      // 已存在 → 取消选中
      this.selectedItemIndex = this.selectedItemIndex.filter(item => item.section !== section || item.row !== row)
    } else {
      // 未选中 → 添加选中
      this.selectedItemIndex = [...this.selectedItemIndex, {section: section, row: row}]
    }
  }

  getSelectedCategories(): Category[] {
    return this.selectedItemIndex.map((item) => {
      return this.categories[item.row]
    });
  }


  checkScope(): boolean{

    if (this.selectedItemIndex.length === 0) {
      Toast.showMessage($r('app.string.quiz_scope_err'))
      return false
    }
    return true
  }

  actionNext(){
    if (!this.checkScope()) {
      return
    }

    QuizManager.shared.categories = this.getSelectedCategories()
    QuizStartViewConfig.open()
  }
}

