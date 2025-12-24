import { ArrayUtils } from "../../../../common/utils/array/ArrayUtils";
import { DateUtils } from "../../../../common/utils/DateUtils";
import { DBBox, DBLearn, DBPiece, DBPlan } from "../plandb/DBPlan_Piece_Box_learn";
import { Box } from "./Box";
import { BoxType, DistanceFromBase } from "./BoxType";
import { DayOf } from "./DayOf";
import { Learn } from "./Learn";
import { Piece } from "./Piece";
import { PlanManager } from "./PlanManager";
import { SearchManager } from "../../../datas/model/SearchManager";
import { WordUser } from "../../../datas/myData/WordUser";

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
  bookId      : number | null;

  // 第天多少个新字
  countPerDay : number;

  // 将words划分为piece列表
  pieces      : Piece[];

  // 划分好的每一个box列表
  boxes       : Box[];

  // 学习记录
  learns      : Learn[];

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

  /// 获取(未删除)状态的wordIds
  get wordIds(): number[] {
    return this.pieces.flatMap((p) => p.wordIds ?? []);
  }

  /// 获取 所有此plan中的所有存在于pieces中的所有[wordId],
  /// 包括可能是 已删除状态 的 wordId
  get wordIdsAll(): number[] | null {
    return this.pieces.reduce<number[]>((acc, p) => acc.concat(p.wordIds ?? []), []);
  }

  /// 获取已经学习的单字(未删除)状态的wordIds
  /**
   * 获取已经学习的单字(未删除)状态的wordIds
   * 每个字只记录一次（即：只要是学习或复习过的字，不管复习过多少次，都只算一次已学习记录）
   * by ko 2021.03.20
   * @param learns 当前plan的学习记录数组
   * @returns 已学习的字列表
   */
  get learnedWordIds(): number[] | null {
    // 获取所有learn对象的wordId，并过滤掉null
    const wordIds: number[] = this.learns.map(l => l.wordId).filter(l => l !== null) as number[];

    // 去除重复元素
    return ArrayUtils.removedDuplicates(wordIds);
  }

  // MARK: - Functions for wordIds in this plan

  /// 获取某天的新字wordIds
  wordIdsWhenNew(dayOf: DayOf): number[] {
    return this.wordIdsFor(dayOf, [BoxType.New]);
  }

  /// 获取某天的复习wordIds
  wordIdsWhenReview(dayOf: DayOf): number[] {
    let distances = dayOf.distances(true);
    return this.wordIdsFor(dayOf, distances);
  }

  ///获取wordIds
  /// 注意：这里获取的wordIds仅仅是此plan中的wordIds，有可能在words中处于deleted状态
  wordIdsFor(dayOf: DayOf, distances: number[] | null = null): number[] {
    let pieceNos = dayOf.pieceNos(distances);
    let set = new Set(pieceNos);
    return this.pieces
      .filter((p) => set.has(p.pieceNo!))
      .reduce<number[]>((acc, p) => acc.concat(p.wordIds ?? []), []);
  }

  // MARK: - Functions for Learned wordIds in this plan

  /// 保存此plan中，指定wordId的某天的学习记录
  saveLearned(wordId: number, dayOf: DayOf): void {
    //相同的字多次出现在多个不同的Piece中，
    //会导致，同一天中，相同的字出现在不同的Box中，如：新字，复习+1天
    //所以这里需要找出所有的pieceNo，同时遍历当天所有的box执行一次保存，才能将进度条改变，否则始进度条始终有剩余
    //by ko 2021.07.31
    this.pieces
      .filter((p) => (p.wordIds ?? []).includes(wordId))
      .forEach((piece) => {
        dayOf.boxes
          .filter((b) => b.pieceNo === piece.pieceNo)
          .forEach((box) => {
            this.saveLearn(dayOf.num, box.distance, piece.pieceNo!, wordId);
          });
      });
  }

  /// 保存此plan中，指定num + distance + pieceNo + wordId的学习记录
  private saveLearn(num: number, distance: number, pieceNo: number, wordId: number): void {
    if (this.planId === null) return;

    let learn       = new Learn();
    learn.planId    = this.planId;
    learn.bookId    = this.bookId;
    learn.num       = num;
    learn.distance  = distance;
    learn.pieceNo   = pieceNo;
    learn.wordId    = wordId;
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
          l.wordId    === wordId
      )
    ) {
      this.learns.push(learn);
    }
  }

  /// 获取某天的新字wordIds
  learnedWordIdsWhenNew(dayOf: DayOf): number[] {
    return this.learnedWordIdsFor(dayOf, [BoxType.New]);
  }

  /// 获取某天的复习wordIds
  learnedWordIdsWhenReview(dayOf: DayOf): number[] {
    let distances = dayOf.distances(true);
    return this.learnedWordIdsFor(dayOf, distances);
  }

  ///获取某天的已经学习过的wordIds
  /// 注意：这里获取的wordIds仅仅是此plan中的wordIds，有可能在words中处于deleted状态
  learnedWordIdsFor(dayOf: DayOf, distances: number[] | null = null): number[] {
    if (distances !== null) {
      let set = new Set(distances);
      return this.learns
        .filter((l) => l.num === dayOf.num && l.distance !== null && set.has(l.distance))
        .map((l) => l.wordId!)
        .filter((id) => id !== null);
    } else {
      return this.learns.filter((l) => l.num === dayOf.num).map((l) => l.wordId!).filter((id) => id !== null);
    }
  }

  // MARK: - words of plan
  ///获取某天的新字words
  wordsWhenNew(dayOf: DayOf): WordUser[] {
    return this.wordsFor(dayOf, [BoxType.New]);
  }

  ///获取某天的复习words
  wordsWhenReview(dayOf: DayOf): WordUser[] {
    let distances = dayOf.distances(true);
    return this.wordsFor(dayOf, distances);
  }

  ///获取Words
  wordsFor(dayOf: DayOf, distances: number[] | null = null): WordUser[] {
    let ids = this.wordIdsFor(dayOf, distances);
    return this.getWordsByIds(ids);
  }

  // MARK: - learned words of plan
  ///获取某天的已经学习新字
  learnedWordsWhenNew(dayOf: DayOf): WordUser[] {
    return this.learnedWordsFor(dayOf, [BoxType.New]);
  }

  ///获取某天的已经复习words
  learnedWordsWhenReview(dayOf: DayOf): WordUser[] {
    let distances = dayOf.distances(true);
    return this.learnedWordsFor(dayOf, distances);
  }

  ///获取已经学习或复习的Words
  learnedWordsFor(dayOf: DayOf, distances: number[] | null = null): WordUser[] {
    let ids = this.learnedWordIdsFor(dayOf, distances);
    return this.getWordsByIds(ids);
  }

  // MARK: - Words from wordIds
  ///获取指定[wordIds]的Words
  getWordsByIds(wordIds: number[]): WordUser[] {
    //过滤掉deleted状态的words
    //使用SearchManager.shared.getAliveWords()获取所有活跃单词
    const aliveWords = SearchManager.shared.getAliveWords();
    
    //使用Set来提高查找效率
    const wordIdSet = new Set(wordIds);
    
    //过滤出包含在wordIds中的单词
    return aliveWords.filter(word => wordIdSet.has(word.idx ?? 0));
  }

  // MARK: - Utils for box

  /// 获取指定wordId在某天dayOf上的 box
  boxForWord(wordId: number, dayOf: DayOf): Box | null {
    let pieceNos = new Set(dayOf.pieceNos());
    let piece    = this.pieces.find((p) => pieceNos.has(p.pieceNo!) && (p.wordIds ?? []).includes(wordId));
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
      (piece.wordIds ?? []).forEach((wordId) => {
        let dbPiece      = new DBPiece();
        dbPiece.planId   = this.planId;
        dbPiece.pieceNo  = piece.pieceNo;
        dbPiece.wordId   = wordId;
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

  /// 向db中添加新的wordIds
  async add(wordIds: number[]): Promise<void> {
    await PlanManager.add(wordIds, this);
  }

  /// (异步)向db中添加新的wordIds
  asyncAdd(wordIds: number[]): void {
    setTimeout(async () => {
      await this.add(wordIds);
    }, 0);
  }

  /// 删除wordIds
  async deleteWordIds(wordIds: number[]): Promise<void> {
    await PlanManager.deleteWordIds(wordIds, this);
  }

  /// (异步)从db中删除wordIds
  asyncDelete(wordIds: number[]): void {
    setTimeout(async () => {
      await this.deleteWordIds(wordIds);
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