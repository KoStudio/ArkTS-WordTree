@ComponentV2
export struct PriceButtonView {
  private static readonly BUTTON_WIDTH_VP          : number            = 90   // 价格按钮宽度
  private static readonly BUTTON_HEIGHT_VP         : number            = 110  // 价格按钮高度
  private static readonly BUTTON_RADIUS_VP         : number            = 3    // 价格按钮圆角，参考 Android 3dp

  @Param title                                     : string            = ''    // 按钮标题
  @Param price                                     : string            = ''    // 价格文案
  @Param term                                      : string            = ''    // 周期文案

  @Param tagText                                   : string | null     = null  // 左上角角标文案
  @Param perMonth                                  : string | null     = null  // 折算后的月均价文案
  @Param isSelected                                : boolean           = false // 是否选中当前按钮
  @Event onClickCallBack                           : () => void        = () => {}

  // 构建价格按钮卡片
  build() {
    Button() {
      Stack({ alignContent: Alignment.TopStart }) {
        Column({ space: 6 }) {
          Text(this.title)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isSelected ? $r('app.color.colorPrimary') : Color.White)
            .textAlign(TextAlign.Center)
            .maxLines(1)

          Text(this.price)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isSelected ? $r('app.color.colorPrimary') : Color.White)
            .textAlign(TextAlign.Center)

          if (this.perMonth !== null && this.perMonth !== undefined && this.perMonth.length > 0) {
            Text(this.perMonth)
              .fontSize(11)
              .fontColor(this.isSelected ? $r('app.color.color_obscure') : Color.White)
              .textAlign(TextAlign.Center)
          } else {
            Text(this.term)
              .fontSize(14)
              .fontColor(this.isSelected ? $r('app.color.colorPrimary') : Color.White)
              .textAlign(TextAlign.Center)
          }
        }
          .width(PriceButtonView.BUTTON_WIDTH_VP)
          .height(PriceButtonView.BUTTON_HEIGHT_VP)
          .padding({ left: 2, right: 2, top: 8, bottom: 8 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        if (this.tagText !== null && this.tagText !== undefined && this.tagText.length > 0) {
          Text(this.tagText)
            .fontSize(10)
            .fontColor(Color.White)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor($r('app.color.color_red'))
        }
      }
    }
      .type(ButtonType.Normal)
      .backgroundColor(this.isSelected ? Color.White : Color.Transparent)
      .border({
        width  : this.isSelected ? 2 : 1,
        color  : this.isSelected ? $r('app.color.color_white') : Color.White,
        radius : PriceButtonView.BUTTON_RADIUS_VP
      })
      .borderRadius(PriceButtonView.BUTTON_RADIUS_VP)
      .onClick(() => {
        this.onClickCallBack()
      })
  }
}
