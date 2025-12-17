
// 全局定义扩展方法
@AnimatableExtend(Button)
function bounce(isActive: boolean = true, times: number = 3, duration: number = 250, isHorizontal: boolean = false) {
  .translate({
    x: isActive && isHorizontal ? 10 : 0,
    y: isActive && !isHorizontal ? -10 : 0 })
  .animation({
    duration: duration / times,
    iterations: times,
    playMode: PlayMode.Alternate,
    curve: Curve.EaseOut
  })
}
