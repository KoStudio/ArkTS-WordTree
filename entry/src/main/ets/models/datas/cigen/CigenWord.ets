//
// CigenWord.ets
// WordTree (HarmonyOS)
//
// 与 iOS `CigenManager/CigenWord.swift` 数据字段一致；`getVName` 对应 `vname`；
// `getDetail` 为鸿蒙展示用（iOS 侧多在 UI 层拼文案）。
//

import { getString } from '../../../common/utils/ResourceUtils'

@ObservedV2
export class CigenWord {
  @Trace idx: number | null = null
  @Trace cid: number | null = null
  @Trace vid: number | null = null
  @Trace titleEn: string | null = null
  @Trace mnemonic: string | null = null
  @Trace desc: string | null = null

  // 与 iOS `CigenWord.vname`（vid → 本地化词缀类型名）一致
  getVName(): string | null {
    switch (this.vid) {
      // 1 常用前缀一  2 常用前缀二  3 常用词根  4 后缀一  5 后缀二  6 词缀
      case 1: return getString($r('app.string.cigen_vname_1'))
      case 2: return getString($r('app.string.cigen_vname_2'))
      case 3: return getString($r('app.string.cigen_vname_3'))
      case 4: return getString($r('app.string.cigen_vname_4'))
      case 5: return getString($r('app.string.cigen_vname_5'))
      case 6: return getString($r('app.string.cigen_vname_6'))
      default: return null
    }
  }

  // 详情展示：可选词缀名 + desc（与 iOS 详情里「〈词缀类型〉描述」展示语义一致）
  public getDetail(): string | null {
    let detail: string | null = null
    const desc = this.desc
    if (desc) {
      const vname = this.getVName()
      if (vname) {
        detail = '    〈' + vname + '〉' + desc
      } else {
        detail = '    ' + desc
      }
    }
    return detail
  }
}
