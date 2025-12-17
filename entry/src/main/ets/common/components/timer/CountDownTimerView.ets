import { IconTintButton } from "../../../app/views/buttons/IconTintButton";
import { QuizManager } from "../../../models/datas/model/QuizManager";

/** 圆环倒计时（可配置颜色、时间，支持外部动态重启） */
@ComponentV2
export struct CountDownTimerView {

  // ========== 对外参数 ==========
  @Param   totalSeconds   : number  = 10           // 倒计时总秒数
  @Param   isPaused       : boolean = false
  @Param   restartKey     : number  = 0
  @Event   onTick?: (remainSeconds: number) => void  // 每秒回调
  @Event   onFinish?      : () => void            // 倒计时完成回调

  @Param   fgColor        : string = '#ffF9948C'  // 前景圆环颜色
  @Param   bgColor        : string = '#ffdedbdb'  // 背景圆环颜色
  @Param   btnWidth       : number = 32
  @Param   btnHeight      : number = 32

  @Event onAppearring: ((instance: CountDownTimerView) => void) | null = null;  //外部调用时，可通过此方法获得当前对象的引用

  @Local private lastSecondNotified: number = -1

  // ========== 本地状态 ==========
  @Local   private remainSeconds : number  = QuizManager.shared.questionSpeed //10    // 剩余秒数
  @Local   private running       : boolean = false // 是否运行中
  @Local   private paused        : boolean = false // 是否暂停中
  private   ringWidth            : number = 4    // 圆环宽度
  private   timerId              : number | undefined

  @Local   private ctxSettings   : RenderingContextSettings = new RenderingContextSettings(true)
  @Local   private ctx           : CanvasRenderingContext2D = new CanvasRenderingContext2D(this.ctxSettings)

  @Monitor('isPaused')
  private onChangeOfPaused() {
    if (this.isPaused) {
      this.pause()
    }else {
      this.resume()
    }
  }

  @Monitor('restartKey')
  private onChangeOfRestart() {
    //外部控制重启Timer
    this.stop()
    this.start()
  }

  aboutToAppear(): void {
    this.onAppearring?.(this)
  }

  // ========== 生命周期清理 ==========
  aboutToDisappear() {
    if (this.timerId !== undefined) {
      clearInterval(this.timerId)
      this.timerId = undefined
    }
  }

  // ========== 构建视图 ==========
  build() {
    Stack() {
      Canvas(this.ctx)
        .width('100%')
        .height('100%')
        .onReady(() => { try { this.draw(this.ctx) } catch(e) {} })

      Row() {
        // IconTintButton({
        //   icon     : this.paused || !this.running ? $r('app.media.roll') : $r('app.media.pause'),
        //   iconSize : this.btnWidth,
        //   iconColor: $r('app.color.colorAccent'),
        //   onClickCallBack: () => {
        //     if (!this.running) { this.start() }
        //     else { this.paused ? this.resume() : this.pause() }
        //   }
        // })
        Text(`${this.remainSeconds.toFixed(0)}`)
          .fontSize(16)
          .minFontScale(0.1)
          .fontColor(Color.White)
          .width(this.btnWidth)
          .height(this.btnHeight)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .align(Alignment.Center)
    .width(this.btnWidth + (this.ringWidth / 2))
    .height(this.btnHeight + (this.ringWidth / 2))

  }

  // ========== 对外 API ==========
  start() {
    if (this.remainSeconds <= 0) this.remainSeconds = this.totalSeconds

    if (this.timerId !== undefined) {
      clearInterval(this.timerId)
      this.timerId = undefined
    }

    this.running = true
    this.paused  = false
    this.updateCanvas()

    this.timerId = setInterval(() => {
      if (!this.running || this.paused) return

      this.remainSeconds = Math.max(0, parseFloat((this.remainSeconds - 0.1).toFixed(1)))
      this.updateCanvas()

      // 每秒回调一次
      const currentSecond = Math.ceil(this.remainSeconds)
      if (currentSecond !== this.lastSecondNotified) {
        this.lastSecondNotified = currentSecond
        try { this.onTick?.(currentSecond) } catch(e) {}
      }

      if (this.remainSeconds <= 0) {
        this.stop()
        try { this.onFinish?.() } catch(e) {}
      }
    }, 100) as number
  }

  pause() {
    if (!this.running) return
    this.paused = true
  }

  resume() {
    if (!this.running && this.remainSeconds > 0) { this.start(); return }
    if (!this.paused) return
    this.paused = false
    this.updateCanvas()
  }

  stop() {
    this.running       = false
    this.paused        = false
    if (this.timerId !== undefined) {
      clearInterval(this.timerId as number)
      this.timerId = undefined
    }
    this.remainSeconds = 0
    this.updateCanvas()
  }

  getRemainSeconds(): number {
    return Math.ceil(this.remainSeconds)
  }

  // ========== Canvas 更新 ==========
  private updateCanvas() {
    try { if (this.ctx) { this.draw(this.ctx) } } catch(e) {}
  }
  private draw(ctx: CanvasRenderingContext2D) {
    if (!ctx) return

    const width   = ctx.width  > 0 ? ctx.width  : 26
    const height  = ctx.height > 0 ? ctx.height : 26
    const cx      = width  / 2
    const cy      = height / 2
    const radius  = Math.min(cx, cy) - this.ringWidth / 2

    ctx.clearRect(0, 0, width, height)

    // 背景环（完整圆）
    ctx.lineWidth   = this.ringWidth
    ctx.strokeStyle = this.bgColor
    ctx.beginPath()
    ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
    ctx.stroke()

    // 前景环（剩余时间比例）
    const percent    = (this.totalSeconds - this.remainSeconds) / this.totalSeconds
    const startAngle = -Math.PI / 2             // 顶部开始
    const endAngle   = startAngle + 2 * Math.PI * percent

    ctx.strokeStyle = this.fgColor
    ctx.beginPath()
    ctx.arc(cx, cy, radius, startAngle, endAngle, false)
    ctx.stroke()
  }
}