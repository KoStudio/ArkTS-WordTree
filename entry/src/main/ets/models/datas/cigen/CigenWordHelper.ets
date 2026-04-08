//
// CigenWordHelper.ets
// WordTree (HarmonyOS)
//
// 对应 iOS `CigenWord.swift` 中 `Word` 扩展：`refWords`、`cigens`、`sameRootDesc`。
// 鸿蒙 `Word` 无法用 associated object，故抽成静态方法，由 UI / Detail 显式 await 调用。
//

import { CigenWord } from './CigenWord'
import { CigenWordDbAccess } from './CigenWordDbAccess'
import { Word } from '../word/Word'
import { SearchManager } from '../model/SearchManager'
import { WordUser } from '../myData/WordUser'

export class CigenWordHelper {

  // 与 iOS `CigenWord.refWords`：同 cid 下词根库中的词 ∩ 当前词书活词（`allLiveWords`）
  static async getRefWords(cigen: CigenWord): Promise<Array<WordUser> | null> {
    const cid = cigen.cid
    if (!cid) {
      return null
    }

    // 不缓存（与 iOS 注释一致：避免语言切换简繁混用）
    const list = await CigenWordDbAccess.shared.getCigenWordsByCid(cid)
    if (!list || list.length === 0) {
      return null
    }

    const titleSet = new Set<string>()
    for (const item of list) {
      const title = item.titleEn
      if (title) {
        titleSet.add(title)
      }
    }

    return SearchManager.shared.getAliveWords().filter(
      word => word.titleEn != null && titleSet.has(word.titleEn)
    )
  }

  // 与 iOS `Word.cigens`：`mnemonic` 与 `desc` 至少一项非空
  static async getCigensByWord(word: Word): Promise<Array<CigenWord> | null> {
    const text = word.titleEn
    if (!text) {
      return null
    }

    const list = await CigenWordDbAccess.shared.getCigenWordsByText(text)
    if (!list) {
      return null
    }

    return list.filter(it => it.mnemonic != null || it.desc != null)
  }

  // 与 iOS `Word.sameRootDesc`
  static async getSameRootDescByWord(word: Word): Promise<string | null> {
    const text = word.titleEn
    if (!text) {
      return null
    }

    return await CigenWordDbAccess.shared.getSameRootStringByText(text)
  }

  // 与 iOS `WordDetail.rootDisplayTextFromCigens`：按详情页 cigens 段顺序拼成一段文案
  static rootDisplayTextFromCigens(cigens: CigenWord[] | null): string {
    // 无双列 desc 与 mnemonic 时无词根段
    if (!cigens || cigens.length < 1) {
      return ''
    }

    const parts: string[] = []

    for (let i = 0; i < cigens.length; i++) {
      const cw  = cigens[i]
      const det = cw.getDetail()
      const mn  = cw.mnemonic ?? ''

      // 有 desc 展示段：mnemonic 可作小标题
      if (det && det.length > 0) {
        parts.push(mn.length > 0 ? `${mn}\n${det}` : det)
      } else if (mn.length > 0) {
        // 仅有助记词时也纳入一段
        parts.push(mn)
      }
    }

    return parts.join('\n\n')
  }
}
