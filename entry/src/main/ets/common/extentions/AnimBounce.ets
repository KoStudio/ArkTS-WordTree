/**
 * 跳动动画参数类型定义
 */
export interface BounceOptions {
  set         : (x: number, y: number) => void   // 必须：设置水平(x)与垂直(y)偏移量的方法
  times?      : number                           // 可选：跳动次数（默认 3 次，即来回跳动 3 下）
  duration?   : number                           // 可选：每一步跳动的动画时间（单位：毫秒，默认 100ms）
  distance?   : number                           // 可选：每一步跳动max距离
  isHorizontal?: boolean                         // 可选：是否水平跳动，默认垂直跳动
  onFinished? : () => void                       // 可选：动画结束后的回调函数
}

/**
 * 执行跳动动画
 * @param options BounceOptions 类型参数，用于配置跳动行为
 */
export function bounce(options: BounceOptions): void {
  const times        = options.times        ?? 2
  const duration     = options.duration     ?? 50
  const distance     = options.distance     ?? 3
  const isHorizontal = options.isHorizontal ?? true
  const setOffset    = options.set

  let count     = 0
  let direction = 1

  /**
   * 执行一步跳动动画
   */
  const bounceStep = () => {
    if (count >= times * 2) {
      // 所有跳动完成，重置偏移并回调
      setOffset(0, 0)
      options.onFinished?.()
      return
    }

    // 设置偏移值：水平或垂直方向
    const offsetX = isHorizontal ? direction * distance : 0
    const offsetY = isHorizontal ? 0 : direction * distance

    // 执行动画
    animateTo({ duration, curve: Curve.EaseOut }, () => {
      setOffset(offsetX, offsetY)
    })

    direction *= -1
    count++
    setTimeout(bounceStep, duration)
  }

  bounceStep()
}