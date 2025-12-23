// CigenWordHelper.ts
import { CigenWord } from './CigenWord';
import { CigenWordDbAccess } from './CigenWordDbAccess';
import { Word } from '../word/Word';
import { SearchManager } from '../model/SearchManager';
import { WordUser } from '../myData/WordUser';

export class CigenWordHelper {

  // ============================================================
  // 同 CID 的所有单词（wordsOfSameCigen / wordsOfSameCid）
  // ============================================================
  static async getRefWords(cigen: CigenWord): Promise<Array<WordUser> | null> {
    const cid = cigen.cid;
    if (!cid) return null;

    // 不做缓存，保持与你原 Kotlin 逻辑一致
    const list = await CigenWordDbAccess.shared.getCigenWordsByCid(cid);
    if (!list || list.length === 0) return null;

    const titleSet = new Set<string>();

    for (const item of list) {
      const title = item.titleEn;
      if (title) {
        titleSet.add(title);
      }
    }

    return SearchManager.shared.getAliveWords().filter(
      word => word.titleEn != null && titleSet.has(word.titleEn)
    );
  }

  // ============================================================
  // Word -> 词根列表
  // ============================================================
  static async getCigensByWord(word: Word): Promise<Array<CigenWord> | null> {
    const text = word.titleEn;
    if (!text) return null;

    // 暂不缓存，防止语言切换导致简繁混用（对齐原实现）
    const list = await CigenWordDbAccess.shared.getCigenWordsByText(text);
    if (!list) return null;

    return list.filter(it => it.mnemonic != null || it.desc != null);
  }

  // ============================================================
  // Word -> 同根描述
  // ============================================================
  static async getSameRootDescByWord(word: Word): Promise<string | null> {
    const text = word.titleEn;
    if (!text) return null;

    return await CigenWordDbAccess.shared.getSameRootStringByText(text);
  }

}