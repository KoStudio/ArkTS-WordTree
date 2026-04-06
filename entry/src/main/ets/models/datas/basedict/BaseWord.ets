import { BaseWordConstants } from "./utils/BaseWordConstants";
import { BaseWordUtility, TitleItem } from "./utils/BaseWordUtility";

@ObservedV2
export class BaseWord {
  @Trace idx        : number | null = null;
  @Trace titleEn    : string | null = null;
  @Trace pronEn     : string | null = null;
  @Trace pronUs     : string | null = null;
  @Trace titleCn1   : string | null = null;
  @Trace titleCn2   : string | null = null;
  @Trace titleCn3   : string | null = null;


  // 与 iOS `String.titleEn_ti_u()`（云读音 key）一致
  get wordEnSoundText(): string {
    return `${this.titleEn ?? ''}_ti_u`
  }

  // 与 iOS `BaseWord.titleCnsJoined` 一致：titleCn1 为 nil 时按空串占位，再拼接 cn2/cn3
  getTitleCnsJoined(): string {
    const titles: string[] = [this.titleCn1 ?? '']

    if (this.titleCn2) {
      titles.push(this.titleCn2)
    }
    if (this.titleCn3) {
      titles.push(this.titleCn3)
    }

    return BaseWordUtility.getJoinedStringByRemovingDuplications(
      titles,
      BaseWordConstants.TitleTextJp.wordsMaxPartLong
    )
  }

  // 与 iOS `BaseWord.titleItems` 一致
  getTitleItems(): Array<TitleItem> {
    const titles: string[] = [this.titleCn1 ?? '']

    if (this.titleCn2) {
      titles.push(this.titleCn2)
    }
    if (this.titleCn3) {
      titles.push(this.titleCn3)
    }

    return BaseWordUtility.getJoinedTitleItemsByRemovingDuplications(
      titles,
      BaseWordConstants.TitleTextJp.wordsMaxPartLong
    )
  }

}