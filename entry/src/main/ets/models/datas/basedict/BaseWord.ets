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


  get wordEnSoundText(): string {
    return `${this.titleEn}_ti_u`
  }

  getTitleCnsJoined(): string {
    const titles: string[] = [];

    if (this.titleCn1) titles.push(this.titleCn1);
    if (this.titleCn2) titles.push(this.titleCn2);
    if (this.titleCn3) titles.push(this.titleCn3);

    return BaseWordUtility.getJoinedStringByRemovingDuplications(
      titles,
      BaseWordConstants.TitleTextJp.wordsMaxPartLong
    );
  }

  getTitleItems(): Array<TitleItem> {
    const titles: string[] = [];

    if (this.titleCn1) titles.push(this.titleCn1);
    if (this.titleCn2) titles.push(this.titleCn2);
    if (this.titleCn3) titles.push(this.titleCn3);

    return BaseWordUtility.getJoinedTitleItemsByRemovingDuplications(
      titles,
      BaseWordConstants.TitleTextJp.wordsMaxPartLong
    );
  }

}