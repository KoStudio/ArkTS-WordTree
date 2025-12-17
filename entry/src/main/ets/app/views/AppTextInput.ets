@ComponentV2
export struct AppTextInput {
  // 必需属性
  @Param text                     : string = ''
  @Event onChangeCallback         : (value: string) => void = (value: string) => {}

  // 可选样式属性（带默认值）
  @Param placeholder              : string | ResourceStr   = ''
  @Param type                     : InputType              = InputType.Normal
  @Param fontSize                 : number | string        = 16
  @Param fontColor                : ResourceColor          = $r('app.color.color_text')
  @Param placeholderColor         : ResourceColor          = Color.Grey
  @Param inputWidth               : string | number        = '100%'
  @Param inputHeight              : string | number        = 50
  @Param bgColor                  : ResourceColor          = Color.White
  @Param inputBorderColor         : ResourceColor          = Color.Gray
  @Param borderBottomWidth        : number                 = 1
  @Param inputRadius              : number                 = 0
  @Param inputPadding             : Padding | number       = { left: 8, right: 8 }
  @Param marginTop                : number                 = 12
  @Param isEnabled                : boolean                = true

  build() {
    TextInput({ text: this.text, placeholder: this.placeholder })
      .type(this.type)
      .onChange((value: string) => {
        this.onChangeCallback(value)
      })
      .width(this.inputWidth)
      .height(this.inputHeight)
      .backgroundColor(this.bgColor)
      .border({
        width : { bottom: this.borderBottomWidth },
        color : this.inputBorderColor,
        radius: this.inputRadius
      })
      .fontSize(this.fontSize)
      .fontColor(this.fontColor)
      .placeholderColor(this.placeholderColor)
      .padding(this.inputPadding)
      .margin({ top: this.marginTop })
      .enabled(this.isEnabled)
  }
}