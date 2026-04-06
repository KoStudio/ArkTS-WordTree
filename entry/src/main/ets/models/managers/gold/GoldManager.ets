//
//  GoldManager.ets
//  WordTree (HarmonyOS)
//
//  与 Android com.ou.wordtree.managers.gold.GoldManager / iOS GoldManager.swift 对齐：
//  Common_Pref、GoldCountKey（Base64 存字符串）、AppCfg 的 G_ 策略。
//  Preference 键名与 Android GoldManager.Constants 一致，鸿蒙侧为 GoldManagerConstants（避免 namespace 合并）。
//

import preferences from '@ohos.data.preferences'
import { getAppContext } from '../../../app/constants/AppContext'
import { DebugFlg } from '../../../app/debug/DebugFlg'
import { LanguageManager } from '../../../common/components/Language/LanguageManager'
import { StringEncoder } from '../../../common/utils/strings/StringEncrypt'
import { DateUtils } from '../../../common/utils/DateUtils'
import { getStringF } from '../../../common/utils/ResourceUtils'
import { Toast } from '../../../common/utils/Toast'
import { AppCfg, AppCfgManager } from '../servercfg/AppCfgManager'

// 发放完成: (当前总金币, 本次新增金币)
export type ProvideGoldFinished = (allCount: number, newCount: number) => void

// 与 Android GoldManager.object Constants 各字段名、取值一致
export class GoldManagerConstants {
  static readonly GoldCountKey: string                       = 'GoldCountKey'
  static readonly GoldProvideLastDateForFirstInstall: string = 'Gold_Provide_LastDate_ForFirstInstall'
  static readonly GoldProvideLastDateForStudy: string        = 'Gold_Provide_LastDate_ForStudy'
  static readonly GoldProvideLastDateForTest: string         = 'Gold_Provide_LastDate_ForTest'
  static readonly GoldProvideLastDateForShareApp: string     = 'Gold_Provide_LastDate_ForShareApp'
}

export class GoldManager {
  private static instance: GoldManager | null = null

  private static readonly LEGACY_PREF_NAME: string = 'Common_Pref'

  private goldsCountInternal: number = 0

  // 单例
  static get shared(): GoldManager {
    // 尚未创建则 new
    if (!GoldManager.instance) {
      GoldManager.instance = new GoldManager()
    }

    return GoldManager.instance
  }

  private constructor() {
    // 从本地 Preferences 恢复 goldsCountInternal
    this.loadGolds()
  }

  // 用户当前金币数（只读）
  get golds(): number {
    return this.goldsCountInternal
  }

  // 从 Common_Pref 读 String；无键或空串返回 null
  private legacyGetString(key: string): string | null {
    try {
      // 与 Android getPref(Common_Pref) 一致
      const pref = preferences.getPreferencesSync(getAppContext(), { name: GoldManager.LEGACY_PREF_NAME })

      // 从未写入过该 key
      if (!pref.hasSync(key)) {
        return null
      }

      const s = pref.getSync(key, '') as string

      // 空串当作无值，与「未发放」语义一致
      if (s.length === 0) {
        return null
      }

      return s
    } catch (_e) {
      // 读失败则当作无缓存
      return null
    }
  }

  // 写入 Common_Pref 并落盘；key：偏好键名，value：待存字符串
  private legacySaveString(key: string, value: string): void {
    try {
      // 与 Android getPref(Common_Pref).edit 一致
      const pref = preferences.getPreferencesSync(getAppContext(), { name: GoldManager.LEGACY_PREF_NAME })

      pref.putSync(key, value)

      // 确保持久化
      pref.flushSync()
    } catch (e) {
      console.error(`GoldManager.legacySaveString failed: ${(e as Error).message}`)
    }
  }

  // 将当前金币数以 Base64 编码写入 GoldCountKey（对齐 EncodeUtility.encodeString）
  private saveGolds(): void {
    const encoded = StringEncoder.encodedToBase64(String(this.goldsCountInternal))

    // 编码失败则跳过写入，避免覆盖为坏数据
    if (encoded) {
      this.legacySaveString(GoldManagerConstants.GoldCountKey, encoded)
    }
  }

  // 从 GoldCountKey 解码恢复金币；失败则为 0
  private loadGolds(): void {
    const encoded = this.legacyGetString(GoldManagerConstants.GoldCountKey)

    const decoded = StringEncoder.decodedFromBase64(encoded)

    let n = 0

    // 有解码结果再解析整数
    if (decoded !== null && decoded !== undefined) {
      const p = Number.parseInt(decoded, 10)

      // 解析成功才采用有效值
      if (!Number.isNaN(p)) {
        n = p
      }
    }

    this.goldsCountInternal = n

    // Debug 下可在此临时覆盖金币（与 Android 注释块对齐）
    if (DebugFlg.isDebugMode()) {
      // golds = 10000
    }
  }

  // MARK: - Policy text helpers

  // 拉取所有 G_ 策略展示用文案（name 列表）；finished：回传与配置行顺序一致的文案数组
  loadPolicyTexts(finished: (texts: Array<string | null>) => void): void {
    const goldPolicies = AppCfgManager.shared.getAllGoldPolicies()

    const texts: Array<string | null> = goldPolicies.map((row) => row.name ?? '')

    finished(texts)
  }

  // 单个 G_ 策略的 name；goldAppCfg：须为 G_ 前缀的 AppCfg；finished：回传 name 或 null
  loadPolicyTextWith(goldAppCfg: AppCfg, finished: (text: string | null) => void): void {
    // 非 G_ 配置不支持
    if (!goldAppCfg.startsWith('G_')) {
      finished(null)

      return
    }

    finished(AppCfgManager.shared.getName(goldAppCfg))
  }

  // 单个 G_ 策略的 name 与数值；goldAppCfg：须为 G_ 前缀；finished：name、value（非法时 null 与 0）
  loadPolicyTextAndGoldsWith(goldAppCfg: AppCfg, finished: (text: string | null, golds: number) => void): void {
    // 非 G_ 配置不支持
    if (!goldAppCfg.startsWith('G_')) {
      finished(null, 0)

      return
    }

    finished(AppCfgManager.shared.getName(goldAppCfg), AppCfgManager.shared.getValue(goldAppCfg))
  }

  // MARK: - Core operations

  // 增加金币并持久化；amount：可为负表示扣减
  incrementGolds(amount: number): void {
    this.goldsCountInternal += amount

    this.saveGolds()
  }

  // MARK: - First install & share app

  // 首次安装奖励；finishBlock：发放成功时回调 (总金币, 本次发放)
  provideGoldsForFirstInstallIfNeeds(finishBlock: ProvideGoldFinished | null): void {
    const gotGolds = AppCfgManager.shared.getGold_FirstInstall()

    // 服务端/本地策略为 0 或负数时不赠送
    if (gotGolds <= 0) {
      return
    }

    const lastDateStr = this.legacyGetString(GoldManagerConstants.GoldProvideLastDateForFirstInstall)

    const needProvide = lastDateStr === null

    // 仅当从未记录过首次安装发放日才发
    if (needProvide) {
      this.legacySaveString(GoldManagerConstants.GoldProvideLastDateForFirstInstall,
        DateUtils.toDateTimeString(new Date()))

      this.incrementGolds(gotGolds)

      finishBlock?.(this.goldsCountInternal, gotGolds)

      Toast.showMessage(getStringF($r('app.string.gain_gold_for_install'), gotGolds))
    }
  }

  // 首次分享应用奖励；finishBlock：发放成功时回调 (总金币, 本次发放)
  provideGoldsForFirstShareAppIfNeeds(finishBlock: ProvideGoldFinished | null): void {
    const gotGolds = AppCfgManager.shared.getGold_ShareApp()

    const lastDateStr = this.legacyGetString(GoldManagerConstants.GoldProvideLastDateForShareApp)

    const needProvide = lastDateStr === null

    // 仅当从未发过分享首奖才发
    if (needProvide) {
      this.legacySaveString(GoldManagerConstants.GoldProvideLastDateForShareApp,
        DateUtils.toDateTimeString(new Date()))

      this.incrementGolds(gotGolds)

      finishBlock?.(this.goldsCountInternal, gotGolds)

      Toast.showMessage(getStringF($r('app.string.set_txt_got_gold'), gotGolds, this.goldsCountInternal))
    }
  }

  // 最近一次分享首奖日期字符串；未领过则 null
  getGoldProvideLastDateForShareApp(): string | null {
    return this.legacyGetString(GoldManagerConstants.GoldProvideLastDateForShareApp)
  }

  // MARK: - Rewarded video ad

  // 激励视频奖励；finishBlock：回调 (总金币, 本次奖励)
  provideGoldsForRewardedVideoAdWithBlock(finishBlock: ProvideGoldFinished | null): void {
    const rewardGolds = AppCfgManager.shared.getGold_WatchAd()

    this.incrementGolds(rewardGolds)

    finishBlock?.(this.goldsCountInternal, rewardGolds)

    Toast.showMessage(getStringF($r('app.string.set_txt_got_gold'), rewardGolds, this.goldsCountInternal))
  }

  // MARK: - Every day study & test

  // 每日学习一次奖励（按繁简选 G_WTT / G_WTS）；finishBlock：发放成功时回调
  provideGoldsForEveryDayStudyIfNeedsWithBlock(finishBlock: ProvideGoldFinished | null): void {
    const appCfg = LanguageManager.isTraditionalChinese() ? AppCfg.G_WTT_EveryDayStudy : AppCfg.G_WTS_EveryDayStudy

    this.provideGoldsForAppCfg(appCfg, GoldManagerConstants.GoldProvideLastDateForStudy, finishBlock)
  }

  // 每日测试一次奖励；finishBlock：发放成功时回调
  provideGoldsForEveryDayTestIfNeedsWithBlock(finishBlock: ProvideGoldFinished | null): void {
    const appCfg = LanguageManager.isTraditionalChinese() ? AppCfg.G_WTT_EveryDayTest : AppCfg.G_WTS_EveryDayTest

    this.provideGoldsForAppCfg(appCfg, GoldManagerConstants.GoldProvideLastDateForTest, finishBlock)
  }

  // MARK: - Common provider

  // 按 AppCfg 与日键发放每日类金币；appCfg：须 G_ 前缀；key：上次发放日偏好键；finishBlock：成功时回调
  private provideGoldsForAppCfg(appCfg: AppCfg, key: string, finishBlock: ProvideGoldFinished | null): void {
    // 非金币策略 AppCfg 直接忽略
    if (!appCfg.startsWith('G_')) {
      return
    }

    const gotGolds = AppCfgManager.shared.getValue(appCfg)

    let needProvide = false

    const dateNow = new Date()

    const lastDateStr = this.legacyGetString(key)

    // 已有上次时间：与「昨天同一时刻」比较，早于则可再次领取
    if (lastDateStr !== null && lastDateStr.length > 0) {
      const lastTime = GoldManager.dateFromStoredString(lastDateStr)

      const threshold = DateUtils.addDays(dateNow, -1)

      // 无合法解析或已跨周期
      if (lastTime === null || lastTime.getTime() < threshold.getTime()) {
        needProvide = true
      }
    } else {
      // 从未记录，可领
      needProvide = true
    }

    // 写入今日、加金币、提示
    if (needProvide) {
      this.legacySaveString(key, DateUtils.toDateTimeString(dateNow))

      this.incrementGolds(gotGolds)

      finishBlock?.(this.goldsCountInternal, gotGolds)

      Toast.showMessage(getStringF($r('app.string.set_txt_got_gold'), gotGolds, this.goldsCountInternal))
    }
  }

  // 将 Preferences 中存的时间串解析为 Date；格式与 DateUtils.toDateTimeString 输出一致（可补 .000）
  private static dateFromStoredString(str: string): Date | null {
    const withMs = str.includes('.') ? str : `${str}.000`

    return DateUtils.toDate(withMs, 'YYYY-MM-DD HH:mm:ss.SSS')
  }
}
