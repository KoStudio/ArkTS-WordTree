import { dMyDataFilePath, dMyDataFolderPath } from "../../../app/constants/AppDefines";
import { createFolderIfNeeds } from "../../../app/constants/AppFunctions";
import { DBAccessor, ParamType } from "../../dbUtils/DBAccessor";
import { relationalStore } from "@kit.ArkData";
import { WordUser } from "./WordUser";
import { ResultSetTool } from "../../dbUtils/ResultSetTool";
import { SearchConstants } from "../model/SearchManager";

// MARK: - 数据表常量
namespace Tables {

  // WordUser 表
  export namespace WordUser {
    export const NAME              = "WordUser";
    export namespace Col {
      export const ID               = "id";
      export const DELETED          = "deleted";
      export const FAVORITE_LEVEL   = "favoriteLevel";
      export const LEARN_TIMES      = "learnTimes";
      export const CORRECTED_TIMES  = "correctedTimes";
      export const WRANG_TIMES      = "wrangTimes";
      export const LAST_RESULT_TYPE = "lastResultType";
      export const WRANG_YEAR       = "wrangYear";
      export const WRANG_MONTH      = "wrangMonth";
      export const WRANG_DAY        = "wrangDay";
      export const MEMO             = "memo";
    }
  }

  // DeleteWord 表
  export namespace DeleteWord {
    export const NAME               = "DeleteWord";
    export namespace Col {
      export const ID               = "id";
      export const DELETED          = "deleted";
    }
  }

}


// MARK: - WordUser 数据库访问类
export class WordUserDbAccess {

  private static instance: WordUserDbAccess;
  private db: DBAccessor | null = null;

  // 私有构造函数
  private constructor() {
    createFolderIfNeeds(dMyDataFolderPath);
    this.db = new DBAccessor(dMyDataFilePath, null, false);
    this.createDbIfNeeds();
  }

  // 获取单例
  public static get shared(): WordUserDbAccess {
    if (!WordUserDbAccess.instance) {
      WordUserDbAccess.instance = new WordUserDbAccess();
    }
    return WordUserDbAccess.instance;
  }

  refreshDb(): void {
    this.createDbIfNeeds();
  }

  // ====== 创建表 ======
  private createDbIfNeeds(): void {
    if (!this.db) return;

    const sqlWordUser = `CREATE TABLE IF NOT EXISTS ${Tables.WordUser.NAME} (
      ${Tables.WordUser.Col.ID} INTEGER PRIMARY KEY,
      ${Tables.WordUser.Col.FAVORITE_LEVEL} INTEGER DEFAULT 0,
      ${Tables.WordUser.Col.LEARN_TIMES} INTEGER DEFAULT 0,
      ${Tables.WordUser.Col.CORRECTED_TIMES} INTEGER DEFAULT 0,
      ${Tables.WordUser.Col.WRANG_TIMES} INTEGER DEFAULT 0,
      ${Tables.WordUser.Col.LAST_RESULT_TYPE} INTEGER DEFAULT 0,
      ${Tables.WordUser.Col.WRANG_YEAR} INTEGER DEFAULT 0,
      ${Tables.WordUser.Col.WRANG_MONTH} INTEGER DEFAULT 0,
      ${Tables.WordUser.Col.WRANG_DAY} INTEGER DEFAULT 0,
      ${Tables.WordUser.Col.MEMO} TEXT
    )`;

    const sqlDeleteWord = `CREATE TABLE IF NOT EXISTS ${Tables.DeleteWord.NAME} (
      ${Tables.DeleteWord.Col.ID} INTEGER PRIMARY KEY,
      ${Tables.DeleteWord.Col.DELETED} INTEGER DEFAULT 0
    )`;

    this.db.updateDb(sqlWordUser);
    this.db.updateDb(sqlDeleteWord);
  }

  // ====== 插入/更新 ======
  async saveWordUser(wordUser: WordUser): Promise<void> {
    if (!this.db) return;

    const sql = `REPLACE INTO ${Tables.WordUser.NAME} (
      ${Tables.WordUser.Col.ID},
      ${Tables.WordUser.Col.FAVORITE_LEVEL},
      ${Tables.WordUser.Col.LEARN_TIMES},
      ${Tables.WordUser.Col.CORRECTED_TIMES},
      ${Tables.WordUser.Col.WRANG_TIMES},
      ${Tables.WordUser.Col.LAST_RESULT_TYPE},
      ${Tables.WordUser.Col.WRANG_YEAR},
      ${Tables.WordUser.Col.WRANG_MONTH},
      ${Tables.WordUser.Col.WRANG_DAY},
      ${Tables.WordUser.Col.MEMO}
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

    const params: ParamType[] = [
      wordUser.id,
      wordUser.favoriteLevel ?? 0,
      wordUser.learnTimes ?? 0,
      wordUser.correctedTimes ?? 0,
      wordUser.wrangTimes ?? 0,
      wordUser.lastResultType ?? 0,
      wordUser.wrangYear ?? 0,
      wordUser.wrangMonth ?? 0,
      wordUser.wrangDay ?? 0,
      wordUser.memo
    ];

    await this.db.updateDb(sql, params);

    // 更新或插入到 DeleteWord 表
    const sqlDeleteWord = `REPLACE INTO ${Tables.DeleteWord.NAME} (${Tables.DeleteWord.Col.ID}, ${Tables.DeleteWord.Col.DELETED}) VALUES (?, ?)`;
    const deletedStatus = wordUser.deleted ? 1 : 0;
    await this.db.updateDb(sqlDeleteWord, [wordUser.id, deletedStatus]);
  }

  // ====== 查询 ======
  async getWordUserById(id: number): Promise<WordUser | null> {
    if (!this.db) return null;

    // 使用 FULL OUTER JOIN 查询 WordUser 和 DeleteWord 表，确保即使 DeleteWord 中没有数据也能返回 WordUser 记录
    const sql = `SELECT wu.*, dw.${Tables.DeleteWord.Col.DELETED}
               FROM ${Tables.WordUser.NAME} wu
               FULL OUTER JOIN ${Tables.DeleteWord.NAME} dw
               ON wu.${Tables.WordUser.Col.ID} = dw.${Tables.DeleteWord.Col.ID}
               WHERE wu.${Tables.WordUser.Col.ID} = ?`;

    const result = await this.db.getData(sql, [id], (rs: relationalStore.ResultSet) =>
    this.createWordUserFromResultSet(rs)
    );

    return result;
  }

  async getAllWordUsers(): Promise<WordUser[] | null> {
    if (!this.db) return null;

    // 使用 FULL OUTER JOIN 查询 WordUser 和 DeleteWord 表，确保返回所有 WordUser 记录
    const sql = `SELECT wu.*, dw.${Tables.DeleteWord.Col.DELETED}
               FROM ${Tables.WordUser.NAME} wu
               FULL OUTER JOIN ${Tables.DeleteWord.NAME} dw
               ON wu.${Tables.WordUser.Col.ID} = dw.${Tables.DeleteWord.Col.ID}
               ORDER BY wu.${Tables.WordUser.Col.ID}`;

    const result = await this.db.getDatas(sql, [], (rs: relationalStore.ResultSet) =>
    this.createWordUserFromResultSet(rs)
    );

    return result;
  }

  // ====== 删除 ======
  async deleteWordUser(id: number): Promise<void> {
    if (!this.db) return;

    const sql = `DELETE FROM ${Tables.WordUser.NAME} WHERE ${Tables.WordUser.Col.ID} = ?`;
    await this.db.updateDb(sql, [id]);

    // 删除 DeleteWord 表中的记录
    const sqlDeleteWord = `DELETE FROM ${Tables.DeleteWord.NAME} WHERE ${Tables.DeleteWord.Col.ID} = ?`;
    await this.db.updateDb(sqlDeleteWord, [id]);
  }

  // ====== DeleteWord 表操作 ======
  async setWordDeletedStatus(id: number, deleted: boolean): Promise<void> {
    if (!this.db) return;

    if (deleted) {
      const sql = `REPLACE INTO ${Tables.DeleteWord.NAME} (${Tables.DeleteWord.Col.ID}, ${Tables.DeleteWord.Col.DELETED}) VALUES (?, ?)`;
      await this.db.updateDb(sql, [id, WordUser.Deleted_Yes]);
    } else {
      const sql = `DELETE FROM ${Tables.DeleteWord.NAME} WHERE ${Tables.DeleteWord.Col.ID} = ?`;
      await this.db.updateDb(sql, [id]);
    }
  }

  async isWordDeleted(id: number): Promise<boolean> {
    if (!this.db) return false;

    const sql = `SELECT ${Tables.DeleteWord.Col.DELETED} FROM ${Tables.DeleteWord.NAME} WHERE ${Tables.DeleteWord.Col.ID} = ?`;
    const result = await this.db.getData(sql, [id], (rs: relationalStore.ResultSet) => {
      const idx = rs.getColumnIndex(Tables.DeleteWord.Col.DELETED);
      return idx >= 0 ? rs.getLong(idx) === WordUser.Deleted_Yes : false;
    });

    return result ?? false;
  }

  async clearDeletedWords(): Promise<void> {
    if (!this.db) return;

    const sql = `DELETE FROM ${Tables.DeleteWord.NAME}`;
    await this.db.updateDb(sql, []);
  }
  // ====== 清空学习次数 ======
  async clearLearnTimes(): Promise<void> {
    if (!this.db) return;

    const sql = `UPDATE ${Tables.WordUser.NAME} SET ${Tables.WordUser.Col.LEARN_TIMES} = 0`;
    await this.db.updateDb(sql);
  }

  // ====== 清空测试结果 ======
  async clearTestResults(): Promise<void> {
    if (!this.db) return;

    const sql = `UPDATE ${Tables.WordUser.NAME}
    SET ${Tables.WordUser.Col.CORRECTED_TIMES} = 0,
        ${Tables.WordUser.Col.WRANG_TIMES} = 0,
        ${Tables.WordUser.Col.LAST_RESULT_TYPE} = ?`;

    await this.db.updateDb(sql, [SearchConstants.TEST_RESULT_NONE]);
  }

  // ====== 清空备忘录 ======
  async clearMemos(): Promise<void> {
    if (!this.db) return;

    const sql = `UPDATE ${Tables.WordUser.NAME} SET ${Tables.WordUser.Col.MEMO} = ''`;
    await this.db.updateDb(sql);
  }

  // ====== 清空收藏等级 ======
  async clearFavorites(): Promise<void> {
    if (!this.db) return;

    const sql = `UPDATE ${Tables.WordUser.NAME} SET ${Tables.WordUser.Col.FAVORITE_LEVEL} = ?`;
    await this.db.updateDb(sql, [SearchConstants.FAVORITE_LEVEL_0]);
  }

  // ====== 清空复习列表 ======
  async clearReviewList(): Promise<void> {
    if (!this.db) return;

    const sql = `UPDATE ${Tables.WordUser.NAME} SET ${Tables.WordUser.Col.LAST_RESULT_TYPE} = ?`;
    await this.db.updateDb(sql, [SearchConstants.TEST_RESULT_NONE]);
  }

  // ====== ResultSet 转对象 ======
  private createWordUserFromResultSet(rs: relationalStore.ResultSet): WordUser {
    const data                          = new WordUser();
    data.id                             = rs.getLong(rs.getColumnIndex(Tables.WordUser.Col.ID));
    data.favoriteLevel                  = rs.getLong(rs.getColumnIndex(Tables.WordUser.Col.FAVORITE_LEVEL));
    data.learnTimes                     = rs.getLong(rs.getColumnIndex(Tables.WordUser.Col.LEARN_TIMES));
    data.correctedTimes                 = rs.getLong(rs.getColumnIndex(Tables.WordUser.Col.CORRECTED_TIMES));
    data.wrangTimes                     = rs.getLong(rs.getColumnIndex(Tables.WordUser.Col.WRANG_TIMES));
    data.lastResultType                 = rs.getLong(rs.getColumnIndex(Tables.WordUser.Col.LAST_RESULT_TYPE));
    data.wrangYear                      = rs.getLong(rs.getColumnIndex(Tables.WordUser.Col.WRANG_YEAR));
    data.wrangMonth                     = rs.getLong(rs.getColumnIndex(Tables.WordUser.Col.WRANG_MONTH));
    data.wrangDay                       = rs.getLong(rs.getColumnIndex(Tables.WordUser.Col.WRANG_DAY));
    data.memo                           = rs.getString(rs.getColumnIndex(Tables.WordUser.Col.MEMO));

    // 处理 deleted 字段
    const deletedIdx                    = rs.getColumnIndex(Tables.DeleteWord.Col.DELETED);
    data.deleted                        = deletedIdx >= 0 && rs.getLong(deletedIdx) === 1; // 如果存在删除字段并且值为 1，则表示已删除

    return data;
  }



}