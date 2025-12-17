import display from '@ohos.display';

/**
 * 屏幕信息工具类
 * @description 提供默认屏幕信息的便捷访问（支持px和vp单位）
 */
export class DisplayUtils {
  private static _defaultDisplay: display.Display = display.getDefaultDisplaySync();

  /**
   * 获取默认屏幕信息
   */
  public static getDefaultDisplay(): display.Display {
    return DisplayUtils._defaultDisplay;
  }

  // px单位方法（保持原有）
  public static getScreenWidthPx(): number {
    return DisplayUtils._defaultDisplay.width;
  }

  public static getScreenHeightPx(): number {
    return DisplayUtils._defaultDisplay.height;
  }

  // vp单位方法（新增）
  public static getScreenWidthVp(): number {
    return DisplayUtils.px2vp(DisplayUtils._defaultDisplay.width);
  }

  public static getScreenHeightVp(): number {
    return DisplayUtils.px2vp(DisplayUtils._defaultDisplay.height);
  }

  /**
   * px转vp（基于标准公式）
   * @param pxValue 像素值
   * @returns 虚拟像素值
   */
  public static px2vp(pxValue: number): number {
    return pxValue / (DisplayUtils._defaultDisplay.densityDPI / 160);
  }

  /**
   * vp转px（基于标准公式）
   * @param vpValue 虚拟像素值
   * @returns 像素值
   */
  public static vp2px(vpValue: number): number {
    return vpValue * (DisplayUtils._defaultDisplay.densityDPI / 160);
  }

  // 其他原有方法保持不变...
  public static getDensityDPI(): number {
    return DisplayUtils._defaultDisplay.densityDPI;
  }

  public static getRefreshRate(): number {
    return DisplayUtils._defaultDisplay.refreshRate;
  }

  public static getRotation(): number {
    return DisplayUtils._defaultDisplay.rotation;
  }
  /**
   * 通过逻辑分辨率比例判断
   * @returns 宽高比≥1.3且最小边≥600dp时返回true
   */
  public static isTabletByLayout(): boolean {
    const widthVp = DisplayUtils.getScreenWidthVp();
    const heightVp = DisplayUtils.getScreenHeightVp();
    const minEdge = Math.min(widthVp, heightVp);
    const aspectRatio = Math.max(widthVp, heightVp) / minEdge;

    return aspectRatio >= 1.3 && minEdge >= 600; // 平板典型特征[1,6](@ref)
  }
  // 方法1: 基于屏幕宽高比的判断（最常用）
  /**
   * 通过宽高比判断是否为横屏
   * @returns 宽 > 高时返回true（横屏）
   */
  public static isLandscapeByAspectRatio(): boolean {
    const width = DisplayUtils.getScreenWidthPx();
    const height = DisplayUtils.getScreenHeightPx();
    return width > height;
  }
}