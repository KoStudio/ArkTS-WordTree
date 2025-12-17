/**
 * 支持着色（Tint）功能的png图片组件
 */
@ComponentV2
export struct TintImage {

  // 组件参数：图片资源
  @Param src: Resource | string | null = null;

  // 组件参数：着色颜色字符串（例如："#ff0000"）
  @Param colorStr: string = "#FF00b242"//ARGB
  @Param iconSize: number | string = 22

  @Param isSvg: boolean = false //默认是png


  build() {
    if(this.isSvg){
      // svg直接使用fillColor
      Image(this.src)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.colorStr)

    }else{
      // 使用 ArkUI 的 Image 组件
      Image(this.src)
        .width(this.iconSize)
        .height(this.iconSize)
        .colorFilter(this.getColorFilterMatrix(this.parseColorString(this.colorStr)))
    }

  }

  /**
   * 根据归一化的 RGBA 值构建颜色滤镜矩阵
   * @param rgba 归一化的 RGBA 数组 [R, G, B, A]，范围 0-1
   * @returns 4x5 的颜色变换矩阵
   */
  private getColorFilterMatrix(rgba: number[]): number[] {

    const r = rgba[0];
    const g = rgba[1];
    const b = rgba[2];
    const a = rgba[3];

    return [
      r, 0, 0, 0, 0, // R 输出 = tint颜色的R * 1.0
      0, g, 0, 0, 0, // G 输出 = tint颜色的G * 1.0
      0, 0, b, 0, 0, // B 输出 = tint颜色的B * 1.0
      0, 0, 0, a, 0  // A 输出 = 原图A * tint颜色的A
    ];
  }

  /**
   * 解析颜色字符串为归一化的 RGBA 数组
   * 支持格式: #RGB, #RRGGBB, #AARRGGBB
   * @param colorStr 颜色字符串
   * @returns 归一化的 RGBA 数组 [R, G, B, A]
   */
  private parseColorString(colorStr: string): number[] {
    let hex = colorStr.replace('#', '');
    let r = 0, g = 0, b = 0, a = 1;

    if (hex.length === 6) { // #RRGGBB
      r = parseInt(hex.substring(0, 2), 16) / 255;
      g = parseInt(hex.substring(2, 4), 16) / 255;
      b = parseInt(hex.substring(4, 6), 16) / 255;
    } else if (hex.length === 8) { // #AARRGGBB
      a = parseInt(hex.substring(0, 2), 16) / 255;
      r = parseInt(hex.substring(2, 4), 16) / 255;
      g = parseInt(hex.substring(4, 6), 16) / 255;
      b = parseInt(hex.substring(6, 8), 16) / 255;
    } else if (hex.length === 3) { // #RGB
      r = parseInt(hex.charAt(0) + hex.charAt(0), 16) / 255;
      g = parseInt(hex.charAt(1) + hex.charAt(1), 16) / 255;
      b = parseInt(hex.charAt(2) + hex.charAt(2), 16) / 255;
    } else if (hex.length === 4) { // #ARGB
      a = parseInt(hex.charAt(0) + hex.charAt(0), 16) / 255;
      r = parseInt(hex.charAt(1) + hex.charAt(1), 16) / 255;
      g = parseInt(hex.charAt(2) + hex.charAt(2), 16) / 255;
      b = parseInt(hex.charAt(3) + hex.charAt(3), 16) / 255;
    } else {
      // 格式错误时使用默认颜色（红色）
      console.error(`Unsupported color format: ${colorStr}`);
      return [1, 0, 0, 1];
    }
    return [r, g, b, a];
  }
}

