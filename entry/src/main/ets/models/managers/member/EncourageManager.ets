// ============================================================
// 导入模块
// ============================================================
import { preferences } from "@kit.ArkData";
import { getAppContext } from "../../../app/constants/AppContext";
import { ArrayUtils } from "../../../common/utils/array/ArrayUtils";
import { DateUtils } from "../../../common/utils/DateUtils";

// ============================================================
// Pref：命名空间常量
// ============================================================
class Pref {
  static readonly Name: string = "Encourage_Setting";
}

// ============================================================
// EncourageType：激励类型枚举
// ============================================================
export enum EncourageType {
  wordPronRewardAd = "wordPronRewardAd",      // 激励广告奖励发音次数
  wordPronShareApp = "wordPronShareApp"       // 分享应用奖励发音次数
}

// ============================================================
// EncourageTypeHelper：激励类型扩展方法（合并了RewardPool功能）
// ============================================================
export class EncourageTypeHelper {

  // ============================================================
  // 私有静态字段：奖励池数据
  // ============================================================

  // 激励广告奖励池（类似Swift中的static var rewardAd）
  private static rewardAd: number[] = ArrayUtils.shuffled([10,10,10,10,10,10,10,10,10,10,20,20,20,30,30,50,80,90,100]);

  // 分享应用奖励池（类似Swift中的static var shareApp）
  private static shareApp: number[] = ArrayUtils.shuffled([30,30,30,30,30,30,30,30,30,30,40,50,50,60,70,80,90,100]);

  // ============================================================
  // 公共静态方法
  // ============================================================

  /**
   * 获取带当天日期的key，如：wordPronRewardAd_2025-11-19
   * 类似Swift中的计算属性getKeyWithToday
   */
  static getKeyWithToday(type: EncourageType): string {
    const today: string = DateUtils.toDateString(new Date()) ?? "";
    return `${type}_${today}`;
  }

  /**
   * 获取所有激励类型（类似Swift的CaseIterable协议）
   */
  static allCases(): EncourageType[] {
    return [EncourageType.wordPronRewardAd, EncourageType.wordPronShareApp];
  }

  /**
   * 获取奖励数量（类似Swift中的rewardCount计算属性）
   * 合并了原RewardPool.getRewardForType的功能
   */
  static getRewardCount(type: EncourageType): number {
    switch (type) {
      case EncourageType.wordPronRewardAd:
        return EncourageTypeHelper.rewardAd[0] || 10; // 默认值
      case EncourageType.wordPronShareApp:
        return EncourageTypeHelper.shareApp[0] || 30; // 默认值
      default:
        return 0;
    }
  }

  /**
   * 重置奖励池（对应Swift中的resetRewards方法）
   * 合并了原RewardPool.resetRewards的功能
   */
  static resetRewards(type: EncourageType): void {
    switch (type) {
      case EncourageType.wordPronRewardAd:
        EncourageTypeHelper.rewardAd = ArrayUtils.shuffled(EncourageTypeHelper.rewardAd);
        break;
      case EncourageType.wordPronShareApp:
        EncourageTypeHelper.shareApp = ArrayUtils.shuffled(EncourageTypeHelper.shareApp);
        break;
    }
  }

}


export class EncourageManager {


  private static _shared: EncourageManager | null = null;

  public static get shared(): EncourageManager {
    if (!EncourageManager._shared) {
      EncourageManager._shared = new EncourageManager();
    }
    return EncourageManager._shared!;
  }

  // 私有构造器
  private constructor() {
    this.clearOldDatas();
  }

  // ============================================================
  // 内部工具方法
  // ============================================================

  /** 获取Preferences实例（类似Swift的UserDefaults） */
  private getPrefs(): preferences.Preferences {
    const context = getAppContext();
    return preferences.getPreferencesSync(context, { name: Pref.Name });
  }

  /** 清空旧日期的数据，只保留今天的（对应Swift的clearOldDatas） */
  /** 清空旧日期的数据，只保留今天的 */
  private clearOldDatas(): void {
    const prefs = this.getPrefs();
    const dict = prefs.getAllSync() as Record<string, number>;

    const newDict: Record<string, number> = {};

    // 只保留今天的数据
    EncourageTypeHelper.allCases().forEach((type: EncourageType) => {
      const key = EncourageTypeHelper.getKeyWithToday(type);
      const val = dict[key];
      if (val !== undefined && val !== null) {
        newDict[key] = val;
      }
    });

    // 重写存储：先删除所有数据，再写入新数据
    Object.keys(dict).forEach((key: string) => {
      prefs.deleteSync(key);
    });

    // 修复：使用Object.keys遍历，通过key访问value
    Object.keys(newDict).forEach((key: string) => {
      const value = newDict[key]; // 通过key获取对应的value
      prefs.putSync(key, value);
    });

    prefs.flushSync();
  }

  // ============================================================
  // 对外公开方法
  // ============================================================

  /**
   * 发放奖品（对应Swift的encourage方法）
   * @param type 激励类型
   * @param rewardCount 奖品数量，如果为空则使用默认奖励数量
   * @param limitOncePerDay 每日是否只奖励一次
   * @returns 是否奖励成功
   */
  public encourage(type: EncourageType, rewardCount?: number, limitOncePerDay: boolean = false): boolean {
    const count = rewardCount ?? EncourageTypeHelper.getRewardCount(type);
    const prefs = this.getPrefs();
    const key = EncourageTypeHelper.getKeyWithToday(type);

    // 检查是否已存在今日记录
    const currentValue = prefs.getSync(key, 0) as number;

    // 如果每日只奖励一次且已存在记录，则返回失败
    if (limitOncePerDay && currentValue > 0) {
      return false;
    }

    // 更新奖励数量
    const newValue = currentValue + count;
    prefs.putSync(key, newValue);
    prefs.flushSync();

    return true;
  }

  /**
   * 获取已获得的每日奖励次数（对应Swift的earnedEncourageCount方法）
   */
  public earnedEncourageCount(type: EncourageType): number {
    const prefs = this.getPrefs();
    const key = EncourageTypeHelper.getKeyWithToday(type);
    const value = prefs.getSync(key, 0) as number;

    return value ?? 0;
  }

  /**
   * 重置奖励池（现在直接调用EncourageTypeHelper的方法）
   */
  public resetRewards(type: EncourageType): void {
    EncourageTypeHelper.resetRewards(type);
  }

  /**
   * 获取当前奖励值（用于调试和显示）
   */
  public getCurrentRewardValue(type: EncourageType): number {
    return EncourageTypeHelper.getRewardCount(type);
  }
}