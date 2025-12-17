import { vibrate } from "../../common/components/Vibrator/Vibrator"

@ComponentV2
export struct StepperButton {

  // ===================== 参数 =====================
  @Param initialValue      : number                                   = 0         // 初始值
  @Param step              : number                                   = 1         // 步长
  @Param minValue          : number                                   = 0         // 最小值
  @Param maxValue          : number                                   = 100       // 最大值
  @Param isEnable          : boolean                                  = true      // 是否启用

  @Param showSignForPositive : boolean                                = false     // 正数是否显示 '+' 前缀
  @Param showSignForZero     : boolean                                = false     // 0 是否显示 '±0'
  @Param showSignForNegative : boolean                                = true      // 负数是否显示 '-'（一般默认 true）
  @Param valueFormatter    : ((val: number) => string) | null         = null      // 可选自定义显示格式

  @Event onValueChange     : (newVal: number, oldVal: number) => void = (n, o) => {}  // 数值变化回调
  @Event onReachMin        : () => void                               = () => {}  // 达到最小值回调
  @Event onReachMax        : () => void                               = () => {}  // 达到最大值回调

  // ===================== 样式配置 =====================
  @Param bgColor           : ResourceColor  = $r('app.color.color_obscure')  // 背景颜色
  @Param textColor         : ResourceColor  = $r('app.color.color_text')  // 文字颜色
  @Param buttonColor       : ResourceColor  = $r('app.color.color_obscure')  // 按钮背景色
  @Param textSize          : number = 16          // 文字大小
  @Param btnRadius         : number = 8           // 圆角半径
  @Param btnWidth          : number = 40          // 按钮宽度
  @Param btnHeight         : number = 32          // 组件整体高度

  // ===================== 内部状态 =====================
  @Local private currentValue : number = 0        // 当前值
  @Local private lastValue    : number = 0        // 上一次值，用于比较触发回调

  // ===================== 生命周期 =====================
  aboutToAppear() {
    // 初始化当前值，并确保在有效范围内
    this.currentValue = this.clampValue(this.initialValue)
    this.lastValue    = this.currentValue
  }

  // ===================== UI 构建 =====================
  build() {
    Row() {
      // 左侧减按钮
      this.buildDecrementButton()

      // 中间数值显示
      this.buildValueDisplay()

      // 右侧加按钮
      this.buildIncrementButton()
    }
    //.width('100%')
    .height(this.btnHeight)
    .backgroundColor(this.bgColor)
    .borderRadius(this.btnRadius)
    .opacity(this.isEnable ? 1.0 : 0.6)       // 禁用状态透明度降低
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  // ===================== 按钮构建方法 =====================
  @Builder
  private buildDecrementButton() {
    Button('-', { type: ButtonType.Normal })
      .width(this.btnWidth)
      .height(this.btnHeight)
      .fontSize(this.textSize)
      .fontColor(this.textColor)
      .backgroundColor(this.buttonColor)
      .borderRadius({ topLeft: this.btnRadius, bottomLeft: this.btnRadius })
      .enabled(this.isEnable && this.currentValue > this.minValue)
      .onClick(() => this.decrement())
  }

  @Builder
  private buildIncrementButton() {
    Button('+', { type: ButtonType.Normal })
      .width(this.btnWidth)
      .height(this.btnHeight)
      .fontSize(this.textSize)
      .fontColor(this.textColor)
      .backgroundColor(this.buttonColor)
      .borderRadius({ topRight: this.btnRadius, bottomRight: this.btnRadius })
      .enabled(this.isEnable && this.currentValue < this.maxValue)
      .onClick(() => this.increment())
  }

  @Builder
  private buildValueDisplay() {
    // 如果外部传入了 valueFormatter，则使用它，否则使用默认格式
    Text(this.valueFormatter
      ? this.valueFormatter(this.currentValue)
      : this.defaultFormatValue())
      //.layoutWeight(1)                     // 占据剩余空间
      .height(this.btnHeight)
      .fontSize(this.textSize)
      .fontColor(this.textColor)
      .textAlign(TextAlign.Center)
      .padding(5)

      //.backgroundColor(Color.White)

  }

  // ===================== 核心逻辑方法 =====================
  /** 减少数值 */
  private decrement() {
    this.setValueInternal(this.currentValue - this.step)
  }

  /** 增加数值 */
  private increment() {
    this.setValueInternal(this.currentValue + this.step)
  }

  /** 设置内部值并触发回调 */
  private setValueInternal(newValue: number) {
    const clamped = this.clampValue(newValue)
    if (clamped !== this.currentValue) {
      const old = this.currentValue
      this.lastValue    = old
      this.currentValue = clamped
      this.onValueChange(clamped, old)
      vibrate()  // 触觉反馈
    }
  }

  /** 限制数值在[minValue, maxValue]范围，并触发边界回调 */
  private clampValue(value: number): number {
    if (value <= this.minValue) {
      this.onReachMin()
      return this.minValue
    }
    if (value >= this.maxValue) {
      this.onReachMax()
      return this.maxValue
    }
    return value
  }

  /** 默认数值格式化 */
  private defaultFormatValue(): string {
    // 步长小于1 → 一位小数，否则整数
    let valStr = this.step < 1
      ? this.currentValue.toFixed(1)//%0.1f
      : this.currentValue.toFixed(0)//%.0f%

    // 根据正负号设置前缀
    if (this.currentValue > 0 && this.showSignForPositive)       valStr = '+' + valStr
    if (this.currentValue < 0 && this.showSignForNegative)       valStr = '-' + valStr.replace('-', '')
    if (this.currentValue === 0 && this.showSignForZero)         valStr = '±0'

    return valStr
  }

  // ===================== 公共方法 =====================
  /** 外部设置值 */
  setValue(value: number, notify: boolean = true) {
    if (notify) {
      this.setValueInternal(value)
    } else {
      this.currentValue = this.clampValue(value)
    }
  }

  /** 获取当前值 */
  getValue(): number {
    return this.currentValue
  }

  /** 重置为初始值 */
  reset() {
    this.setValue(this.initialValue)
  }
}