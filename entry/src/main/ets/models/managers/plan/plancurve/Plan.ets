import { ArrayUtils } from "../../../../common/utils/array/ArrayUtils";
import { DateUtils } from "../../../../common/utils/DateUtils";
import { DBBox, DBLearn, DBPiece, DBPlan } from "../plandb/DBPlan_Piece_Box_learn";
import { Box } from "./Box";
import { BoxType, DistanceFromBase } from "./BoxType";
import { DayOf } from "./DayOf";
import { Learn } from "./Learn";
import { Piece } from "./Piece";
import { PlanManager } from "./PlanManager";

// MARK: - Plan
export class Plan {

  // 用于db保存
  planId      : number | null;
  planName    : string | null;
  startDate   : Date   | null;

  distances   : number[];

  // 进度： 即currentDayOf 的index
  process     : number;        // 暂时未用

  // 关联的bookId
  private bookId      : number | null;

  // 第天多少个新字
  private countPerDay : number;

  // 将words划分为piece列表
  private pieces      : Piece[];

  // 划分好的每一个box列表
  private boxes       : Box[];

  // 学习记录
  private learns      : Learn[];

  // fileprivate var _book: Book? //缓存用

  constructor(
    planId      : number | null = null,
    planName    : string | null,
    startDate   : Date   | null = new Date(),
    distances   : DistanceFromBase[],
    process     : number        = 0,
    bookId      : number | null = null,
    countPerDay : number,
    pieces      : Piece[],
    boxes       : Box[],
    learns      : Learn[]       = []
  ) {
    this.planId      = planId;
    this.planName    = planName;
    this.startDate   = startDate;
    this.distances   = distances;
    this.process     = process;
    this.bookId      = bookId;
    this.countPerDay = countPerDay;
    this.pieces      = pieces;
    this.boxes       = boxes;
    this.learns      = learns;
  }

  // MARK: - Getters for private properties

  /// 关联的 bookId
  getBookId(): number | null {
    return this.bookId;
  }

  /// 第天多少个新字
  getCountPerDay(): number {
    return this.countPerDay;
  }

  /// 将 words 划分为 piece 列表
  getPieces(): Piece[] {
    return this.pieces;
  }

  /// 划分好的每一个 box 列表
  getBoxes(): Box[] {
    return this.boxes;
  }

  /// 学习记录
  getLearns(): Learn[] {
    return this.learns;
  }

  // MARK: - endDate & Utils for Date

  /// 结束日期（通过开始日期计算出）
  get endDate(): Date | null {
    if (this.startDate !== null) {
      const lastDay: number | null = this.dayOfs.length > 0
        ? this.dayOfs[this.dayOfs.length - 1].num
        : null;
      if (lastDay !== null) {
        return this.addDays(this.startDate, lastDay);
      }
    }
    return null;
  }

  /// 当前(今天)是第几天
  get numOfToday(): number | null {
    if (this.startDate !== null) {
      let now = new Date();
      return this.daysTo(this.startDate, now);
    }
    return null;
  }

  /// 获取指定dayOf的日期
  dateOn(dayOf: DayOf): Date | null {
    if (this.startDate !== null) {
      return this.addDays(this.startDate, dayOf.num);
    }
    return null;
  }

  /// 获取指定dayOf的日期 (字符串)
  dateStringOn(dayOf: DayOf): ResourceStr | null {
    let date = this.dateOn(dayOf);
    if (date !== null) {
      let now = new Date();
      let daysToNow = this.daysTo(date, now);
      if (daysToNow === 0) {//今天
        return $r("app.string.plan_str_today");
      } else if (daysToNow === 1) {//昨天
        return $r("app.string.plan_str_yesterday");
      } else if (daysToNow === -1) {//明天
        return $r("app.string.plan_str_tomorrow");
      }
      return this.formatedDateString(date);
    }
    return null;
  }

  /// 获取指定日期的dayOf
  dayOfFor(date: Date): DayOf | null {
    if (this.startDate !== null) {
      let num = this.daysTo(this.startDate, date);
      return this.dayOfs.find((d) => d.num === num) ?? null;
    }
    return null;
  }

  // MARK: - dayOfs

  // 日份List
  get dayOfs(): DayOf[] {
    let dict: Map<number, Box[]> = new Map();

    // 每天的boxes按distance从小-大排序，
    // 这样就是实现每天的新字在前，复习的字在后面
    this.boxes.sort((a, b) => a.compareTo(b)).forEach((box) => {
      if (dict.has(box.num)) {
        dict.get(box.num)!.push(box);
      } else {
        dict.set(box.num, [box]);
      }
    });

    let dayOfs: DayOf[] = Array.from(dict.keys())
      .sort((a, b) => a - b)
      .map((key) => new DayOf(key, dict.get(key)!));

    return dayOfs;
  }

  // MARK: - Operation in memo

  /// 在内存中添加piece
  appendMemPiece(piece: Piece): void {
    this.pieces.push(piece);
  }

  /// 在内存中删除piece
  removeMemPiece(piece: Piece): void {
    this.pieces = this.pieces.filter((p) => !p.equals(piece));
  }

  /// 在内存中添加box
  appendMemBox(box: Box): void {
    this.boxes.push(box);
  }

  /// 从内存中添加boxes
  appendMemBoxes(boxes: Box[]): void {
    this.boxes.push(...boxes);
  }

  /// 在内存中删除box
  removeMemBox(box: Box): void {
    this.boxes = this.boxes.filter((b) => !b.equals(box));
  }

  /// 在内存中添加learn
  appendMemLearn(learn: Learn): void {
    this.learns.push(learn);
  }

  /// 在内存中删除learn
  removeMemLearn(learn: Learn): void {
    this.learns = this.learns.filter((l) => !l.equals(learn));
  }

  /// 在内存中删除全部Learn
  removeMemAllLearns(): void {
    this.learns = [];
  }

  // MARK: - Ref Get Functions

  /// 获取(未删除)状态的texts
  get texts(): string[] {
    return this.pieces.flatMap((p) => p.texts ?? []);
  }

  /// 获取 所有此plan中的所有存在于pieces中的所有[text],
  /// 包括可能是 已删除状态 的 text
  get textsAll(): string[] | null {
    return this.pieces.reduce<string[]>((acc, p) => acc.concat(p.texts ?? []), []);
  }

  /// 获取已经学习的单字(未删除)状态的texts
  /**
   * 获取已经学习的单字(未删除)状态的texts
   * 每个字只记录一次（即：只要是学习或复习过的字，不管复习过多少次，都只算一次已学习记录）
   * by ko 2021.03.20
   * @param learns 当前plan的学习记录数组
   * @returns 已学习的字列表
   */
  get learnedTexts(): string[] | null {
    // 获取所有learn对象的text，并过滤掉null
    const texts: string[] = this.learns.map(l => l.text).filter(l => l !== null) as string[];

    // 去除重复元素
    return ArrayUtils.removedDuplicates(texts);
  }

  // MARK: - Functions for texts in this plan

  /// 获取某天的新字texts
  textsWhenNew(dayOf: DayOf): string[] {
    return this.textsFor(dayOf, [BoxType.New]);
  }

  /// 获取某天的复习texts
  textsWhenReview(dayOf: DayOf): string[] {
    let distances = dayOf.distances(true);
    return this.textsFor(dayOf, distances);
  }

  ///获取texts
  /// 注意：这里获取的texts仅仅是此plan中的texts，有可能在words中处于deleted状态
  textsFor(dayOf: DayOf, distances: number[] | null = null): string[] {
    let pieceNos = dayOf.pieceNos(distances);
    let set = new Set(pieceNos);
    return this.pieces
      .filter((p) => set.has(p.pieceNo!))
      .reduce<string[]>((acc, p) => acc.concat(p.texts ?? []), []);
  }

  // MARK: - Functions for Learned texts in this plan

  /// 保存此plan中，指定text的某天的学习记录
  saveLearned(text: string, dayOf: DayOf): void {
    //相同的字多次出现在多个不同的Piece中，
    //会导致，同一天中，相同的字出现在不同的Box中，如：新字，复习+1天
    //所以这里需要找出所有的pieceNo，同时遍历当天所有的box执行一次保存，才能将进度条改变，否则始进度条始终有剩余
    //by ko 2021.07.31
    this.pieces
      .filter((p) => (p.texts ?? []).includes(text))
      .forEach((piece) => {
        dayOf.boxes
          .filter((b) => b.pieceNo === piece.pieceNo)
          .forEach((box) => {
            this.saveLearn(dayOf.num, box.distance, piece.pieceNo!, text);
          });
      });
  }

  /// 保存此plan中，指定num + distance + pieceNo + text的学习记录
  private saveLearn(num: number, distance: number, pieceNo: number, text: string): void {
    if (this.planId === null) return;

    let learn       = new Learn();
    learn.planId    = this.planId;
    learn.bookId    = this.bookId;
    learn.num       = num;
    learn.distance  = distance;
    learn.pieceNo   = pieceNo;
    learn.text      = text;
    learn.learnDate = new Date();
    learn.save();

    if (
      !this.learns.some(
        (l) =>
        l.planId    === this.planId &&
          l.bookId    === this.bookId &&
          l.num       === num &&
          l.distance  === distance &&
          l.pieceNo   === pieceNo &&
          l.text      === text
      )
    ) {
      this.learns.push(learn);
    }
  }

  /// 获取某天的新字texts
  learnedTextsWhenNew(dayOf: DayOf): string[] {
    return this.learnedTextsFor(dayOf, [BoxType.New]);
  }

  /// 获取某天的复习texts
  learnedTextsWhenReview(dayOf: DayOf): string[] {
    let distances = dayOf.distances(true);
    return this.learnedTextsFor(dayOf, distances);
  }

  ///获取某天的已经学习过的texts
  /// 注意：这里获取的texts仅仅是此plan中的texts，有可能在words中处于deleted状态
  learnedTextsFor(dayOf: DayOf, distances: number[] | null = null): string[] {
    if (distances !== null) {
      let set = new Set(distances);
      return this.learns
        .filter((l) => l.num === dayOf.num && l.distance !== null && set.has(l.distance))
        .map((l) => l.text!)
        .filter((t) => t !== null);
    } else {
      return this.learns.filter((l) => l.num === dayOf.num).map((l) => l.text!).filter((t) => t !== null);
    }
  }

  // MARK: - Utils for box

  /// 获取指定text在某天dayOf上的 box
  boxForWord(text: string, dayOf: DayOf): Box | null {
    let pieceNos = new Set(dayOf.pieceNos());
    let piece    = this.pieces.find((p) => pieceNos.has(p.pieceNo!) && (p.texts ?? []).includes(text));
    if (piece !== null && piece !== undefined) {
      return dayOf.boxes.find((b) => b.pieceNo === piece?.pieceNo) ?? null;
    }
    return null;
  }

  // MARK: - DBPlanとの交換

  /// 转换为 DBPlan
  asDBPlan(): DBPlan {
    let dbPlan         = new DBPlan();
    dbPlan.planId      = this.planId;
    dbPlan.planName    = this.planName;
    dbPlan.bookId      = this.bookId;
    dbPlan.countPerDay = this.countPerDay;
    dbPlan.startDate   = this.startDate;
    dbPlan.distances   = this.distances.join(",");
    dbPlan.process     = this.process;
    return dbPlan;
  }

  /// 获取转换后的 DBPieces
  getDBPieces(): DBPiece[] {
    let dbPieces: DBPiece[] = [];
    this.pieces.forEach((piece) => {
      (piece.texts ?? []).forEach((text) => {
        let dbPiece      = new DBPiece();
        dbPiece.planId   = this.planId;
        dbPiece.pieceNo  = piece.pieceNo;
        dbPiece.text     = text;
        dbPieces.push(dbPiece);
      });
    });
    return dbPieces;
  }

  /// 获取转换后的 DBBoxes
  getDBBoxes(): DBBox[] {
    let dbBoxes: DBBox[] = [];
    this.dayOfs.forEach((dayOf) => {
      dayOf.boxes.forEach((box) => {
        let dbBox      = new DBBox();
        dbBox.planId   = this.planId;
        dbBox.num      = dayOf.num;
        dbBox.distance = box.distance;
        dbBox.pieceNo  = box.pieceNo;
        dbBoxes.push(dbBox);
      });
    });
    return dbBoxes;
  }

  /// 获取转换后的 DBLearns
  getDBLearns(): DBLearn[] {
    return this.learns.map((l) => l.asDBLearn());
  }

  // MARK: - 工具函数 (Swift 的 Date 扩展方法替代)
  private addDays(date: Date, days: number): Date {
    let d = new Date(date);
    d.setDate(d.getDate() + days);
    return d;
  }

  private daysTo(start: Date, end: Date): number {
    return DateUtils.daysTo(start, end)
  }

  private formatedDateString(date: Date): string {
    return DateUtils.toDateString(date)
  }


  ///============================PlanManager 中的Extension============================
  /// 保存到db
  async save(): Promise<void> {
    await PlanManager.save(this);
  }

  /// 从db中删除
  async delete(): Promise<void> {
    await PlanManager.delete(this);
  }

  /// 向db中添加新的texts
  async add(texts: string[]): Promise<void> {
    await PlanManager.add(texts, this);
  }

  /// (异步)向db中添加新的texts
  asyncAdd(texts: string[]): void {
    setTimeout(async () => {
      await this.add(texts);
    }, 0);
  }

  /// 删除texts
  async deleteTexts(texts: string[]): Promise<void> {
    await PlanManager.deleteTexts(texts, this);
  }

  /// (异步)从db中删除texts
  asyncDelete(texts: string[]): void {
    setTimeout(async () => {
      await this.deleteTexts(texts);
    }, 0);
  }

  /// 删除此plan的Learn
  async deleteLearn(): Promise<void> {
    await PlanManager.deleteLearnForPlan(this);
  }

  /// 获取临时用的BookId
  getTempBookId(): number | null {
    return this.planId !== null ? this.planId + PlanManager.planBookIdPref : null;
  }

}