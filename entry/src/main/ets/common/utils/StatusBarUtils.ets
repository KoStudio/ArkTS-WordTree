import { BusinessError } from '@kit.BasicServicesKit'; // 错误处理
import common from '@ohos.app.ability.common'; // 通用能力接口
import window from '@ohos.window';

// 状态栏工具类
export class StatusBarUtil {
  // 使用静态属性存储状态栏高度，便于全局访问
  private static readonly STATUS_BAR_HEIGHT_KEY: string = 'statusBarHeight';

  /**
   * 设置状态栏的内容颜色（文字和图标的颜色）
   * 类似于SwiftUI中修改UIApplication.shared.statusBarStyle
   * @param color 颜色字符串，例如 '#000000' (黑色) 或 '#FFFFFF' (白色)
   * @param context 上下文对象
   */
  static async setStatusBarContentColor(color: string): Promise<void> {
    try {
      const context = getContext(StatusBarUtil)
      // 使用正确的API获取窗口实例[5,6](@ref)
      const currentWindow = await window.getLastWindow(context);
      // 设置状态栏属性[3](@ref)
      await currentWindow.setWindowSystemBarProperties({
        statusBarContentColor: color
      });
      console.info('StatusBar content color set to: ' + color);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to set status bar content color. Code: ${err.code}, message: ${err.message}`);
    }
  }

  /**
   * 设置状态栏的背景颜色
   * @param color 颜色字符串，支持透明度
   * @param context 上下文对象
   */
  static async setStatusBarBackgroundColor(color: string): Promise<void> {
    try {
      const currentWindow = await window.getLastWindow(getContext(StatusBarUtil));
      await currentWindow.setWindowSystemBarProperties({
        statusBarColor: color
      });
      console.info('StatusBar background color set to: ' + color);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to set status bar background color. Code: ${err.code}, message: ${err.message}`);
    }
  }

  /**
   * 获取状态栏高度（单位：px）
   * 类似于iOS中的safeAreaInsets.top[5,8](@ref)
   * @param context 上下文对象
   * @returns 状态栏高度的Promise
   */
  static async getStatusBarHeight(): Promise<number> {
    try {
      const currentWindow = await window.getLastWindow(getContext(StatusBarUtil));
      // 获取系统避免区域[5,8](@ref)
      const avoidArea = currentWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const statusBarHeightPx = avoidArea.topRect.height;

      AppStorage.setOrCreate(StatusBarUtil.STATUS_BAR_HEIGHT_KEY, statusBarHeightPx);
      return statusBarHeightPx;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to get status bar height. Code: ${err.code}, message: ${err.message}`);
      return 0;
    }
  }

  /**
   * 设置沉浸式状态栏[3,4](@ref)
   * @param context 上下文对象
   */
  static async setImmersiveStatusBar(): Promise<void> {
    try {
      const context = getContext(StatusBarUtil)
      const currentWindow = await window.getLastWindow(context)
      // 设置窗口布局为全屏[3,4](@ref)
      await currentWindow.setWindowLayoutFullScreen(true);
      await currentWindow.setWindowSystemBarEnable(['status']);
      await currentWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000'
      });
      await StatusBarUtil.getStatusBarHeight();
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to set immersive status bar. Code: ${err.code}, message: ${err.message}`);
    }
  }

  // 便捷方法
  static async setDarkContent(): Promise<void> {
    await StatusBarUtil.setStatusBarContentColor('#000000');
  }

  static async setLightContent(): Promise<void> {
    await StatusBarUtil.setStatusBarContentColor('#FFFFFF');
  }
}