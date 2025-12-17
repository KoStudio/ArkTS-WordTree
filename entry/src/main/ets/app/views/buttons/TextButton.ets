
@ComponentV2
export struct TextButton {
  // 必需属性（通过@Param从外部传入）
  @Param text: string | ResourceStr = ''  // 按钮文本
  @Event onClickCallBack: () => void = () => {}

  // 可选样式属性（带默认值）
  @Param fontSize         : number | string  = 16
  @Param fontColor        : ResourceColor    = $r('app.color.color_white')
  @Param fontColorPressed : ResourceColor    = $r('app.color.color_text')
  @Param bgColor          : ResourceColor    = $r('app.color.color_btn_bg')
  @Param bgColorPressed   : ResourceColor    = $r('app.color.color_btn_bg_down')
  @Param buttonType       : ButtonType       = ButtonType.Normal
  @Param radius           : number | string  = 6
  @Param textPadding      : Padding | number = 6
  @Param minWidth         : number           = 88
  @Param maxHeight        : number           = 32
  @Param isEnabled        : boolean          = true

  // 内部状态管理
  @Local pressed: boolean = false

  build() {
    Button() {
      Text(this.text)
        .fontSize(this.fontSize)
        .fontColor(this.isEnabled ? (this.pressed ? this.fontColorPressed : this.fontColor) : $r('app.color.color_black'))
        .minFontScale(0.1)
    }
    .width('auto')  // 根据内部内容自适应宽度
    .constraintSize({ minWidth: this.minWidth, maxHeight: this.maxHeight})  // 指定最小宽度为 66
    .type(this.buttonType)
    .backgroundColor(this.isEnabled ? (this.pressed ? this.bgColorPressed : this.bgColor) : $r('app.color.color_gray_light'))
    // .enabled(this.isEnabled)
    .opacity(this.isEnabled ? 1 : 0.9)
    .borderRadius(this.radius)
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
    .stateEffect(true)
  }
}