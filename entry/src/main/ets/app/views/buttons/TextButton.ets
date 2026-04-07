@ComponentV2
export struct TextButton {
  @Param text: string | ResourceStr = ''
  @Event onClickCallBack: () => void = () => {}

  @Param isEnabled        : boolean          = true

  @Param fontSize         : number | string  = 16
  @Param fontColor        : ResourceColor    = $r('app.color.color_white')
  @Param fontColorPressed : ResourceColor    = $r('app.color.color_text')
  @Param fontColorDisable : ResourceColor    = $r('app.color.color_black')

  @Param bgColor          : ResourceColor    = $r('app.color.color_btn_bg')
  @Param bgColorPressed   : ResourceColor    = $r('app.color.color_btn_bg_down')
  @Param bgColorDisable   : ResourceColor    = $r('app.color.color_gray_light')

  @Param buttonType       : ButtonType       = ButtonType.Normal
  @Param radius           : number | string  = 4
  @Param textPadding      : Padding | number = 10
  @Param minWidth         : number           = 88
  @Param maxHeight        : number           = 40

  @Local pressed: boolean = false

  build() {
    Button() {
      Text(this.text)
        .fontSize(this.fontSize)
        .fontColor(this.isEnabled
          ? (this.pressed ? this.fontColorPressed : this.fontColor)
          : this.fontColorDisable)
        .minFontScale(0.1)
    }
    .width('auto')
    .constraintSize({ minWidth: this.minWidth, maxHeight: this.maxHeight })
    .type(this.buttonType)
    .backgroundColor(this.isEnabled
      ? (this.pressed ? this.bgColorPressed : this.bgColor)
      : this.bgColorDisable)
    .opacity(this.isEnabled ? 1 : 0.9)
    .borderRadius(this.radius)
    .padding(this.textPadding)
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.pressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false
      }
    })
    .onClick(() => {
      if (this.isEnabled) {
        this.onClickCallBack()
      }
    })
    .stateEffect(true)
  }
}
