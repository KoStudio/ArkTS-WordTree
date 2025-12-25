import { buildNavTitle } from "../../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../../app/constants/AppDefines"
import { buildStandardMenu } from "../../../app/constants/AppFunctions"
import { NoDataPanel } from "../../../app/views/NoDataView"
import { getString } from "../../../common/utils/ResourceUtils"
import { SearchManager } from "../../../models/datas/model/SearchManager"
import { WordUser } from "../../../models/datas/myData/WordUser"
import { NavTo } from "../../../pages/NavPathManager"
import { WordCardsViewConfig } from "../../card/wordcard/WordCardsView"


export namespace MyRecordsViewConfig {

  ///导航key
  export const NavKey = "MyRecordsView_show"

  ///打开方式
  export function open(){
    NavTo(MyRecordsViewConfig.NavKey, undefined, true)
  }


}

@ComponentV2
export struct MyRecordsView {



   @Local private words: WordUser[] = []


  async aboutToAppear() {

  }

  // 更新全局数据
  private async loadData() {
    this.words = await SearchManager.shared.getWordsWithRecord()
  }

  build() {
    NavDestination(){
      Stack(){

        //通用 背景
        //BgImage()

        if (this.words.length > 0){
          //构建列表
          this.buildList()
        }else{
          NoDataPanel()
        }

      }
      .backgroundColor($r('app.color.color_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .onAppear(() => {
        this.loadData()
      })
    }
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .menus(buildStandardMenu(this.buildMenuItems()))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色
    .onShown(()=>{
      this.loadData()
    })

  }


  buildMenuItems(): NavigationMenuItem[] {
    return [ ]
  }

  getNavTitle(): ResourceStr {
    return getString($r('app.string.nav_title_mine_record'))
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

       Text(`${rowIndex + 1}. ${word.titleEn}`)
         .fontSize(18)
         .fontColor($r('app.color.color_text'))


       Text(word.titleCn1)
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
   .border({width: {bottom: 1}, style: BorderStyle.Dashed, color: $r('app.color.color_obscure')})
  }

  handleRowClick(rowIndex: number){
    //   goto card
    WordCardsViewConfig.open({words: this.words, initIndex: rowIndex})
  }

}

