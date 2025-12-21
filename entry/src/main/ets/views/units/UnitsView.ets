import { buildNavTitle } from "../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../app/constants/AppDefines";
import { SectionDatas } from "../../common/utils/array/SectionDatas";
import { Part, Unit } from "../../models/datas/model/Part_Unit";
import { SearchConstants, SearchManager } from "../../models/datas/model/SearchManager";
import {  NavTo } from "../../pages/NavPathManager";
import json from "@ohos.util.json";
import { IconTintButton } from "../../app/views/buttons/IconTintButton";
import { getString, getStringF } from "../../common/utils/ResourceUtils";
import { TintImage } from "../../app/views/TintImage";
import { UnitWordsViewConfig } from "./UnitWordsView";
import { WordCardsViewConfig } from "./wordcard/WordCardsView";
import { TEUtility } from "../../common/utils/TEUtility";
import { BgImage } from "../../app/views/BgImage";


export namespace UnitsViewConfig {

  ///导航key
  export const NavKey = "UnitsView_show"

  ///打开方式
  export function open(param: Param){
    NavTo(UnitsViewConfig.NavKey, param, true)
  }

  export interface Param {
    categoryId: number
  }

}

@ComponentV2
export struct UnitsView {


  @Param categoryId: number = SearchConstants.CATEGORY_ID_ALL
//  @Local private units: Unit[] = []

  @Local sectionUnits: SectionDatas<string, Unit> = new SectionDatas()
  @Local category: Part | null = null

  private listScroller: ListScroller     = new ListScroller();
  private refreshKey : number = 0

  //@Consumer(GlobalKey.kNavPath) navPath?: NavPathStack

  async aboutToAppear() {

    this.loadData()

  }

  // @Monitor('dataModel.myUnits')
  // onMyUnitsChanged() {
  //   //this.updateUnits()
  // }

  // 更新全局数据
  private async loadData() {
    this.sectionUnits = SearchManager.shared.getUnitsSectionedByCategory(this.categoryId)
    this.category  = SearchManager.shared.getCategoryById(this.categoryId) || null
  }

  build() {
    NavDestination(){
      Stack(){

        //通用 背景
        BgImage()

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
    return this.category?.partName ||  $r('app.string.nav_title_learn_unitlist')

  }
  @Builder buildList(){
    Column() {
      List({ space: 0, scroller: this.listScroller }) {
        // 使用ListItemGroup实现分组
        ForEach(this.sectionUnits.allSections(), (section: string, sectionIndex: number) => {
          ListItemGroup({ header: this.buildGroupHeader(section, sectionIndex), style: ListItemGroupStyle.NONE }) {
            // 内层unit列表
            ForEach(this.sectionUnits.allDatasOfSectionIndex(sectionIndex), (unit: Unit, rowIndex: number) => {
              ListItem() {
                this.buildRowContent(sectionIndex, rowIndex, unit)
              }
              .onClick(()=>{
                this.handleRowClick(sectionIndex, rowIndex, unit)
              })
              //.margin({ bottom: 1 })
            }, (unit: Unit, rowIndex: number) => `unit_${unit.unitId}__${this.refreshKey}`)
          }
        }, (section: string, sectionIndex: number) => `${json.stringify(section)}_${this.refreshKey}`)

      }
      .key(`${this.refreshKey}`)
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .sticky(StickyStyle.Header)

    }
    //.padding({ top: 0 })
    // .backgroundColor($r('app.color.color_obscure'))
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

  // 提取分组头部为Builder方法
  @Builder
  buildGroupHeader(section: string, index: number) {
    Row({space: 20}){
      //icon
      TintImage({src: this.getSectionIcon(index), colorStr: '#ffffff', iconSize: 22})

      /// 共0个
      Text(section)
        .fontColor($r('app.color.color_white'))
        .fontSize(12)
    }
    .backgroundColor(this.getSectionBgColor(section))
    .padding({left: 20,top: 2, bottom: 2 })
    .width('100%')
    .height(26)
    .justifyContent(FlexAlign.Start)
  }

  // 提取课程内容为Builder方法
  @Builder
  buildRowContent(sectionIndex: number, rowIndex: number, unit: Unit) {

    Row(){
      //left
      Column(){

        Row(){
          Text(getStringF($r('app.string.str_unit_no'), unit.unitId)) //`Lesson${unit.unitNo}`
            .fontSize(16)
            .fontColor($r('app.color.colorAccent2'))

          if (unit.unitName){
            Text(unit.unitName)
              .fontSize(16)
              .fontColor($r('app.color.color_text'))
              .margin({left: 5})

          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        //进度条
        Progress({ value: unit.learnedWords.length, total: unit.aliveWords.length, type: ProgressType.Linear })
          .foregroundColor($r('app.color.colorAccent2'))
          .backgroundColor($r('app.color.color_obscure'))
          .height(2)
          .width('100%')


        Row(){
          Text(`${unit.learnedWords.length}/${unit.aliveWords.length}`)
            .fontColor($r('app.color.color_detail'))
            .fontSize(14)
        }
        .justifyContent(FlexAlign.End)
        .width('100%')

      }
      .padding(10)
      .layoutWeight(1)

      //right
      Column(){
        //list 按钮
        IconTintButton({icon: $r('app.media.learn_btn_more_1'), iconColor:'#999999', iconSize: 22, onClickCallBack:()=>{
          UnitWordsViewConfig.open({unitId: unit.unitId})
        }})
      }
    }
    .padding(16)
    .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
    .backgroundColor($r('app.color.color_background'))
  }

  handleRowClick(sectionIndex: number, rowIndex: number, unit: Unit){
    //   goto card
    WordCardsViewConfig.open({words: unit.aliveWords, initIndex: unit.indexOfNextLearnWord})
  }
}

