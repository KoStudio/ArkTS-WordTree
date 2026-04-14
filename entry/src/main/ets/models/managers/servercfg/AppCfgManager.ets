//
//  AppCfgManager.ets
//  WordTree (HarmonyOS)
//
//  与 Android `com.ou.wordtree.managers.servercfg.AppCfgManager` 对齐：
//  本地缓存 + 定时拉取 ServerCfg，key 与 Kotlin `AppCfg.name` 一致（服务端 Book_AppCfg 表）。
//

import preferences from '@ohos.data.preferences'
import { getAppContext } from '../../../app/constants/AppContext'
import { LanguageManager } from '../../../common/components/Language/LanguageManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { NetWorkTool } from '../../../common/utils/NetworkUtils'
import { Toast } from '../../../common/utils/Toast'
import { MemberManager } from '../member/MemberManager'
import { TimeToManager, TimeToType } from '../timeto/TimeToManager'
import { ServerCfg, ServerCfgManager } from './ServerCfgManager'

// MARK: - Pref（与 Android `Pref` object 一致）
class Pref {
  static readonly Name: string = 'S_AppCfg_Manager_pref'
  static readonly ValueKeyPrefix: string = 'v:'
  static readonly NameKeyPrefix: string = 'n:'
}

/** 与 Android `AppCfgManager.Notification` 嵌套对象一致（ArkTS 用 `export namespace`） */
export namespace AppCfgNotification {
  export namespace Name {
    export const AppCfgUpdated: string = 'app_cfg_updated_from_server'
  }
}

/**
 * 与 Android `enum class AppCfg` 逐项对应；字符串值须等于 Kotlin `.name`（服务端 key）。
 * 行尾注释与 `AppCfgManager.kt` 中 enum 条目一致。
 */
export enum AppCfg {
  ///通用
  Android_WTS_Home_Notice_idx_in_Instruction             = 'Android_WTS_Home_Notice_idx_in_Instruction',             // [通用] [WordTree_CNS]首页滚动公告在Instruction_Harmony中对应的idx。 idx == 0: 不会查询Server端, idx > 0 : 会查询Server端的Instruction_Harmony表 [鸿蒙]
  Android_WTT_Home_Notice_idx_in_Instruction             = 'Android_WTT_Home_Notice_idx_in_Instruction',             // [通用] [WordTree_CNT]首页滚动公告在Instruction_Harmony中对应的idx。 idx == 0: 不会查询Server端, idx > 0 : 会查询Server端的Instruction_Harmony表 [鸿蒙]
  Android_TT_Home_Notice_idx_in_Instruction              = 'Android_TT_Home_Notice_idx_in_Instruction',              // [通用] [TangoTree]首页滚动公告在Instruction_Harmony中对应的idx。 idx == 0: 不会查询Server端, idx > 0 : 会查询Server端的Instruction_Harmony表 [鸿蒙]

  Android_WTS_ShareAppLink_idx_in_Instruction            = 'Android_WTS_ShareAppLink_idx_in_Instruction',            // [通用] [WordTree_CNS]分享应用link 在Instruction_Harmony中对应的idx。(idx <= 0：不会查询Server端(使用本地链接)，idx > 0：才会从Instruction_Harmony中查询链接)]
  Android_WTT_ShareAppLink_idx_in_Instruction            = 'Android_WTT_ShareAppLink_idx_in_Instruction',            // [通用] [WordTree_CNT]分享应用link 在Instruction_Harmony中对应的idx。(idx <= 0：不会查询Server端(使用本地链接)，idx > 0：才会从Instruction_Harmony中查询链接)]
  Android_TT_ShareAppLink_idx_in_Instruction             = 'Android_TT_ShareAppLink_idx_in_Instruction',             // [通用] [TangoTree]分享应用link 在Instruction_Harmony中对应的idx。(idx <= 0：不会查询Server端(使用本地链接)，idx > 0：才会从Instruction_Harmony中查询链接)]

  IOS_SubscribePriceShowIntroductoryFirst                = 'IOS_SubscribePriceShowIntroductoryFirst',                // [通用] 订阅价格是否优先显示推介促销价格［iOS］
  Android_SubscribePrice_is_Show_PriceTip                = 'Android_SubscribePrice_is_Show_PriceTip',                // [通用] 订阅价格是否显示价格提示［iOS］
  Android_HwMember_Show_ConsumablePriceButtons_is_ON     = 'Android_HwMember_Show_ConsumablePriceButtons_is_ON',     // [Android] 华为会员页是否显示后三个单次购买价格按钮
  Android_HwMember_Show_ConsumablePriceAsMonths_is_ON    = 'Android_HwMember_Show_ConsumablePriceAsMonths_is_ON',    // [Android] 华为会员页单次购买价格按钮是否按“月数会员”方式显示
  Android_WxMember_Show_PriceButtons_MoreThan1Year_is_ON = 'Android_WxMember_Show_PriceButtons_MoreThan1Year_is_ON', // [Android] 微信会员页是否显示大于1年的价格按钮
  IOS_Show_Wx_QRLogin_When_Weixin_Not_installed          = 'IOS_Show_Wx_QRLogin_When_Weixin_Not_installed',          // [通用] 未安装微信时，是否显示微信QR登录。0:不显示，1:显示QR登录  [iOS]

  AutoRefreshSubscriptionInfo_is_ON                      = 'AutoRefreshSubscriptionInfo_is_ON',                      // [通用] 是否启用 自动刷新会员订阅时间
  AutoRefreshSubscriptionInfo_Interval_Minutes           = 'AutoRefreshSubscriptionInfo_Interval_Minutes',           // [通用] 自动刷新 服务器上的会员订阅的 时间间隔（只读）单位：分钟 [AutoRefreshSubscriptionInfo_is_ON启用了才有效]

  CosAuditCheckForSignup_is_ON                           = 'CosAuditCheckForSignup_is_ON',                           // [通用] 是否启用 注册审核(0：未启用，1：已启用）
  CosAuditCheckForLogin_is_ON                            = 'CosAuditCheckForLogin_is_ON',                            // [通用] 是否启用 登录审核(0：未启用，1：已启用）
  CosAuditCheckForMemo_is_ON                             = 'CosAuditCheckForMemo_is_ON',                             // [通用] 是否启用 笔记审核(0：未启用，1：已启用）

  CBook_Useable_is_ON                                    = 'CBook_Useable_is_ON',                                    // [通用] 是否启用 CBook[总开关]（Cos下载的Book）(0：未启用〈使用App bundle内的Book〉，1：已启用）
  CBook_AutoUpdateCheck_is_ON                            = 'CBook_AutoUpdateCheck_is_ON',                            // [通用] 是否启用 CBook自动更新检查
  CBook_AutoUpdateCheck_Interval_Minutes                 = 'CBook_AutoUpdateCheck_Interval_Minutes',                 // [通用]  CBook自动更新检查 时间间隔 单位：分钟 [CBook_AutoUpdateCheck_is_ON启用了才有效]
  CBookList_AutoUpdateCheck_is_ON                        = 'CBookList_AutoUpdateCheck_is_ON',                        // [通用] 是否启用 CBookList自动更新检查(更新检查 时间间隔也使用CBook_AutoUpdateCheck_Interval_Minutes)

  ///会员 M
  M_MemberUseCloudSound                                  = 'M_MemberUseCloudSound',                                  // [会员] 是否使用云声音(0：未启用，1：已启用）

  ///非会员 N
  N_NonMemberUseCloudSound                               = 'N_NonMemberUseCloudSound',                               // [非会员] 是否使用云声音(0：未启用，1：已启用）

  /// 非会员策略 Id（由服务器下发，原 ObjC 宏）
  N_WordPron_Times                                       = 'N_WordPron_Times',                                       // 单词发音 每日免费次数 _Free_Times_Per_Day
  N_ExamplePron_Times                                    = 'N_ExamplePron_Times',                                    // 例句发音 每日免费次数
  N_DictShow_Times                                       = 'N_DictShow_Times',                                       // 内置词典 每日免费次数
  N_Free_Units_Count                                     = 'N_Free_Units_Count',                                     // 免费单元个数
  N_Lock_AutoPron                                        = 'N_Lock_AutoPron',                                        // [锁定]自动发音
  N_Lock_NightMode                                       = 'N_Lock_NightMode',                                       // [锁定]夜晚模式
  N_Lock_HideTrans                                       = 'N_Lock_HideTrans',                                       // [锁定]隐藏翻译
  N_Lock_RetestMistake                                   = 'N_Lock_RetestMistake',                                   // [锁定]再测一次(仅错误单词)
  N_Free_Plan_DayOfs_Count                               = 'N_Free_Plan_DayOfs_Count',                               // 记忆曲线 免费天数
  N_Lock_Cigen                                           = 'N_Lock_Cigen',                                           // [锁定]词根助记
  N_Lock_SameRoot                                        = 'N_Lock_SameRoot',                                        // [锁定]同根词
  N_OnlineDict_Times                                     = 'N_OnlineDict_Times',                                     // 在线字典 每日免费次数
  N_Challenge_Times                                      = 'N_Challenge_Times',                                      // 挑战模式 每日免费次数
  N_EBook_MaxCount                                       = 'N_EBook_MaxCount',                                       // 非会员可创建的 EBook 最大个数（自建词汇本数量上限）

  G_WTS_FirstInstall                                     = 'G_WTS_FirstInstall',                                     // 首次安装赠送金币数量
  G_WTS_EveryDayStudy                                    = 'G_WTS_EveryDayStudy',                                    // 每日学习赠送金币数量
  G_WTS_EveryDayTest                                     = 'G_WTS_EveryDayTest',                                     // 每日测试赠送金币数量
  G_WTS_ShareApp                                         = 'G_WTS_ShareApp',                                         // 首次分享应用赠送金币数量
  G_WTS_WatchAd                                          = 'G_WTS_WatchAd',                                          // 每次观看激励广告赠送金币数量

  G_WTT_FirstInstall                                     = 'G_WTT_FirstInstall',                                     // 首次安装赠送金币数量
  G_WTT_EveryDayStudy                                    = 'G_WTT_EveryDayStudy',                                    // 每日学习赠送金币数量
  G_WTT_EveryDayTest                                     = 'G_WTT_EveryDayTest',                                     // 每日测试赠送金币数量
  G_WTT_ShareApp                                         = 'G_WTT_ShareApp',                                         // 首次分享应用赠送金币数量
  G_WTT_WatchAd                                          = 'G_WTT_WatchAd',                                          // 每次观看激励广告赠送金币数量

  G_TT_FirstInstall                                      = 'G_TT_FirstInstall',                                      // 首次安装赠送金币数量
  G_TT_EveryDayStudy                                     = 'G_TT_EveryDayStudy',                                     // 每日学习赠送金币数量
  G_TT_EveryDayTest                                      = 'G_TT_EveryDayTest',                                      // 每日测试赠送金币数量
  G_TT_ShareApp                                          = 'G_TT_ShareApp',                                          // 首次分享应用赠送金币数量
  G_TT_WatchAd                                           = 'G_TT_WatchAd',                                           // 每次观看激励广告赠送金币数量
}

/** 与 Android `AppCfg.all` 顺序一致，供遍历 / 服务端合并 */
export const APP_CFG_ALL: AppCfg[] = [
  AppCfg.Android_WTS_Home_Notice_idx_in_Instruction,
  AppCfg.Android_WTT_Home_Notice_idx_in_Instruction,
  AppCfg.Android_TT_Home_Notice_idx_in_Instruction,
  AppCfg.Android_WTS_ShareAppLink_idx_in_Instruction,
  AppCfg.Android_WTT_ShareAppLink_idx_in_Instruction,
  AppCfg.Android_TT_ShareAppLink_idx_in_Instruction,
  AppCfg.IOS_SubscribePriceShowIntroductoryFirst,
  AppCfg.Android_SubscribePrice_is_Show_PriceTip,
  AppCfg.Android_HwMember_Show_ConsumablePriceButtons_is_ON,
  AppCfg.Android_HwMember_Show_ConsumablePriceAsMonths_is_ON,
  AppCfg.Android_WxMember_Show_PriceButtons_MoreThan1Year_is_ON,
  AppCfg.IOS_Show_Wx_QRLogin_When_Weixin_Not_installed,
  AppCfg.AutoRefreshSubscriptionInfo_is_ON,
  AppCfg.AutoRefreshSubscriptionInfo_Interval_Minutes,
  AppCfg.CosAuditCheckForSignup_is_ON,
  AppCfg.CosAuditCheckForLogin_is_ON,
  AppCfg.CosAuditCheckForMemo_is_ON,
  AppCfg.CBook_Useable_is_ON,
  AppCfg.CBook_AutoUpdateCheck_is_ON,
  AppCfg.CBook_AutoUpdateCheck_Interval_Minutes,
  AppCfg.CBookList_AutoUpdateCheck_is_ON,
  AppCfg.M_MemberUseCloudSound,
  AppCfg.N_NonMemberUseCloudSound,
  AppCfg.N_WordPron_Times,
  AppCfg.N_ExamplePron_Times,
  AppCfg.N_DictShow_Times,
  AppCfg.N_Free_Units_Count,
  AppCfg.N_Lock_AutoPron,
  AppCfg.N_Lock_NightMode,
  AppCfg.N_Lock_HideTrans,
  AppCfg.N_Lock_RetestMistake,
  AppCfg.N_Free_Plan_DayOfs_Count,
  AppCfg.N_Lock_Cigen,
  AppCfg.N_Lock_SameRoot,
  AppCfg.N_OnlineDict_Times,
  AppCfg.N_Challenge_Times,
  AppCfg.N_EBook_MaxCount,
  AppCfg.G_WTS_FirstInstall,
  AppCfg.G_WTS_EveryDayStudy,
  AppCfg.G_WTS_EveryDayTest,
  AppCfg.G_WTS_ShareApp,
  AppCfg.G_WTS_WatchAd,
  AppCfg.G_WTT_FirstInstall,
  AppCfg.G_WTT_EveryDayStudy,
  AppCfg.G_WTT_EveryDayTest,
  AppCfg.G_WTT_ShareApp,
  AppCfg.G_WTT_WatchAd,
  AppCfg.G_TT_FirstInstall,
  AppCfg.G_TT_EveryDayStudy,
  AppCfg.G_TT_EveryDayTest,
  AppCfg.G_TT_ShareApp,
  AppCfg.G_TT_WatchAd,
]

export interface GoldPolicyRow {
  key: string
  value: number
  name: string | null
}

export class AppCfgManager {
  //MARK: -
  ///缓存dict（key -> value）
  private dict: Map<string, number> = new Map()
  ///缓存name（key -> name）
  private nameDict: Map<string, string> = new Map()

  private static instance: AppCfgManager | null = null

  static get shared(): AppCfgManager {
    if (!AppCfgManager.instance) {
      AppCfgManager.instance = new AppCfgManager()
    }
    return AppCfgManager.instance
  }

  private constructor() {
    this.init()
  }

  private init(): void {
    //从本地加载
    this.loadPreference()
    ///从服务器加载 configs
    this.loadConfigsIfNeeds()
  }

  private isCurLanguageCNT(): boolean {
    // 统一使用 LanguageManager 的当前语言索引，避免冷启动时 Context Locale 不一致
    return LanguageManager.isTraditionalChinese()
  }

  ///默认值
  private static getDefaultValue(cfg: AppCfg): number {
    switch (cfg) {
      case AppCfg.Android_WTS_Home_Notice_idx_in_Instruction:              return 1  // [WordTree_CNS]首页滚动公告在Instruction_Harmony中对应的idx。 idx == 0: 不会查询Server端, idx > 0 : 会查询Server端的Instruction_Harmony表 [鸿蒙]
      case AppCfg.Android_WTT_Home_Notice_idx_in_Instruction:              return 2  // [WordTree_CNT]首页滚动公告在Instruction_Harmony中对应的idx。 idx == 0: 不会查询Server端, idx > 0 : 会查询Server端的Instruction_Harmony表 [鸿蒙]
      case AppCfg.Android_TT_Home_Notice_idx_in_Instruction:               return 3  // [TangoTree]首页滚动公告在Instruction_Harmony中对应的idx。 idx == 0: 不会查询Server端, idx > 0 : 会查询Server端的Instruction_Harmony表 [鸿蒙]
      case AppCfg.Android_WTS_ShareAppLink_idx_in_Instruction:             return 11  // [WordTree_CNS]分享应用link 在Instruction_Harmony中对应的idx。(idx <= 0：不会查询Server端(使用本地链接)，idx > 0：才会从Instruction_Harmony中查询链接)]
      case AppCfg.Android_WTT_ShareAppLink_idx_in_Instruction:             return 12  // [WordTree_CNT]分享应用link 在Instruction_Harmony中对应的idx。(idx <= 0：不会查询Server端(使用本地链接)，idx > 0：才会从Instruction_Harmony中查询链接)]
      case AppCfg.Android_TT_ShareAppLink_idx_in_Instruction:              return 13  // [TangoTree]分享应用link 在Instruction_Harmony中对应的idx。(idx <= 0：不会查询Server端(使用本地链接)，idx > 0：才会从Instruction_Harmony中查询链接)]
      case AppCfg.IOS_SubscribePriceShowIntroductoryFirst:                 return 1  // [通用]iOS订阅价格是否优先显示推介促销价格 (0: 不显示促销价格，1：显示促销价格)
      case AppCfg.Android_SubscribePrice_is_Show_PriceTip:                 return 1  // [通用] 订阅价格是否显示价格提示［Android］
      case AppCfg.Android_HwMember_Show_ConsumablePriceButtons_is_ON:      return 1  // [Android] 华为会员页默认显示后三个单次购买价格按钮(0:不显示，1:显示)
      case AppCfg.Android_HwMember_Show_ConsumablePriceAsMonths_is_ON:     return 0  // [Android] 华为会员页单次购买价格按钮显示方式(0:按年，1:按月数)
      case AppCfg.Android_WxMember_Show_PriceButtons_MoreThan1Year_is_ON:  return 1  // [Android] 微信会员页默认显示大于1年的价格按钮(0:不显示，1:显示)
      case AppCfg.IOS_Show_Wx_QRLogin_When_Weixin_Not_installed:           return 1  // [通用] 未安装微信时，是否显示微信QR登录。0:不显示，1:显示QR登录  [iOS]
      case AppCfg.AutoRefreshSubscriptionInfo_is_ON:                       return 1  // [通用] 是否启用 自动刷新会员订阅时间(0：未启用，1：已启用）
      case AppCfg.AutoRefreshSubscriptionInfo_Interval_Minutes:            return 60 * 12  // [通用] 自动刷新 服务器上的会员订阅的 时间间隔（只读） 单位：分钟 [AutoRefreshSubscriptionInfo_is_ON启用了才有效]
      case AppCfg.CosAuditCheckForSignup_is_ON:                            return 1  // [通用] 是否启用 注册审核(0：未启用，1：已启用）
      case AppCfg.CosAuditCheckForLogin_is_ON:                             return 1  // [通用] 是否启用 登录审核(0：未启用，1：已启用）
      case AppCfg.CosAuditCheckForMemo_is_ON:                              return 1  // [通用] 是否启用 笔记审核(0：未启用，1：已启用）
      case AppCfg.CBook_Useable_is_ON:                                     return 1  // [通用] 是否启用 CBook[总开关]（Cos下载的Book）(0：未启用〈使用App bundle内的Book〉，1：已启用）
      case AppCfg.CBook_AutoUpdateCheck_is_ON:                             return 1  // [通用] 是否启用 CBook自动更新检查
      case AppCfg.CBook_AutoUpdateCheck_Interval_Minutes:                  return 60 * 48  // [通用] CBook自动更新检查 时间间隔 单位：分钟 [CBook_AutoUpdateCheck_is_ON启用了才有效]
      case AppCfg.CBookList_AutoUpdateCheck_is_ON:                         return 1  // [通用] 是否启用 CBookList自动更新检查(更新检查 时间间隔也使用CBook_AutoUpdateCheck_Interval_Minutes)
      case AppCfg.M_MemberUseCloudSound:                                   return 1  // [会员] 是否使用云声音(0：未启用，1：已启用）
      case AppCfg.N_NonMemberUseCloudSound:                                return 1  // [非会员] 是否使用云声音(0：未启用，1：已启用）
      case AppCfg.N_WordPron_Times:                                        return 80  // 单词发音 每日免费次数 _Free_Times_Per_Day
      case AppCfg.N_ExamplePron_Times:                                     return 10  // 例句发音 每日免费次数
      case AppCfg.N_DictShow_Times:                                        return 10  // 内置词典 每日免费次数
      case AppCfg.N_Free_Units_Count:                                      return 100  // 免费单元个数
      case AppCfg.N_Lock_AutoPron:                                         return 1  // [锁定]自动发音   [0： off，1：lock]
      case AppCfg.N_Lock_NightMode:                                        return 1  // [锁定]夜晚模式   [0： off，1：lock]
      case AppCfg.N_Lock_HideTrans:                                        return 1  // [锁定]隐藏翻译   [0： off，1：lock]
      case AppCfg.N_Lock_RetestMistake:                                    return 1  // [锁定]再测一次(仅错误单词)  [0： off，1：lock]
      case AppCfg.N_Free_Plan_DayOfs_Count:                                return 5  // 记忆曲线 免费天数
      case AppCfg.N_Lock_Cigen:                                            return 1  // [锁定]词根助记 [0： off，1：lock]
      case AppCfg.N_Lock_SameRoot:                                         return 1  // [锁定]同根词   [0： off，1：lock]
      case AppCfg.N_OnlineDict_Times:                                      return 100  // 在线字典 每日免费次数
      case AppCfg.N_Challenge_Times:                                       return 10  // 挑战模式 每日免费次数
      case AppCfg.N_EBook_MaxCount:                                        return 1  // 非会员默认最多可创建 1 个 EBook（自建词汇本）
      case AppCfg.G_WTS_FirstInstall:                                      return 100  // 首次安装赠送100个金币
      case AppCfg.G_WTS_EveryDayStudy:                                     return 10  // 每日学习赠送10个金币
      case AppCfg.G_WTS_EveryDayTest:                                      return 10  // 每日测试赠送10个金币
      case AppCfg.G_WTS_ShareApp:                                          return 300  // 首次分享应用赠送300个金币
      case AppCfg.G_WTS_WatchAd:                                           return 10  // 每次观看激励广告赠送10个金币
      case AppCfg.G_WTT_FirstInstall:                                      return 100  // 首次安裝贈送100個金幣
      case AppCfg.G_WTT_EveryDayStudy:                                     return 10  // 每日學習贈送10個金幣
      case AppCfg.G_WTT_EveryDayTest:                                      return 10  // 每日測試贈送10個金幣
      case AppCfg.G_WTT_ShareApp:                                          return 300  // 首次分享應用贈送300個金幣
      case AppCfg.G_WTT_WatchAd:                                           return 10  // 每次觀看激勵廣告贈送10個金幣
      case AppCfg.G_TT_FirstInstall:                                       return 100  // 初インストール時に100ゴールドをゲット。
      case AppCfg.G_TT_EveryDayStudy:                                      return 10  // 毎日学習すると10ゴールドをゲット。
      case AppCfg.G_TT_EveryDayTest:                                       return 10  // 毎日テストすると10ゴールドをゲット。
      case AppCfg.G_TT_ShareApp:                                           return 300  // 🎉アプリを共有すると300ゴールドをゲット。
      case AppCfg.G_TT_WatchAd:                                            return 10  // 🎉広告を見ると、💰ゴールド10個ゲット❗️
      default:                                                             return 0
    }
  }

  //MARK: - save & load local prefs

  private savePreference(): void {
    try {
      const pref = preferences.getPreferencesSync(getAppContext(), { name: Pref.Name })
      this.dict.forEach((value: number, key: string) => {
        pref.putSync(Pref.ValueKeyPrefix + key, value)
      })
      this.nameDict.forEach((value: string, key: string) => {
        pref.putSync(Pref.NameKeyPrefix + key, value)
      })
      pref.flushSync()
    } catch (e) {
      console.error(`AppCfgManager.savePreference failed: ${(e as Error).message}`)
    }
  }

  private loadPreference(): void {
    try {
      ///先设置本地默认值
      APP_CFG_ALL.forEach((cfg: AppCfg) => {
        this.dict.set(cfg, AppCfgManager.getDefaultValue(cfg))
      })

      const pref = preferences.getPreferencesSync(getAppContext(), { name: Pref.Name })
      APP_CFG_ALL.forEach((cfg: AppCfg) => {
        ///更新已经保存的值
        const def = AppCfgManager.getDefaultValue(cfg)
        const valueKey = Pref.ValueKeyPrefix + cfg
        let savedValue: number
        if (pref.hasSync(valueKey)) {
          savedValue = pref.getSync(valueKey, def) as number
        } else {
          savedValue = pref.getSync(cfg, def) as number
        }
        this.dict.set(cfg, savedValue)

        const nameKey = Pref.NameKeyPrefix + cfg
        if (pref.hasSync(nameKey)) {
          const n = pref.getSync(nameKey, '') as string
          if (n && n.length > 0) {
            this.nameDict.set(cfg, n)
          }
        }
      })
    } catch (e) {
      console.error(`AppCfgManager.loadPreference failed: ${(e as Error).message}`)
    }
  }

  //MARK: -

  ///[判断时间间隔]一次获取所有ServerConfigs
  loadConfigsIfNeeds(): void {
    ///检查网络连接
    if (!NetWorkTool.checkInternetConnection(false)) {
      return
    }

    //7天
    //检查是否到时间需要，从服务器更新Configs
    if (TimeToManager.isTimeTo(TimeToType.updateServerConfigs)) {
      //执行一次ServerCfg查询
      this.refreshServerCfgs()
      //保存本次更新时间
      TimeToManager.saveTime(TimeToType.updateServerConfigs, true)
    }
  }

  ///立即执行一次ServerCfg查询
  refreshServerCfgs(): void {
    ///从服务器 或缓存中 加载 configs
    ServerCfgManager.loadServerCfgs((succeed: boolean, msg: string | null, serverCfgs: ServerCfg[] | null) => {
      if (succeed && serverCfgs) {
        APP_CFG_ALL.forEach((appCfg: AppCfg) => {
          const serverCfg = serverCfgs.find((sc: ServerCfg) => sc.key === appCfg)
          if (serverCfg) {
            // 与 iOS 保持一致：只有服务端明确返回 value 时才覆盖本地值，
            // 避免把有效缓存误写成 0。
            if (serverCfg.value !== null && serverCfg.value !== undefined) {
              this.dict.set(appCfg, serverCfg.value)
            }
            //保存name
            if (serverCfg.name !== null && serverCfg.name !== undefined && serverCfg.name.length > 0) {
              this.nameDict.set(appCfg, serverCfg.name)
            }
          }
        })

        //保存到本地
        this.savePreference()

        ///发送配置更新通知，有需要的地方（如：Marquee Notice）可以即时获得通知
        SimpleEventBus.emit(AppCfgNotification.Name.AppCfgUpdated)
        Toast.showDebugMessage('刷新ServerCfg成功')
      } else {
        Toast.showDebugMessage(msg ?? '')
      }
    })
  }

  //MARK: - get functions
  /// 获取　[通用]鸿蒙首页滚动公告idx(Instruction_Harmony表)
  getHomeNoticeIdx_In_Instruction_ForAndroid(): number {
    if (this.isCurLanguageCNT()) {
      return this.dict.get(AppCfg.Android_WTT_Home_Notice_idx_in_Instruction) ??
        AppCfgManager.getDefaultValue(AppCfg.Android_WTT_Home_Notice_idx_in_Instruction)
    }
    return this.dict.get(AppCfg.Android_WTS_Home_Notice_idx_in_Instruction) ??
      AppCfgManager.getDefaultValue(AppCfg.Android_WTS_Home_Notice_idx_in_Instruction)
  }

  /// 获取　[通用] 分享应用link 在Instruction_Harmony中对应的idx
  getAndroid_ShareAppLink_idx_in_Instruction(): number {
    if (this.isCurLanguageCNT()) {
      return this.dict.get(AppCfg.Android_WTT_ShareAppLink_idx_in_Instruction) ??
        AppCfgManager.getDefaultValue(AppCfg.Android_WTT_ShareAppLink_idx_in_Instruction)
    }
    return this.dict.get(AppCfg.Android_WTS_ShareAppLink_idx_in_Instruction) ??
      AppCfgManager.getDefaultValue(AppCfg.Android_WTS_ShareAppLink_idx_in_Instruction)
  }

  /// 获取　[通用]订阅价格是否优先显示　推介促销价格
  isSubscribePriceShowIntroductoryFirst(): boolean {
    return (this.dict.get(AppCfg.IOS_SubscribePriceShowIntroductoryFirst) ??
      AppCfgManager.getDefaultValue(AppCfg.IOS_SubscribePriceShowIntroductoryFirst)) === 1
  }

  /// 获取　[通用]订阅价格是否显示价格提示
  isSubscribePrice_Show_PriceTip(): boolean {
    return (this.dict.get(AppCfg.Android_SubscribePrice_is_Show_PriceTip) ??
      AppCfgManager.getDefaultValue(AppCfg.Android_SubscribePrice_is_Show_PriceTip)) === 1
  }

  /// 获取 [Android] 华为会员页是否显示后三个单次购买价格按钮
  isHwMember_Show_ConsumablePriceButtons_is_ON(): boolean {
    return (this.dict.get(AppCfg.Android_HwMember_Show_ConsumablePriceButtons_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.Android_HwMember_Show_ConsumablePriceButtons_is_ON)) === 1
  }

  /// 获取 [Android] 华为会员页单次购买价格按钮是否按“月数会员”方式显示
  isHwMember_Show_ConsumablePriceAsMonths_is_ON(): boolean {
    return (this.dict.get(AppCfg.Android_HwMember_Show_ConsumablePriceAsMonths_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.Android_HwMember_Show_ConsumablePriceAsMonths_is_ON)) === 1
  }

  /// 获取 [Android] 微信会员页是否显示大于1年的价格按钮
  isWxMember_Show_PriceButtons_MoreThan1Year_is_ON(): boolean {
    return (this.dict.get(AppCfg.Android_WxMember_Show_PriceButtons_MoreThan1Year_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.Android_WxMember_Show_PriceButtons_MoreThan1Year_is_ON)) === 1
  }

  /// 获取　[通用] 未安装微信时，是否显示微信QR登录。0:不显示，1:显示QR登录  [iOS]
  isShowWxQRLogin_When_Weixin_Not_installed_ForIOS(): boolean {
    return (this.dict.get(AppCfg.IOS_Show_Wx_QRLogin_When_Weixin_Not_installed) ??
      AppCfgManager.getDefaultValue(AppCfg.IOS_Show_Wx_QRLogin_When_Weixin_Not_installed)) === 1
  }

  /// 获取　[通用] 是否启用 自动刷新会员订阅时间
  isAutoRefreshSubscriptionInfo_is_ON(): boolean {
    return (this.dict.get(AppCfg.AutoRefreshSubscriptionInfo_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.AutoRefreshSubscriptionInfo_is_ON)) === 1
  }

  /// 获取　[通用]自动刷新 服务器上的会员订阅的 时间间隔（只读） 单位：分钟
  getAutoRefreshSubscriptionInfo_Interval_Minutes(): number {
    return this.dict.get(AppCfg.AutoRefreshSubscriptionInfo_Interval_Minutes) ??
      AppCfgManager.getDefaultValue(AppCfg.AutoRefreshSubscriptionInfo_Interval_Minutes)
  }

  /// 获取　[通用] 是否启用 审核检查for注册 (用户名)
  isCosAuditCheckForSignup_is_ON(): boolean {
    return (this.dict.get(AppCfg.CosAuditCheckForSignup_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.CosAuditCheckForSignup_is_ON)) === 1
  }

  /// 获取　[通用] 是否启用 审核检查for登录 (用户名和头像)
  isCosAuditCheckForLogin_is_ON(): boolean {
    return (this.dict.get(AppCfg.CosAuditCheckForLogin_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.CosAuditCheckForLogin_is_ON)) === 1
  }

  /// 获取　[通用] 是否启用 审核检查for笔记
  isCosAuditCheckForMemo_is_ON(): boolean {
    return (this.dict.get(AppCfg.CosAuditCheckForMemo_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.CosAuditCheckForMemo_is_ON)) === 1
  }

  /// [通用] 是否启用 CBook[总开关]（Cos下载的Book）(0：未启用〈使用App bundle内的Book〉，1：已启用）
  isCBook_Useable_is_ON(): boolean {
    return (this.dict.get(AppCfg.CBook_Useable_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.CBook_Useable_is_ON)) === 1
  }

  /// [通用] 是否启用 CBook自动更新检查
  isCBook_AutoUpdateCheck_is_ON(): boolean {
    return (this.dict.get(AppCfg.CBook_AutoUpdateCheck_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.CBook_AutoUpdateCheck_is_ON)) === 1
  }

  /// [通用] CBook自动更新检查 时间间隔 单位：分钟 [CBook_AutoUpdateCheck_is_ON启用了才有效]
  getCBook_AutoUpdateCheck_Interval_Minutes(): number {
    return this.dict.get(AppCfg.CBook_AutoUpdateCheck_Interval_Minutes) ??
      AppCfgManager.getDefaultValue(AppCfg.CBook_AutoUpdateCheck_Interval_Minutes)
  }

  /// [通用] 是否启用 CBookList自动更新检查(更新检查 时间间隔也使用CBook_AutoUpdateCheck_Interval_Minutes)
  isCBookList_AutoUpdateCheck_is_ON(): boolean {
    return (this.dict.get(AppCfg.CBookList_AutoUpdateCheck_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.CBookList_AutoUpdateCheck_is_ON)) === 1
  }

  /// [通用] 是否启用 CBookIcon自动更新检查(更新检查 时间间隔也使用CBook_AutoUpdateCheck_Interval_Minutes) [Android]
  isCBookIcon_AutoUpdateCheck_is_ON(): boolean {
    return (this.dict.get(AppCfg.CBookList_AutoUpdateCheck_is_ON) ??
      AppCfgManager.getDefaultValue(AppCfg.CBookList_AutoUpdateCheck_is_ON)) === 1
  }

  //MARK: - get funcs - for Member & Non Member

  // MARK: - Non Member Policies (ServerCfg2)
  /// 获取　非会员　单词发音 每日免费次数 _Free_Times_Per_Day
  getNonMember_WordPron_Times(): number {
    return this.dict.get(AppCfg.N_WordPron_Times) ?? AppCfgManager.getDefaultValue(AppCfg.N_WordPron_Times)
  }

  /// 获取　非会员　例句发音 每日免费次数
  getNonMember_ExamplePron_Times(): number {
    return this.dict.get(AppCfg.N_ExamplePron_Times) ?? AppCfgManager.getDefaultValue(AppCfg.N_ExamplePron_Times)
  }

  /// 获取　非会员　内置词典 每日免费次数
  getNonMember_DictShow_Times(): number {
    return this.dict.get(AppCfg.N_DictShow_Times) ?? AppCfgManager.getDefaultValue(AppCfg.N_DictShow_Times)
  }

  /// 获取　非会员　免费单元个数
  getNonMember_Free_Units_Count(): number {
    return this.dict.get(AppCfg.N_Free_Units_Count) ?? AppCfgManager.getDefaultValue(AppCfg.N_Free_Units_Count)
  }

  /// 获取　非会员　记忆曲线 免费天数
  getNonMember_Free_Plan_DayOfs_Count(): number {
    return this.dict.get(AppCfg.N_Free_Plan_DayOfs_Count) ?? AppCfgManager.getDefaultValue(AppCfg.N_Free_Plan_DayOfs_Count)
  }

  /// 获取　非会员　在线字典 每日免费次数
  getNonMember_OnlineDict_Times(): number {
    return this.dict.get(AppCfg.N_OnlineDict_Times) ?? AppCfgManager.getDefaultValue(AppCfg.N_OnlineDict_Times)
  }

  /// 获取　非会员　挑战模式 每日免费次数
  getNonMember_Challenge_Times(): number {
    return this.dict.get(AppCfg.N_Challenge_Times) ?? AppCfgManager.getDefaultValue(AppCfg.N_Challenge_Times)
  }

  /// 获取　非会员　可创建 EBook 最大个数（自建词汇本数量上限）
  getNonMember_EBook_MaxCount(): number {
    return this.dict.get(AppCfg.N_EBook_MaxCount) ?? AppCfgManager.getDefaultValue(AppCfg.N_EBook_MaxCount)
  }

  /// 获取　非会员 [锁定]自动发音 状态 (0：off，1：lock)
  isNonMember_Lock_AutoPron(): boolean {
    return (this.dict.get(AppCfg.N_Lock_AutoPron) ?? AppCfgManager.getDefaultValue(AppCfg.N_Lock_AutoPron)) === 1
  }

  /// 获取　非会员 [锁定]夜晚模式 状态 (0：off，1：lock)
  isNonMember_Lock_NightMode(): boolean {
    return (this.dict.get(AppCfg.N_Lock_NightMode) ?? AppCfgManager.getDefaultValue(AppCfg.N_Lock_NightMode)) === 1
  }

  /// 获取　非会员 [锁定]隐藏翻译 状态 (0：off，1：lock)
  isNonMember_Lock_HideTrans(): boolean {
    return (this.dict.get(AppCfg.N_Lock_HideTrans) ?? AppCfgManager.getDefaultValue(AppCfg.N_Lock_HideTrans)) === 1
  }

  /// 获取　非会员 [锁定]再测一次(仅错误单词) 状态 (0：off，1：lock)
  isNonMember_Lock_RetestMistake(): boolean {
    return (this.dict.get(AppCfg.N_Lock_RetestMistake) ?? AppCfgManager.getDefaultValue(AppCfg.N_Lock_RetestMistake)) === 1
  }

  /// 获取　非会员 [锁定]词根助记 状态 (0：off，1：lock)
  isNonMember_Lock_Cigen(): boolean {
    return (this.dict.get(AppCfg.N_Lock_Cigen) ?? AppCfgManager.getDefaultValue(AppCfg.N_Lock_Cigen)) === 1
  }

  /// 获取　非会员 [锁定]同根词 状态 (0：off，1：lock)
  isNonMember_Lock_SameRoot(): boolean {
    return (this.dict.get(AppCfg.N_Lock_SameRoot) ?? AppCfgManager.getDefaultValue(AppCfg.N_Lock_SameRoot)) === 1
  }

  //MARK: - Cloud Sound functions

  /// 获取　[会员] 是否使用云声音
  isMemberUseCloudSound(): boolean {
    return (this.dict.get(AppCfg.M_MemberUseCloudSound) ?? AppCfgManager.getDefaultValue(AppCfg.M_MemberUseCloudSound)) === 1
  }

  /// 获取　[非会员] 是否使用云声音
  isNonMemberUseCloudSound(): boolean {
    return (this.dict.get(AppCfg.N_NonMemberUseCloudSound) ?? AppCfgManager.getDefaultValue(AppCfg.N_NonMemberUseCloudSound)) === 1
  }

  /// 检查云声音是否可用（根据会员状态返回对应的开关值）
  checkCloudSoundUsable(): boolean {
    return MemberManager.shared.isActive ? this.isMemberUseCloudSound() : this.isNonMemberUseCloudSound()
  }

  // MARK: - Gold Policies (from GoldPolicyManager)

  /// 首次安装赠送金币
  getGold_FirstInstall(): number {
    if (this.isCurLanguageCNT()) {
      return this.dict.get(AppCfg.G_WTT_FirstInstall) ?? AppCfgManager.getDefaultValue(AppCfg.G_WTT_FirstInstall)
    }
    return this.dict.get(AppCfg.G_WTS_FirstInstall) ?? AppCfgManager.getDefaultValue(AppCfg.G_WTS_FirstInstall)
  }

  /// 每日学习赠送金币
  getGold_EveryDayStudy(): number {
    if (this.isCurLanguageCNT()) {
      return this.dict.get(AppCfg.G_WTT_EveryDayStudy) ?? AppCfgManager.getDefaultValue(AppCfg.G_WTT_EveryDayStudy)
    }
    return this.dict.get(AppCfg.G_WTS_EveryDayStudy) ?? AppCfgManager.getDefaultValue(AppCfg.G_WTS_EveryDayStudy)
  }

  /// 每日测试赠送金币
  getGold_EveryDayTest(): number {
    if (this.isCurLanguageCNT()) {
      return this.dict.get(AppCfg.G_WTT_EveryDayTest) ?? AppCfgManager.getDefaultValue(AppCfg.G_WTT_EveryDayTest)
    }
    return this.dict.get(AppCfg.G_WTS_EveryDayTest) ?? AppCfgManager.getDefaultValue(AppCfg.G_WTS_EveryDayTest)
  }

  /// 首次分享应用赠送金币
  getGold_ShareApp(): number {
    if (this.isCurLanguageCNT()) {
      return this.dict.get(AppCfg.G_WTT_ShareApp) ?? AppCfgManager.getDefaultValue(AppCfg.G_WTT_ShareApp)
    }
    return this.dict.get(AppCfg.G_WTS_ShareApp) ?? AppCfgManager.getDefaultValue(AppCfg.G_WTS_ShareApp)
  }

  /// 每次观看激励广告赠送金币
  getGold_WatchAd(): number {
    if (this.isCurLanguageCNT()) {
      return this.dict.get(AppCfg.G_WTT_WatchAd) ?? AppCfgManager.getDefaultValue(AppCfg.G_WTT_WatchAd)
    }
    return this.dict.get(AppCfg.G_WTS_WatchAd) ?? AppCfgManager.getDefaultValue(AppCfg.G_WTS_WatchAd)
  }

  /// 获取所有 G_ 开头的金币策略配置项（用于替代 GoldPolicyManager）
  /// 返回可配置的数组，包含 key, value, name
  getAllGoldPolicies(): GoldPolicyRow[] {
    const ps: AppCfg[] = this.isCurLanguageCNT() ? [
      AppCfg.G_WTT_FirstInstall,
      AppCfg.G_WTT_EveryDayStudy,
      AppCfg.G_WTT_EveryDayTest,
      AppCfg.G_WTT_ShareApp,
    ] : [
      AppCfg.G_WTS_FirstInstall,
      AppCfg.G_WTS_EveryDayStudy,
      AppCfg.G_WTS_EveryDayTest,
      AppCfg.G_WTS_ShareApp,
    ]

    const out: GoldPolicyRow[] = []
    ps.forEach((appCfg: AppCfg) => {
      const key = appCfg
      const value = this.dict.get(key) ?? AppCfgManager.getDefaultValue(appCfg)
      // 仅展示金币数量大于 0 的策略文案。
      if (value <= 0) {
        return
      }
      const name = this.nameDict.get(key) ?? null
      out.push({ key: key, value: value, name: name })
    })
    return out
  }

  /// 根据 AppCfg 获取对应的 name
  getName(appCfg: AppCfg): string | null {
    return this.nameDict.get(appCfg) ?? null
  }

  /// 根据 AppCfg 获取对应的 value
  getValue(appCfg: AppCfg): number {
    return this.dict.get(appCfg) ?? AppCfgManager.getDefaultValue(appCfg)
  }

  // MARK: - 兼容旧鸿蒙调用名（映射到 Android 对齐后的 API）

  /** @deprecated 请改用 `getHomeNoticeIdx_In_Instruction_ForAndroid` */
  getHomeNoticeIdx_In_Instruction(): number {
    return this.getHomeNoticeIdx_In_Instruction_ForAndroid()
  }
}
