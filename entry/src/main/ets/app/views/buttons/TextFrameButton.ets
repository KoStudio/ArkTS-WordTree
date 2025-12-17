
@ComponentV2
export struct TextFrameButton {
  // 必需属性（通过@Param从外部传入）
  @Param text: string | ResourceStr = ''  // 按钮文本
  @Event onClickCallBack: () => void = () => {}

  // 可选样式属性（带默认值）
  @Param fontSize         : number | string  = 16
  @Param fontColor        : ResourceColor    = $r('app.color.color_white')
  @Param fontColorPressed : ResourceColor    = $r('app.color.color_text')
  @Param frameColor          : ResourceColor    = $r('app.color.color_btn_bg')
  @Param frameColorPressed   : ResourceColor    = $r('app.color.color_btn_bg_down')
  @Param frameColorDisabled  : ResourceColor    = $r('app.color.color_btn_bg_down')
  @Param buttonType       : ButtonType       = ButtonType.Normal
  @Param radius           : number | string  = 6
  @Param textPadding      : Padding | number = 6
  @Param minWidth         : Length           = 88
  @Param minHeight        : Length           = 32
  @Param isEnabled        : boolean          = true

  // 内部状态管理
  @Local pressed: boolean = false

  build() {
    Button() {
      Text(this.text)
        .fontSize(this.fontSize)
        .fontColor(this.pressed ? this.fontColorPressed : this.fontColor)
        .minFontScale(0.1)
    }
    .width('auto')  // 根据内部内容自适应宽度
    .constraintSize({ minWidth: this.minWidth, minHeight: this.minHeight})  // 指定最小宽度为 66
    .type(this.buttonType)
    .backgroundColor(Color.Transparent)
    // .enabled(this.isEnabled) //不直接控制enabled，因为会整体变透明度，控制onClick就好
    .opacity(this.isEnabled ? 1 : 0.88)
    .borderRadius(this.radius)
    .border({width: 1, color: this.isEnabled ? (this.pressed ? this.frameColorPressed : this.frameColor) : this.frameColorDisabled})
    .padding(this.textPadding)
    .onTouch((event) => {
      // 处理按压状态
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
    .stateEffect(false)
  }
}