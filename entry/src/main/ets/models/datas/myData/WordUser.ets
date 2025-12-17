import { TEUtility } from "../../../common/utils/TEUtility";
import { SearchConstants } from "../model/SearchManager";
import { Word } from "../word/Word";
import { WordUserDbAccess } from "./WordUserDbAccess";

// ============================================================
@ObservedV2
export class WordUser extends Word {
  // 用户数据字段
 @Trace favoriteLevel  : number = 0;
 @Trace learnTimes     : number = 0;
 @Trace correctedTimes : number = 0;
 @Trace wrangTimes     : number = 0;
 @Trace lastResultType : number = 0;
 @Trace wrangYear      : number = 0;
 @Trace wrangMonth     : number = 0;
 @Trace wrangDay       : number = 0;
 @Trace memo           : string | null = null;
 @Trace deleted        : boolean = false;

  public static readonly Deleted_Yes = 1;
  public static readonly Deleted_No  = 0;

  constructor(init?: Partial<WordUser>) {
    super(); // 调用 Word 构造函数
    if (init) {
      // 手动赋值每个字段
      if (init.id !== undefined)            this.id = init.id;
      if (init.unitId !== undefined)        this.unitId = init.unitId;
      if (init.unitNo !== undefined)        this.unitNo = init.unitNo;
      if (init.categoryId !== undefined)    this.categoryId = init.categoryId;
      if (init.categoryName !== undefined)  this.categoryName = init.categoryName;
      if (init.wordEn !== undefined)        this.wordEn = init.wordEn;
      if (init.wordJp !== undefined)        this.wordJp = init.wordJp;
      if (init.wordKind !== undefined)      this.wordKind = init.wordKind;
      if (init.wordPronounce !== undefined) this.wordPronounce = init.wordPronounce;
      if (init.exampleEn !== undefined)     this.exampleEn = init.exampleEn;
      if (init.exampleJp !== undefined)     this.exampleJp = init.exampleJp;
      if (init.redWord !== undefined)       this.redWord = init.redWord;
      if (init.unitName !== undefined)      this.unitName = init.unitName;

      if (init.favoriteLevel !== undefined)  this.favoriteLevel = init.favoriteLevel;
      if (init.learnTimes !== undefined)     this.learnTimes = init.learnTimes;
      if (init.correctedTimes !== undefined) this.correctedTimes = init.correctedTimes;
      if (init.wrangTimes !== undefined)     this.wrangTimes = init.wrangTimes;
      if (init.lastResultType !== undefined) this.lastResultType = init.lastResultType;
      if (init.wrangYear !== undefined)      this.wrangYear = init.wrangYear;
      if (init.wrangMonth !== undefined)     this.wrangMonth = init.wrangMonth;
      if (init.wrangDay !== undefined)       this.wrangDay = init.wrangDay;
      if (init.memo !== undefined)           this.memo = init.memo;
      if (init.deleted !== undefined)        this.deleted = init.deleted;
    }
  }



  // MARK: - 工具方法
  isDeleted(): boolean {
    return this.deleted;
  }

  // 获取裁剪后的日语文本（类似Swift的computed property）
  get wordJpClippedString(): string {
    // return this.wordJp ? this.wordJp.split(',')[0] : '';
    return TEUtility.clipString(this.wordJp)
  }

  // 获取错误日期字符串
  get wrangDateString(): string {
    return `${this.wrangYear}/${this.wrangMonth}/${this.wrangDay}`;
  }

  // 增加学习次数（类似Swift的mutating方法）
  incrementLearnTimes(): void {
    this.learnTimes++;
  }

  // 增加测试结果
  incrementTestResult(result: number): void {
    this.lastResultType = result;
    if (result === SearchConstants.TEST_RESULT_CORRECT) {
      this.correctedTimes++;
    } else if (result === SearchConstants.TEST_RESULT_WRONG) {
      this.wrangTimes++;

      const now       = new Date();
      this.wrangYear  = now.getFullYear();
      this.wrangMonth = now.getMonth() + 1;
      this.wrangDay   = now.getDate();
    }
  }


  public getWrangDateString(): string {
    return TEUtility.convertDateStringFromYMD(this.wrangYear, this.wrangMonth, this.wrangDay);
  }

  public getWrangDate(): Date {
    return TEUtility.convertDateFromYMD(this.wrangYear, this.wrangMonth, this.wrangDay);
  }

  public async changeDeletedWord(toDelete: boolean): Promise<void> {
    this.deleted = toDelete
    if (this.id) {
      await WordUserDbAccess.shared.setWordDeletedStatus(this.id, toDelete)
    }

  }

}