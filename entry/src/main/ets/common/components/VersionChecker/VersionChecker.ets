import bundle from '@ohos.bundle';
import preferences from '@ohos.data.preferences';
import { bundleManager } from '@kit.AbilityKit';
import { getAppContext } from '../../../app/constants/AppContext';
import { DebugLog } from '../../../app/debug/DebugLog';

// 使用 @ObservedV2 和 @Trace 装饰器进行状态管理[6,7](@ref)

export class VersionChecker {
  // 单例实例
  private static instance: VersionChecker = new VersionChecker();

  // UserDefaults 键名
  private versionListKey: string = "VersionHistory";
  private maxRecordCount: number = 5;
  private defaultVersion: string = "0.0.0";

  // 当前版本信息[4](@ref)
  private _oldVersion: string = this.defaultVersion;
  private _newVersion: string = this.defaultVersion;

  // 获取单例实例
  public static get shared(): VersionChecker {
    return VersionChecker.instance;
  }

  private constructor() {
    this.initVersionInfo();
  }

  // 初始化版本信息
  private async initVersionInfo(): Promise<void> {
    try {
      // 获取当前应用版本信息
      const bundleInfo     = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const currentVersion = bundleInfo.versionName || this.defaultVersion;

      // 从 Preferences 获取版本记录
      const context        = getAppContext() // 获取应用上下文
      const prefs          = await preferences.getPreferences(context, 'version_prefs');
      const versionHistory = await prefs.get(this.versionListKey, []) as  string[]

      // 设置旧版本和新版本
      this._oldVersion     = versionHistory.length === 0 ? this.defaultVersion : versionHistory[versionHistory.length - 1];
      this._newVersion     = currentVersion;
    } catch (error) {
      console.error("Failed to initialize version info: " + error.message);
    }
  }


  /// 是否为当前版本的首次启动
  public async isFirstLaunchOfCurrentVersion(): Promise<boolean> {
    if (this._newVersion === this.defaultVersion) {
      await this.initVersionInfo()
    }
    return this._oldVersion !== this._newVersion;
  }

  /// 如果需要更新，则执行更新逻辑
  public async runVersionUpdateIfNeeded(updateProcess: (oldVersion: string, newVersion: string) => void): Promise<void> {
    // 仅在首次启动且当前版本未执行过更新时，才执行更新逻辑
    if (!await this.isFirstLaunchOfCurrentVersion()) {
      return;
    }

    // 执行更新
    updateProcess(this._oldVersion, this._newVersion);

    // 更新版本历史
    await this.markVersionAsUpdated();
  }


  /**
   * 仅执行一次指定 token 的回调（同步版）
   */
  public runOnceWithTokenSync(token: string, callback: () => void): void {
    if (!token || token.trim().length === 0) return;

    // 取同步 Preferences
    const ctx = getAppContext();
    try {
      const prefs = preferences.getPreferencesSync(ctx, { name: 'version_prefs' });

      // 是否已执行过
      const hasRun = prefs.getSync(token, false) as boolean;
      if (hasRun) return;

      // 执行回调
      callback();

      // 标记已执行
      prefs.putSync(token, true);
      prefs.flushSync()

    } catch (error) {
      DebugLog.e(error)
    }

  }

  /// 在更新完成后，记录当前版本
  private async markVersionAsUpdated(): Promise<void> {
    try {
      const context = getAppContext() // 获取应用上下文
      const prefs = await preferences.getPreferences(context, 'version_prefs');
      let versionHistory: string[] = await prefs.get(this.versionListKey, []) as  string[]

      // 确保当前版本不重复，并添加到历史记录
      if (!versionHistory.includes(this._newVersion)) {
        versionHistory.push(this._newVersion);
      }

      // 限制记录数量
      if (versionHistory.length > this.maxRecordCount) {
        versionHistory = versionHistory.slice(versionHistory.length - this.maxRecordCount);
      }

      // 保存版本记录[11](@ref)
      await prefs.put(this.versionListKey, versionHistory);
      await prefs.flush();

      // 更新旧版本引用
      this._oldVersion = this._newVersion;
    } catch (error) {
      console.error("Failed to mark version as updated: " + error.message);
    }
  }
}