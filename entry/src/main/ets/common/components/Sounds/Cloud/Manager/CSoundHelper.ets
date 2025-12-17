import { CDBSound } from "../CSoundDbAccessor/CDBSound";
import { CSoundManager } from "./CSoundManager";

// 字符串扩展方法
export class CSoundHelper {
  /**
   * 检查声音缓存是否存在
   * @param text 要检查的文本
   * @returns 是否存在缓存
   */
  static async isSoundCacheExists(text: string): Promise<boolean> {
    return await CSoundManager.shared.isCSoundExistsInCache(text)
  }

  /**
   * 启动下载或生成声音
   * @param text 要处理的文本
   * @returns 声音数据或null
   */
  static async startDownloadOrGenerateSound(text: string): Promise<CDBSound | null> {
    return await CSoundManager.shared.getSound(text, true, true);
  }


  ///用于汉字（会下自动按 拼音[如果entry.pinyin1存在]和汉字 同时查找）
  ///判断此text的声音是否存在于： 本地DB or 缓存(pinyin1) or 缓存(汉字)
  // static async isSoundExistsInLocalOrCache_WithPinyinAndText(text: string): Promise<boolean> {
  //   let entry = await EntryHelper.entry(text)
  //
  //   let rtn = false
  //   if (entry) {
  //     // entry 存在
  //     //pinyin1,或text
  //     rtn = (await CSoundManager.shared.isCSoundExistsInCache(entry.pinyin1 || text) || await CSoundManager.shared.isCSoundExistsInCache(text))
  //
  //   }else{
  //     // entry 不存在
  //     rtn = await CSoundManager.shared.isCSoundExistsInCache(text)
  //   }
  //   return rtn
  // }
  //
  // /**
  //  * 启动按拼音下载，或者合成发音
  //  * 若 Entry 不存在，则按汉字合成发音
  //  */
  // static async startDownloadOrGenerateSound_WithPinyinAndText(text: string): Promise<void> {
  //   let entry = await EntryHelper.entry(text)
  //
  //   // entry 存在
  //   if (entry) {
  //     // 如果拼音存在
  //     if (entry.pinyin1) {
  //       // 用拼音 启动下载 或 合成
  //       await CSoundManager.shared.getSound(entry.pinyin1, true, true)
  //     } else {
  //       // 拼音不存在时，直接用汉字生成
  //       //CSoundManager.shared.startGenerateSound(language, text)
  //       await  CSoundManager.shared.getSound(text, true, true)
  //     }
  //   } else {
  //     // entry 不存在
  //     // 拼音不存在时，直接用汉字生成
  //     //CSoundManager.shared.startGenerateSound(language, text)
  //     await CSoundManager.shared.getSound(text, true, true)
  //   }
  // }
}
