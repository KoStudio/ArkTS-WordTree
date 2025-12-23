import preferences from '@ohos.data.preferences'
import { getAppContext } from '../../../app/constants/AppContext'
import { dMemberFlag } from '../../../app/constants/AppDefines'
import { getString } from '../../../common/utils/ResourceUtils'
import { MemberManager } from '../member/MemberManager'

// ============================================================
// MARK: - DetailItem 偏好设置常量
export class DetailItemPref {
  static readonly Name      = "DetailItemSort_Setting001"
  static readonly kOrder    = "DetailItem_Key_Order"
  static readonly kVisiable = "DetailItem_Key_Visable"
}

// ============================================================
// MARK: - 详情项枚举
export enum DetailItem {
  // Word            = "Word",            // 单词
  WordChange      = "WordChange",      // 单词变形
  Cigens          = "Cigens",          // 词根助记
  SameRootDesc    = "SameRootDesc",    // 同根词
  Examples        = "Examples",        // 例句
  SynWords        = "SynWords",        // 同义词
  AsynWords       = "AsynWords",       // 反义词
  UsedPhrase      = "UsedPhrase",      // 常用短语
  En2En           = "En2En",           // 英英释义
  Discriminate    = "Discriminate"     // 详细说明
  // Jiucuo          // 纠错
  // Memos           // Memos
}

// ============================================================
// MARK: - 详情项排序结构
export class ItemOrder {
  item      : DetailItem
  order     : number
  isVisible : boolean

  constructor(item: DetailItem,
    order: number,
    isVisible: boolean) {
    this.item      = item
    this.order     = order
    this.isVisible = isVisible
  }

  equals(other: ItemOrder): boolean {
    return this.item === other.item
  }
}

// ============================================================
// MARK: - 通知常量
export namespace DetailItemNotification {
  export enum Name {
    ItemVisibleOrderChanged = "Detail_Item_Visible_Order_Changed"
  }
}

// ============================================================
// MARK: - DetailItemManager
export class DetailItemManager {

  private static instance: DetailItemManager
  private context   : Context | null = null
  private itemOrders: ItemOrder[]    = []

  // MARK: - 单例
  static get shared(): DetailItemManager {
    if (!this.instance) {
      this.instance = new DetailItemManager()
      this.instance.init()
    }
    return this.instance
  }

  // MARK: - 构造
  private constructor() {
    this.context = getAppContext()
  }

  // MARK: - 初始化
  init(): void {
    this.loadPreference()
  }

  // MARK: - 保存偏好（同步）
  private savePreference(): void {
    if (!this.context) return

    try {
      const pref = preferences.getPreferencesSync(
        this.context,
        { name: DetailItemPref.Name }
      )

      this.itemOrders.forEach(itemOrder => {
        pref.putSync(
          itemOrder.item,
          itemOrder.order.toString() + "_" + itemOrder.isVisible.toString()
        ) // {item : order_visiable} 如: {WordChange : 0_true}
      })

      pref.flushSync()
    } catch (err) {
      console.error(`保存偏好设置失败: ${JSON.stringify(err)}`)
    }
  }

  // MARK: - 加载偏好
  private loadPreference(): void {

    this.itemOrders = []

    this.itemOrders.push(this.createItemOrder(DetailItem.WordChange   , 1, true))
    this.itemOrders.push(this.createItemOrder(DetailItem.Cigens       , 2, true))
    this.itemOrders.push(this.createItemOrder(DetailItem.SameRootDesc , 3, true))
    this.itemOrders.push(this.createItemOrder(DetailItem.Examples     , 4, true))
    this.itemOrders.push(this.createItemOrder(DetailItem.SynWords     , 5, true))
    this.itemOrders.push(this.createItemOrder(DetailItem.AsynWords    , 6, true))
    this.itemOrders.push(this.createItemOrder(DetailItem.UsedPhrase   , 7, true))
    this.itemOrders.push(this.createItemOrder(DetailItem.En2En        , 8, true))
    this.itemOrders.push(this.createItemOrder(DetailItem.Discriminate , 9, true))
  }

  /// 获取一个排好序的副本
  getItemOrders(): ItemOrder[] {

    return this.itemOrders.map(it => {

      // 词根助记不可用
      if (it.item === DetailItem.Cigens &&
        !MemberManager.shared.checkCigenUsable(false)) {

        return new ItemOrder(it.item, it.order, false) // 只改变副本的 isVisible

      } else if (it.item === DetailItem.SameRootDesc &&
        !MemberManager.shared.checkSameRootUsable(false)) {

        // 同根词
        return new ItemOrder(it.item, it.order, false)

      } else {
        return it
      }

    }).sort((a, b) => a.order - b.order)
  }

  // MARK: - 交换顺序
  exchangeOrder(srcItem: DetailItem,
    tgtItem: DetailItem): void {

    const srcOrder = this.itemOrders.find(o => o.item === srcItem)
    const tgtOrder = this.itemOrders.find(o => o.item === tgtItem)
    if (!srcOrder || !tgtOrder) return

    const tmp      = srcOrder.order
    srcOrder.order = tgtOrder.order
    tgtOrder.order = tmp

    // 保存
    this.savePreference()
  }

  // MARK: - 修改可见性
  changeVisible(item: DetailItem,
    toVisible: boolean): void {

    const order = this.itemOrders.find(o => o.item === item)
    if (!order) return

    order.isVisible = toVisible

    // 保存
    this.savePreference()
  }

  // MARK: - 创建 ItemOrder
  private createItemOrder(item: DetailItem,
    order: number,
    visible: boolean): ItemOrder {

    if (!this.context) {
      return new ItemOrder(item, order, visible)
    }

    try {
      const pref  = preferences.getPreferencesSync(
        this.context,
        { name: DetailItemPref.Name }
      )

      const value = pref.getSync(
        item,
        order.toString() + "_" + visible.toString()
      ) as string

      const parts = value.split("_")
      let o       = order
      let v       = visible

      if (parts.length === 2) {
        o = parseInt(parts[0])
        v = parts[1] === 'true'
      }

      return new ItemOrder(item, o, v)

    } catch (err) {
      return new ItemOrder(item, order, visible)
    }
  }

  // MARK: - 本地化名称
  getLocalizedName(item: DetailItem): ResourceStr {
    switch (item) {

      // case Word
      case DetailItem.WordChange :
        return getString($r("app.string.learn_detail_txt_wordchang"))                      // 单词变形

      case DetailItem.Cigens :
        return getString($r("app.string.learn_detail_txt_mnemonic"))
          + (MemberManager.shared.nonMember.isLockedCigen ? dMemberFlag : "") // 词根助记

      case DetailItem.SameRootDesc :
        return getString($r("app.string.learn_detail_txt_samerootdesc"))
          + (MemberManager.shared.nonMember.isLockedSameRoot ? dMemberFlag : "") // 同根词

      case DetailItem.Examples :
        return getString($r("app.string.learn_detail_txt_example"))                        // 例句

      case DetailItem.SynWords :
        return getString($r("app.string.learn_detail_txt_synwords"))                       // 同义词

      case DetailItem.AsynWords :
        return getString($r("app.string.learn_detail_txt_asynwords"))                      // 反义词

      case DetailItem.UsedPhrase :
        return getString($r("app.string.learn_detail_txt_usedphrase"))                     // 常用短语

      case DetailItem.En2En :
        return getString($r("app.string.learn_detail_txt_en2en"))                          // 英英释义

      case DetailItem.Discriminate :
        return getString($r("app.string.learn_detail_txt_discriminate"))                   // 详细说明

      default : return ''
    }
  }
}