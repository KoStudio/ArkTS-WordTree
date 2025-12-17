import { IconTintButton } from "./buttons/IconTintButton"
import { TextButton } from "./buttons/TextButton"

// 定义按钮项的数据结构
export interface NavButtonItem {
  text?: ResourceStr        // 文本（可选）
  icon?: Resource           // 图标（可选）
  isSvg?: boolean           // 默认是png
  color?: ResourceColor     // 颜色
  onClick?: () => void      // 点击回调（可选）
}

@ComponentV2
export struct NavBarView {

  // 中间标题
  @Param title?: ResourceStr | null = null

  // 左右两侧按钮（可包含任意多个）
  @Param leftButtons: NavButtonItem[]    = []
  @Param rightButtons: NavButtonItem[]   = []
  @Param navBarBgColor: ResourceColor    = $r('app.color.colorPrimary')
  @Param navBarTitleColor: ResourceColor = Color.White //titleColor, 也是默认的icon的tintColor，各btn可以再单独设置


  build() {
    Stack() {
      // 中间标题
      if (this.title) {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.navBarTitleColor)
          .alignSelf(ItemAlign.Center)
      }

      // 顶部左右按钮区域
      Row({space: 16}) {
        // 左侧按钮组
        ForEach(this.leftButtons, (btn: NavButtonItem) => {
          if (btn.icon) {
            // 左侧 图标按钮
            IconTintButton({
              icon: btn.icon,
              iconColor: btn.color ?? this.navBarTitleColor,
              isSvg: btn.isSvg,
              iconSize: 22,
              onClickCallBack: btn.onClick
            })
          } else if (btn.text) {
            // 左侧 文本按钮
            TextButton({
              text: btn.text,
              fontColor: btn.color ?? this.navBarTitleColor,
              bgColor: Color.Transparent,
              minWidth: 44,
              onClickCallBack: () => { btn.onClick?.() }
            })
          }
        })

        // 中间留空自动分隔
        Blank().layoutWeight(1)

        // 右侧按钮组
        ForEach(this.rightButtons, (btn: NavButtonItem) => {
          if (btn.icon) {
            // 右侧 图标按钮
            IconTintButton({
              icon: btn.icon,
              iconColor: btn.color ?? this.navBarTitleColor,
              iconSize: 22,
              isSvg: btn.isSvg,
              onClickCallBack: btn.onClick
            })
          } else if (btn.text) {
            // 右侧 文本按钮
            TextButton({
              text: btn.text,
              fontColor: btn.color ?? this.navBarTitleColor,
              bgColor: Color.Transparent,
              minWidth: 44,
              onClickCallBack: () => { btn.onClick?.() }
            })
          }
        })
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .constraintSize({minHeight: 50})
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .backgroundColor(this.navBarBgColor)
  }
}

