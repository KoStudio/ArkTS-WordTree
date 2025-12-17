import { DebugLog } from "../../../app/debug/DebugLog";
import { DateUtils } from "../../../common/utils/DateUtils";
import { preferences } from "@kit.ArkData";
import { getAppContext } from "../../../app/constants/AppContext";
import { TimeTo } from "./TimeToCfg";


/** TimeToType 枚举 */
export enum TimeToType {
  updateServerConfigs        = "updateServerConfigs",
  autoRefreshSubsciptionInfo = "autoRefreshSubsciptionInfo",
}

/** TimeToManager Key 常量统一管理 */
class TimeToKeys {
  public static readonly PrefNamespace: string = "TimeToDictKey";

  public static lastTime(typeName: string): string {
    return `${TimeToKeys.PrefNamespace}_${typeName}_LastTime`;
  }

  public static lastResult(typeName: string): string {
    return `${TimeToKeys.PrefNamespace}_${typeName}_LastResult`;
  }
}

/** TimeToManager：同步方法版本 */
export class TimeToManager {

  // -------------------------
  // 内部统一获取 Preferences
  // -------------------------
  private static _getPrefs(): preferences.Preferences {
    const context = getAppContext();
    return preferences.getPreferencesSync(context, { name: TimeToKeys.PrefNamespace });
  }

  // -------------------------
  // TimeToType 接口
  // -------------------------

  /** 检查是否已到执行时间，返回 true 可执行 */
  public static isTimeTo(type: TimeToType): boolean {
    const limitMinute = TimeToManager.limitMinuteForType(type);
    return TimeToManager.isTimeToByName(type, limitMinute);
  }

  /** 获取上次执行结果，返回 true/false/undefined */
  public static getLastResult(type: TimeToType): boolean | undefined {
    return TimeToManager.getLastResultByName(type);
  }

  /** 保存当前时间及执行结果 */
  public static saveTime(type: TimeToType, result: boolean): void {
    TimeToManager.saveTimeByName(type, result);
  }

  /** 清空指定 type 的保存时间和结果 */
  public static clearSavedTime(type: TimeToType): void {
    TimeToManager.clearSavedTimeByName(type);
  }

  // -------------------------
  // 按 typeName 操作的通用方法
  // -------------------------

  /** 检查指定 typeName 是否已到执行时间 */
  public static isTimeToByName(typeName: string, limitMinute: number): boolean {
    try {
      const prefs = TimeToManager._getPrefs();
      const lastTimeStr = prefs.getSync(TimeToKeys.lastTime(typeName), '') as string;

      if (lastTimeStr) {
        const lastTime = DateUtils.toDate(lastTimeStr);
        if (lastTime) {
          const now = new Date();
          const diffMinutes = (now.getTime() - lastTime.getTime()) / 1000 / 60;
          if (limitMinute > diffMinutes) {
            DebugLog.d(`Time not yet for: ${typeName} Limit:${limitMinute} (passed:${diffMinutes.toFixed(2)}min)`);
            return false;
          }
        }
      }
      return true;
    } catch (err) {
      DebugLog.d(`isTimeToByName error: ${err}`);
      return true;
    }
  }

  /** 获取指定 typeName 的上次执行结果 */
  public static getLastResultByName(typeName: string): boolean | undefined {
    try {
      const prefs = TimeToManager._getPrefs();
      const raw = prefs.getSync(TimeToKeys.lastResult(typeName), null);
      
      if (raw === null || raw === undefined) {
        return undefined;
      }
      
      if (typeof raw === 'boolean') {
        return raw;
      }
      
      if (typeof raw === 'string') {
        return raw.toLowerCase() === 'true';
      }
      
      return undefined;
    } catch (err) {
      DebugLog.d(`getLastResultByName error: ${err}`);
      return undefined;
    }
  }

  /** 保存 typeName 的当前时间和执行结果 */
  public static saveTimeByName(typeName: string, result: boolean): void {
    try {
      const prefs = TimeToManager._getPrefs();
      const nowStr = DateUtils.toFullString(new Date());
      prefs.putSync(TimeToKeys.lastTime(typeName), nowStr);
      prefs.putSync(TimeToKeys.lastResult(typeName), result);
      prefs.flushSync();
      DebugLog.d(`saveTime for: ${typeName}`);
    } catch (err) {
      DebugLog.d(`saveTimeByName error for ${typeName}: ${err}`);
    }
  }

  /** 清空指定 typeName 的时间和结果 */
  public static clearSavedTimeByName(typeName: string): void {
    try {
      const prefs = TimeToManager._getPrefs();
      prefs.putSync(TimeToKeys.lastTime(typeName), '');
      prefs.putSync(TimeToKeys.lastResult(typeName), '');
      prefs.flushSync();
      DebugLog.d(`cleared savedTime for: ${typeName}`);
    } catch (err) {
      DebugLog.d(`clearSavedTimeByName error for ${typeName}: ${err}`);
    }
  }

  /** 清空所有已保存的时间和结果 */
  public static clearAllSavedTime(): void {
    try {
      const prefs = TimeToManager._getPrefs();
      const allKeys = Object.keys(prefs.getAllSync());
      for (const key of allKeys) {
        prefs.putSync(key, '');
      }
      prefs.flushSync();
      DebugLog.d('cleared all savedTime');
    } catch (err) {
      DebugLog.d(`clearAllSavedTime error: ${err}`);
    }
  }

  // -------------------------
  // 内部方法
  // -------------------------

  /** 根据 TimeToType 获取限制分钟数 */
  private static limitMinuteForType(type: TimeToType): number {
    const hourMinute = 60;
    switch (type) {
      case TimeToType.updateServerConfigs        :  return TimeTo.UpdateServerConfigs * hourMinute;
      case TimeToType.autoRefreshSubsciptionInfo :  return TimeTo.AutoRefreshSubscriptionInfo * hourMinute; //AppCfgManager.shared.getAutoRefreshSubscriptionInfo_Interval_Minutes();
      default: return 0;
    }
  }
}