import { buildNavTitle } from "../../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../../app/constants/AppDefines";
import { Part, Unit } from "../../../models/datas/model/Part_Unit";
import { SearchConstants, SearchManager } from "../../../models/datas/model/SearchManager";
import { NavTo } from "../../../pages/NavPathManager";
import { BgImage } from "../../../app/views/BgImage";
import { IndexPath } from "../../../common/interface/IndexPath";
import { QuizScopeFooter } from "./QuizScope";
import { TEUtility } from "../../../common/utils/TEUtility";
import { Toast } from "../../../common/utils/Toast";
import { QuizManager } from "../../../models/datas/model/QuizManager";
import { QuizStartViewConfig } from "../start/QuizStartView";

export namespace QuizScopeFavoriteViewConfig {

  ///导航key
  export const NavKey = "QuizScopeFavoriteView_show"

  ///打开方式
  export function open(){
    NavTo(QuizScopeFavoriteViewConfig.NavKey, undefined, true)
  }


}

@ComponentV2
export struct QuizScopeFavoriteView {


  @Local favorites    :number[] = []

  private refreshKey   : number                     = 0
  @Local private selectedItemIndex: IndexPath[] = []
  @Local private isSelectdAll: boolean = false


  async aboutToAppear() {
    this.loadData()
  }


  // 更新全局数据
  private async loadData() {
    this.favorites = SearchManager.shared.getAllFavorites()
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
    return $r('app.string.nav_title_quiz_scope_favorite')

  }
  @Builder
  buildList() {
    Column() {
      List() {

        ForEach(this.favorites, (favorite: number, index: number) => {
          ListItem() {
            this.buildRowContent(index, favorite)
          }
          .margin({ left: 16, right: 16, bottom: 12 })
          .onClick(() => this.handleRowClick(0, index))
        })

      }
      .divider({ strokeWidth: 0 }) // 无分割线
      .edgeEffect(EdgeEffect.None)
      .width('100%')

    }
    .layoutWeight(1)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
  @Builder
  buildRowContent(index: number, favorite: number) {
    Row(){

      Text(TEUtility.getFavoriteStarTextString(favorite))
        .fontSize(22)
        .fontColor($r('app.color.color_gold'))

      Image(this.isSelected(0, index)? $r('app.media.quiz_check_yes') : $r('app.media.quiz_check_no'))
        .width(22)
        .height(22)

    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 15, right: 15, top: 10, bottom: 10 })
    .border({ width: {bottom: 1}, color: $r('app.color.color_obscure') })
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
      for (let r = 0; r < this.favorites.length; r++) {
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

  getSelectedFavorites(): number[] {
    return this.selectedItemIndex.map((item) => {
      return this.favorites[item.row]
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

    QuizManager.shared.favorites = this.getSelectedFavorites()
    QuizStartViewConfig.open()
  }
}

