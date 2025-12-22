@ComponentV2
export struct NoDataPanel {

  @Param message    : ResourceStr = 'No Data.';

  @Local imageSrc   : Resource    = $r('app.media.watermark');
  @Local imageWidth : number      = 120;
  @Local imageHeight: number      = 160;
  @Local textColor  : ResourceColor = $r('app.color.color_text2')//'#e0e0e0';
  @Local spacing    : number      = 15;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Image(this.imageSrc)
          .id('imgNodata')
          .width(this.imageWidth)
          .height(this.imageHeight)

        Text(this.message)
          .id('tvNodata')
          .fontSize(16)
          .fontColor(this.textColor)
          .margin({ top: this.spacing })
      }

      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')

  }
}