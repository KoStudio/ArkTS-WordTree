import { StringEncoder } from "../../../common/utils/strings/StringEncrypt";
import { TEUtility } from "../../../common/utils/TEUtility";
import { ResultSetTool } from "../../dbUtils/ResultSetTool";
import { SearchConstants } from "../model/SearchManager";
import { Word } from "../word/Word";
import { WordUserDbAccess } from "./WordUserDbAccess";

// ============================================================
@ObservedV2
export class WordUser extends Word {

  // ================== 常量 ==================
  public static readonly KShareMemo_MemoText   : string = "kMemoText"
  public static readonly KShareMemo_AuthorName : string = "kAuthorName"
  public static readonly KShareMemo_MemoId     : string = "kMemoId"

  public static readonly Deleted_Yes = 1;
  public static readonly Deleted_No  = 0;


  // 用户数据字段
  // @Trace titleEn        : string  = ""


  @Trace favoriteLevel  : number = 0;
  @Trace learnTimes     : number = 0;
  @Trace correctedTimes : number = 0;
  @Trace wrangTimes     : number = 0;
  @Trace lastResultType : number = 0;
  // @Trace wrangYear      : number = 0;
  // @Trace wrangMonth     : number = 0;
  // @Trace wrangDay       : number = 0;
  @Trace wrangDate      : Date | null = null
  // @Trace unitId         : number  = 0
  // @Trace partId         : number  = 0

  @Trace memo           : string | null = null;
  @Trace shareMemos     : Array<Record<string, string>> = []

  @Trace deleted        : boolean = false;


  get wrangYear(): number {
    return this.wrangDate?.getFullYear() || 0
  }

  get wrangMonth(): number {
    return (this.wrangDate?.getMonth() ?? 0) + 1
  }

  get wrangDay(): number {
    return this.wrangDate?.getDate() ?? 0
  }

  // MARK: - 工具方法
  isDeleted(): boolean {
    return this.deleted;
  }

  // 获取裁剪后的日语文本（类似Swift的computed property）
  get wordJpClippedString(): string {
    // return this.wordJp ? this.wordJp.split(',')[0] : '';
    // return TEUtility.clipString(this.titleCn1)
    return this.titleCn1ClippedShort
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
      // this.wrangYear  = now.getFullYear();
      // this.wrangMonth = now.getMonth() + 1;
      // this.wrangDay   = now.getDate();
      this.wrangDate = now
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
    if (this.idx) {
      await WordUserDbAccess.shared.setWordDeletedStatus(this.titleEn, toDelete)//.setWordDeletedStatus(this.id, toDelete)
    }

  }

}