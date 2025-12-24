import { dMyDataFilePath, dMyDataFolderPath } from "../../../../app/constants/AppDefines";
import { createFolderIfNeeds } from "../../../../app/constants/AppFunctions";
import { StringEncoder } from "../../../../common/utils/strings/StringEncrypt";
import { DBAccessor, ParamType, SqlObj } from "../../../dbUtils/DBAccessor";
import { relationalStore } from "@kit.ArkData";
import { ResultSetTool } from "../../../dbUtils/ResultSetTool";
import { DBBox, DBLearn, DBPiece, DBPlan } from "./DBPlan_Piece_Box_learn";

// MARK: - 数据表常量
namespace Tables {
  // MARK: - Plan
  export namespace Plan {
    export const name = "P_Plan";
    export namespace Col {
      export const planId      = "planId";
      export const planName    = "planName";
      export const bookId      = "bookId";
      export const countPerDay = "countPerDay";
      export const startDate   = "startDate";
      export const distances   = "distances";
      export const process     = "process";
    }
  }

  // MARK: - Piece
  export namespace Piece {
    export const name          = "P_Piece";
    export namespace Col {
      export const planId      = "planId";
      export const pieceNo     = "pieceNo";
      export const wordId      = "wordId";
    }
  }

  // MARK: - Box
  export namespace Box {
    export const name          = "P_Box";
    export namespace Col {
      export const planId      = "planId";
      export const num         = "num";
      export const distance    = "distance";
      export const pieceNo     = "pieceNo";
    }
  }

  // MARK: - Learn
  export namespace Learn {
    export const name          = "P_Learn";
    export namespace Col {
      export const planId      = "planId";
      export const bookId      = "bookId";
      export const num         = "num";
      export const distance    = "distance";
      export const pieceNo     = "pieceNo";
      export const wordId      = "wordId";
      export const learnDate   = "learnDate";
    }
  }
}

// MARK: - PlanDbAccess
export class PlanDbAccess {
  private static instance: PlanDbAccess;
  private db: DBAccessor | null = null;

  private constructor() {
    createFolderIfNeeds(dMyDataFolderPath);
    this.db = new DBAccessor(dMyDataFilePath, null, false);
    this.createDbIfNeeds();
  }

  public static get shared(): PlanDbAccess {
    if (!PlanDbAccess.instance) {
      PlanDbAccess.instance = new PlanDbAccess();
    }
    return PlanDbAccess.instance;
  }

  // ====== 创建表（如果不存在） ======
  private createDbIfNeeds(): void {
    if (!this.db) return;

    const sqlPlan = `CREATE TABLE IF NOT EXISTS "${Tables.Plan.name}" (
            "${Tables.Plan.Col.planId}"      INTEGER PRIMARY KEY NOT NULL,
            "${Tables.Plan.Col.planName}"    TEXT,
            "${Tables.Plan.Col.bookId}"      INTEGER,
            "${Tables.Plan.Col.countPerDay}" INTEGER,
            "${Tables.Plan.Col.startDate}"   TEXT,
            "${Tables.Plan.Col.distances}"   TEXT,
            "${Tables.Plan.Col.process}"     TEXT
        )`;

    const sqlPiece = `CREATE TABLE IF NOT EXISTS "${Tables.Piece.name}" (
            "${Tables.Piece.Col.planId}"     INTEGER,
            "${Tables.Piece.Col.pieceNo}"    INTEGER,
            "${Tables.Piece.Col.wordId}"     INTEGER
        )`;

    const sqlBox = `CREATE TABLE IF NOT EXISTS "${Tables.Box.name}" (
            "${Tables.Box.Col.planId}"       INTEGER,
            "${Tables.Box.Col.num}"          INTEGER,
            "${Tables.Box.Col.distance}"     INTEGER,
            "${Tables.Box.Col.pieceNo}"      INTEGER
        )`;

    const sqlLearn = `CREATE TABLE IF NOT EXISTS "${Tables.Learn.name}" (
            "${Tables.Learn.Col.planId}"     INTEGER,
            "${Tables.Learn.Col.bookId}"     INTEGER,
            "${Tables.Learn.Col.num}"        INTEGER,
            "${Tables.Learn.Col.distance}"   INTEGER,
            "${Tables.Learn.Col.pieceNo}"    INTEGER,
            "${Tables.Learn.Col.wordId}"     INTEGER,
            "${Tables.Learn.Col.learnDate}"  TEXT
        )`;

    this.db.updateDb(sqlPlan);
    this.db.updateDb(sqlPiece);
    this.db.updateDb(sqlBox);
    this.db.updateDb(sqlLearn);
  }

  // ====== 恢复数据时刷新 DB ======
  refreshDb(): void {
    this.createDbIfNeeds();
  }

  // ====== 插入 / 更新 ======
  async insertOrUpdatePlan(plan: DBPlan): Promise<void> {
    if (!this.db) return;
    const sqlObj = this.createSqlObjForPlan(plan);
    if (!sqlObj) return;
    await this.db.updateDb(sqlObj.sql, sqlObj.params);
  }

  async insertPiece(piece: DBPiece): Promise<void> {
    if (!this.db) return;
    const sqlObj = this.createSqlObjForPiece(piece);
    if (!sqlObj) return;
    await this.db.updateDb(sqlObj.sql, sqlObj.params);
  }

  async insertBox(box: DBBox): Promise<void> {
    if (!this.db) return;
    const sqlObj = this.createSqlObjForBox(box);
    if (!sqlObj) return;
    await this.db.updateDb(sqlObj.sql, sqlObj.params);
  }

  async insertLearn(learn: DBLearn): Promise<void> {
    if (!this.db) return;
    const sqlObj = this.createSqlObjForLearn(learn);
    if (!sqlObj) return;
    await this.db.updateDb(sqlObj.sql, sqlObj.params);
  }

  // ====== 删除操作 ======
  async deletePlan(planId: number): Promise<void> {
    const sql = `DELETE FROM ${Tables.Plan.name} WHERE ${Tables.Plan.Col.planId} = ?`;
    await this.db?.updateDb(sql, [planId]);
  }

  async deletePiece(wordId: number, planId: number): Promise<void> {
    const sql = `DELETE FROM ${Tables.Piece.name} WHERE ${Tables.Piece.Col.wordId} = ? AND ${Tables.Piece.Col.planId} = ?`;
    await this.db?.updateDb(sql, [wordId, planId]);
  }

  async deleteBox(pieceNo: number, planId: number): Promise<void> {
    const sql = `DELETE FROM ${Tables.Box.name} WHERE ${Tables.Box.Col.pieceNo} = ? AND ${Tables.Box.Col.planId} = ?`;
    await this.db?.updateDb(sql, [pieceNo, planId]);
  }

  async deleteLearn(planId: number, wordIds?: number[]): Promise<void> {
    if (!this.db) return;

    let sql = `DELETE FROM ${Tables.Learn.name} WHERE ${Tables.Learn.Col.planId} = ?`;
    const params: ParamType[] = [planId];

    if (wordIds && wordIds.length > 0) {
      const wordIdList = wordIds.map(id => `'${id}'`).join(",");
      sql += ` AND ${Tables.Learn.Col.wordId} IN (${wordIdList})`;
    }

    await this.db.updateDb(sql, params);
  }

  // ====== 查询操作 ======
  async getNextPlanId(): Promise<number> {
    const maxId = await this.db?.getMax(Tables.Plan.Col.planId, Tables.Plan.name);
    return (maxId != null ? maxId + 1 : 1);
  }

  async getPlans(): Promise<DBPlan[] | null> {
    const sql = `SELECT * FROM ${Tables.Plan.name}`;
    return await this.db?.getDatas(sql, [], rs => this.createDBPlan(rs)) ?? null;
  }

  async getPlanByPlanId(planId: number): Promise<DBPlan | null> {
    const sql = `SELECT * FROM ${Tables.Plan.name} WHERE ${Tables.Plan.Col.planId} = ?`;
    return await this.db?.getData(sql, [planId], rs => this.createDBPlan(rs)) ?? null;
  }

  async getPlanByBookId(bookId: number): Promise<DBPlan | null> {
    const sql = `SELECT * FROM ${Tables.Plan.name} WHERE ${Tables.Plan.Col.bookId} = ?`;
    return await this.db?.getData(sql, [bookId], rs => this.createDBPlan(rs)) ?? null;
  }

  async getPieces(planId: number): Promise<DBPiece[] | null> {
    const sql = `SELECT * FROM ${Tables.Piece.name} WHERE ${Tables.Piece.Col.planId} = ?`;
    return await this.db?.getDatas(sql, [planId], rs => this.createDBPiece(rs)) ?? null;
  }

  async getBoxs(planId: number, pieceNo?: number): Promise<DBBox[] | null> {
    let sql = `SELECT * FROM ${Tables.Box.name} WHERE ${Tables.Box.Col.planId} = ?`;
    const params: ParamType[] = [planId];

    if (pieceNo != null) {
      sql += ` AND ${Tables.Box.Col.pieceNo} = ?`;
      params.push(pieceNo);
    }

    return await this.db?.getDatas(sql, params, rs => this.createDBBox(rs)) ?? null;
  }

  async getLearns(planId: number): Promise<DBLearn[] | null> {
    const sql = `SELECT * FROM ${Tables.Learn.name} WHERE ${Tables.Learn.Col.planId} = ?`;
    return await this.db?.getDatas(sql, [planId], rs => this.createDBLearn(rs)) ?? null;
  }

  // ====== 事务操作 ======
  async addOrUpdateInTransaction(plan: DBPlan, pieces: DBPiece[], boxes: DBBox[]): Promise<void> {
    if (!plan.planId || !this.db) return;

    const sqlList: string[] = [];
    const paramsList: ParamType[][] = [];

    // Plan
    const planSqlObj = this.createSqlObjForPlan(plan);
    if (planSqlObj) {
      sqlList.push(planSqlObj.sql);
      paramsList.push(planSqlObj.params);
    }

    // 删除旧的 Pieces
    sqlList.push(`DELETE FROM ${Tables.Piece.name} WHERE ${Tables.Piece.Col.planId} = ?`);
    paramsList.push([plan.planId]);

    // 删除旧的 Boxes
    sqlList.push(`DELETE FROM ${Tables.Box.name} WHERE ${Tables.Box.Col.planId} = ?`);
    paramsList.push([plan.planId]);

    // 插入 Pieces
    pieces.forEach(piece => {
      const sqlObj = this.createSqlObjForPiece(piece);
      if (sqlObj) {
        sqlList.push(sqlObj.sql);
        paramsList.push(sqlObj.params);
      }
    });

    // 插入 Boxes
    boxes.forEach(box => {
      const sqlObj = this.createSqlObjForBox(box);
      if (sqlObj) {
        sqlList.push(sqlObj.sql);
        paramsList.push(sqlObj.params);
      }
    });

    await this.db.updateDbBatch(sqlList, paramsList);
  }

  // MARK: - 事务删除 Plan
   async deletePlanTransaction(plan: DBPlan): Promise<void> {
     if (!this.db) return;
    if (!plan.planId || !PlanDbAccess.shared) return;

    const planId = plan.planId;

    const sqlList: string[] = [];
    const paramsList: ParamType[][] = [];

    // ====== 删除 Plan ======
    sqlList.push(`DELETE FROM ${Tables.Plan.name} WHERE ${Tables.Plan.Col.planId} = ?`);
    paramsList.push([planId]);

    // ====== 删除旧的 Pieces ======
    sqlList.push(`DELETE FROM ${Tables.Piece.name} WHERE ${Tables.Piece.Col.planId} = ?`);
    paramsList.push([planId]);

    // ====== 删除旧的 Boxes ======
    sqlList.push(`DELETE FROM ${Tables.Box.name} WHERE ${Tables.Box.Col.planId} = ?`);
    paramsList.push([planId]);

    // ====== 删除 Learns ======
    sqlList.push(`DELETE FROM ${Tables.Learn.name} WHERE ${Tables.Learn.Col.planId} = ?`);
    paramsList.push([planId]);

    // ====== 执行事务 ======
    await this.db.updateDbBatch(sqlList, paramsList);
  }

  // ====== ResultSet -> 实体 ======
  private createDBPlan(rs: relationalStore.ResultSet): DBPlan {
    const data       = new DBPlan();
    data.planId      = rs.getLong(rs.getColumnIndex(Tables.Plan.Col.planId));
    data.planName    = ResultSetTool.decodeString(rs, Tables.Plan.Col.planName);
    data.bookId      = rs.getLong(rs.getColumnIndex(Tables.Plan.Col.bookId));
    data.countPerDay = rs.getLong(rs.getColumnIndex(Tables.Plan.Col.countPerDay));
    data.startDate   = ResultSetTool.getDate(rs, Tables.Plan.Col.startDate)
    data.distances   = ResultSetTool.decodeString(rs, Tables.Plan.Col.distances);
    data.process     =  rs.getLong(rs.getColumnIndex(Tables.Plan.Col.process));
    return data;
  }

  private createDBPiece(rs: relationalStore.ResultSet): DBPiece {
    const data       = new DBPiece();
    data.planId      = rs.getLong(rs.getColumnIndex(Tables.Piece.Col.planId));
    data.pieceNo     = rs.getLong(rs.getColumnIndex(Tables.Piece.Col.pieceNo));
    data.wordId      = rs.getLong(rs.getColumnIndex(Tables.Piece.Col.wordId));
    return data;
  }

  private createDBBox(rs: relationalStore.ResultSet): DBBox {
    const data       = new DBBox();
    data.planId      = rs.getLong(rs.getColumnIndex(Tables.Box.Col.planId));
    data.num         = rs.getLong(rs.getColumnIndex(Tables.Box.Col.num));
    data.distance    = rs.getLong(rs.getColumnIndex(Tables.Box.Col.distance));
    data.pieceNo     = rs.getLong(rs.getColumnIndex(Tables.Box.Col.pieceNo));
    return data;
  }

  private createDBLearn(rs: relationalStore.ResultSet): DBLearn {
    const data       = new DBLearn();
    data.planId      = rs.getLong(rs.getColumnIndex(Tables.Learn.Col.planId));
    data.bookId      = rs.getLong(rs.getColumnIndex(Tables.Learn.Col.bookId));
    data.num         = rs.getLong(rs.getColumnIndex(Tables.Learn.Col.num));
    data.distance    = rs.getLong(rs.getColumnIndex(Tables.Learn.Col.distance));
    data.pieceNo     = rs.getLong(rs.getColumnIndex(Tables.Learn.Col.pieceNo));
    data.wordId      = rs.getLong(rs.getColumnIndex(Tables.Learn.Col.wordId));
    data.learnDate   = ResultSetTool.getDate(rs, Tables.Learn.Col.learnDate) //new Date(rs.getString(rs.getColumnIndex(Tables.Learn.Col.learnDate)));
    return data;
  }

  // ====== 构建 SqlObj ======
  private createSqlObjForPlan(plan: DBPlan): SqlObj | null {
    if (!plan.planId || !plan.planName) return null;
    const sql = `REPLACE INTO ${Tables.Plan.name} (
            ${Tables.Plan.Col.planId},
            ${Tables.Plan.Col.planName},
            ${Tables.Plan.Col.bookId},
            ${Tables.Plan.Col.countPerDay},
            ${Tables.Plan.Col.startDate},
            ${Tables.Plan.Col.distances},
            ${Tables.Plan.Col.process}
        ) VALUES(?, ?, ?, ?, ?, ?, ?)`;
    const params: ParamType[] = [
      plan.planId,
      StringEncoder.encodeAndAddSalt(plan.planName),
      plan.bookId ?? null,
      plan.countPerDay ?? null,
      this.formatDateToString(plan.startDate),
      StringEncoder.encodeAndAddSalt(plan.distances ),
      plan.process ?? null
    ];
    return { sql, params };
  }

  private createSqlObjForPiece(piece: DBPiece): SqlObj | null {
    if (!piece.planId || piece.pieceNo == null || !piece.wordId) return null;
    const sql = `REPLACE INTO ${Tables.Piece.name} (
            ${Tables.Piece.Col.planId},
            ${Tables.Piece.Col.pieceNo},
            ${Tables.Piece.Col.wordId}
        ) VALUES(?, ?, ?)`;
    const params: ParamType[] = [
      piece.planId,
      piece.pieceNo,
      piece.wordId,
    ];
    return { sql, params };
  }

  private createSqlObjForBox(box: DBBox): SqlObj | null {
    if (!box.planId || box.pieceNo == null) return null;
    const sql = `REPLACE INTO ${Tables.Box.name} (
            ${Tables.Box.Col.planId},
            ${Tables.Box.Col.num},
            ${Tables.Box.Col.distance},
            ${Tables.Box.Col.pieceNo}
        ) VALUES(?, ?, ?, ?)`;
    const params: ParamType[] = [
      box.planId,
      box.num ?? null,
      box.distance ?? null,
      box.pieceNo
    ];
    return { sql, params };
  }

  private createSqlObjForLearn(learn: DBLearn): SqlObj | null {
    if (!learn.planId || !learn.wordId) return null;
    const sql = `REPLACE INTO ${Tables.Learn.name} (
            ${Tables.Learn.Col.planId},
            ${Tables.Learn.Col.bookId},
            ${Tables.Learn.Col.num},
            ${Tables.Learn.Col.distance},
            ${Tables.Learn.Col.pieceNo},
            ${Tables.Learn.Col.wordId},
            ${Tables.Learn.Col.learnDate}
        ) VALUES(?, ?, ?, ?, ?, ?, ?)`;
    const params: ParamType[] = [
      learn.planId,
      learn.bookId ?? null,
      learn.num ?? null,
      learn.distance ?? null,
      learn.pieceNo ?? null,
      learn.wordId,
      this.formatDateToString(learn.learnDate)
    ];
    return { sql, params };
  }

  formatDateToString(date: Date | null | undefined): string | null {
    if (!date) {
      return null
    }

    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0'); // 月份从0开始需+1
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    const milliseconds = String(date.getMilliseconds()).padStart(3, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${milliseconds}`;
  }

  // ====== dbPath getter ======
  get dbPath(): string | null {
    return dMyDataFilePath ?? null;
  }
}

// DBPlan, DBPiece, DBBox, DBLearn 可根据实际定义补充