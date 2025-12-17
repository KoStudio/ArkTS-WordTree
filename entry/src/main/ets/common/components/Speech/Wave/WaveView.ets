@ComponentV2
export struct WaveView {
  // ===================== 外部传入参数 =====================
  @Param waveSpeed    : number = 0.08;   // 波形移动速度（值越大移动越快）
  @Param waveAmplitude: number = 8;     // 波峰高度（与音量强度关联）
  @Param waveHeight   : number = 50;    // 波形基准高度（Y轴位置）

  // ===================== 组件内部状态 =====================
  @Local private offsetX: number = 0;   // 波形横向偏移量（用于动画位移）

  // ===================== 动画控制属性 =====================
  private animId   : number            = 0;  // 动画ID（用于取消动画）
  private settings : RenderingContextSettings = new RenderingContextSettings(true);  // 画布设置（开启抗锯齿）
  private context  : CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);  // 画布上下文

  // ===================== 生命周期方法 =====================
  /**
   * 组件销毁时停止动画（避免资源泄漏）
   */
  aboutToDisappear() {
    if (this.animId !== 0) {
      this.cancelAnimationFrame(this.animId);  // 取消动画帧
      this.animId = 0;                         // 重置动画ID
    }
  }

  // ===================== UI构建 =====================
  build() {
    Column() {
      Canvas(this.context)  // 创建画布
        .width('100%')   // 宽度100%
        .height(250)     // 固定高度250vp
        .backgroundColor('transparent')  // 透明背景
        .onReady(() => {  // 画布准备就绪回调
          const width  = this.context.width;   // 获取画布实际宽度
          const height = this.context.height;  // 获取画布实际高度
          this.startWaveAnimation(width, height);  // 启动波纹动画
        })
    }
    .width('100%')  // 容器宽度100%
  }

  // ===================== 动画控制方法 =====================
  /**
   * 启动水波动画（基于requestAnimationFrame实现）
   * @param width  - 画布宽度
   * @param height - 画布高度
   */
  private startWaveAnimation(width: number, height: number) {
    if (this.animId !== 0) return;  // 防止重复启动

    const animate = () => {
      this.offsetX += this.waveSpeed;    // 更新波形偏移量（使用动态速度）
      this.drawWaves(width, height);     // 重绘画布
      this.animId = this.requestAnimationFrame(animate);  // 请求下一帧
    };

    this.animId = this.requestAnimationFrame(animate);  // 启动动画循环
  }

  /**
   * 绘制双波纹效果（主波+次波叠加）
   * @param width  - 画布宽度
   * @param height - 画布高度
   */
  private drawWaves(width: number, height: number) {
    this.context.clearRect(0, 0, width, height);  // 清空画布

    // 绘制主波（浅蓝色半透明）
    this.context.fillStyle = 'rgba(135, 206, 250, 0.6)';
    this.context.fill(this.buildWavePath(width, height));

    // 绘制次波（相位偏移产生层次感）
    this.offsetX += Math.PI / 4;                    // 添加相位偏移
    this.context.fillStyle = 'rgba(173, 216, 230, 0.4)';
    this.context.fill(this.buildWavePath(width, height));
    this.offsetX -= Math.PI / 4;                    // 恢复原始相位
  }

  // ===================== 路径构建方法 =====================
  /**
   * 构建水波路径（基于正弦函数）
   * @param width  - 画布宽度
   * @param height - 画布高度
   * @returns Path2D对象（描述波形路径）
   */
  private buildWavePath(width: number, height: number): Path2D {
    const path         = new Path2D();  // 创建新路径
    const waveFrequency = 2.5 * Math.PI / width;  // 计算波形频率（基于宽度）

    path.moveTo(0, this.waveHeight);  // 起点定位到波形基准高度

    // 构建正弦曲线路径（关键算法）
    for (let x = 0; x <= width; x++) {
      // 计算每个x坐标对应的y值（正弦函数）
      const y = this.waveAmplitude * Math.sin(waveFrequency * x + this.offsetX) + this.waveHeight;
      path.lineTo(x, y);  // 连接路径点
    }

    // 封闭路径形成波带
    path.lineTo(width, height);  // 右下角
    path.lineTo(0, height);      // 左下角
    path.closePath();            // 闭合路径

    return path;
  }

  // ===================== 动画辅助方法 =====================
  /**
   * 模拟requestAnimationFrame（兼容HarmonyOS环境）
   * @param callback - 回调函数
   * @returns 定时器ID
   */
  private requestAnimationFrame(callback: () => void): number {
    return setTimeout(callback, 16);  // ≈60fps（16ms/帧）
  }

  /**
   * 取消动画帧
   * @param id - 定时器ID
   */
  private cancelAnimationFrame(id: number) {
    clearTimeout(id);  // 清除定时器
  }
}