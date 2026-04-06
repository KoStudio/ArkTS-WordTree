//
// MarqueeManager.ets
// WordTree (HarmonyOS)
//
// 与 iOS `MarqueeManager.swift`、Android `MarqueeManager.kt` 对齐：首页滚动公告、会员限显、内链解析、分享后激励。
//

import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { getStringF } from '../../../common/utils/ResourceUtils'
import { Toast } from '../../../common/utils/Toast'
import { ShareUtils } from '../../../common/utils/ShareUtils'
import { LinkViewConfig } from '../../../app/views/LinkView'
import { AppCfgManager } from '../servercfg/AppCfgManager'
import { Instruction } from '../instruction/Instruction'
import { InstructionManager } from '../instruction/InstructionManager'
import { MemberManager } from '../member/MemberManager'
import { EncourageManager, EncourageType, EncourageTypeHelper } from '../member/EncourageManager'
import { GoldManager } from '../gold/GoldManager'
import { LinkData, LinkLimit, LinkType, linkLimitFromValue, linkTypeFromValue } from './LinkData'
import { InstructionsViewConfig } from '../../../views/setting/instruction/InstructionsView'

export class MarqueeManager {

  // 公告数据刷新后通知 UI（SubLearnView 等订阅）

  static readonly NOTICE_UPDATED: string = 'marquee_notice_updated'

  private static instance: MarqueeManager | null = null

  // 单例
  static get shared(): MarqueeManager {

    // 尚未创建则 new
    if (!MarqueeManager.instance) {
      MarqueeManager.instance = new MarqueeManager()
    }

    return MarqueeManager.instance
  }

  // 禁止外部构造，统一走 shared
  private constructor() {
  }

  // 公告标题（Instruction.title）
  title                   : string | null = null
  // 公告链接（url 或 OpenLink JSON，见 LinkData）
  link                    : string | null = null
  // 用户点击关闭后本进程内不再展示
  closedByUser            : boolean       = false
  // 非会员从公告发起分享后置位，回前台时兑现激励
  needEncourageForShareApp: boolean       = false

  // 通知订阅方刷新跑马灯 UI
  private emitUpdated(): void {

    // 广播配置或文案变更
    SimpleEventBus.emit(MarqueeManager.NOTICE_UPDATED)
  }

  // 当前是否应显示顶部横幅（与 shouldShowBanner 语义一致，供 UI 绑定）
  shouldShowBanner(): boolean {

    // ServerCfg 关闭首页公告 idx
    if (AppCfgManager.shared.getHomeNoticeIdx_In_Instruction_ForAndroid() <= 0) {
      return false
    }

    // 用户曾点关闭
    if (this.closedByUser) {
      return false
    }

    const t = this.title
    const l = this.link

    // 标题与链接均需非空
    return t != null && t.length > 0 && l != null && l.length > 0
  }

  // 按 AppCfg 开关拉取 Instruction，更新 title/link 并广播（无参数）
  loadNoticeIfNeeds(): void {

    const idx = AppCfgManager.shared.getHomeNoticeIdx_In_Instruction_ForAndroid()

    // idx>0：向服务端拉取单条 Instruction
    if (idx > 0) {

      // 按主键查询公告 Instruction
      InstructionManager.loadInstruction(idx, (succeed: boolean, _msg: string | null, instruction: Instruction | null) => {

        this.title = instruction?.title ?? null
        this.link = instruction?.link ?? null

        // 从 link JSON 解析会员限显
        const limit = linkLimitFromValue(LinkData.linkData(this.link)?.limit)

        // 限会员可见且当前非会员
        if (limit === LinkLimit.Member) {

          // 非会员不展示
          if (!MemberManager.shared.isActive) {
            this.title = null
            this.link = null
          }
        } else if (limit === LinkLimit.Nonmember) {

          // 限非会员可见且当前已是会员
          if (MemberManager.shared.isActive) {
            this.title = null
            this.link = null
          }
        }

        // 异步返回时若配置已把 idx 改为 0，则不再展示（与 iOS/Android 注释一致）
        if (AppCfgManager.shared.getHomeNoticeIdx_In_Instruction_ForAndroid() === 0) {
          this.title = null
          this.link = null
        }

        // 通知学习页刷新横幅
        this.emitUpdated()
      })
    } else {

      // idx 为 0：清空并隐藏
      this.title = null
      this.link = null

      // 通知学习页移除横幅
      this.emitUpdated()
    }
  }

  // 用户点击公告；link：服务端下发的地址或 OpenLink JSON 字符串
  openLink(link: string): void {

    // 直接外链浏览器页
    if (link.startsWith('http://') || link.startsWith('https://')) {

      // 应用内 Web 页打开
      LinkViewConfig.open({ title: this.title ?? '', url: link })
      return
    }

    // 解析 OpenLink JSON
    const linkData = LinkData.linkData(link)

    // 非 JSON 或解析失败
    if (linkData === null) {

      // 调试提示
      Toast.showDebugMessage('open link not found.')
      return
    }

    const linkType = linkTypeFromValue(linkData.type)

    // 打开使用说明列表
    if (linkType === LinkType.Instruction) {

      // 导航到 InstructionsView
      InstructionsViewConfig.open()
      return
    }

    // 系统分享应用
    if (linkType === LinkType.ShareApp) {

      // 与单例方法一致，并记录激励标记
      MarqueeManager.shared.shareApp()
      return
    }

    // 打开会员购买 Sheet
    if (linkType === LinkType.MemberBuy) {

      // 首页 Index 订阅此事件
      SimpleEventBus.emit(MemberManager.NOTIFY_OPEN_MEMBER_SHEET)
      return
    }

    const sublink = linkData.type

    // type 字段本身是 http(s) 子链（带 limit 等扩展时的写法）
    if (sublink !== null &&
      (sublink.startsWith('http://') || sublink.startsWith('https://'))) {

      // 以内链 Web 打开子 url
      LinkViewConfig.open({ title: this.title ?? '', url: sublink })
      return
    }

    // 不识别的 type
    Toast.showDebugMessage(`open link type error:${sublink ?? ''}`)
  }

  // 发起分享应用（非会员会置 needEncourageForShareApp）
  shareApp(): void {

    // 调系统分享面板
    ShareUtils.shareThisAppWithLoadedLink()

    // 仅非会员需要发音/金币激励流程
    if (!MemberManager.shared.isActive) {
      this.needEncourageForShareApp = true
    }
  }

  // 从分享或其它页面回到前台时调用；对齐 Android StudyFragment.onStart / EntryAbility.onForeground
  sharedAppDoEncourageIfNeeds(): void {

    // 未从公告分享入口触发
    if (!this.needEncourageForShareApp) {
      return
    }

    this.needEncourageForShareApp = false

    // 会员无此激励
    if (MemberManager.shared.isActive) {
      return
    }

    // 已记过分享金币日期：走每日一次发音奖励；否则尝试首分享金币
    if (GoldManager.shared.getGoldProvideLastDateForShareApp() != null) {

      // 当日池顶次数
      const reward = EncourageTypeHelper.getRewardCount(EncourageType.wordPronShareApp)

      // 每日仅限成功一次
      if (EncourageManager.shared.encourage(EncourageType.wordPronShareApp, reward, true)) {

        const total = MemberManager.shared.remainWordPronCount()

        // 提示获赠次数
        Toast.showMessage(getStringF($r('app.string.set_msg_share_done'), reward, total), true)

        // 打乱下一轮奖励池
        EncourageManager.shared.resetRewards(EncourageType.wordPronShareApp)
      }
    } else {

      // 首次分享可能触发金币发放
      GoldManager.shared.provideGoldsForFirstShareAppIfNeeds(null)
    }
  }
}
