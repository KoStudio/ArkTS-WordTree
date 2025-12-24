import { DebugFlg } from '../../../app/debug/DebugFlg';
import { DebugLog } from '../../../app/debug/DebugLog';
import { SubscribeManager } from '../../../common/iab/SubscribeManager';
import { DateUtils } from '../../../common/utils/DateUtils';
import { Toast } from '../../../common/utils/Toast';
import { DailyCountManager, DailyCountType } from './DailyCountManaer';
import { EncourageManager, EncourageType } from './EncourageManager';

// ============================================================
// MARK: - 非会员默认限制常量
class NonMemberDefaultLimits {
  static readonly wordPronCountDaily       : number = 20   // 每日 发音50次 （单词, 字典）
  static readonly examplePronCountDaily    : number = 10   // 每日 发音10次 （例句）
  static readonly dictShowCountDaily       : number = 5    // 每日 内置词典显示 10次
  static readonly freeUnitsCount           : number = 100  // 免费单元个数 （通常一个Book是40个单元，这里默认是100个单元，表示不限制)
  static readonly freePlanDayOfsCount      : number = 5    // 记忆曲线免费天数
  static readonly onlineDictUseCountDaily  : number = 100  // 每日 在线字曲　使用 100次
  static readonly challengeUseCountDaily   : number = 10   // 每日 挑战模式　使用 100次
}

// ============================================================
// MARK: - 非会员结构
class NonMember {
  // MARK: - Limit times daily
  maxWordPronCountDaily        : number = NonMemberDefaultLimits.wordPronCountDaily
  maxExamplePronCountDaily     : number = NonMemberDefaultLimits.examplePronCountDaily
  maxDictShowCountDaily        : number = NonMemberDefaultLimits.dictShowCountDaily
  maxFreeUnitsCount            : number = NonMemberDefaultLimits.freeUnitsCount
  maxFreePlanDayOfsCount       : number = NonMemberDefaultLimits.freePlanDayOfsCount
  maxOnlineDictUseCountDaily   : number = NonMemberDefaultLimits.onlineDictUseCountDaily
  maxChallengeUseCountDaily    : number = NonMemberDefaultLimits.challengeUseCountDaily

  // MARK: - lock function

  // 限制自动发音
  isLockedAutoPron       : boolean = true

  // 限制 夜晚模式
  isLockedNightMode      : boolean = true

  // 限制 隐藏翻译
  isLockedHideTrans      : boolean = true

  // 限制 再测一次(仅错误单词)
  isLockedRetestMistake  : boolean = true

  // 限制 词根助记
  isLockedCigen          : boolean = true

  // 限制 同根词
  isLockedSameRoot       : boolean = true
}

// ============================================================
// MARK: - 会员常量
class BeMember {
  static readonly maxCount : number = 2 << 20 // Int的一半足够，如果直接用Int.max 可能会遇到 Int.max + num 的情况时，就越界了
  static readonly memberFlg: number = 1       // 会员标志 示例
}

// ============================================================
// MARK: - MemberManager
export class MemberManager {

  private static _shared: MemberManager | null = null

  public static get shared(): MemberManager {
    if (!MemberManager._shared) {
      MemberManager._shared = new MemberManager()
      MemberManager._shared.init()
    }
    return MemberManager._shared!
  }

  // 私有构造器
  private constructor() {}

  // ============================================================
  // MARK: - 初始化
  private init(): void {
    /// 使用异步获取，以防首次初始化未成功，这样只影响后台线程
    setTimeout(() => {
      /// 从服务器加载 policies
      this.loadNonMemberPolicyIfNeeds()
    }, 0)
  }

  /// 调试用 调试会员
  private readonly debugMember: boolean = false

  /// 非会员 变量
  public nonMember: NonMember = new NonMember()

  private isDebug(): boolean {
    // 这里可以根据实际环境返回调试状态
    return DebugFlg.isDebugMode(); // 默认返回false
  }

  // ============================================================
  // MARK: - Member time
  get isActive(): boolean {

    // 调试模式检查
    if (this.isDebug() && this.debugMember) {
      return true;
    }

    // 检查订阅会员或礼品会员是否活跃
    const subscribeActive = SubscribeManager.shared.currentItem?.isActive ?? false;
    // const giftActive = GiftMemberManager.shared.isActive;

    return subscribeActive //|| giftActive;
  }

  /**
   * 会员过期时间（对应Swift中的expireDate计算属性）
   */
  get expireDate(): Date | null {
    // 调试模式返回当前日期
    if (this.isDebug() && this.debugMember) {
      return new Date();
    }

    // 获取订阅和礼品会员的过期时间，取较晚者
    const subscribeDate = SubscribeManager.shared.currentItem?.expireDate ?? null;
    // const giftDate = GiftMemberManager.shared.expireDate;

    // return this.maxDate(subscribeDate, giftDate);
    return subscribeDate
  }

  /**
   * 格式化过期时间字符串（对应Swift中的expireDateString计算属性）
   */
  get expireDateString(): string {
    if (this.isDebug() && this.debugMember) {
      return "<DEBUG>会员无限期";
    }

    if (this.expireDate) {
      // 这里需要实现日期格式化，暂时返回简单字符串
      return DateUtils.toDateTimeString(this.expireDate)
    }

    return "";
  }

  // ============================================================
  // MARK: - 非会员策略加载
  private loadNonMemberPolicyIfNeeds(): void {
    // TODO: 这里是伪代码，需要接入网络请求或缓存
    // 对应 Java 中 NonMemberPolicyManager.shared.loadPoliciesWithCallBack
  }

  // ============================================================
  // MARK: - Member ability 限制属性
  private get maxWordPronCountDaily()      : number { return this.isActive ? BeMember.maxCount : this.nonMember.maxWordPronCountDaily }
  private get maxExamplePronCountDaily()   : number { return this.isActive ? BeMember.maxCount : this.nonMember.maxExamplePronCountDaily }
  private get maxDictShowCountDaily()      : number { return this.isActive ? BeMember.maxCount : this.nonMember.maxDictShowCountDaily }
  private get maxFreeUnitsCount()          : number { return this.isActive ? BeMember.maxCount : this.nonMember.maxFreeUnitsCount }
  private get maxFreePlanDayOfsCount()     : number { return this.isActive ? BeMember.maxCount : this.nonMember.maxFreePlanDayOfsCount }
  private get maxOnlineDictUseCountDaily() : number { return this.isActive ? BeMember.maxCount : this.nonMember.maxOnlineDictUseCountDaily }
  private get maxChallengeUseCountDaily()  : number { return this.isActive ? BeMember.maxCount : this.nonMember.maxChallengeUseCountDaily }

  // ============================================================
  // MARK: - 是否显示广告
  get canShowAds(): boolean {
    return !this.isActive
  }

  // ============================================================
  // MARK: - 是否可以下载离线数据
  get canDownloadOffLineData(): boolean {
    return this.isActive
  }

  // ============================================================
  // MARK: - Check times functions

  /// 检查 单词发音功能 是否可用
  public checkWordPronUsable(showMessage: boolean = true): boolean {
    if (this.isActive) { return true } // 非会员才做检查

    /// 剩余 单词发音次数
    if (this.remainWordPronCount() === 0) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_word_pron'))
      }
      return false
    }

    return true
  }

  /// 返回剩余 单词发音次数（用于 奖励用户时显示剩余次数）
  public remainWordPronCount(): number {
    // 非会员默认次数 + 分享应用奖励次数 + 激励广告奖励次数
    const limitCount = this.maxWordPronCountDaily
      + EncourageManager.shared.earnedEncourageCount(EncourageType.wordPronShareApp)
      + EncourageManager.shared.earnedEncourageCount(EncourageType.wordPronRewardAd);

    // 计算剩余次数
    const remainCount = limitCount - DailyCountManager.shared.dailyCount(DailyCountType.wordPron);

    return remainCount > 0 ? remainCount : 0;
  }

  /// 检查 例句发音功能 是否可用
  public checkExamplePronUsable(showMessage: boolean = true): boolean {
    if (this.isActive) { return true } // 非会员才做检查

    if (this.maxExamplePronCountDaily <= DailyCountManager.shared.dailyCount(DailyCountType.examplePron)) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_example_pron'))
      }
      return false
    }

    return true
  }

  /// 检查 内置词典 是否可用
  public checkDictShowable(showMessage: boolean = true): boolean {
    if (this.isActive) { return true } // 非会员才做检查

    if (this.maxDictShowCountDaily <= DailyCountManager.shared.dailyCount(DailyCountType.dictShow)) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_dict_show'))
      }
      return false
    }

    return true
  }

  /// 检查 单元 是否可用
  public checkUnitUsable(curUnitNo: number, showMessage: boolean = true): boolean {
    if (this.isActive) { return true } // 非会员才做检查

    if (this.maxFreeUnitsCount < curUnitNo) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_use_all_units'))
      }
      return false
    }

    return true
  }

  /// 检查 dayOf 是否可用
  public checkDayOfUsable(curDayOfNum: number, showMessage: boolean = true): boolean {
    if (this.isActive) { return true } // 非会员才做检查

    if (this.maxFreePlanDayOfsCount < curDayOfNum) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_use_all_plan_dayofs'))
      }
      return false
    }

    return true
  }

  // ============================================================
  // MARK: - Check Lock functions

  /// 检查 是否可以使用自动发音
  public checkAutoPronUsable(showMessage: boolean = true): boolean {
    if (!this.nonMember.isLockedAutoPron) { return true } // 非会员 锁定自动发音 功能是否启用
    if (this.isActive) { return true } // 非会员才做检查

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_auto_pron'))
    }

    return false
  }

  /// 检查 是否可以使用夜晚模式
  public checkNightModeUsable(showMessage: boolean = true): boolean {
    if (!this.nonMember.isLockedNightMode) { return true } // 非会员 锁定夜晚模式 功能是否启用
    if (this.isActive) { return true } // 非会员才做检查

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_use_night_mode'))
    }

    return false
  }

  /// 检查 是否可以使用隐藏翻译
  public checkHideTransUsable(showMessage: boolean = true): boolean {
    if (!this.nonMember.isLockedHideTrans) { return true } // 非会员 锁定隐藏翻译 功能是否启用
    if (this.isActive) { return true } // 非会员才做检查

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_use_hide_trans'))
    }

    return false
  }

  /// 检查 是否可以使用 再测一次（仅错误单词）
  public checkRetestMistakeUsable(showMessage: boolean = true): boolean {
    if (!this.nonMember.isLockedRetestMistake) { return true } // 非会员 锁定再测一次 功能是否启用
    if (this.isActive) { return true } // 非会员才做检查

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_use_retest_mistake'))
    }

    return false
  }

  /// 检查 是否可以使用词根助记
  public checkCigenUsable(showMessage: boolean = true): boolean {
    if (!this.nonMember.isLockedCigen) { return true } // 非会员 锁定词根助记 功能是否启用
    if (this.isActive) { return true } // 非会员才做检查

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_use_cigen'))
    }

    return false
  }

  /// 检查 是否可以使用同根词
  public checkSameRootUsable(showMessage: boolean = true): boolean {
    if (!this.nonMember.isLockedSameRoot) { return true } // 非会员 锁定同根词 功能是否启用
    if (this.isActive) { return true } // 非会员才做检查

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_use_sameroot'))
    }

    return false
  }

  /// 检查 在线字典 是否可用
  public checkOnlineDictUsable(showMessage: boolean = true): boolean {
    if (this.isActive) { return true } // 非会员才做检查

    if (this.maxOnlineDictUseCountDaily <= DailyCountManager.shared.dailyCount(DailyCountType.onlineDict)) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_online_dict_use'))
      }
      return false
    }

    return true
  }

  /// 检查 挑战模式 是否可用
  public checkChallengeDictUsable(showMessage: boolean = true): boolean {
    if (this.isActive) { return true } // 非会员才做检查

    if (this.maxChallengeUseCountDaily <= DailyCountManager.shared.dailyCount(DailyCountType.challenge)) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_challenge_use'))
      }
      return false
    }

    return true
  }
}