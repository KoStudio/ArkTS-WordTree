//
//  MemberManager.ets
//  WordTree (HarmonyOS)
//
//  与 Android com.ou.wordtree.managers.member.MemberManager、
//  iOS MemberManager.swift 对齐：非会员限制来自 AppCfgManager（已废弃本地 NonMember 可变块）。
//

import { DebugFlg } from '../../../app/debug/DebugFlg'
import { SubscribeManager } from '../../../common/iab/SubscribeManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { DateUtils } from '../../../common/utils/DateUtils'
import { getStringF } from '../../../common/utils/ResourceUtils'
import { Toast } from '../../../common/utils/Toast'
import { BookManager } from '../../datas/book/BookManager'
import { AppCfgManager } from '../servercfg/AppCfgManager'
import { DailyCountManager, DailyCountType } from './DailyCountManaer'
import { EncourageManager, EncourageType } from './EncourageManager'

// 与 Android Int.MAX_VALUE/2、Swift Int.max/2 一致，避免 max + n 溢出
class BeMember {
  static readonly maxCount: number = 1073741823
}

// 需弹出首页会员 Sheet 时发出；Index 等根页面订阅（对齐 Android openMemberActivity / iOS MemberViewManager.show）
export class MemberManager {
  static readonly NOTIFY_OPEN_MEMBER_SHEET: string = 'member_manager_notify_open_member_sheet'

  private static instance: MemberManager | null = null

  static get shared(): MemberManager {
    if (!MemberManager.instance) {
      MemberManager.instance = new MemberManager()
    }

    return MemberManager.instance
  }

  private constructor() {
  }

  // 调试：true 时视为永久会员（与 Android debugMember 一致）
  private readonly debugMember: boolean = false

  // 当前是否为 Debug 构建
  private isDebug(): boolean {
    return DebugFlg.isDebugMode()
  }

  // MARK: - Member time

  // 是否处于会员有效期（含调试会员）
  get isActive(): boolean {
    // Debug 且打开调试会员开关
    if (this.isDebug() && this.debugMember) {
      return true
    }

    const subscribeActive = SubscribeManager.shared.currentItem?.isActive ?? false

    return subscribeActive
  }

  // 会员到期时间；非会员或调试时为 null / 占位
  get expireDate(): Date | null {
    // Debug 会员用当前时间占位
    if (this.isDebug() && this.debugMember) {
      return new Date()
    }

    return SubscribeManager.shared.currentItem?.expireDate ?? null
  }

  // 格式化后的到期时间展示串
  get expireDateString(): string {
    if (this.isDebug() && this.debugMember) {
      return '<DEBUG>会员无限期'
    }

    const d = this.expireDate

    // 有到期日则格式化
    if (d) {
      return DateUtils.toDateTimeString(d)
    }

    return ''
  }

  // MARK: - Member ability（非会员限制直接使用 AppCfgManager，与 iOS/Android 一致）

  // 每日 查看单词发音 次数上限
  get maxWordPronCountDaily(): number {
    return this.isActive ? BeMember.maxCount : AppCfgManager.shared.getNonMember_WordPron_Times()
  }

  // 每日 查看例句发音 次数上限
  get maxExamplePronCountDaily(): number {
    return this.isActive ? BeMember.maxCount : AppCfgManager.shared.getNonMember_ExamplePron_Times()
  }

  // 每日 内置词典 显示次数上限
  get maxDictShowCountDaily(): number {
    return this.isActive ? BeMember.maxCount : AppCfgManager.shared.getNonMember_DictShow_Times()
  }

  // 非会员可免费使用的单元序号上限（与单元编号比较方式同 Android）
  get maxFreeUnitsCount(): number {
    return this.isActive ? BeMember.maxCount : AppCfgManager.shared.getNonMember_Free_Units_Count()
  }

  // 记忆曲线免费 dayOf 个数上限
  get maxFreePlanDayOfsCount(): number {
    return this.isActive ? BeMember.maxCount : AppCfgManager.shared.getNonMember_Free_Plan_DayOfs_Count()
  }

  // 每日 在线词典 使用次数上限
  get maxOnlineDictUseCountDaily(): number {
    return this.isActive ? BeMember.maxCount : AppCfgManager.shared.getNonMember_OnlineDict_Times()
  }

  // 每日 挑战模式 使用次数上限
  get maxChallengeUseCountDaily(): number {
    return this.isActive ? BeMember.maxCount : AppCfgManager.shared.getNonMember_Challenge_Times()
  }

  // 非会员可创建的 EBook（自建词汇本）个数上限
  get maxEBookCount(): number {
    return this.isActive ? BeMember.maxCount : AppCfgManager.shared.getNonMember_EBook_MaxCount()
  }

  // 是否展示广告（非会员 true）
  get canShowAds(): boolean {
    return !this.isActive
  }

  // 是否允许离线下载等会员数据能力
  get canDownloadOffLineData(): boolean {
    return this.isActive
  }

  // MARK: - 打开会员购买 UI

  // showMemberPurchasePage 为 true 时通知根页面弹出会员 Sheet（无订阅者时 EventBus 会 warn，可忽略）
  private requestOpenMemberSheet(showMemberPurchasePage: boolean): void {
    // 调用方不要求引导购买
    if (!showMemberPurchasePage) {
      return
    }

    // 与首页 Index 中 bindSheet 联动

    SimpleEventBus.emit(MemberManager.NOTIFY_OPEN_MEMBER_SHEET)
  }

  // MARK: - Check times functions

  // 非会员是否允许「下载词汇」能力；showMessage：是否 Toast；showMemberPurchasePage：是否尝试打开会员页
  checkBooksDownloadable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    // 会员不限
    if (this.isActive) {
      return true
    }

    this.requestOpenMemberSheet(showMemberPurchasePage)

    // 提示非会员不可下载
    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_download_books'))
    }

    return false
  }

  // 非会员创建 EBook 是否未超上限；showMessage：超限提示；showMemberPurchasePage：是否打开会员页
  checkEBookCreatable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    // 会员不限本数
    if (this.isActive) {
      return true
    }

    const books = BookManager.shared.books

    const currentCount = books.filter((b) => b.isEBook).length

    // 未达非会员上限
    if (currentCount < this.maxEBookCount) {
      return true
    }

    this.requestOpenMemberSheet(showMemberPurchasePage)

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_add_ebook'))
    }

    return false
  }

  // 单词发音是否仍有次数；showMessage：用尽时是否提示（与 Android 一致，不弹会员页）
  checkWordPronUsable(showMessage: boolean = true): boolean {
    if (this.isActive) {
      return true
    }

    // 当日次数已用尽
    if (this.remainWordPronCount() === 0) {
      if (showMessage) {
        Toast.showMessage(getStringF($r('app.string.member_manager_msg_limit_word_pron'), this.maxWordPronCountDaily))
      }

      return false
    }

    return true
  }

  // 剩余单词发音次数（含 Encourage 奖励）
  remainWordPronCount(): number {
    const limitCount = this.maxWordPronCountDaily
      + EncourageManager.shared.earnedEncourageCount(EncourageType.wordPronShareApp)
      + EncourageManager.shared.earnedEncourageCount(EncourageType.wordPronRewardAd)

    const remainCount = limitCount - DailyCountManager.shared.dailyCount(DailyCountType.wordPron)

    return remainCount > 0 ? remainCount : 0
  }

  // 例句发音是否可用；showMessage：用尽时是否提示；showMemberPurchasePage：是否打开会员页
  checkExamplePronUsable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    if (this.isActive) {
      return true
    }

    // 已达非会员每日例句发音上限
    if (this.maxExamplePronCountDaily <= DailyCountManager.shared.dailyCount(DailyCountType.examplePron)) {
      this.requestOpenMemberSheet(showMemberPurchasePage)

      if (showMessage) {
        Toast.showMessage(getStringF($r('app.string.member_manager_msg_limit_example_pron'), this.maxExamplePronCountDaily))
      }

      return false
    }

    return true
  }

  // 内置词典是否可用；showMessage：用尽时是否提示；showMemberPurchasePage：是否打开会员页
  checkDictShowable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    if (this.isActive) {
      return true
    }

    // 已达非会员每日内置词典展示上限
    if (this.maxDictShowCountDaily <= DailyCountManager.shared.dailyCount(DailyCountType.dictShow)) {
      this.requestOpenMemberSheet(showMemberPurchasePage)

      if (showMessage) {
        Toast.showMessage(getStringF($r('app.string.member_manager_msg_limit_dict_show'), this.maxDictShowCountDaily))
      }

      return false
    }

    return true
  }

  // 单元是否可用；curUnitNo：当前单元序号；showMessage：是否提示；showMemberPurchasePage：是否打开会员页
  checkUnitUsable(curUnitNo: number, showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    if (this.isActive) {
      return true
    }

    // 超出非会员可免费使用的单元序号
    if (this.maxFreeUnitsCount < curUnitNo) {
      this.requestOpenMemberSheet(showMemberPurchasePage)

      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_use_all_units'))
      }

      return false
    }

    return true
  }

  // 记忆曲线 dayOf 是否可用；curDayOfNum：dayOf 序号
  checkDayOfUsable(curDayOfNum: number, showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    if (this.isActive) {
      return true
    }

    // 超出非会员可免费使用的记忆曲线 dayOf 序号
    if (this.maxFreePlanDayOfsCount < curDayOfNum) {
      this.requestOpenMemberSheet(showMemberPurchasePage)

      if (showMessage) {
        Toast.showMessage($r('app.string.member_manager_msg_limit_use_all_plan_dayofs'))
      }

      return false
    }

    return true
  }

  // MARK: - Check Lock functions（0：off 1：lock，与 AppCfg 一致）

  // 自动发音：被策略锁且非会员则不可用
  checkAutoPronUsable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    // AppCfg 未锁则全体可用
    if (!AppCfgManager.shared.isNonMember_Lock_AutoPron()) {
      return true
    }

    if (this.isActive) {
      return true
    }

    this.requestOpenMemberSheet(showMemberPurchasePage)

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_auto_pron'))
    }

    return false
  }

  // 夜间模式：被策略锁且非会员则不可用
  checkNightModeUsable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    // AppCfg 未锁定夜间模式
    if (!AppCfgManager.shared.isNonMember_Lock_NightMode()) {
      return true
    }

    if (this.isActive) {
      return true
    }

    this.requestOpenMemberSheet(showMemberPurchasePage)

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_use_night_mode'))
    }

    return false
  }

  // 隐藏释义：被策略锁且非会员则不可用
  checkHideTransUsable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    // AppCfg 未锁定隐藏释义
    if (!AppCfgManager.shared.isNonMember_Lock_HideTrans()) {
      return true
    }

    if (this.isActive) {
      return true
    }

    this.requestOpenMemberSheet(showMemberPurchasePage)

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_use_hide_trans'))
    }

    return false
  }

  // 再测一次（仅错题）；命名与 Android checkRetestMisakeUsable 对应功能一致，鸿蒙保留正确拼写 Mistake
  checkRetestMistakeUsable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    // AppCfg 未锁定「仅错题再测」
    if (!AppCfgManager.shared.isNonMember_Lock_RetestMistake()) {
      return true
    }

    if (this.isActive) {
      return true
    }

    this.requestOpenMemberSheet(showMemberPurchasePage)

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_use_retest_mistake'))
    }

    return false
  }

  // 词根助记：被策略锁且非会员则不可用
  checkCigenUsable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    // AppCfg 未锁定词根助记
    if (!AppCfgManager.shared.isNonMember_Lock_Cigen()) {
      return true
    }

    if (this.isActive) {
      return true
    }

    this.requestOpenMemberSheet(showMemberPurchasePage)

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_use_cigen'))
    }

    return false
  }

  // 同根词：被策略锁且非会员则不可用
  checkSameRootUsable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    // AppCfg 未锁定同根词
    if (!AppCfgManager.shared.isNonMember_Lock_SameRoot()) {
      return true
    }

    if (this.isActive) {
      return true
    }

    this.requestOpenMemberSheet(showMemberPurchasePage)

    if (showMessage) {
      Toast.showMessage($r('app.string.member_manager_msg_limit_use_sameroot'))
    }

    return false
  }

  // 在线词典每日次数
  checkOnlineDictUsable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    if (this.isActive) {
      return true
    }

    // 已达非会员每日在线词典上限
    if (this.maxOnlineDictUseCountDaily <= DailyCountManager.shared.dailyCount(DailyCountType.onlineDict)) {
      this.requestOpenMemberSheet(showMemberPurchasePage)

      if (showMessage) {
        Toast.showMessage(getStringF($r('app.string.member_manager_msg_limit_online_dict_use'), this.maxOnlineDictUseCountDaily))
      }

      return false
    }

    return true
  }

  // 挑战模式每日次数
  checkChallengeDictUsable(showMessage: boolean = true, showMemberPurchasePage: boolean = false): boolean {
    if (this.isActive) {
      return true
    }

    // 已达非会员每日挑战次数上限
    if (this.maxChallengeUseCountDaily <= DailyCountManager.shared.dailyCount(DailyCountType.challenge)) {
      this.requestOpenMemberSheet(showMemberPurchasePage)

      if (showMessage) {
        Toast.showMessage(getStringF($r('app.string.member_manager_msg_limit_challenge_use'), this.maxChallengeUseCountDaily))
      }

      return false
    }

    return true
  }
}
