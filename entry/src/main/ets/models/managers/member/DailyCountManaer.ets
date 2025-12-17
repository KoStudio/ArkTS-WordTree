import { preferences } from "@kit.ArkData";
import { getAppContext } from "../../../app/constants/AppContext";
import { DateUtils } from "../../../common/utils/DateUtils";
import { MemberManager } from "./MemberManager";


// ============================================================
// Pref：命名空间常量
// ============================================================
class Pref {
  static readonly Name : string = "DailyCount_Setting";
}


// ============================================================
// DailyCountType：每日计数类型
// ============================================================
export enum DailyCountType {
  wordPron       = "wordPron",
  wordStorke     = "wordStorke",
  phrasePron     = "phrasePron",
  dictationTimes = "dictationTimes",
}


// 扩展方法（为 enum 添加 getKeyWithToday）
export class DailyCountTypeHelper {

  /**
   * 获取带当天日期的 key，如：wordPron_2025-11-19
   */
  static getKeyWithToday(type: DailyCountType): string {
    const today: string = DateUtils.toDateString(new Date()) ?? "";
    return `${type}_${today}`;
  }
}


// ============================================================
// DailyCountManager：每日次数管理器
// ============================================================
export class DailyCountManager {

  // 单例
  private static _shared: DailyCountManager | null = null;

  public static get shared(): DailyCountManager {
    if (!DailyCountManager._shared) {
      DailyCountManager._shared = new DailyCountManager();
    }
    return DailyCountManager._shared!;
  }


  // 私有构造器
  private constructor() {
    this.clearOldDatas();
  }


  // ============================================================
  // 内部工具方法
  // ============================================================

  /** 获取 Preferences */
  private getPrefs(): preferences.Preferences {
    const context = getAppContext();
    return preferences.getPreferencesSync(context, { name: Pref.Name });
  }

  /** 清空旧日期的数据，只保留今天的 */
  private clearOldDatas(): void {
    const prefs = this.getPrefs();
    const dict  = prefs.getAllSync() as Record<string, number>;

    const newDict: Record<string, number> = {};

    for (const type of Object.values(DailyCountType)) {
      const key = DailyCountTypeHelper.getKeyWithToday(type);
      const val = dict[key];
      if (val !== undefined && val !== null) {
        newDict[key] = val;
      }
    }

    // 重写存储
    for (const key of Object.keys(dict)) {
      prefs.deleteSync(key);
    }

    for (const key of Object.keys(newDict)) {
      prefs.putSync(key, newDict[key]);
    }

    prefs.flushSync();
  }


  // ============================================================
  // 对外方法
  // ============================================================

  /**
   * 增加指定类型的每日计数（仅非会员时记录）
   */
  public increase(type: DailyCountType): void {

    // 非会员才记录次数
    if (MemberManager.shared.isActive) return;

    const prefs = this.getPrefs();
    const key   = DailyCountTypeHelper.getKeyWithToday(type);

    const raw   = prefs.getSync(key, 0) as number;
    const value = (raw ?? 0) + 1;

    prefs.putSync(key, value);
    prefs.flushSync();
  }

  /**
   * 获取指定类型当天的次数
   */
  public dailyCount(type: DailyCountType): number {
    const prefs = this.getPrefs();
    const key   = DailyCountTypeHelper.getKeyWithToday(type);
    const val   = prefs.getSync(key, 0) as number;

    return val ?? 0;
  }
}