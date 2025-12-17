import { buildNavTitle } from "../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../app/constants/AppDefines";
import { SearchManager } from "../../models/datas/model/SearchManager";
import { NavTo } from "../../pages/NavPathManager";

import { Word } from "../../models/datas/word/Word";
import { BgImage } from "../../app/views/BgImage";
import { WordCardsViewConfig } from "./wordcard/WordCardsView";
import { WordUser } from "../../models/datas/myData/WordUser";
import { getStringF } from "../../common/utils/ResourceUtils";
import { TintImage } from "../../app/views/TintImage";
import { SpeechRecordManager } from "../../common/components/Speech/Recorder/SpeechRecordManager";
import { SpeechRecordDbAccessor } from "../../common/components/Speech/Recorder/SpeechRecordDbAccessor";


export namespace UnitWordsViewConfig {

  ///导航key
  export const NavKey = "UnitWordsView_show"

  ///打开方式
  export function open(param: Param){
    NavTo(UnitWordsViewConfig.NavKey, param, true)
  }

  export interface Param {
    unitId: number
  }

}

@ComponentV2
export struct UnitWordsView {


   @Param @Require unitId: number
   @Local private words: WordUser[] = []

  @Local private recordManager       : SpeechRecordManager  = new SpeechRecordManager() // 语音录音管理器

  async aboutToAppear() {
    this.loadData()
  }

  // 更新全局数据
  private async loadData() {
    this.words = SearchManager.shared.getWordsByUnitId(this.unitId)
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
    return getStringF($r('app.string.str_unit_no'), this.unitId)//`Lesson${this.unitId}`

  }
  @Builder buildList(){
    Column() {
      List({ space: 0 }) {
        // 内层unit列表
        ForEach(this.words, (word: WordUser, rowIndex: number) => {
          ListItem() {
            this.buildRowContent(rowIndex, word)
          }
          .onClick(()=>{
            this.handleRowClick(rowIndex)
          })
          .margin({ bottom: 1 })
        })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)

    }
    .padding({ top: 0 })
    .backgroundColor($r('app.color.color_transparent'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
  }


  @Builder
  buildRowContent(rowIndex: number, word: WordUser) {
   Row(){

     ///left
     Column(){

       Text(`${rowIndex + 1}. ${word.wordEn}`)
         .fontSize(18)
         .fontColor($r('app.color.color_text'))


       Text(word.wordJp)
         .fontSize(15)
         .fontColor($r('app.color.color_detail'))
         .margin({left: 15, top: 5})


     }
     .justifyContent(FlexAlign.Center)
     .alignItems(HorizontalAlign.Start)

     //right
     Row({space: 10}){
       if (word.memo){
         //memo icon
         //TintImage({src: $r('app.media.learn_icon_memo'), iconSize: 20, colorStr:"#888888"})
         Image($r('app.media.learn_icon_memo'))
           .width(14)
           .height(17)
       }

       //录音icon
       //TintImage({src: $r('app.media.learn_icon_voice')})

     }

   }
   .justifyContent(FlexAlign.SpaceBetween)
   .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding(10)
    .layoutWeight(1)
    .padding(16)
    .backgroundColor($r('app.color.color_clear'))
  }

  handleRowClick(rowIndex: number){
    //   goto card
    WordCardsViewConfig.open({words: this.words, initIndex: rowIndex})
  }
}

