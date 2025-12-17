export class Word {
  id              : number | null = null;
  unitId          : number | null = null;
  unitNo          : number | null = null;
  categoryId      : number | null = null;
  categoryName    : string | null = null;
  wordEn          : string | null = null;
  wordJp          : string | null = null;
  wordKind        : string | null = null;
  wordPronounce   : string | null = null;
  exampleEn       : string | null = null;
  exampleJp       : string | null = null;
  redWord         : string | null = null;
  unitName        : string | null = null;

  get wordEnSoundText(): string {
    return `${this.wordEn}_ti_u`
  }
}