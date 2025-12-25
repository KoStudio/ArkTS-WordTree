import { ListWordRow } from "../../../app/views/ListWordRow"
import { SpeechRecordManager } from "../../../common/components/Speech/Recorder/SpeechRecordManager"
import { SearchManager } from "../../../models/datas/model/SearchManager"
import { WordUser } from "../../../models/datas/myData/WordUser"


@ComponentV2
export struct UnitWordListView {

  @Param @Require unitId: number
  @Param @Require onClickedRow: (rowIndex: number, words: WordUser[]) => void

   @Local private words: WordUser[] = []

  //@Local private recordManager       : SpeechRecordManager  = new SpeechRecordManager() // 语音录音管理器

  async aboutToAppear() {
    this.loadData()
  }

  // 更新全局数据
  private async loadData() {
    this.words = SearchManager.shared.getWordsByUnitId(this.unitId)
  }

  build() {
     Stack(){
       //构建列表
       this.buildList()
     }
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
    ListWordRow({no: rowIndex + 1, word: word, isShowMemoFlg: true})

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
   //
   // }
   // .justifyContent(FlexAlign.SpaceBetween)
   // .alignItems(VerticalAlign.Center)
   //  .width('100%')
   //  .padding(10)
   //  .layoutWeight(1)
   //  .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
   //  .backgroundColor($r('app.color.color_background'))
  }

  handleRowClick(rowIndex: number){
    //   goto card
    // WordCardsViewConfig.open({words: this.words, initIndex: rowIndex})
    this.onClickedRow(rowIndex, this.words)
  }
}

