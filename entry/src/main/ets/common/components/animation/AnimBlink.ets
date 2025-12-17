/**
 * 闪烁动画参数类型定义
 */
export interface BlinkOptions {
  set        : (opacity: number) => void   // 必须：设置透明度的方法（0~1）
  times?     : number                      // 可选：闪烁次数（默认 3 次）
  duration?  : number                      // 可选：每次闪烁的时间（默认 500ms）
  onFinished?: () => void                 // 可选：动画完成后的回调函数
}

/**
 * 执行闪烁动画（类似 SwiftUI 中 blink 效果）
 */
export function blink(options: BlinkOptions): void {
  const times     = options.times    ?? 3
  const duration  = options.duration ?? 300
  const set       = options.set

  let count     = 0
  let visible   = true

  /**
   * 执行一步闪烁
   */
  const blinkStep = () => {
    if (count >= times * 2) {
      // 所有闪烁完成，恢复为可见
      set(1)
      options.onFinished?.()
      return
    }

    // 设置透明度（1 可见，0 隐藏）
    const nextOpacity = visible ? 0 : 1

    // 执行动画
    animateTo({ duration, curve: Curve.EaseInOut }, () => {
      set(nextOpacity)
    })

    visible = !visible
    count++

    setTimeout(blinkStep, duration)
  }

  blinkStep()
}