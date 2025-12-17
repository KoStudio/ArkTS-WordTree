import { vibrate } from "../../../common/components/Vibrator/Vibrator"

@ComponentV2
export struct TextCheckBox {
  // 必需属性
  @Param text    : ResourceStr     = ""
  @Param checked : boolean         = false
  @Event $checked : (checked: boolean) => void = (checked) => {}

  // 可选样式
  @Param fontSize        : number | string = 16
  @Param textColor       : ResourceColor   = $r('app.color.colorPrimary')
  @Param textColorChecked: ResourceColor   = $r('app.color.colorPrimary')
  @Param boxSize         : number | string = 20
  @Param boxColor        : ResourceColor   = $r('app.color.colorPrimary')
  @Param boxColorChecked : ResourceColor   = $r('app.color.colorPrimary')
  @Param spacing         : number          = 6  // 文本与复选框间距


  build() {
    Button() {
      Row({ space: this.spacing }) {
        this.BuildBox()
        this.BuildText()
      }
      .alignItems(VerticalAlign.Center)
    }
    .backgroundColor(Color.Transparent)
    .onClick(() => {

      this.actionChk(!this.checked)

    })
  }

  // MARK: - 内部封装
  @Builder BuildBox() {
    Column({}) {
      Checkbox()
        .width(this.boxSize)
        .height(this.boxSize)
        .shape(CheckBoxShape.ROUNDED_SQUARE)
        .unselectedColor(this.boxColor)
        .selectedColor(this.boxColorChecked)
        .select($$this.checked)
        .onChange((value: boolean) => {
          this.actionChk(value)
        })

    }
  }

  @Builder BuildText() {
    Text(this.text)
      .fontSize(this.fontSize)
      .fontColor(this.checked ? this.textColorChecked : this.textColor)
      .alignSelf(ItemAlign.Center)
  }

  private actionChk(value: boolean){
    this.$checked(value)

    //震动
    vibrate()
  }
}