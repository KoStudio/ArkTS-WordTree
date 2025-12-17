import { vibrate } from "../../../common/components/Vibrator/Vibrator"

export enum IconPosition {
  Left,
  Top
}

@ComponentV2
export struct IconTextButton {
  // 必需属性
  @Param icon            : Resource | null = null
  @Param text            : ResourceStr     = ""
  @Event onClickCallBack : () => void      = () => {}

  // 可选样式
  @Param iconSize        : number | string = 24
  @Param fontSize        : number | string = 16
  @Param iconColor       : ResourceColor   = $r('app.color.colorAccent')
  @Param iconColorSelected: ResourceColor  = $r('app.color.colorAccent2')
  @Param textColor       : ResourceColor   = $r('app.color.colorPrimary')
  @Param bgColor         : ResourceColor   = Color.Transparent
  @Param buttonType      : ButtonType      = ButtonType.Normal
  @Param iconPosition    : IconPosition    = IconPosition.Left
  @Param spacing         : number          = 6   // 图标和文字间距

  // 内部状态
  @Local pressed: boolean = false

  build() {
    Button() {
      if (this.iconPosition === IconPosition.Left) {
        Row({ space: this.spacing}) {
          this.BuildIcon()
          this.BuildText()
        }
        .alignItems(VerticalAlign.Center)
      } else if (this.iconPosition === IconPosition.Top) {
        Column({ space: this.spacing }) {
          this.BuildIcon()
          this.BuildText()
        }
        .alignItems(HorizontalAlign.Center)
      }
    }
    .type(this.buttonType)
    .backgroundColor(this.bgColor)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down || event.type === TouchType.Move) {
        this.pressed = true
      } else {
        this.pressed = false
      }
    })
    .onClick(() => {
      this.onClickCallBack()
      vibrate()
    })
    .stateEffect(this.pressed)
  }

  // MARK: - 内部封装
  @Builder BuildIcon() {
    if (this.icon) {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.pressed ? this.iconColorSelected : this.iconColor)
    }
  }

  @Builder BuildText() {
    Text(this.text)
      .fontSize(this.fontSize)
      .fontColor(this.textColor)
      .alignSelf(ItemAlign.Center)
  }
}