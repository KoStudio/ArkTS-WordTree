

@ComponentV2
export struct RandarChartV2 {
  // ========== 输入参数（只读） ==========
  @Param parts: ChartPart[] = [];
  @Param guideLineCount: number = 5;
  @Param showPercentText: boolean = true;
  @Param showInfo: boolean = true;
  @Param chartWidth: number = 300;
  @Param chartHeight: number = 300;
  @Param isGuideLineCircle: boolean = false

  // ========== 事件回调（用于父组件更新数据） ==========
  @Event onPartsUpdate?: (updatedParts: ChartPart[]) => void;
  @Event onPartClick?: (partName: string, part: ChartPart) => void;

  // ========== 本地状态和配置 ==========
  @Local private ctxSettings: RenderingContextSettings = new RenderingContextSettings(true);
  @Local private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.ctxSettings);
  @Local private isCanvasReady: boolean = false;

  // 常量定义
  private readonly START_ANGLE_OFFSET: number = 0//从右边开始 //-Math.PI / 2; // 从顶部开始[2](@ref)
  private readonly GUIDE_LINE_COLOR: string = '#E0E0E0';
  private readonly POINT_RADIUS: number = 4;

  // ========== 生命周期和监控 ==========
  @Monitor('parts', 'guideLineCount', 'showPercentText')
  onDataChange() {
    if (this.isCanvasReady) {
      this.drawCanvas();
    }
  }

  aboutToAppear() {
    this.isCanvasReady = true;
  }

  // ========== 构建视图 ==========
  build() {
    Row({ space: 12 }) {
      // 左侧 Canvas 绘图区域
      this.buildCanvas()

      // 右侧图例信息（条件渲染）
      if (this.showInfo) {
        //this.buildLegend()
      }
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Center)
    .padding(16)
    .onClick((event: ClickEvent) => {
      this.handleCanvasClick(event);
    })
  }

  // ========== Canvas 区域构建器 ==========
  @Builder
  buildCanvas() {
    Column() {
      Canvas(this.ctx)
        .width(this.chartWidth)
        .height(this.chartHeight)
        .onReady(() => {
          this.isCanvasReady = true;
          this.drawCanvas();
        })
    }
    .layoutWeight(1)
  }

  // ========== 图例区域构建器 ==========
  @Builder
  buildLegend() {
    Column({ space: 8 }) {

      ForEach(this.parts, (part: ChartPart, index?: number) => {
        Row({ space: 8 }) {
          // 颜色标识
          Rect()
            .width(12)
            .height(12)
            .backgroundColor(part.color)
            .borderRadius(2)

          // 文本信息
          Column({ space: 2 }) {
            Text(part.partName)
              .fontSize(15)
              .fontColor(Color.Black)
              .textAlign(TextAlign.Start)

            Text(`${part.curCount}/${part.allCount} (${(part.ratio * 100).toFixed(1)}%)`)
              .fontSize(15)
              .fontColor(Color.Black)
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding(4)
        .onClick(() => {
          if (this.onPartClick) {
            this.onPartClick(part.partName, part.clone());
          }
        })
      }, (part: ChartPart) => part.partName)
    }
    .width(140)
    .padding(8)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    //.shadow({ radius: 2, color: '#1A000000', offsetX: 1, offsetY: 1 })
  }

  // ========== 绘制主入口 ==========
  private drawCanvas(): void {
    if (!this.isCanvasReady || !this.ctx) return;

    try {
      const width = this.chartWidth;
      const height = this.chartHeight;

      this.ctx.clearRect(0, 0, width, height);

      const centerX = width / 2;
      const centerY = height / 2;
      const radius = Math.min(width, height) * 0.35; // 留出边距

      // 依次绘制各个图层
      if (this.isGuideLineCircle) {
        this.drawGuideLinesCircle(centerX, centerY, radius);
      }else{
        this.drawGuideLinesSquare(centerX, centerY, radius);
      }

      this.drawDataArea(centerX, centerY, radius);
      this.drawDataPoints(centerX, centerY, radius);
      this.drawDimensionLabels(centerX, centerY, radius);

    } catch(e) {
      console.error("绘制Canvas错误:", e);
    }
  }

  // ========== 绘制引导线 ==========
  // ========== 绘制引导线（改为直线连接） ==========
  private drawGuideLinesSquare(centerX: number, centerY: number, radius: number): void {
    this.ctx.strokeStyle = this.GUIDE_LINE_COLOR;
    this.ctx.lineWidth = 1;
    //this.ctx.setLineDash([5, 3]); // 虚线

    const count = this.parts.length;
    if (count === 0) return;

    const angleStep = (2 * Math.PI) / count;

    // ---------- 多边形层 ----------
    for (let i = 1; i <= this.guideLineCount; i++) {
      const r = radius * (i / this.guideLineCount);

      this.ctx.beginPath();

      for (let j = 0; j < count; j++) {
        const angle = this.START_ANGLE_OFFSET + angleStep * j;
        const x = centerX + r * Math.cos(angle);
        const y = centerY + r * Math.sin(angle);

        if (j === 0) {
          this.ctx.moveTo(x, y);
        } else {
          this.ctx.lineTo(x, y);
        }
      }

      this.ctx.closePath();
      this.ctx.stroke();

      // ---------- 旁边的百分比文本 ----------
      if (this.showPercentText) {
        const percent = `${(i / this.guideLineCount * 100).toFixed(0)}%`;
        this.ctx.fillStyle = this.GUIDE_LINE_COLOR;
        this.ctx.font = '10px sans-serif';
        this.ctx.textAlign = 'center';
        this.ctx.textBaseline = 'middle';

        this.ctx.fillText(percent, centerX + r + 15, centerY);
      }
    }

    // ---------- 维度分隔线 ----------
    this.ctx.setLineDash([]);
    for (let i = 0; i < count; i++) {
      const angle = this.START_ANGLE_OFFSET + angleStep * i;
      const endX = centerX + radius * Math.cos(angle);
      const endY = centerY + radius * Math.sin(angle);

      this.ctx.beginPath();
      this.ctx.moveTo(centerX, centerY);
      this.ctx.lineTo(endX, endY);
      this.ctx.stroke();
    }
  }

  private drawGuideLinesCircle(centerX: number, centerY: number, radius: number): void {
    this.ctx.strokeStyle = this.GUIDE_LINE_COLOR;
    this.ctx.lineWidth = 1;
    this.ctx.setLineDash([5, 3]); // 虚线样式

    // 绘制同心圆引导线[2](@ref)
    for (let i = 1; i <= this.guideLineCount; i++) {
      const currentRadius = radius * (i / this.guideLineCount);

      this.ctx.beginPath();
      this.ctx.arc(centerX, centerY, currentRadius, 0, Math.PI * 2);
      this.ctx.stroke();

      // 绘制百分比文本[2](@ref)
      if (this.showPercentText) {
        this.ctx.fillStyle = this.GUIDE_LINE_COLOR;
        this.ctx.font = '12px sans-serif';
        this.ctx.textAlign = 'center';
        this.ctx.textBaseline = 'middle';

        const percent = `${(i / this.guideLineCount * 100).toFixed(0)}%`;
        this.ctx.fillText(percent, centerX + currentRadius + 15, centerY);
      }
    }

    // 绘制维度分隔线[2](@ref)
    this.ctx.setLineDash([]); // 实线
    if (this.parts.length === 0) return;

    const angleStep = (2 * Math.PI) / this.parts.length;

    for (let i = 0; i < this.parts.length; i++) {
      const angle = this.START_ANGLE_OFFSET + angleStep * i;
      const endX = centerX + radius * Math.cos(angle);
      const endY = centerY + radius * Math.sin(angle);

      this.ctx.beginPath();
      this.ctx.moveTo(centerX, centerY);
      this.ctx.lineTo(endX, endY);
      this.ctx.stroke();
    }
  }

  // ========== 绘制数据区域 ==========
  private drawDataArea(centerX: number, centerY: number, radius: number): void {
    if (this.parts.length === 0) return;

    const angleStep = (2 * Math.PI) / this.parts.length;

    this.ctx.fillStyle = this.calculateFillColor();
    this.ctx.strokeStyle = this.calculateLineColor();
    this.ctx.lineWidth = 2;
    this.ctx.setLineDash([]);

    this.ctx.beginPath();

    for (let i = 0; i < this.parts.length; i++) {
      const part = this.parts[i];
      const angle = this.START_ANGLE_OFFSET + angleStep * i;
      const pointRadius = radius * part.ratio;
      const x = centerX + pointRadius * Math.cos(angle);
      const y = centerY + pointRadius * Math.sin(angle);

      if (i === 0) {
        this.ctx.moveTo(x, y);
      } else {
        this.ctx.lineTo(x, y);
      }
    }

    this.ctx.closePath();
    this.ctx.fill();
    this.ctx.stroke();
  }

  // ========== 绘制数据点 ==========
  private drawDataPoints(centerX: number, centerY: number, radius: number): void {
    if (this.parts.length === 0) return;

    const angleStep = (2 * Math.PI) / this.parts.length;

    for (let i = 0; i < this.parts.length; i++) {
      const part = this.parts[i];
      const angle = this.START_ANGLE_OFFSET + angleStep * i;
      const pointRadiusValue = radius * part.ratio;
      const x = centerX + pointRadiusValue * Math.cos(angle);
      const y = centerY + pointRadiusValue * Math.sin(angle);

      // 绘制数据点[2](@ref)
      this.ctx.fillStyle = part.color;
      this.ctx.beginPath();
      this.ctx.arc(x, y, this.POINT_RADIUS, 0, Math.PI * 2);
      this.ctx.fill();

      // 绘制数据点外圈
      this.ctx.strokeStyle = '#FFFFFF';
      this.ctx.lineWidth = 1.5;
      this.ctx.stroke();
    }
  }

  // ========== 绘制维度标签 ==========
  private drawDimensionLabels(centerX: number, centerY: number, radius: number): void {
    if (this.parts.length === 0) return;

    const angleStep = (2 * Math.PI) / this.parts.length;
    const labelRadius = radius + 20; // 标签距离中心的半径

    this.ctx.fillStyle = '#111111';
    this.ctx.font = '22px sans-serif';
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';

    for (let i = 0; i < this.parts.length; i++) {
      const part = this.parts[i];
      const angle = this.START_ANGLE_OFFSET + angleStep * i;
      const x = centerX + labelRadius * Math.cos(angle);
      const y = centerY + labelRadius * Math.sin(angle);

      this.ctx.fillText(part.partName, x, y);
    }
  }

  // ========== 工具方法 ==========
  private calculateFillColor(): string {
    if (this.parts.length > 0) {
      // 使用第一个数据的颜色作为填充色，带透明度
      const baseColor = this.parts[0].color;
      return baseColor.replace(')', ', 0.3)').replace('rgb', 'rgba');
    }
    return 'rgba(76, 175, 80, 0.3)'; // 默认颜色
  }

  private calculateLineColor(): string {
    if (this.parts.length > 0) {
      return this.parts[0].color;
    }
    return '#4CAF50'; // 默认颜色
  }

  // ========== 事件处理 ==========
  private handleCanvasClick(event: ClickEvent): void {
    // 可以扩展点击交互逻辑
    console.log('Canvas被点击', event);
  }

  // ========== 公共API方法 ==========
  public updatePartData(partName: string, newCurCount: number): void {
    const updatedParts = this.parts.map(part => {
      if (part.partName === partName) {
        const updatedPart = part.clone();
        updatedPart.curCount = Math.max(0, Math.min(updatedPart.allCount, newCurCount));
        return updatedPart;
      }
      return part.clone();
    });

    // 通过事件通知父组件更新数据[8](@ref)
    if (this.onPartsUpdate) {
      this.onPartsUpdate(updatedParts);
    }
  }

  public refresh(): void {
    if (this.isCanvasReady) {
      this.drawCanvas();
    }
  }
}

// ChartPart.ets - 数据模型定义
@ObservedV2
export class ChartPart {
  @Trace partName: string = '';
  @Trace allCount: number = 0;
  @Trace curCount: number = 0;
  @Trace color: string = '#994CAF50';

  constructor(partName?: string, allCount?: number, curCount?: number, color?: string) {
    if (partName) this.partName = partName;
    if (allCount !== undefined) this.allCount = allCount;
    if (curCount !== undefined) this.curCount = curCount;
    if (color) this.color = color;
  }

  // 计算当前比率 (0~1)
  get ratio(): number {
    return this.allCount > 0 ? Math.min(this.curCount / this.allCount, 1) : 0;
  }

  // 深拷贝方法
  clone(): ChartPart {
    return new ChartPart(this.partName, this.allCount, this.curCount, this.color);
  }
}