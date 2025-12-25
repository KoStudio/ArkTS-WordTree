import { WordUser } from "../../models/datas/myData/WordUser"

@ComponentV2
export struct  ListWordRow {

  @Param no?: number = undefined
  @Param @Require word: WordUser
  @Param  isShowMemoFlg: boolean = false
  @Param  titleColor: ResourceColor = $r('app.color.color_list_item_title')

  build() {
    Row(){
      if (this.no != undefined){
        Text(`${this.no}`)
          .fontSize(18)
          .fontColor($r('app.color.color_list_item_detail'))
          .margin({right: 10})
      }

      ///left
      Column(){
        Text(`${this.word.titleEn}`)
          .fontSize(18)
          .fontColor(this.titleColor)
          .margin({left: 5, top: 0})

        Text(this.word.titleCn1ClippedShort)
          .fontSize(15)
          .fontColor($r('app.color.color_list_item_subtitle'))
          .margin({left: 5, top: 5})

      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)



      //right
      Row({space: 10}){
        if (this.word.memo){
          //memo icon
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
    .border({width: {bottom: 1}, style:BorderStyle.Dashed, color: $r('app.color.color_obscure')})
    .backgroundColor($r('app.color.color_background'))
  }
}