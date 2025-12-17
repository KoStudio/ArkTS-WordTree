import { ColorPickerView } from "./ColorPickerView"

@ComponentV2
export struct ColorPickerButton {
  // ======== 外部可配置参数 ========
  @Param @Require currentColor: string                         // 当前颜色值（例如 "#FF0000"）
  @Event onColorPicked: (color: string) => void                 // 选中颜色后的回调

  // ======== 可选参数（带默认值） ========
  @Param btnWidth: number        = 36
  @Param btnHeight: number       = 36
  @Param cornerRadius: number    = 5
  @Param btnBorderWidth: number  = 1

  // ======== 内部状态 ========
  @Local private selectedColor: string ='#FF0000'    // 内部实际显示颜色


  aboutToAppear(){
    this.selectedColor = this.currentColor
  }

  // ======== 构建入口 ========
  build() {
    Rect()
      .width(this.btnWidth)
      .height(this.btnHeight)
      .fill(this.selectedColor)
      .radius(this.cornerRadius)
      .strokeWidth(this.btnBorderWidth)
      .bindMenu(this.buildColorPickerContent())
  }

  // ======== 构建颜色选择器视图 ========
  @Builder
  private buildColorPickerContent() {
    ColorPickerView({
      selectedColor: this.selectedColor,
      onColorPicked: (color: string) => {
        this.selectedColor = color             // 🔹 内部颜色立即刷新
        this.onColorPicked(color)              // 🔹 通知外部
      }
    })
  }
}