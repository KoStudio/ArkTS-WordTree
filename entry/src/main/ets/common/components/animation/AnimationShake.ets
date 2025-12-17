export interface ShakeRotateOptions {
  setAngle    : (angle: number) => void   // 设置旋转角度
  times?      : number                     // 摇晃次数，默认 3
  duration?   : number                     // 每步时间，默认 60ms
  angle?      : number                     // 摇晃幅度，默认 5°
  onFinished? : () => void                 // 动画完成回调
}

/**
 * 左右旋转式抖动
 */
export function shakeRotate(options: ShakeRotateOptions): void {
  const times    = options.times    ?? 3
  const duration = options.duration ?? 60
  const angle    = options.angle    ?? 5
  const setAngle = options.setAngle

  let count     = 0
  let direction = 1

  const shakeStep = () => {
    if (count >= times * 2) {
      setAngle(0)
      options.onFinished?.()
      return
    }

    animateTo({ duration, curve: Curve.EaseOut }, () => {
      setAngle(direction * angle)
    })

    direction *= -1
    count++
    setTimeout(shakeStep, duration)
  }

  shakeStep()
}