@ComponentV2
export struct NoDataPanel {

  @Param message    : ResourceStr = 'No Data.';

  // 为 true 时根 Stack 占满父布局高度；为 false 时高度随内容（便于与下方按钮等在页面中部成组排列）
  @Param expandHeight: boolean = true;

  @Local imageSrc   : Resource    = $r('app.media.watermark');
  @Local imageWidth : number      = 120;
  @Local imageHeight: number      = 160;
  @Local textColor  : ResourceColor = $r('app.color.color_text2')//'#e0e0e0';
  @Local spacing    : number      = 15;

  // 水印图与提示文案列
  @Builder
  private mainColumn() {
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

  build() {
    // 分支：是否铺满高度（默认与其它列表空态一致）
    if (this.expandHeight) {
      Stack({ alignContent: Alignment.Center }) {
        this.mainColumn()
      }
        .width('100%')
        .height('100%')
    } else {
      Stack({ alignContent: Alignment.Center }) {
        this.mainColumn()
      }
        .width('100%')
    }
  }
}
