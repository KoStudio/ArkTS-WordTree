import { Constants } from "../../../app/constants/Constants";
import { AppUtility } from "../../../common/utils/AppUtility";
import { StringEncoder } from "../../../common/utils/strings/StringEncrypt";
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
    if (this.wordDetail) {
      return this.wordDetail
    }

    //查询  本地DB
    this.wordDetail = await SearchManager.shared.getWordDbAccess()?.getWordDetailByTitleEn(this.titleEn) ?? null

    ///再次查询OnlineWord
    if (this.wordDetail === null){
      let it = await import('../myData/WordUserDbAccess')
      this.wordDetail = await it.WordUserDbAccess.shared.getOnlineWordDetailByTitleEn(this.titleEn) ?? null
    }

    return this.wordDetail
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