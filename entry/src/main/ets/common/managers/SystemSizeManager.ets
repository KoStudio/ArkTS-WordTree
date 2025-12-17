import { window } from '@kit.ArkUI';

/**
 * 系统栏与可用区域管理工具
 * 功能：动态计算排除系统栏后的可用区域尺寸
 */
@ObservedV2
export class SystemSizeManager {
  private static instance: SystemSizeManager;
  private windowObj: window.Window | null = null;

  // 系统栏高度（像素单位）
  @Trace private _statusBarHeightPx: number = 0;
  @Trace private _bottomNavBarHeightPx: number = 0;
  @Trace private _indicatorHeightPx: number = 0;

  // 窗口原始尺寸（像素单位）
  @Trace private _windowWidthPx: number = 0;
  @Trace private _windowHeightPx: number = 0;

  private constructor() {
    // 将实例连接到 AppStorageV2，用于响应式更新
    // AppStorageV2.connect(this, () => this);
  }

  /**
   * 获取单例实例
   */
  public static get shared(): SystemSizeManager {
    if (!SystemSizeManager.instance) {
      SystemSizeManager.instance = new SystemSizeManager();
    }
    return SystemSizeManager.instance;
  }

  /**
   * 初始化窗口实例
   * @param windowStage 窗口阶段对象
   */
  public init(windowStage: window.WindowStage): void {
    // 获取主窗口对象
    this.windowObj = windowStage.getMainWindowSync();

    // 设置窗口为全屏布局（内容绘制区域覆盖系统栏）
    // this.windowObj.setWindowLayoutFullScreen(true);

    // 初始化窗口尺寸和系统栏信息
    this.updateWindowMetrics();
    // 注册窗口监听事件
    this.registerListeners();
  }

  //=== 公开属性 ===//

  /**
   * 获取可用宽度（单位：vp）
   */
  public get availableWidth(): number {
    // 全屏模式下宽度无需扣除系统栏
    return px2vp(this._windowWidthPx);
  }

  /**
   * 获取可用高度（单位：vp）
   * 会自动扣除状态栏 + 底部导航栏（或指示器）的高度
   */
  public get availableHeight(): number {
    const totalSystemBarHeight =
      this._statusBarHeightPx + Math.max(this._bottomNavBarHeightPx, this._indicatorHeightPx);
    return px2vp(this._windowHeightPx - totalSystemBarHeight);
  }

  //=== 私有方法 ===//

  /**
   * 更新窗口尺寸和系统栏高度信息
   */
  private updateWindowMetrics(): void {
    if (!this.windowObj) return;

    // 获取窗口原始尺寸（同步方式）
    const props = this.windowObj.getWindowProperties();
    this._windowWidthPx = props.windowRect.width;
    this._windowHeightPx = props.windowRect.height;

    // 获取系统状态栏和底部导航栏的避让区域
    const systemArea = this.windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    this._statusBarHeightPx = systemArea.topRect.height;
    this._bottomNavBarHeightPx = systemArea.bottomRect.height;

    // 获取手势指示器避让区域（部分设备存在）
    const indicatorArea = this.windowObj.getWindowAvoidArea(
      window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR
    );
    this._indicatorHeightPx = indicatorArea.bottomRect.height;
  }

  /**
   * 注册窗口变化监听器
   */
  private registerListeners(): void {
    // 监听窗口尺寸变化
    this.windowObj?.on('windowSizeChange', (rect) => {
      this._windowWidthPx = rect.width;
      this._windowHeightPx = rect.height;
    });

    // 监听避让区域（系统栏）变化
    this.windowObj?.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
      if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
        this._statusBarHeightPx = data.area.topRect.height;
        this._bottomNavBarHeightPx = data.area.bottomRect.height;
      } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        this._indicatorHeightPx = data.area.bottomRect.height;
      }
    });
  }
}