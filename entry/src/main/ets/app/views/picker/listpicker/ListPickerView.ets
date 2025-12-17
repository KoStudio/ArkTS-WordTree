import { dFontNameDefault } from "../../../constants/AppDefines"
import { TintImage } from "../../TintImage"

export interface ListPickerItem {
  title : string            // 显示的文字标题
  font? : string            // 字体名（用于字体选择器）
  icon? : ResourceStr       // 可选图标资源
}

@ComponentV2
export struct ListPickerView {
  // ======== 参数区 ========
  @Param @Require items        : ListPickerItem[]                          // 数据源（必须传入）
  @Param selectedIndex?        : number           = -1                     // 当前选中索引（默认无选中）
  @Param itemColor?            : ResourceColor    = Color.Black            // 文字颜色（可选）
  @Param @Require onPicked     : (item: ListPickerItem, index: number) => void // 点击回调（必须）

  // ======== 构建区 ========
  build() {
    List({ space: 4 }) {
      ForEach(this.items, (item: ListPickerItem, index: number) => {
        // 单行列表项
        ListItem() {

          Row() {

            // 左侧：图标 + 文本
            Row({ space: 8 }) {
              if (item.icon) {
                Image(item.icon)
                  .width(20)
                  .height(20)
                  .fillColor(this.itemColor ?? Color.Black)
              }

              Text(item.title)
                .fontColor(this.itemColor ?? Color.Black)
                .fontWeight(FontWeight.Regular)
                .fontFamily(item.font ?? dFontNameDefault)//'HarmonyOS Sans'
            }

            // 右侧：选中打勾图标
            if (this.selectedIndex === index) {
              TintImage({src: $r('app.media.done'), colorStr: '#0000FF'})
                .width(20)
                .height(20)

            }
          }
          .backgroundColor(Color.White)
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10})
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween)
          .onClick(() => this.onPicked(item, index))
          .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
        }
      }, (item: ListPickerItem, index: number) => `${index}-${item.title}`)
    }
    .padding(12)
    .backgroundColor(Color.White)

  }
}