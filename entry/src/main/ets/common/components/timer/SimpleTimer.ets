export class SimpleTimer {
  private interval: number = 0
  private callback: (() => void) | null = null
  private timerId: number | null = null
  private isActive: boolean = false
  private isPaused: boolean = false
  private isOneShot: boolean = false

  constructor(interval: number = 0) {
    this.interval = interval
  }

  /**
   * 启动定时器
   * @param callback 回调函数
   * @param oneShot 是否只执行一次（默认 false）
   */
  start(callback: () => void, oneShot: boolean = false) {
    this.stop() // 先停止旧定时器
    this.callback = callback
    this.isActive = true
    this.isPaused = false
    this.isOneShot = oneShot

    if (oneShot) {
      this.timerId = setTimeout(() => {this.run()}, this.interval)
    } else {
      this.timerId = setInterval(() => {this.run()}, this.interval)
    }
  }

  /**
   * 停止定时器
   */
  stop() {
    if (this.timerId !== null) {
      if (this.isOneShot) {
        clearTimeout(this.timerId)
      } else {
        clearInterval(this.timerId)
      }
    }
    this.timerId = null
    this.isActive = false
    this.isPaused = false
  }

  /**
   * 暂停定时器
   */
  pause() {
    if (this.isActive) {
      this.isPaused = true
      this.stop()
    }
  }

  /**
   * 恢复定时器
   */
  resume() {
    if (this.isPaused && this.callback) {
      this.start(this.callback, this.isOneShot)
      this.isPaused = false
    }
  }

  /**
   * 执行回调
   */
  private run() {
    if (!this.callback) return
    this.callback()
    if (this.isOneShot) this.stop()
  }

  /**
   * 是否正在运行
   */
  isRunning(): boolean {
    return this.isActive
  }

  /**
   * 设置间隔
   */
  setInterval(interval: number) {
    this.interval = interval
  }

  /**
   * 获取间隔
   */
  getInterval(): number {
    return this.interval
  }
}