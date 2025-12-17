import { CircleView, CircleViewStyle, GraphPart } from "../../../../app/views/CircleView";
import json from "@ohos.util.json";


@ComponentV2
export struct GraphInfoPanel {

  @Param title: ResourceStr = ''
  @Param titleColor: ResourceColor = $r('app.color.colorPrimary')
  @Param parts: GraphPart[] = [];
  @Param allCount: number   = 0;
  @Param precision: number  = 1; //小数点后几位，如：12.5%, 会自动四舍五入


  build() {
    Column({ space: 10 }) {

      // up "概况"
      Text(this.title)
        .fontSize(16)
        .fontColor(this.titleColor)
        .margin({top: 10, left: 10})


      // mid 主面板
      Column() {

        // 圆环图
        CircleView({
          parts: this.parts,
          allCount: this.allCount,
          ringWidth: 28,
          ring3DWidth: 5,
          style: CircleViewStyle.Ring3D,
          bgColorShow: true,
          showInfo: false
        })
          .width(180)
          .height(180)
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')

      // down Info 面板（下方图例）
      Row({ space: 0 }) {
        ForEach(this.parts, (part: GraphPart, index: number) => {

          Stack(){//边框

            //info是否竖向排列， 3个以下是适合横向，5个以下适合竖向
            if (this.parts.length > 3) {
              this.buildOneInfoColumn(part, index)
            }else {
              this.buildOneInfoRow(part, index)
            }
          }
          .width(`${100/this.parts.length}%`)
          .padding(5)
          .border({width: {top: 1, bottom: 1, left: (index === 0 || index === this.allCount - 1) ? 0 : 1, right: 0}, color: $r('app.color.color_obscure')})
        }, (part: GraphPart) =>json.stringify(part))
      }
      .width('100%')
      .margin({top: 10, bottom: 20})
      .justifyContent(FlexAlign.Center)

    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')

  }


  @Builder buildOneInfoRow(part: GraphPart, index: number){
    Row({ space: 4}) {
      //颜色块
      Rect()
        .width(12)
        .height(12)
        .fill(part.color)
        .borderRadius(3)

      //正确率: 20%
      Row(){
        //正确率:
        Text(`${part.partName}: `)
          .fontSize(10)
          .maxFontSize(10)
          .minFontSize(2)
          .maxLines(1)
          .fontColor(Color.Black)

        //20%
        Text(`${(this.allCount > 0 ? (part.count * 100 / this.allCount).toFixed(this.precision) : 0)}%`)
          .fontSize(10)
          .maxFontSize(10)
          .minFontSize(2)
          .maxLines(1)
          .fontColor(part.color)
      }

    }
  }


  @Builder buildOneInfoColumn(part: GraphPart, index: number){
    Column({ space: 4}) {
      //颜色块
      Rect()
        .width(12)
        .height(12)
        .fill(part.color)
        .borderRadius(3)

      //正确率: 20%
      Text(`${part.partName}: ${(this.allCount > 0 ? (part.count * 100 / this.allCount).toFixed(this.precision) : 0)}%`)
        .fontSize(10)
        .maxFontSize(10)
        .minFontSize(2)
        .maxLines(1)
        .fontColor(part.color)
    }
  }

}