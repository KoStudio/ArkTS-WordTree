// SimpleTimerCountDown.ets
export class SimpleTimerCountDown {
  private refreshFrequency: number = 100;        // 刷新频率100ms
  private totalMs: number = 0;                 // 总时长(毫秒)
  private remainMs: number = 0;                // 剩余时间(毫秒)
  private active: boolean = false;             // 是否活跃
  private paused: boolean = false;              // 是否暂停
  private callback: ((remainMs: number) => void) | null = null; // 回调函数
  private timerId: number = -1;                // 定时器ID

  constructor(intervalMs: number = 0) {
    this.setTotalInterval(intervalMs);
  }

  /** 设置总时长(毫秒) */
  setTotalInterval(intervalMs: number): void {
    this.totalMs = Math.max(0, intervalMs);
    this.remainMs = this.totalMs;
  }

  /** 设置总时长(秒) */
  setIntervalSeconds(seconds: number): void {
    this.setTotalInterval(seconds * 1000);
  }

  /** 启动倒计时(回调函数方式) */
  start(callback: (remainMs: number) => void): void {
    if (this.remainMs <= 0) return;

    // 清理可能存在的旧定时器[6](@ref)
    this.stop();

    this.callback = callback;
    this.active = true;
    this.paused = false;

    // 使用setInterval创建定时器[8](@ref)
    this.timerId = setInterval(() => {
      if (!this.active) return;

      this.remainMs = Math.max(0, this.remainMs - this.refreshFrequency);
      this.callback?.(this.remainMs);

      if (this.remainMs <= 0) {
        this.stop();
      }
    }, this.refreshFrequency);
  }

  /** 异步启动(返回Promise) */
  async startAsync(intervalMs: number, onTick?: (remainMs: number) => void): Promise<void> {
    this.setTotalInterval(intervalMs);
    return new Promise<void>((resolve) => {
      this.start((remain) => {
        onTick?.(remain);
        if (remain <= 0) resolve();
      });
    });
  }

  /** 停止倒计时 */
  stop(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);  // 清除定时器[6](@ref)
      this.timerId = -1;
    }
    this.active = false;
    this.paused = false;
  }

  /** 暂停倒计时 */
  pause(): void {
    if (this.active && !this.paused) {
      this.paused = true;
      this.active = false;
      if (this.timerId >= 0) {
        clearInterval(this.timerId);
        this.timerId = -1;
      }
    }
  }

  /** 恢复倒计时 */
  resume(): void {
    if (this.paused && !this.active) {
      this.paused = false;
      this.active = true;

      this.timerId = setInterval(() => {
        if (!this.active) return;

        this.remainMs = Math.max(0, this.remainMs - this.refreshFrequency);
        this.callback?.(this.remainMs);

        if (this.remainMs <= 0) {
          this.stop();
        }
      }, this.refreshFrequency);
    }
  }

  /** 重置倒计时 */
  reset(): void {
    this.stop();
    this.remainMs = this.totalMs;
  }

  /** 重新开始 */
  restart(): void {
    this.stop();
    this.remainMs = this.totalMs;
    if (this.callback) {
      this.start(this.callback);
    }
  }

  /** 检查是否活跃 */
  isActive(): boolean {
    return this.active;
  }

  /** 检查是否暂停 */
  isPausing(): boolean {
    return this.paused;
  }

  /** 获取剩余时间 */
  getRemainInterval(): number {
    return this.remainMs;
  }

  /** 获取总时长 */
  getTotalInterval(): number {
    return this.totalMs;
  }

  /** 销毁实例(释放资源) */
  destroy(): void {
    this.stop();
    this.callback = null;
  }
}