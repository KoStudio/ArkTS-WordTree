// MARK: - SegmentItem 接口
export interface SegmentItem {
  title     : ResourceStr   // 段标题
  isEnabled : boolean       // 是否可用
}

// MARK: - Segment 控件
@ComponentV2
export struct SegmentButton {
  // ========== 外部参数 ==========
  @Param @Require items                : SegmentItem[]                // 段标题数组（每个 item 可控制是否可用）
  @Param selectedIndex                 : number          = 0           // 当前选中索引
  @Event onSelect                      : (index: number) => void       // 点击回调

  // ========== 尺寸相关参数（可外部设置） ==========
  @Param totalWidth                    : Length          = 'auto'      // 总宽度（数字=px / 字符串=如 '100%' / 'auto'）
  @Param totalHeight                   : Length          = 'auto'      // 总高度（数字=px / 字符串=如 '44px' / 'auto'）

  // ========== 可配置样式参数（带默认值） ==========
  @Param cornerRadius                  : number          = 20          // 圆角大小
  @Param fontSize                      : number          = 15          // 字体大小
  @Param btnPadding                    : Padding         = { top: 6, bottom: 6, left: 18, right: 18 } // 内边距
  @Param spacing                       : number          = 0           // 按钮间距

  @Param selectedTextColor             : ResourceColor   = Color.White  // 选中文字颜色
  @Param unselectedTextColor           : ResourceColor   = $r('app.color.colorPrimary') // 未选中文字颜色
  @Param disabledTextColor             : ResourceColor   = $r('app.color.color_gray') // 禁用文字颜色

  @Param selectedBgColor               : ResourceColor   = $r('app.color.colorPrimary') // 选中背景色
  @Param unselectedBgColor             : ResourceColor   = Color.Transparent            // 未选中背景色
  @Param disabledBgColor               : ResourceColor   = Color.Transparent            // 禁用背景色

  @Param btnBorderColor                : ResourceColor   = $r('app.color.colorPrimary') // 边框颜色
  @Param btnBorderWidth                : number          = 1           // 边框宽度

  // ========== 内部状态 ==========
  @Local private computedBtnWidth      : Length          = 'auto'      // 计算后的每个按钮宽度（在 aboutToAppear 初始化）
  @Local private btnCount              : number          = 0           // 按钮数量（缓存，避免在 build 中计算逻辑）

  // ========== 内部方法 ==========
  private isSelected(index: number) : boolean {
    return this.selectedIndex === index
  }

  private isEnabled(index: number) : boolean {
    return this.items.length > index ? this.items[index].isEnabled : true
  }

  // ========== 生命周期：计算每个按钮宽度 ==========
  aboutToAppear() {
    // 按钮数量
    this.btnCount = this.items.length > 0 ? this.items.length : 1

    // totalWidth 为数字（像素）时，直接平均分配（返回数字）
    if (typeof this.totalWidth === 'number') {
      const numWidth = (this.totalWidth as number) / this.btnCount
      this.computedBtnWidth = Math.floor(numWidth) // 使用整数像素（可按需保留小数）
      return
    }

    // totalWidth 为字符串且为百分比（如 "100%"）时，解析百分比并平均分配
    if (typeof this.totalWidth === 'string' && (this.totalWidth as string).trim().endsWith('%')) {
      const s       = (this.totalWidth as string).trim()
      const percent = parseFloat(s.substring(0, s.length - 1)) // 例如 100
      if (!isNaN(percent)) {
        const eachPercent = percent / this.btnCount
        // 保留 4 位小数以减少误差
        this.computedBtnWidth = `${(Math.round(eachPercent * 10000) / 10000).toString()}%`
        return
      }
    }

    // 其它情况回退为 'auto'（按内容自适应）
    this.computedBtnWidth = 'auto'
  }

  // ========== 构建视图 ==========
  build() {
    Row({ space: this.spacing }) {
      ForEach(this.items, (item: SegmentItem, index: number) => {
        Text(item.title)
          .width(this.computedBtnWidth) // 使用预先计算好的宽度（number 或 字符串百分比 或 'auto'）
          .height(this.totalHeight)
          .fontSize(this.fontSize)
          .padding(this.btnPadding)
          .fontColor(this.isSelected(index) ? this.selectedTextColor : (this.isEnabled(index) ? this.unselectedTextColor : this.disabledTextColor))
          .backgroundColor(this.isSelected(index) ? this.selectedBgColor : (this.isEnabled(index)  ? this.unselectedBgColor : this.disabledBgColor))
          .borderRadius(this.cornerRadius)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.items[index].isEnabled) {
              this.onSelect(index)
            }
          })
      })
    }
    .width(this.totalWidth)
    .height(this.totalHeight)
    .borderRadius(this.cornerRadius)
    .border({ color: this.btnBorderColor, width: this.btnBorderWidth })
    .backgroundColor(Color.Transparent)
  }
}