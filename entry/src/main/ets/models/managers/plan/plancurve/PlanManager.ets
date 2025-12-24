import { preferences } from "@kit.ArkData";
import { getAppContext } from "../../../../app/constants/AppContext";
import { SimpleEventBus } from "../../../../common/components/eventbus/SimpleEventBus";
import { SettingManager } from "../../setting/SettingManager";
import { DBPlanHelper } from "../plandb/DBPlanHelper";
import { DBPlan } from "../plandb/DBPlan_Piece_Box_learn";
import { PlanDbAccess } from "../plandb/PlanDbAccess";
import { Box } from "./Box";
import { DistanceFromBase } from "./BoxType";
import { Learn } from "./Learn";
import { Piece } from "./Piece";
import { Plan } from "./Plan";

class Prefs {
  static readonly Name                     = "Plan_Settings";
  static readonly kCurrentPlanId           = "Current_Plan_Id";

}

// 定义 PieceCount 类型
interface PieceCount {
  pieceNo: number;
  count: number;
}

// 定义通知相关的常量
export class PlanManagerNotification {

  static readonly namePlanUpdated = "PlanManager.Plan.updated.with_book_id"

  static readonly kPlanId = "PlanIdKey"

}


@ObservedV2
export class PlanManager {


  //MARK: - Notification
  // public static Notification = {
  //   Name: {
  //     static PlanUpdated: new NSNotificationName("PlanManager.Plan.updated.with_book_id")
  //   },
  //   UserInfoKey: {
  //     //Zhika中的bookId可能是Nil
  //     static kPlanId: "PlanIdKey"
  //   }
  // };

  //MARK: - Singleton
  public static shared: PlanManager = new PlanManager();

  private context: Context;
  private prefs: preferences.Preferences | null = null;

  // 当前正在学习的 plan 的对应的 planId
  private _currentPlanId: number | null = null;

  get currentPlanId(): number | null {
    return this._currentPlanId;
  }

  private set currentPlanId(value: number | null) {
    this._currentPlanId = value;
    this.savePreference(); // Swift 中 didSet 的逻辑
  }

  // MARK: - current plan
  // 当前正在学习的 plan，用于首页
  @Trace private _plan: Plan | null = null;

  get plan(): Plan | null {
    return this._plan;
  }

  set plan(value: Plan | null) {
    this._plan = value;
    this.currentPlanId = value?.planId ?? null; // Swift 中 didSet 的逻辑

    if (!value) {
      SettingManager.shared.currentBookId = -1
    }
  }

  private constructor() {
    this.context = getAppContext();
    this.initPreferences(); // 异步调用但不 await
  }

  // 提供一个异步初始化方法
  public async init(): Promise<void> {
    // 等待 preferences 初始化完成
    await this.initPreferences();

    if (this.currentPlanId != null) {
      this.plan = await PlanManager.getPlanByPlanId(this.currentPlanId);
    }
  }

  //MARK: - Preference 初始化
  private async initPreferences() {
    this.prefs = await preferences.getPreferences(this.context, Prefs.Name);
    await this.loadPreference();
  }

  //MARK: - 保存 & 加载
  // 保存当前planId
  private async savePreference(): Promise<void> {
    if (!this.prefs) return;
    await this.prefs.put(Prefs.kCurrentPlanId, this.currentPlanId ?? 0);
    await this.prefs.flush(); // 确保保存
  }

  // 加载当前planId
  private async loadPreference(): Promise<void> {
    if (!this.prefs) return;
    const value = await this.prefs.get(Prefs.kCurrentPlanId, null);
    if (value != null) {
      this.currentPlanId = value as number;
    }
  }


  //MARK: - Operations for Plan
  ///planId + 1000
  public static planBookIdPref: number = 1000;

  //MARK: - Load Plan & Save Plan

  ///从DB加载所有的plans
  /// 从DB加载所有的plans
  public static async getPlans(): Promise<Plan[] | null> {
    const dbPlans: DBPlan[] | null = await PlanDbAccess.shared.getPlans();
    if (!dbPlans) return null;

    // 使用 Promise.all 并行处理异步函数
    const plans: Plan[] = await Promise.all(
      dbPlans.map(async (dbPlan: DBPlan): Promise<Plan> => {
        const dbPlanHelper: DBPlanHelper = new DBPlanHelper(dbPlan);

        // 预先获取所有异步数据
        const pieces: Piece[] = await dbPlanHelper.getPieces();
        const boxes : Box[]   = await dbPlanHelper.getBoxes();
        const learns: Learn[] = await dbPlanHelper.getLearns();

        const plan: Plan = new Plan(
           dbPlan.planId,
           dbPlan.planName,
           dbPlan.startDate,
           dbPlan.distances!.split(",").map((s: string) => parseInt(s)),
           dbPlan.process ?? 0,
           dbPlan.bookId,
           dbPlan.countPerDay!,
           pieces,
           boxes,
           learns
        );

        return plan;
      })
    );

    return plans;
  }

  ///从DB加载plan
  /// 根据 planId 从 DB 获取单个 Plan
  public static async getPlanByPlanId(planId: number): Promise<Plan | null> {
    const dbPlan: DBPlan | null = await PlanDbAccess.shared.getPlanByPlanId(planId);
    if (!dbPlan) return null;

    const dbPlanHelper: DBPlanHelper = new DBPlanHelper(dbPlan);

    // 预先获取所有异步数据
    const pieces: Piece[] = await dbPlanHelper.getPieces();
    const boxes : Box[]   = await dbPlanHelper.getBoxes();
    const learns: Learn[] = await dbPlanHelper.getLearns();

    return new Plan(
      dbPlan.planId,
      dbPlan.planName,
      dbPlan.startDate,
      dbPlan.distances!.split(",").map((s: string) => Number(s)),
      dbPlan.process ?? 0,
      dbPlan.bookId,
      dbPlan.countPerDay!,
      pieces,
      boxes,
      learns
    );
  }

  ///保存plan到DB
  public static async save(plan: Plan): Promise<void> {
    //如果planId为nil时，为新增
    if (plan.planId === null) {
      plan.planId = await PlanDbAccess.shared.getNextPlanId();
    }

    await PlanDbAccess.shared.addOrUpdateInTransaction(
      plan.asDBPlan(),
      plan.getDBPieces(),
      plan.getDBBoxes()
    );

    // 发送通知
    SimpleEventBus.emit(PlanManagerNotification.namePlanUpdated, plan.planId)
  }

  ///删除Plan
  public static async delete(plan: Plan): Promise<void> {
    //删除Plan
    //事务执行Delete（Plan+Piece+Box+Learn）
    await PlanDbAccess.shared.deletePlanTransaction(plan.asDBPlan());

    //发送通知
    SimpleEventBus.emit(PlanManagerNotification.namePlanUpdated, plan.planId)
  }

  //MARK: - Create Plan
  ///创建plan用(会删除旧的学习记录)
  ///只在内存中创建，不会保存到db
  ///如果之前有旧的planId，会继续使用旧的planId, 同时会删除相应的learn记录
  ///如果没有旧的planId，则为nil
  ///countPerDay : 每日学习个数（新字的） ，是整个plan全局的默认值
  public static async createPlan(
    planId: number | null,
    planName: string,
    texts: string[],
    bookId: number | null = null,
    countPerDay: number,
    distances: DistanceFromBase[]
  ): Promise<Plan> {

    // 删除之前 plan 的旧的 Learn
    if (planId != null) {
      await PlanDbAccess.shared.deleteLearn(planId);
    }

    // 获取 pieces 列表
    const pieces: Piece[] = PlanManager.dividedPieces(texts, countPerDay);

    // 计算 boxes
    const boxes: Box[] = pieces.flatMap(piece => PlanManager.boxesComputed(piece, distances));

    // 创建 Plan 实例
    const plan = new Plan(
      planId,
      planName,
      new Date(),        // 当前日期
      distances,
      0,
      bookId,
      countPerDay,
      pieces,
      boxes,
      []
    );

    return plan;
  }

  /// 主要用于更新plan中的某个pieceNo的wordCnt
  ///
  /// pieceCount: 具体为某天（某个pieceNo）指定学习个数（新字），如果为空，则使用countPerDay
  /// isRepeatPieceCount：后面的每天，是否重复执行新的pieceCount。false: 使用全局的countPerDay, true:使用peiceCount
  public static createPlanFromPlan(
    plan: Plan,
    pieceCount?: PieceCount,
    isRepeatPieceCount: boolean = false
  ): Plan {

    // 获取 texts (所有此 plan 中的未删除的 texts)
    const texts: string[] = plan.texts;
    const textsSet: Set<string> = new Set(texts);

    /////////////////////////////////////////////////////////////////////////////////
    /// plan.pieces 中存在缺少某个 piece 的可能:
    //   （有可能是学习个数被改为0后，db 的 pieces 中无 text 的记录，再次获取到的 plan.pieces 中就会缺少这个 piece）
    //
    /// 因为切分 pieces 时是从 0 开始的，pieceNo 也是从 0 开始的，所以，最大的 pieceNo 就是最初应该有的 pieces 的个数
    //
    // 这里按 maxPieceNo 遍历，
    // 1. 如果在 plan.pieces 中找到了相应 pieceNo 的 piece，那么保存每个 pieceNo 对应的 texts 的个数;
    // 2. 如果未在 plan.pieces 中找到相对应 pieceNo 的 piece，那么，此 pieceNo 的 texts 的个数即为 0;
    //
    //    by ko 2023.04.25
    //
    /////////////////////////////////////////////////////////////////////////////////

    const pieceCounts: PieceCount[] = [];
    const maxPieceNo: number = Math.max(...plan.getPieces().map(p => p.pieceNo), 0);

    for (let pieceNo = 0; pieceNo <= maxPieceNo; pieceNo++) {

      // 先设默认，此 pieceNo 的 texts 的个数即为 0
      let curPieceCount: PieceCount = { pieceNo, count: 0 };

      /// 获取 plan 中当前 pieceNo 的 texts 的个数
      const piece = plan.getPieces().find(p => p.pieceNo === pieceNo);
      if (piece) {
        /// plan 中有此 piece
        // 使用原来 piece 中的 count
        // 不能直接使用 piece.texts.length，因为有可能已经被删除过了
        const textsCount = piece.texts.filter(t => textsSet.has(t)).length;
        curPieceCount.count = textsCount;
      }

      /// 需要更改学习数量时
      if (pieceCount) {
        if (pieceNo === pieceCount.pieceNo) {
          // 当前 piece 需要替换成新的 count
          curPieceCount = pieceCount;
        } else if (isRepeatPieceCount && pieceNo > pieceCount.pieceNo) {
          // 重复执行为 true 时，此后的所有 piece 也需要替换成新的 count
          curPieceCount.count = pieceCount.count;
        }
      }

      pieceCounts.push(curPieceCount);
    }

    // 获取 日份 列表
    const pieces: Piece[] = PlanManager.dividedPieces(texts, plan.getCountPerDay(), pieceCounts, isRepeatPieceCount);
    const boxes: Box[] = pieces.flatMap(p => PlanManager.boxesComputed(p, plan.distances));

    const newPlan = new Plan(
      plan.planId,
      plan.planName,
      plan.startDate,
      plan.distances,
      0, //process
      plan.getBookId(),
      plan.getCountPerDay(),
      pieces,
      boxes,
      plan.getLearns()
    );

    return newPlan;
  }

  ///为已经存在的plan添加新的words
  public static async add(texts: string[], plan: Plan): Promise<void> {
    if (texts.length === 0) return;

    /////新加一个piece
    const addNewPiece = (pieceNo: number, text: string) => {
      //新加一个piece
      let newPiece = new Piece(pieceNo, [text] );

      //计算newPiece在DayOfs中的位置
      let boxes = PlanManager.boxesComputed(newPiece, plan.distances);

      plan.appendMemPiece(newPiece);
      plan.appendMemBoxes(boxes);
    };

    let hasNewTextToBeAddIntoPlan = false;

    texts.forEach(newText => {
      let existedTexts = plan.textsAll;
      if (!existedTexts?.includes(newText)) {

        const pieces     = plan.getPieces();
        const maxPieceNo = Math.max(...pieces.map(p => p.pieceNo));
        const lastPiece  = pieces.find(p => p.pieceNo === maxPieceNo) ?? null;

        if (lastPiece && lastPiece.texts.length < plan.getCountPerDay()) {
          //piece 中还有位置
          lastPiece.appendMem(newText);
        } else {
          //新加一个piece
          addNewPiece((lastPiece?.pieceNo ?? -1) + 1, newText);
        }
        hasNewTextToBeAddIntoPlan = true;
      }
    });

    // 需要保存plan时
    if (hasNewTextToBeAddIntoPlan) {
      //保存
      await plan.save();
    }
  }

  ///从plan中删除words
  public static async deleteTexts(texts: string[], plan: Plan): Promise<void> {
    ////删除内存 中的缓存
    plan.getPieces().forEach(piece => {
      texts.forEach(text => {
        //删除text
        piece.removeMem(text);

        //删除此piece
        if (piece.texts.length === 0) {
          plan.removeMemPiece(piece);

          //删除 相应的boxes
          plan.getBoxes().filter(b => b.pieceNo === piece.pieceNo).forEach(b => plan.removeMemBox(b));
        }

        //删除内存 word的Learn
        plan.getLearns().forEach(l => plan.removeMemLearn(l));
      });
    });

    //保存db(更新内存中plan+pieces+box)
    await plan.save();

    //还要删除DB中相应texts的learn
    //这里为了与plan主逻辑区分，不放在一个transaction中执行
    if (plan.planId != null) {
      await PlanDbAccess.shared.deleteLearn(plan.planId, texts);
    }

    //重新加载当前plan
    if (plan.planId === PlanManager.shared.plan?.planId) {
      PlanManager.shared.plan = plan;
    }
  }

  /// 保存学习记录Learn
  public static async saveLearn(learn: Learn): Promise<void> {
    // 保存到db
    await PlanDbAccess.shared.insertLearn(learn.asDBLearn());
  }

  /// 删除此plan的所有learn
  public static async deleteLearnForPlan(plan: Plan): Promise<void> {
    //删除内存中的数据
    plan.removeMemAllLearns();

    //删除db中的数据
    if (plan.planId != null) {
      await PlanDbAccess.shared.deleteLearn(plan.planId);
    }
  }

  ///计算 指定piece的所有box
  private static boxesComputed(piece: Piece, distances: DistanceFromBase[]): Box[] {
    let boxes: Box[] = [];
    //遍历每个distance
    distances.forEach(distance => {
      //某天的其中一个box
      boxes.push(new Box(distance, piece.pieceNo));
    });
    return boxes;
  }

  /// 获取划分好的pieces
  /// 获取划分好的 pieces（完全等效于 Swift 原版逻辑）
  private static dividedPieces(
    texts: string[],
    countPerDay: number,
    pieceCounts: PieceCount[] | null = null,
    isRepeatPieceCount: boolean = false
  ): Piece[] {

    // 将 words 分隔为 piece
    const pieces: Piece[] = [];
    let tempTexts: string[] = [...texts]; // 剩余文本，等效 Swift 中的 tempIds
    let i = 0;

    // 循环处理剩余文本
    while (tempTexts.length > 0) {
      const pieceNo = i;

      /// 重复执行为 true 时，此后的所有 piece 也是和目标 day 的 pieceCount 一样的。
      /// 当 dayOfs 由少变多时，新增加的 dayOfs 在 pieceCounts 中找不到值，这时用最后一个即可
      const arrayCount = pieceCounts?.find(p => p.pieceNo === pieceNo)?.count
        ?? (isRepeatPieceCount ? pieceCounts?.[pieceCounts.length - 1]?.count ?? countPerDay : countPerDay);

      // 取前 arrayCount 个文本作为当前 piece
      const pieceWordIds = tempTexts.slice(0, arrayCount);

      // 更新剩余文本
      tempTexts = tempTexts.slice(arrayCount);

      const piece = new Piece(pieceNo, pieceWordIds);
      pieces.push(piece);

      i += 1;
    }

    return pieces;
  }
}