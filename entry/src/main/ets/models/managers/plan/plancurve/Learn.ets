import { DBLearn } from "../plandb/DBPlan_Piece_Box_learn";
import { PlanManager } from "./PlanManager";

// MARK: - Plan Learn
export class Learn {
  planId    : number | null;
  bookId    : number | null;
  num       : number | null;
  distance  : number | null;
  pieceNo   : number | null;
  wordId    : number | null;
  learnDate : Date | null;

  constructor(
    planId    : number | null = null,
    bookId    : number | null = null,
    num       : number | null = null,
    distance  : number | null = null,
    pieceNo   : number | null = null,
    wordId    : number | null = null,
    learnDate : Date | null = null
  ) {
    this.planId    = planId;
    this.bookId    = bookId;
    this.num       = num;
    this.distance  = distance;
    this.pieceNo   = pieceNo;
    this.wordId    = wordId;
    this.learnDate = learnDate;
  }

  // MARK: - Equatable
  equals(other: Learn): boolean {
    return (
      this.planId   === other.planId &&
        this.bookId   === other.bookId &&
        this.num      === other.num &&
        this.distance === other.distance &&
        this.pieceNo  === other.pieceNo &&
        this.wordId     === other.wordId
    );
  }

  // MARK: - Comparable
  compareTo(other: Learn): number {
    if (this.planId === other.planId) {
      return (this.bookId ?? 0) - (other.bookId ?? 0);
    } else if (this.bookId === other.bookId) {
      return (this.num ?? 0) - (other.num ?? 0);
    } else if (this.num === other.num) {
      return (this.distance ?? 0) - (other.distance ?? 0);
    } else if (this.distance === other.distance) {
      return (this.pieceNo ?? 0) - (other.pieceNo ?? 0);
    } else if (this.pieceNo === other.pieceNo) {
      let left  = this.wordId  ?? "";
      let right = other.wordId ?? "";
      return left - right;
    } else {
      return (this.wordId ?? "") === (other.wordId ?? "") ? 0 : 1;
    }
  }

  // MARK: - Hashable
  hashCode(): number {
    let str =
      `planId_${this.planId ?? 0}`     +
        `bookId_${this.bookId ?? 0}`     +
        `num_${this.num ?? 0}`           +
        `distance_${this.distance ?? 0}` +
        `pieceNo_${this.pieceNo ?? 0}`   +
        `wordId_${this.wordId ?? ""}`;
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      hash = (hash << 5) - hash + str.charCodeAt(i);
      hash |= 0; // 转换为32位整数
    }
    return hash;
  }

  // MARK: - DBLearn 相关

  /// 转换为 DBLearn
  asDBLearn(): DBLearn {
    let dbLearn        = new DBLearn();
    dbLearn.planId     = this.planId;
    dbLearn.bookId     = this.bookId;
    dbLearn.num        = this.num;
    dbLearn.distance   = this.distance;
    dbLearn.pieceNo    = this.pieceNo;
    dbLearn.wordId       = this.wordId;
    dbLearn.learnDate  = this.learnDate;
    return dbLearn;
  }

  ///============================PlanManager 中的Extension============================
  ///向db中insert一条Learn数据
  save(){
    PlanManager.saveLearn(this)
  }
}