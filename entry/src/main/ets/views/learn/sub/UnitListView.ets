import { SectionDatas } from "../../../common/utils/array/SectionDatas";
import { Part, Unit } from "../../../models/datas/model/Part_Unit";
import { SearchConstants, SearchManager } from "../../../models/datas/model/SearchManager";
import json from "@ohos.util.json";
import { getStringF } from "../../../common/utils/ResourceUtils";
import { IconTintButton } from "../../../app/views/buttons/IconTintButton";
import { MemberManager } from "../../../models/managers/member/MemberManager";


@ComponentV2
export struct UnitListView {


  @Param @Require onClickedRow: (sectionIndex: number, rowIndex: number, unit: Unit) => void
  @Param @Require onClickedBtnList: (sectionIndex: number, rowIndex: number, unit: Unit) => void


  @Local sectionUnits: SectionDatas<string, Unit> = new SectionDatas()
  @Local category: Part | null = null

  private listScroller: ListScroller     = new ListScroller();
  private refreshKey : number = 0


  async aboutToAppear() {
    this.loadData()
  }

  private async loadData() {
    this.sectionUnits = SearchManager.shared.getUnitsSectionedByPart(SearchConstants.PART_ID_ALL)

  }

  build() {
   Stack(){
     this.buildList()
   }
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
    .backgroundColor($r('app.color.color_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
  }

  //
  // getSectionIcon(sectionIndex: number): Resource {
  //   return TEUtility.getCategorySectionIcon(sectionIndex)
  // }
  //
  // getSectionBgColor(section: string): ResourceColor {
  //   return TEUtility.getCategorySectionBgColor(section)
  // }

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
        .fontWeight(FontWeight.Regular)
    }
    // .backgroundColor(this.getSectionBgColor(section))
    .backgroundColor($r('app.color.color_obscure'))
    .padding({left: 10,top: 2, bottom: 2 })
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

          Text(unit.unitName)
            .fontSize(16)
            .fontColor($r('app.color.color_list_item_subtitle'))
            .margin({left: 5})
          //
          // // Text(getStringF($r('app.string.str_unit_no'), unit.unitId)) //`Lesson${unit.unitNo}`
          // Text(getStringF($r('app.string.str_unit_no'), unit.unitId)) //`Lesson${unit.unitNo}`
          //   .fontSize(16)
          //   .fontColor($r('app.color.color_list_item_subtitle'))
          //
          // if (unit.unitName){
          //   Text(unit.unitName)
          //     .fontSize(16)
          //     .fontColor($r('app.color.color_text'))
          //     .margin({left: 5})
          //
          // }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        //进度条
        Progress({ value: unit.learnedWords.length, total: unit.aliveWords.length, type: ProgressType.Linear })
          .backgroundColor($r('app.color.color_obscure'))
          .color($r('app.color.colorAccent2'))
          .height(5)
          .width('100%')


        Row(){
          Text(`${unit.learnedWords.length}/${unit.aliveWords.length}`)
            .fontColor($r('app.color.color_detail'))
            .fontSize(14)
        }
        .justifyContent(FlexAlign.End)
        .width('100%')

      }
      .padding(6)
      .layoutWeight(1)

      //right
      Column(){
        //list 按钮
        IconTintButton({icon: $r('app.media.learn_btn_more_1'), iconColor:'#999999', iconSize: 22, onClickCallBack:()=>{
          // QuickLearnWordsViewConfig.open({unitId: unit.unitId})
          this.onClickedBtnList(sectionIndex, rowIndex, unit)
        }})
      }
    }
    .padding(10)
    .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
    .backgroundColor($r('app.color.color_background'))
  }

  handleRowClick(sectionIndex: number, rowIndex: number, unit: Unit){
    //   goto card
    // WordCardsViewConfig.open({words: unit.aliveWords, initIndex: unit.indexOfNextLearnWord})

    if (!MemberManager.shared.checkUnitUsable(unit.unitId)) {
      return
    }

    this.onClickedRow(sectionIndex, rowIndex, unit)
  }
}

