import { vibrate } from "../../../common/components/Vibrator/Vibrator"
import { getColor } from "../../../common/utils/ResourceUtils"
import { TintImage } from "../TintImage"

/////////////////////////////////////
/// png图片使用的，可以着色的图标按钮
/////////////////////////////////////
@ComponentV2
export struct IconTintButton {
  // 必需属性（通过@Param从外部传入）
  @Param icon              : Resource | null = null
  @Param isSvg             : boolean = false //默认是png
  @Event onClickCallBack   : () => void      = () => {}



  // 可选样式属性（通过@Param支持外部修改）
  @Param iconSize          : number | string = 22
  @Param iconColor         : ResourceColor   = $r('app.color.colorPrimary')
  @Param iconColorSelected : ResourceColor   = $r('app.color.colorAccent2')
  @Param bgColor           : ResourceColor   = Color.Transparent
  @Param buttonType        : ButtonType      = ButtonType.Normal
  @Param isEnabled        : boolean          = true

  // 内部状态管理（使用@Local）
  @Local pressed: boolean = false

  build() {
    Button() {
      TintImage({src: this.icon, colorStr: getColor(this.pressed ? this.iconColorSelected : this.iconColor), iconSize: this.iconSize, isSvg: this.isSvg})
        .width(this.iconSize)
        .height(this.iconSize)

    }
    .width(this.iconSize)
    .height(this.iconSize)
    .type(this.buttonType)
    .backgroundColor(this.bgColor)
    .enabled(this.isEnabled)
    .opacity(this.isEnabled ? 1 : 0.6)
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
