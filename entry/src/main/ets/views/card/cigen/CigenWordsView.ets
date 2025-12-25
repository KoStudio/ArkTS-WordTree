import { buildNavTitle } from "../../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../../app/constants/AppDefines"
import { ListWordRow } from "../../../app/views/ListWordRow"
import { WordUser } from "../../../models/datas/myData/WordUser"
import { NavTo } from "../../../pages/NavPathManager"
import { WordCardsViewConfig } from "../wordcard/WordCardsView"


export namespace CigenWordsViewConfig {

  ///导航key
  export const NavKey = "CigenWordsView_show"

  ///打开方式
  export function open(param: Param){
    NavTo(CigenWordsViewConfig.NavKey, param, true)
  }

  export interface Param {
    words: WordUser[]
    navTitle: string
  }

}

@ComponentV2
export struct CigenWordsView {

  @Param words: WordUser[] = []
  @Param navTitle: string = ''

  build() {
    NavDestination(){
      Stack(){
        this.buildList()
      }
      .backgroundColor($r('app.color.color_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

    }
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色

  }

  getNavTitle(): ResourceStr {
    return this.navTitle//getStringF($r('app.string.str_unit_no'), this.unitId)//`Lesson${this.unitId}`
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
    ListWordRow({no: rowIndex + 1, word: word})

    // Row(){
    //   Text(`${rowIndex + 1}`)
    //     .fontSize(18)
    //     .fontColor($r('app.color.color_list_item_detail'))
    //     .margin({right: 10})
    //
    //   ///left
    //   Column(){
    //
    //
    //     Text(`${word.titleEn}`)
    //       .fontSize(18)
    //       .fontColor($r('app.color.color_list_item_title'))
    //
    //     Text(word.titleCn1ClippedShort)
    //       .fontSize(15)
    //       .fontColor($r('app.color.color_list_item_subtitle'))
    //       .margin({left: 5, top: 5})
    //
    //   }
    //   .width('100%')
    //   .justifyContent(FlexAlign.Center)
    //   .alignItems(HorizontalAlign.Start)
    //
    //   //right
    //   Row({space: 10}){
    //     if (word.memo){
    //
    //       Image($r('app.media.learn_icon_memo'))
    //         .width(14)
    //         .height(17)
    //     }
    //
    //
    //   }
    //
    // }
    // .justifyContent(FlexAlign.SpaceBetween)
    // .alignItems(VerticalAlign.Center)
    // .width('100%')
    // .padding(10)
    // .layoutWeight(1)
    // .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
    // .backgroundColor($r('app.color.color_background'))
  }

  handleRowClick(rowIndex: number){
    //   goto card
    WordCardsViewConfig.open({words: this.words, initIndex: rowIndex})
    // this.onClickedRow(rowIndex, this.words)
  }
}

