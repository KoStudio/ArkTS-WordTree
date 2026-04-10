@ComponentV2
export struct PriceButtonView {
  @Param title            : string         = ''
  @Param price            : string         = ''
  @Param term             : string         = ''
  @Param tagText          : string | null  = null
  @Param perMonth         : string | null  = null
  @Param isSelected       : boolean        = false
  @Event onClickCallBack  : () => void     = () => {}

  // 构建价格按钮卡片
  build() {
    Button() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Column({ space: 6 }) {
          Text(this.title)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isSelected ? $r('app.color.colorPrimary') : Color.White)
            .textAlign(TextAlign.Center)
            .maxLines(1)

          Text(this.price)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isSelected ? $r('app.color.colorPrimary') : Color.White)
            .textAlign(TextAlign.Center)

          if (this.perMonth !== null && this.perMonth !== undefined && this.perMonth.length > 0) {
            Text(this.perMonth)
              .fontSize(12)
              .fontColor(this.isSelected ? $r('app.color.colorPrimary') : Color.White)
              .textAlign(TextAlign.Center)
          } else {
            Text(this.term)
              .fontSize(12)
              .fontColor(this.isSelected ? $r('app.color.colorPrimary') : Color.White)
              .textAlign(TextAlign.Center)
          }
        }
          .width(112)
          .height(96)
          .padding({ left: 10, right: 10, top: 14, bottom: 10 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        if (this.tagText !== null && this.tagText !== undefined && this.tagText.length > 0) {
          Text(this.tagText)
            .fontSize(10)
            .fontColor(Color.White)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor($r('app.color.color_red'))
            .borderRadius(8)
            .margin({ top: 6, right: 6 })
        }
      }
    }
      .type(ButtonType.Normal)
      .backgroundColor(this.isSelected ? Color.White : Color.Transparent)
      .border({
        width  : this.isSelected ? 2 : 1,
        color  : this.isSelected ? $r('app.color.color_white') : Color.White,
        radius : 8
      })
      .borderRadius(8)
      .onClick(() => {
        this.onClickCallBack()
      })
  }
}
