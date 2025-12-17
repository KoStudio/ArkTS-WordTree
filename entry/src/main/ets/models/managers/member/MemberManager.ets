import { SubscribeManager } from '../../../common/iab/SubscribeManager';
import { DateUtils } from '../../../common/utils/DateUtils';
import { Toast } from '../../../common/utils/Toast';


class ConstantsBeMember {
  ///会员相关常量（对应Swift中的BeMember）
  static readonly maxCount: number = 2 << 20 // 使用安全的最大值，避免Int越界问题（对应Swift中的Int.max / 2）
}

export class MemberManager {

  private static _shared: MemberManager | null = null;

  public static get shared(): MemberManager {
    if (!MemberManager._shared) {
      MemberManager._shared = new MemberManager();
    }
    return MemberManager._shared!;
  }

  // 私有构造器
  private constructor() {

  }

  /** 调试用标志，对应Swift中的debugMember */
  private readonly debugMember: boolean = false;

  /**
   * 调试检查方法（对应Swift中的isDebug()）
   */
  private isDebug(): boolean {
    // 这里可以根据实际环境返回调试状态
    return false; // 默认返回false
  }

  /**
   * 获取两个日期中的较晚者（对应Swift中的maxDate函数）
   */
  private maxDate(date1: Date | null, date2: Date | null): Date | null {
    if (!date1) return date2;
    if (!date2) return date1;
    return date1 > date2 ? date1 : date2;
  }

  // ============================================================
  // 会员状态属性（对应Swift中的计算属性）
  // ============================================================

  /**
   * 是否是活跃会员（对应Swift中的isActive计算属性）
   */
  get isActive(): boolean {

    // 调试模式检查
    if (this.isDebug() && this.debugMember) {
      return true;
    }

    // 检查订阅会员或礼品会员是否活跃
    const subscribeActive = SubscribeManager.shared.currentItem?.isActive ?? false;
    //const giftActive = GiftMemberManager.shared.isActive;

    return subscribeActive// || giftActive;
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
    //const giftDate = GiftMemberManager.shared.expireDate;

    //return this.maxDate(subscribeDate, giftDate);
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
  // 功能可用性检查属性（对应Swift中的can计算属性）
  // ============================================================

  /** 是否显示广告 */
  get canShowAds(): boolean {
    return !this.isActive;
  }


  ///检查 单词发音功能 是否可用
  public checkWordPronUsable(showMessage: boolean = true): boolean {
    if (!this.isActive) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_word_pron'));
      }

      return false;
    }
    return true;

  }

  ///检查　例句发音功能 是否可用
  public checkExamplePronUsable(showMessage: boolean = true): boolean {
    if (!this.isActive) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_example_pron'));
      }

      return false;
    }
    return true;

  }

  ///检查　录音功能 是否可用
  public checkRecordUsable(showMessage: boolean = true): boolean {
    if (!this.isActive) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_record'));
      }

      return false;
    }
    return true;

  }

  ///检查　隱藏翻譯  是否可用
  public checkHideTransUsable(showMessage: boolean = true): boolean {
    if (!this.isActive) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_hide_trans'));
      }

      return false;
    }
    return true;

  }

  ///检查　再測驗功能 是否可用
  public checkRetestUsable(showMessage: boolean = true): boolean {
    if (!this.isActive) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_retest_mistake'));
      }

      return false;
    }
    return true;

  }

  ///检查　自动发音功能 是否可用
  public checkAutoPronUsable(showMessage: boolean = true): boolean {
    if (!this.isActive) {
      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_auto_pron'));
      }

      return false;
    }
    return true;

  }

}