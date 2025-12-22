import { buildNavTitle } from "../../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../../app/constants/AppDefines";
import { TintImage } from "../../../app/views/TintImage";
import { SectionDatas } from "../../../common/utils/array/SectionDatas";
import { getStringF } from "../../../common/utils/ResourceUtils";
import { TEUtility } from "../../../common/utils/TEUtility";
import { Part, Unit } from "../../../models/datas/model/Part_Unit";
import { SearchConstants, SearchManager } from "../../../models/datas/model/SearchManager";
import { NavTo } from "../../../pages/NavPathManager";
import json from "@ohos.util.json";
import { BgImage } from "../../../app/views/BgImage";
import { IndexPath } from "../../../common/interface/IndexPath";
import { IconButton } from "../../../app/views/buttons/IconButton";
import { QuizScopeFooter } from "./QuizScope";
import { Toast } from "../../../common/utils/Toast";
import { QuizManager } from "../../../models/datas/model/QuizManager";
import { QuizStartViewConfig } from "../start/QuizStartView";

export namespace QuizScopeAllViewConfig {

  ///导航key
  export const NavKey = "QuizScopeAllView_show"

  ///打开方式
  export function open(){
    NavTo(QuizScopeAllViewConfig.NavKey, undefined, true)
  }


}

@ComponentV2
export struct QuizScopeAllView {


  @Local sectionUnits  : SectionDatas<string, Unit> = new SectionDatas()
  private listScroller : ListScroller               = new ListScroller();
  private refreshKey   : number                     = 0
  @Local private selectedItemIndex: IndexPath[] = []
  @Local private isSelectdAll: boolean = false


  async aboutToAppear() {
    this.loadData()
  }


  // 更新全局数据
  private async loadData() {
    this.sectionUnits = SearchManager.shared.getUnitsSectionedByPart(SearchConstants.PART_ID_ALL)
  }

  build() {
    NavDestination(){
      Stack(){

        //通用 背景
        // BgImage()

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
    return $r('app.string.nav_title_quiz_scope_all')

  }

  @Builder
  buildList() {
    Column() {

      Scroll() {

        Column({ space: 0 }) {

          // 遍历所有 Section
          ForEach(this.sectionUnits.allSections(), (section: string, sectionIndex: number) => {

            // --- 分组头部 ---
            this.buildGroupHeader(section, sectionIndex)

            // --- Flex 内容区域 (自动换行) ---
            Flex({
              direction: FlexDirection.Row,
              wrap: FlexWrap.Wrap,      // ⭐ 关键：自动换行
              justifyContent: FlexAlign.Start,
              alignItems: ItemAlign.Start
            }) {

              // 遍历组内 Units
              ForEach(
                this.sectionUnits.allDatasOfSectionIndex(sectionIndex),
                (unit: Unit, rowIndex: number) => {

                  // 单个 Unit 的点击区域
                  Column() {
                    this.buildRowContent(sectionIndex, rowIndex, unit)
                  }
                  .onClick(() => this.handleRowClick(sectionIndex, rowIndex, unit))
                  .margin({ right: 12, bottom: 12 }) // 每个单元之间的间距
                },
                (unit: Unit) => `unit_${unit.unitId}_${this.refreshKey}`
              )

            }
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })

          }, (section: string) => `${json.stringify(section)}_${this.refreshKey}`)

        }
        .width('100%')

      }
      .scrollBar(BarState.Auto)

    }
    .backgroundColor($r('app.color.color_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .layoutWeight(1)
  }
  getSectionIcon(sectionIndex: number): Resource {
    return TEUtility.getCategorySectionIcon(sectionIndex)
  }

  getSectionBgColor(section: string): ResourceColor {
    return TEUtility.getCategorySectionBgColor(section)
  }

  // 提取分组头部为Builder方法
  @Builder
  buildGroupHeader(section: string, index: number) {
    Row({space: 20}){
      //icon
      // TintImage({src: this.getSectionIcon(index), colorStr: '#ffffff', iconSize: 22})

      /// 共0个
      Text(section)
        .fontColor($r('app.color.colorPrimary'))
        .fontSize(16)
        .fontWeight(FontWeight.Normal)
    }
    // .backgroundColor(this.getSectionBgColor(section))
    .backgroundColor($r('app.color.color_obscure'))
    .padding({left: 10,top: 2, bottom: 2 })
    .width('100%')
    .height(26)
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  buildRowContent(sectionIndex: number, rowIndex: number, unit: Unit) {
    Row({space: 6}) {
      // 勾选图标
      Image(this.isSelected(sectionIndex, rowIndex)? $r('app.media.quiz_check_yes') : $r('app.media.quiz_check_no'))
        .width(22)
        .height(22)


      Text(getStringF($r('app.string.str_unit_no'), unit.unitId))
        .fontSize(16)
        .fontColor($r('app.color.color_text'))


    }
    .padding({ left: 5, right: 5, top: 5, bottom: 5 })
    // .border({ width: 1, color: $r('app.color.color_obscure') })
    .borderRadius(2)   // 看起来更像“卡片”
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
      for (let s = 0; s < this.sectionUnits.allSections().length; s++) {
        for (let r = 0; r < this.sectionUnits.allDatasOfSectionIndex(s).length; r++) {
          this.selectedItemIndex.push({section: s, row: r})
          this.selectedItemIndex = [...this.selectedItemIndex]
        }
      }
    }else{
      this.selectedItemIndex = []
    }
  }

  handleRowClick(section: number, row: number, unit: Unit){

    // 编辑状态下点击单元格
    if (this.isSelected(section, row)) {
      // 已存在 → 取消选中
      this.selectedItemIndex = this.selectedItemIndex.filter(item => item.section !== section || item.row !== row)
    } else {
      // 未选中 → 添加选中
      this.selectedItemIndex = [...this.selectedItemIndex, {section: section, row: row}]
    }
  }

  getSelectedUnits(): Unit[] {
    return this.selectedItemIndex.map((item) => {
      return this.sectionUnits.allDatasOfSectionIndex(item.section)[item.row]
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

    QuizManager.shared.units = this.getSelectedUnits()
    QuizStartViewConfig.open()
  }
}

