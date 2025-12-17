import { vibrate } from "../../common/components/Vibrator/Vibrator"

@ComponentV2
export struct NumberPickerView {

  // ===================== 参数 =====================
  @Param maxValue: number = 100               // 最大值
  @Param minValue: number = 1                 // 最小值
  @Param selectedValue: number = 20           // 当前选中值（外部可传入）
  @Event onSelected: (val: number) => void = (val: number) => {}  // 选中回调（向外通知）

  // ===================== 内部状态 =====================
  @Local private datas: string[] = []         // 显示数据（含前后占位 ''）
  @Local private leftIndex: number = 0        // Swiper.index（左侧可见项）
  @Local private centerIndex: number = 0      // 中间项索引（用于高亮样式）
  @Local private itemWidth: number = 30       // 每项宽度基准（可调整）

  // ===================== 生命周期 =====================
  aboutToAppear() {
    // 准备数据并将 selectedValue 对齐到中间
    this.refreshDatas()
    this.refreshSelectedValue()
  }

  // ===================== UI 构建 =====================
  build() {
    Column() {
      Stack() {
        // 中间背景：圆角长方形，高亮中间项
        Rect()
          .backgroundColor($r('app.color.color_obscure'))
          .borderRadius(12)          // 圆角长方形
          .radius(12)
          .width(80)
          .height(40)
          .opacity(0.08)
          .align(Alignment.Center)

        // Swiper 轮盘
        Swiper() {
          // ForEach 渲染每一项（datas 包含前后占位）
          ForEach(this.datas, (item: string, index: number) => {
            Column() {
              Text(item)
                // 内联判断：是否为中间项（index === centerIndex）
                .opacity(item === '' ? 0 : (index === this.centerIndex ? 1 : 0.45))
                .fontSize(index === this.centerIndex ? 32 : 26)
                .fontWeight(index === this.centerIndex ? FontWeight.Bold : FontWeight.Normal)
                //.fontColor(index === this.centerIndex ? Color.Red : Color.Black)
                //.scale({ x: index === this.centerIndex ? 1 : 0.78, y: index === this.centerIndex ? 1 : 0.78 })
                .textAlign(TextAlign.Center)
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .width('100%')
        .height(70)
        .displayCount(3)                         // 同时显示 3 项（左/中/右）
        .displayMode(SwiperDisplayMode.STRETCH) // 视觉更像轮盘
        .loop(false)
        .autoPlay(false)
        .indicator(false)
        .itemSpace(this.itemWidth)
        .cachedCount(2)
        .curve(Curve.EaseOut)
        .index(this.leftIndex)                   // 传入左侧索引
        .onChange((leftIdx: number) => {
          // Swiper.onChange 回来的 index 是 leftmost（左侧可见项），中间项 = leftIdx + 1
          const centerIdx = leftIdx + 1

          // 边界保护
          const safeCenter = Math.min(Math.max(centerIdx, 0), this.datas.length - 1)
          const maxLeft = Math.max(0, this.datas.length - 3)  // displayCount=3

          // 更新索引（left & center）
          this.leftIndex   = Math.min(Math.max(leftIdx, 0), maxLeft)
          this.centerIndex = safeCenter

          // 触发外部 onSelected（如果中间项不是占位）
          const data = this.datas[safeCenter]
          if (data && data.trim() !== '') {
            const val = parseInt(data.trim())
            if (!isNaN(val)) {
              // 可选：同步内部 selectedValue（如需要）
              // this.selectedValue = val
              this.onSelected(val)
            }
          }

          // 震动反馈
          vibrate()
        })
      }
      .alignContent(Alignment.Center)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ===================== 方法 =====================

  /**
   * 刷新数据数组
   * - 生成从 minValue 到 maxValue 的字符串数组
   * - 在前后各添加 1 个空占位 ''，保证首尾也能居中显示
   */
  private refreshDatas(): void {
    const mainData: string[] = Array.from<number, string>(
      { length: this.maxValue - this.minValue + 1 },
      (_, i) => `${i + this.minValue}`
    )

    // 前后各添加 1 个空占位，displayCount = 3 时足够
    this.datas = ['', ...mainData, '']
  }

  /**
   * 依据 selectedValue 设置 leftIndex 与 centerIndex，使 selectedValue 显示在中间
   * - 若找不到 selectedValue，则默认展示数组中部
   */
  private refreshSelectedValue(): void {
    const strValue = `${this.selectedValue}`
    const idx = this.datas.indexOf(strValue)

    if (idx >= 0) {
      // 期望 selectedValue 在中间：leftIndex = idx - 1
      let desiredLeft = idx - 1
      const maxLeft = Math.max(0, this.datas.length - 3) // displayCount=3

      if (desiredLeft < 0) desiredLeft = 0
      if (desiredLeft > maxLeft) desiredLeft = maxLeft

      this.leftIndex   = desiredLeft
      this.centerIndex = desiredLeft + 1
    } else {
      // 未找到：默认把数组中间项放在中间显示
      const middle = Math.floor(this.datas.length / 2)
      const desiredLeft = Math.max(0, middle - 1)
      this.leftIndex   = desiredLeft
      this.centerIndex = desiredLeft + 1
    }

    // 如果 center 有实际数值，触发一次 onSelected（同步初始状态）
    const centerVal = this.datas[this.centerIndex]
    if (centerVal && centerVal.trim() !== '') {
      const v = parseInt(centerVal.trim())
      if (!isNaN(v)) this.onSelected(v)
    }
  }
}