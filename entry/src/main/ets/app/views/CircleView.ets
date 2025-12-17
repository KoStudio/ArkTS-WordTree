// ======================= GraphPart =======================
export interface  GraphPart {
  partName     : string
  count        : number
  color        : string

}


// ======================= ENUM =======================
export enum CircleViewStyle {
  Pan          = 0,
  Ring         = 1,
  Ring3D       = 2
}


// ======================= CircleView =======================
@ComponentV2
export struct CircleView {

  // ========== 外部参数 ==========
  @Param parts               : GraphPart[]              = [];
  @Param allCount            : number                   = 100;

  @Param ringWidth           : number                   = 40;
  @Param ring3DWidth         : number                   = 8;

  @Param bgColor             : string                   = "#E6E6E6";
  @Param bgColorShow         : boolean                  = false;
  @Param showInfo            : boolean                  = false;
  @Param showInfoPercentage  : boolean                  = false;
  @Param style               : CircleViewStyle          = CircleViewStyle.Ring3D;

  // ========== 本地状态 ==========
  @Local private ctxSettings : RenderingContextSettings = new RenderingContextSettings(true);
  @Local private ctx         : CanvasRenderingContext2D = new CanvasRenderingContext2D(this.ctxSettings);

  private angleOffset        : number                   = -Math.PI / 2;


  @Monitor('parts', 'allCount')
  onChangeOfData(){
    this.drawCanvas()
  }

  // ========== 构建视图 ==========
  build() {
    Row() {
      // 左侧 Canvas 绘图
      Canvas(this.ctx)
        .width('auto')
        .height('100%')
        .onReady(() => { try { this.drawCanvas(); } catch(e) {} })

      // 图例
      if (this.showInfo) {
        Column({ space: 8 }) {
          ForEach(this.parts, (part: GraphPart) => {
            Row({ space: 8 }) {
              Rect()
                .width(12)
                .height(12)
                .backgroundColor(part.color)

              Text(this.infoText(part))
                .fontSize(11)
                .fontColor($r('sys.color.black'))
                .textAlign(TextAlign.Start)
            }
            .alignItems(VerticalAlign.Center)
          })
        }
        .padding({ left: 8 })
      }
    }
    .align(Alignment.Center)
  }


  // ========== 绘制主入口 ==========
  private drawCanvas() {
    if (!this.ctx) return;

    try {
      const width   = this.ctx.width  > 0 ? this.ctx.width  : 200;
      const height  = this.ctx.height > 0 ? this.ctx.height : 200;
      const diameter= Math.min(width, height);
      const radius  = diameter / 2;
      const cx      = radius;
      const cy      = radius;

      this.ctx.clearRect(0, 0, width, height);

      // 背景圆
      // ===== 按风格绘制背景 =====
      if (this.allCount === 0) {

        switch (this.style) {

          case CircleViewStyle.Pan: {
            // 饼图 → 实心圆背景
            this.ctx.fillStyle = this.bgColor;
            this.ctx.beginPath();
            this.ctx.arc(cx, cy, radius, 0, Math.PI * 2);
            this.ctx.fill();
            break;
          }

          case CircleViewStyle.Ring:
          case CircleViewStyle.Ring3D: {
            // 环 → 空心环背景
            const r = radius - (this.ringWidth / 2);
            this.ctx.lineWidth = this.ringWidth;
            this.ctx.strokeStyle = this.bgColor;
            this.ctx.beginPath();
            this.ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            this.ctx.stroke();
            break;
          }
        }
      }

      if (!this.parts || this.parts.length === 0)
        return;

      switch (this.style) {
        case CircleViewStyle.Pan:   this.drawPan (this.ctx, cx, cy, radius); break;
        case CircleViewStyle.Ring:  this.drawRing(this.ctx, cx, cy, radius); break;
        case CircleViewStyle.Ring3D:this.drawRing3D(this.ctx, cx, cy, radius); break;
      }
    } catch(e) {
      console.error("drawCanvas error:", e);
    }
  }


  // ========== 绘制 扇形 ==========
  private drawPan(ctx  : CanvasRenderingContext2D,
    cx   : number,
    cy   : number,
    radius: number) {

    const total      = this.allCount <= 0 ? 1 : this.allCount;
    let startAngle   = this.angleOffset;

    for (const part of this.parts) {
      const sweep    = part.count / total * 2 * Math.PI;
      const endAngle = startAngle + sweep;

      ctx.fillStyle = part.color;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.arc(cx, cy, radius, startAngle, endAngle);
      ctx.closePath();
      ctx.fill();

      startAngle = endAngle;
    }
  }


  // ========== 绘制 环 ==========
  private drawRing(ctx  : CanvasRenderingContext2D,
    cx   : number,
    cy   : number,
    radius: number) {

    const total      = this.allCount <= 0 ? 1 : this.allCount;
    const r          = radius - (this.ringWidth / 2);
    ctx.lineWidth    = this.ringWidth;

    if (this.allCount === 0 || this.bgColorShow) {
      ctx.strokeStyle = this.bgColor;
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, 2 * Math.PI);
      ctx.stroke();
    }

    let startAngle   = this.angleOffset;

    for (const part of this.parts) {
      const sweep    = part.count / total * 2 * Math.PI;
      const endAngle = startAngle + sweep;

      ctx.strokeStyle = part.color;
      ctx.beginPath();
      ctx.arc(cx, cy, r, startAngle, endAngle);
      ctx.stroke();

      startAngle = endAngle;
    }
  }


  // ========== 绘制 3D 环 ==========
  private drawRing3D(ctx  : CanvasRenderingContext2D,
    cx   : number,
    cy   : number,
    radius: number) {

    this.drawRing(ctx, cx, cy, radius);

    const total      = this.allCount <= 0 ? 1 : this.allCount;
    const r          = radius - this.ringWidth + (this.ring3DWidth / 2);
    ctx.lineWidth    = this.ring3DWidth;

    const reflectColor = "rgba(0,0,0,0.1)";
    let startAngle     = this.angleOffset;

    for (const part of this.parts) {
      const sweep      = part.count / total * 2 * Math.PI;
      const endAngle   = startAngle + sweep;

      ctx.strokeStyle = reflectColor;
      ctx.beginPath();
      ctx.arc(cx, cy, r, startAngle, endAngle);
      ctx.stroke();

      startAngle = endAngle;
    }
  }


  // ========== 工具 API ==========
  private infoText(part: GraphPart): string {
    if (this.showInfoPercentage && this.allCount > 0) {
      return `${part.partName}: ${(part.count * 100 / this.allCount).toFixed(1)}%`;
    }
    return `${part.partName}: ${part.count}`;
  }

  // public addPart(name : string,
  //   count: number,
  //   color: string) {
  //
  //   if (this.sumParts() + count > this.allCount)
  //     return;
  //
  //   this.parts.push(new GraphPart(name, count, color));
  //   try { this.drawCanvas(); } catch(e) {}
  // }
  //
  // public updatePart(name : string,
  //   count: number) {
  //
  //   let p = this.parts.find(it => it.partName === name);
  //   if (!p) {
  //     p = new GraphPart(name, count, "#000000");
  //     this.parts.push(p);
  //   }
  //
  //   p.count = count;
  //   try { this.drawCanvas(); } catch(e) {}
  // }

  public sumParts(): number {
    return this.parts.reduce((s, p) => s + p.count, 0);
  }

  public refresh() {
    try { this.drawCanvas(); } catch(e) {}
  }
}