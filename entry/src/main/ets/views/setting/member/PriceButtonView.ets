@ComponentV2
export struct PriceButtonView {
  private static readonly BUTTON_WIDTH_VP          : number            = 90   // 价格按钮宽度
  private static readonly BUTTON_HEIGHT_VP         : number            = 110  // 价格按钮高度
  private static readonly BUTTON_RADIUS_VP         : number            = 3    // 价格按钮圆角，参考 Android 3dp
  private static readonly BORDER_WIDTH_VP          : number            = 1    // 按钮边框宽度；选中与未选中保持一致，避免左上角标位置变化

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

          Text(this.displayPriceText())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isSelected ? $r('app.color.colorPrimary') : Color.White)
            .textAlign(TextAlign.Center)

          if (this.perMonth !== null && this.perMonth !== undefined && this.perMonth.length > 0) {
            Text(this.perMonth)
              .fontSize(11)
              .fontColor($r('app.color.color_gray'))
              .textAlign(TextAlign.Center)
          } else {
            // 与 Android `PriceButtonView.setTerm(...)` 当前行为保持一致：
            // term 行先保留占位，但默认隐藏，这样没有月均价时按钮高度也不会变化。
            Text(this.term)
              .fontSize(14)
              .fontColor($r('app.color.color_gray'))
              .textAlign(TextAlign.Center)
              .visibility(Visibility.Hidden)
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
            .backgroundColor($r('app.color.color_text_marked'))
        }
      }
    }
      .type(ButtonType.Normal)
      .width(PriceButtonView.BUTTON_WIDTH_VP)
      .height(PriceButtonView.BUTTON_HEIGHT_VP)
      .padding(0)
      .backgroundColor(this.isSelected ? Color.White : Color.Transparent)
      .border({
        width  : PriceButtonView.BORDER_WIDTH_VP,
        color  : this.isSelected ? $r('app.color.color_white') : Color.White,
        radius : PriceButtonView.BUTTON_RADIUS_VP
      })
      .borderRadius(PriceButtonView.BUTTON_RADIUS_VP)
      .onClick(() => {
        this.onClickCallBack()
      })
  }

  // 价格显示文案；与 Android `setPrice(...)` 语义一致，去掉末尾的 `.00`
  private displayPriceText(): string {
    const dotIndex = this.price.lastIndexOf('.00')

    // 分支：没有 `.00` 时直接返回原文案
    if (dotIndex < 0) {
      return this.price
    }

    const suffix = this.price.substring(dotIndex + 3)

    // 分支：`.00` 后面如果还跟着数字，则不是末尾金额格式，不做处理
    for (let i = 0; i < suffix.length; i++) {
      const ch = suffix[i]
      if (ch >= '0' && ch <= '9') {
        return this.price
      }
    }

    return this.price.substring(0, dotIndex) + suffix
  }

}
