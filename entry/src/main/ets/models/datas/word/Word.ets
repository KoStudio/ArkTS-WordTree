import { Constants } from "../../../app/constants/Constants";
import { AppUtility } from "../../../common/utils/AppUtility";
import { StringEncoder } from "../../../common/utils/strings/StringEncrypt";
import { EWordEditableField } from "../../managers/eword/EWordEditManager";
import { SearchManager } from "../model/SearchManager";
import { WordDetail } from "./WordDetail";

export class Word {
  idx             : number | null = null;
  partId          : number | null = null;
  partName        : string | null = null;

  unitId          : number | null = null;
  unitNo          : number | null = null;
  unitName        : string | null = null;

  titleEn         : string | null = null;
  titleCn1        : string | null = null;
  titleCn2        : string | null = null;
  titleCn3        : string | null = null;

  pronEn          : string | null = null;
  pronUs          : string | null = null;
  exampleEn1      : string | null = null;
  exampleCn1      : string | null = null;

  private wordDetail: WordDetail | null = null

  // async getWordDetail(): Promise<WordDetail | null> {
  //   if (!this.wordDetail) {
  //     this.wordDetail = await SearchManager.shared.getWordDbAccess()?.getWordDetailByTitleEn(this.titleEn) ?? null
  //   }
  //   return this.wordDetail
  // }

  async getWordDetail(): Promise<WordDetail | null> {
    // 已缓存详情对象则直接返回，避免重复查库
    if (this.wordDetail) {
      return this.wordDetail
    }

    // 从当前课本 textDb 的 Word 表按 titleEn 查询详情
    this.wordDetail = await SearchManager.shared.getWordDbAccess()?.getWordDetailByTitleEn(this.titleEn) ?? null

    // 主词库中不存在时再查 learnDb 的 WordOnlineTemp
    if (this.wordDetail === null){

      // 动态 import，减轻模块启动依赖
      let it = await import('../myData/WordUserDbAccess')

      // 读取在线临时表中的完整词条
      this.wordDetail = await it.WordUserDbAccess.shared.getOnlineWordDetailByTitleEn(this.titleEn) ?? null
    }

    // 已得到详情且能确定 titleEn 时，合并 EWordOverride 展示覆盖
    if (this.wordDetail !== null && this.titleEn) {

      // 动态 import EWordManager，避免 Word ↔ WordUserDbAccess 循环引用
      const ewm = await import('../../managers/eword/EWordManager')

      // 加载该词在 learnDb 中的 [fieldKey: value]
      const ov = await ewm.EWordManager.shared.loadOverrides(this.titleEn);

      // 将覆盖应用到 WordDetail（含 root、cognates 等扩展字段）
      this.wordDetail.applyEWordOverrideMap(ov);
    }

    return this.wordDetail
  }

  /**
   * 列表层合并 EWord 覆盖（与 iOS `Word.applyEWordOverrideMap(forWord:)` 一致，目前仅 titleCn1）。
   */
  applyEWordOverrideMap(map: Record<string, string>): void {
    const k = EWordEditableField.titleCn1 as string;

    // 与 iOS 列表层一致：仅当存在 item9 覆盖时才替换释义 1
    if (map[k] !== undefined && map[k] !== null) {
      this.titleCn1 = map[k];
    }
  }

  get titleEnEncodeToBase64(): string | null {
    return StringEncoder.encodedToBase64(this.titleEn)
  }

  get titleEnEncodeAndAddSalt(): string | null {
    return StringEncoder.encodeAndAddSalt(this.titleEn)
  }

  get wordEnSoundText(): string {
    return `${this.titleEn}_ti_u`
  }

  get titleCn1Clipped(): string {
    return AppUtility.getClippedStringWithoutKindFrom(this.titleCn1 || '')
  }

  get titleCn1ClippedShort(): string {
    return AppUtility.getClippedStringSeperatedFirstPartFrom(this.titleCn1 || '')
  }

  get titleCn1Kind(): string {
    return AppUtility.getKindOfString(this.titleCn1 || '')
  }

  /**
   * 将多个中文释义合并为一个字符串（去重）
   */
  getTitleCnsJoined(): string {
    const titles: string[] = [];

    if (this.titleCn1) {
      titles.push(this.titleCn1);
    }
    if (this.titleCn2) {
      titles.push(this.titleCn2);
    }
    if (this.titleCn3) {
      titles.push(this.titleCn3);
    }

    return AppUtility.getJoinedStringByRemovingDuplications(
      titles,
      Constants.TitleTextJp.wordsMaxPart
    );
  }
}