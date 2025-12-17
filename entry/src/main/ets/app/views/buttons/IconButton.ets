import { vibrate } from "../../../common/components/Vibrator/Vibrator"

/////////////////////////////////////
/// svg图片使用的，可以着色的图标按钮
/////////////////////////////////////

@ComponentV2
export struct IconButton {
  // 必需属性（通过@Param从外部传入）
  @Param icon              : Resource | null = null
  @Event onClickCallBack   : () => void      = () => {}

  // 可选样式属性（通过@Param支持外部修改）
  @Param iconSize          : number | string = 22
  @Param iconColor         : ResourceColor   = $r('app.color.colorPrimary')
  @Param iconColorSelected : ResourceColor   = $r('app.color.colorAccent2')
  @Param bgColor           : ResourceColor   = Color.Transparent
  @Param buttonType        : ButtonType      = ButtonType.Normal

  // 内部状态管理（使用@Local）
  @Local pressed: boolean = false

  build() {
    Button() {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.pressed ? this.iconColorSelected : this.iconColor)
    }
    .type(this.buttonType)
    .width(this.iconSize)
    .height(this.iconSize)
    .backgroundColor(this.bgColor)
    .onTouch((event: TouchEvent)=>{

      ///按下状态
      if (event.type === TouchType.Down || event.type === TouchType.Move) {
        this.pressed = true
      }else{
        this.pressed = false
      }
    })
    .onClick(() => {
      this.onClickCallBack();

      vibrate() //震动

    })
    .stateEffect(this.pressed) // 响应状态变化
  }
}
