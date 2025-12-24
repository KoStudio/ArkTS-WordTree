import { Box } from "../plancurve/Box";
import { Learn } from "../plancurve/Learn";
import { Piece } from "../plancurve/Piece";
import { DBBox, DBLearn, DBPiece, DBPlan } from "./DBPlan_Piece_Box_learn";
import { PlanDbAccess } from "./PlanDbAccess";

// MARK: - PlanHelper
export class DBPlanHelper {

  private plan: DBPlan;

  constructor(plan: DBPlan) {
    this.plan = plan;
  }

  // MARK: - Private Helpers

  /** 获取此 DBPlan 的 DBPieces */
  async dbPieces(): Promise<DBPiece[]> {
    if (this.plan.planId) {
      return await PlanDbAccess.shared.getPieces(this.plan.planId) ?? [];
    }
    return [];
  }

  /** 获取此 DBPlan 的 DBBoxes，可选过滤 pieceNo、num、distances */
  async dbBoxes(pieceNo?: number, num?: number, distances?: Set<number>): Promise<DBBox[]> {
    if (!this.plan.planId) return [];

    let boxes = await PlanDbAccess.shared.getBoxs(this.plan.planId, pieceNo) ?? [];

    if (num != null) {
      boxes = boxes.filter(b => (b.num ?? -1) === num);
    }

    if (distances != null) {
      boxes = boxes.filter(b => distances.has(b.distance ?? -1));
    }

    return boxes;
  }

  /** 获取此 DBPlan 的所有 texts（可指定 pieceNo） */
  async texts(pieceNo?: number): Promise<string[]> {
    const pieces = await this.dbPieces();
    if (pieceNo != null) {
      return pieces.filter(p => p.pieceNo === pieceNo).map(p => p.text ?? "").filter(t => t);
    }
    return pieces.map(p => p.text ?? "").filter(t => t);
  }

  /** 获取此 DBPlan 的 DBLearns */
  async dbLearns(): Promise<DBLearn[]> {
    if (this.plan.planId) {
      return await PlanDbAccess.shared.getLearns(this.plan.planId) ?? [];
    }
    return [];
  }

  // MARK: - Utils for Plan

  /** 获取转换后的 Pieces */
  async getPieces(): Promise<Piece[]> {
    const piecesSet = new Set<Piece>();
    const dbPieces = await this.dbPieces();

    dbPieces.forEach(dbPiece => {
      const pieceNo = dbPiece.pieceNo;
      const text = dbPiece.text;
      if (pieceNo != null && text) {
        const existed = Array.from(piecesSet).find(p => p.pieceNo === pieceNo);
        if (existed) {
          existed.appendMem(text);
        } else {
          piecesSet.add(new Piece(pieceNo, [text]));
        }
      }
    });

    return Array.from(piecesSet).sort((a, b) => a.pieceNo - b.pieceNo);
  }

  /** 获取转换后的 Boxes */
  async getBoxes(): Promise<Box[]> {
    const boxesSet = new Set<Box>();
    const dbBoxes = await this.dbBoxes();

    dbBoxes.forEach(dbBox => {
      const pieceNo = dbBox.pieceNo;
      const distance = dbBox.distance;
      if (pieceNo != null && distance != null) {
        boxesSet.add(new Box(distance, pieceNo)); // Set 自动去重
      }
    });

    return Array.from(boxesSet).sort((a, b) => a.pieceNo - b.pieceNo);
  }

  /** 获取转换后的 Learns */
  async getLearns(): Promise<Learn[]> {
    // var learns = [Learn]()
    const learns = new Set<Learn>(); // 用Set更快

    // 等待异步获取 dbLearns
    const dbLearnsArray: DBLearn[] = await this.dbLearns();

    for (let i = 0; i < dbLearnsArray.length; i++) {
      const dbLearn = dbLearnsArray[i];

      if (dbLearn.planId != null &&
        dbLearn.bookId != null &&
        dbLearn.num != null &&
        dbLearn.distance != null &&
        dbLearn.pieceNo != null &&
        dbLearn.text != null &&
        dbLearn.learnDate != null) {

        const learn = new Learn();
        learn.planId    = dbLearn.planId;
        learn.bookId    = dbLearn.bookId;
        learn.num       = dbLearn.num;
        learn.distance  = dbLearn.distance;
        learn.pieceNo   = dbLearn.pieceNo;
        learn.text      = dbLearn.text;
        learn.learnDate = dbLearn.learnDate;

        //// 使用Set，无需判断Contains
        learns.add(learn);
      }
    }

    // 转数组并按 learnDate 升序排序
    return Array.from(learns).sort((a, b) => (a.learnDate?.getTime() ?? 0) - (b.learnDate?.getTime() ?? 0));
  }
}