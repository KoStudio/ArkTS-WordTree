import { dMyDataFilePath, dMyDataFolderPath } from "../../../app/constants/AppDefines";
import { createFolderIfNeeds } from "../../../app/constants/AppFunctions";
import { DBAccessor, ParamType } from "../../dbUtils/DBAccessor";
import { relationalStore } from "@kit.ArkData";
import { WordUser } from "./WordUser";
import { ResultSetTool } from "../../dbUtils/ResultSetTool";
import { SearchConstants } from "../model/SearchManager";
import { DebugLog } from "../../../app/debug/DebugLog";
import { DateUtils } from "../../../common/utils/DateUtils";
import { AppUtility } from "../../../common/utils/AppUtility";
import { StringEncoder } from "../../../common/utils/strings/StringEncrypt";
import { DB } from "../../dbUtils/DBConstants";
import { WordDetail } from "../word/WordDetail";
import { WordTable } from "../word/WordDbAccess";

export namespace Tables {

  // MARK: - Learn 表
  export namespace Learn {
    export const NAME = "Learn"

    export namespace Col {
      export const TITLE_EN        = "titleEn"
      export const LEARN_TIMES     = "learnTimes"
      export const CORRECTED_TIMES = "correctedTimes"
      export const WRANG_TIMES     = "wrangTimes"
      export const FAVORITE_LEVEL  = "favoriteLevel"
      export const LAST_RESULT     = "lastResult"
      export const WRANG_DATE      = "wrangDate"
      export const UNIT_ID         = "unitId"
      export const PART_ID         = "partId"
      export const MEMO            = "memo"
      export const SHARE_MEMOS     = "shareMemos"
    }
  }

  // MARK: - DeleteWord 表
  export namespace DeleteWord {
    export const NAME = "DeleteWord"

    export namespace Col {
      export const TITLE_EN = "titleEn"
      export const DELETED  = "deleted"
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

  // MARK: - 创建表（完全等价 Java createLearnDbIfNeeded）
  private createDbIfNeeds(): void {
    if (!this.db) return

    const sqlLearn = `
      CREATE TABLE IF NOT EXISTS ${Tables.Learn.NAME} (
        ${Tables.Learn.Col.TITLE_EN}        TEXT PRIMARY KEY NOT NULL,
        ${Tables.Learn.Col.LEARN_TIMES}     INTEGER NOT NULL,
        ${Tables.Learn.Col.CORRECTED_TIMES} INTEGER NOT NULL,
        ${Tables.Learn.Col.WRANG_TIMES}     INTEGER NOT NULL,
        ${Tables.Learn.Col.FAVORITE_LEVEL}  INTEGER NOT NULL,
        ${Tables.Learn.Col.LAST_RESULT}     INTEGER NOT NULL,
        ${Tables.Learn.Col.WRANG_DATE}      TIMESTAMP,
        ${Tables.Learn.Col.UNIT_ID}         INTEGER NOT NULL,
        ${Tables.Learn.Col.PART_ID}         INTEGER NOT NULL,
        ${Tables.Learn.Col.MEMO}            TEXT,
        ${Tables.Learn.Col.SHARE_MEMOS}     TEXT
      )
    `

    const sqlDeleteWord = `
      CREATE TABLE IF NOT EXISTS ${Tables.DeleteWord.NAME} (
        ${Tables.DeleteWord.Col.TITLE_EN} TEXT PRIMARY KEY NOT NULL,
        ${Tables.DeleteWord.Col.DELETED}  INTEGER NOT NULL
      )
    `

    const sqlWordTable = `
      CREATE TABLE IF NOT EXISTS ${WordTable.TableOnline_Name} (
        ${WordTable.Col.IDX}          INTEGER,
        ${WordTable.Col.PARTID}      INTEGER,
        ${WordTable.Col.PARTNAME}    TEXT,
        ${WordTable.Col.UNITID}      INTEGER,
        ${WordTable.Col.UNITNAME}    TEXT,
        ${WordTable.Col.UNITNO}      INTEGER,
        ${WordTable.Col.TITLEEN}     TEXT,
        ${WordTable.Col.PRONEN}      TEXT,
        ${WordTable.Col.PRONUS}      TEXT,
        ${WordTable.Col.TITLECN1}    TEXT,
        ${WordTable.Col.TITLECN2}    TEXT,
        ${WordTable.Col.TITLECN3}    TEXT,
        ${WordTable.Col.WORDIMAGE}   TEXT,
        ${WordTable.Col.WORDCHANGE}  TEXT,
        ${WordTable.Col.SYNWORDS}    TEXT,
        ${WordTable.Col.ASYNWORDS}   TEXT,
        ${WordTable.Col.EXAMPLEEN1}  TEXT,
        ${WordTable.Col.EXAMPLECN1}  TEXT,
        ${WordTable.Col.EXAMPLEEN2}  TEXT,
        ${WordTable.Col.EXAMPLECN2}  TEXT,
        ${WordTable.Col.EXAMPLEEN3}  TEXT,
        ${WordTable.Col.EXAMPLECN3}  TEXT,
        ${WordTable.Col.USEDPHRASE}  TEXT,
        ${WordTable.Col.EN2EN}        TEXT,
        ${WordTable.Col.DISCRIMINATE} TEXT
      )
    `

    try {
      this.db.updateDb(sqlLearn)
      this.db.updateDb(sqlDeleteWord)
      this.db.updateDb(sqlWordTable)
    } catch (e) {
      DebugLog.e(`LearnDbAccess >>> createDbIfNeeds: ${e}`)
    }
  }

  // ====== 插入/更新 ======
  async saveWordUser(wordUser: WordUser): Promise<void> {
    if (!this.db) return;

    const sql = `
      REPLACE INTO ${Tables.Learn.NAME} (
        ${Tables.Learn.Col.TITLE_EN},
        ${Tables.Learn.Col.LEARN_TIMES},
        ${Tables.Learn.Col.CORRECTED_TIMES},
        ${Tables.Learn.Col.WRANG_TIMES},
        ${Tables.Learn.Col.FAVORITE_LEVEL},
        ${Tables.Learn.Col.LAST_RESULT},
        ${Tables.Learn.Col.WRANG_DATE},
        ${Tables.Learn.Col.UNIT_ID},
        ${Tables.Learn.Col.PART_ID},
        ${Tables.Learn.Col.MEMO},
        ${Tables.Learn.Col.SHARE_MEMOS}
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `

    const params: ParamType[] = [
      wordUser.titleEnEncodeToBase64, //未加盐的base64编码字符做为UserData主键
      wordUser.learnTimes,
      wordUser.correctedTimes,
      wordUser.wrangTimes,
      wordUser.favoriteLevel,
      wordUser.lastResultType,
      DateUtils.toFullString(wordUser.wrangDate || new Date()),
      wordUser.unitId,
      wordUser.partId,
      wordUser.memo,
      AppUtility.getJsonFromList(wordUser.shareMemos)
    ]

    await this.db.updateDb(sql, params);


  }

  // MARK: - 插入或更新删除单词数据（对应Java的insertOrRemoveDeleteWordDataForWord）
  // async insertOrRemoveDeleteWordDataForWord(wordUser: WordUser): Promise<void> {
  //   if (!this.db) return;
  //
  //   let sql: string;
  //   let params: ParamType[];
  //
  //   if (wordUser.deleted) {
  //     // 插入或更新
  //     sql = `REPLACE INTO ${Tables.DeleteWord.NAME} (
  //       ${Tables.DeleteWord.Col.TITLE_EN},
  //       ${Tables.DeleteWord.Col.DELETED}
  //     ) VALUES(?, ?)`;
  //
  //     params = [
  //       wordUser.titleEnEncodeToBase64, //未加盐的base64编码字符做为UserData主键
  //       WordUser.Deleted_Yes
  //     ];
  //   } else {
  //     // 移除
  //     sql = `DELETE FROM ${Tables.DeleteWord.NAME}
  //            WHERE ${Tables.DeleteWord.Col.TITLE_EN} = ?`;
  //
  //     params = [wordUser.titleEnEncodeToBase64];//未加盐的base64编码字符做为UserData主键
  //   }
  //
  //   try {
  //     await this.db.updateDb(sql, params);
  //   } catch (e) {
  //     DebugLog.e(`WordUserDbAccess >>> insertOrRemoveDeleteWordDataForWord: ${e}`);
  //   }
  // }

  /**
   * 插入或更新 WordTable 数据
   * 逻辑：
   * 1. 根据 titleEn（Base64，不加盐）先删除旧数据
   * 2. 再插入完整 WordTable 记录
   */
  async insertOrUpdateOnlineDataForWord(word: WordDetail): Promise<void> {
    if (!this.db) return;

    const titleEn: string | null = word.titleEn;
    if (!titleEn) return;

    // 仅 Base64 编码（不加盐）
    const titleEnBase64: string | null = word.titleEnEncodeToBase64;
    if (!titleEnBase64) return;

    // ============================================================
    // MARK: - 删除旧数据
    // ============================================================
    const sqlDelete: string = `
        DELETE FROM ${WordTable.TableOnline_Name}
        WHERE SUBSTR(
            ${WordTable.Col.TITLEEN},
            ${DB.salt} + 1,
            LENGTH(${WordTable.Col.TITLEEN}) - ${DB.salt}
        ) = ?
    `;

    const paramsDelete: ParamType[] = [
      titleEnBase64 // 仅 Base64 编码
    ];

    // ============================================================
    // MARK: - 插入新数据
    // ============================================================
    const sqlInsert: string = `
        INSERT INTO ${WordTable.TableOnline_Name} (
            ${WordTable.Col.IDX},
            ${WordTable.Col.PARTID},
            ${WordTable.Col.PARTNAME},
            ${WordTable.Col.UNITID},
            ${WordTable.Col.UNITNAME},
            ${WordTable.Col.UNITNO},
            ${WordTable.Col.TITLEEN},
            ${WordTable.Col.PRONEN},
            ${WordTable.Col.PRONUS},
            ${WordTable.Col.TITLECN1},
            ${WordTable.Col.TITLECN2},
            ${WordTable.Col.TITLECN3},
            ${WordTable.Col.WORDIMAGE},
            ${WordTable.Col.WORDCHANGE},
            ${WordTable.Col.SYNWORDS},
            ${WordTable.Col.ASYNWORDS},
            ${WordTable.Col.EXAMPLEEN1},
            ${WordTable.Col.EXAMPLECN1},
            ${WordTable.Col.EXAMPLEEN2},
            ${WordTable.Col.EXAMPLECN2},
            ${WordTable.Col.EXAMPLEEN3},
            ${WordTable.Col.EXAMPLECN3},
            ${WordTable.Col.USEDPHRASE},
            ${WordTable.Col.EN2EN},
            ${WordTable.Col.DISCRIMINATE}
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    `;

    const paramsInsert: ParamType[] = [
      word.idx,
      word.partId,
      StringEncoder.encodeAndAddSalt(word.partName),
      word.unitId,
      StringEncoder.encodeAndAddSalt(word.unitName),
      word.unitNo,
      word.titleEnEncodeToBase64, // 加密 + 加盐（与 Word 表统一）
      StringEncoder.encodeAndAddSalt(word.pronEn),
      StringEncoder.encodeAndAddSalt(word.pronUs),
      StringEncoder.encodeAndAddSalt(word.titleCn1),
      StringEncoder.encodeAndAddSalt(word.titleCn2),
      StringEncoder.encodeAndAddSalt(word.titleCn3),
      StringEncoder.encodeAndAddSalt(word.wordImage),
      StringEncoder.encodeAndAddSalt(word.wordChange),
      StringEncoder.encodeAndAddSalt(word.synWords),
      StringEncoder.encodeAndAddSalt(word.asynWords),
      StringEncoder.encodeAndAddSalt(word.exampleEn1),
      StringEncoder.encodeAndAddSalt(word.titleCn1),
      StringEncoder.encodeAndAddSalt(word.exampleEn2),
      StringEncoder.encodeAndAddSalt(word.exampleCn2),
      StringEncoder.encodeAndAddSalt(word.exampleEn3),
      StringEncoder.encodeAndAddSalt(word.exampleCn3),
      StringEncoder.encodeAndAddSalt(word.usedPhrase),
      StringEncoder.encodeAndAddSalt(word.en2En),
      StringEncoder.encodeAndAddSalt(word.discriminate)
    ];

    // ============================================================
    // MARK: - 执行
    // ============================================================
    try {
      DebugLog.d(sqlDelete);
      DebugLog.d(JSON.stringify(paramsDelete));

      await this.db.updateDb(sqlDelete, paramsDelete);

      DebugLog.d(sqlInsert);
      DebugLog.d(JSON.stringify(paramsInsert));

      await this.db.updateDb(sqlInsert, paramsInsert);
    } catch (e) {
      DebugLog.e(`WordDbAccess >>> insertOrUpdateOnlineDataForWord: ${e}`);
    }
  }

  public async resetWordTables(): Promise<void> {
    if (!this.db) return;
    // ------------------------------------------------------------
    // 保留收藏的单词
    // TODO: 保留记录 & 记忆单词
    // ------------------------------------------------------------

    const salt = DB.salt;

    const sql = `
                DELETE FROM ${WordTable.TableOnline_Name}
                WHERE SUBSTR(${WordTable.Col.TITLEEN}, ${salt} + 1, LENGTH(${WordTable.Col.TITLEEN}) - ${salt})
                    NOT IN (
                        SELECT SUBSTR(a.${WordTable.Col.TITLEEN}, ${salt} + 1, LENGTH(a.${WordTable.Col.TITLEEN}) - ${salt})
                        FROM ${WordTable.TableOnline_Name} a
                        LEFT JOIN ${Tables.Learn.NAME} b
                            ON SUBSTR(a.${WordTable.Col.TITLEEN}, ${salt} + 1, LENGTH(a.${WordTable.Col.TITLEEN}) - ${salt})
                               = b.${Tables.Learn.Col.TITLE_EN}
                        WHERE b.${Tables.Learn.Col.FAVORITE_LEVEL} > 0
                    )
                `;

    await this.db.updateDb(sql, []);
  }

  // ====== 查询 ======
  async getWordUserByTitleEn(titleEn: string): Promise<WordUser | null> {
    if (!this.db) return null;

    const titleEnBase64 = StringEncoder.encodedToBase64(titleEn)
    if (!titleEnBase64) return null;

    const sql = `SELECT wu.*, dw.${Tables.DeleteWord.Col.DELETED}
                 FROM ${Tables.Learn.NAME} wu
                 LEFT JOIN ${Tables.DeleteWord.NAME} dw
                 ON wu.${Tables.Learn.Col.TITLE_EN} = dw.${Tables.DeleteWord.Col.TITLE_EN}
                 WHERE wu.${Tables.Learn.Col.TITLE_EN} = ?`;

    const result = await this.db.getData(sql, [titleEnBase64], (rs: relationalStore.ResultSet) =>
    this.createWordUserFromResultSet(rs)
    );

    return result;
  }


  async getAllWordUsers(): Promise<WordUser[] | null> {
    if (!this.db) return null;

    const sql = `SELECT wu.*, dw.${Tables.DeleteWord.Col.DELETED}
                 FROM ${Tables.Learn.NAME} wu
                 LEFT JOIN ${Tables.DeleteWord.NAME} dw
                 ON wu.${Tables.Learn.Col.TITLE_EN} = dw.${Tables.DeleteWord.Col.TITLE_EN}
                 ORDER BY wu.${Tables.Learn.Col.TITLE_EN}`;

    const result = await this.db.getDatas(sql, [], (rs: relationalStore.ResultSet) =>
    this.createWordUserFromResultSet(rs)
    );

    return result;
  }

  // ====== 删除 ======
  async deleteWordUser(titleEn: string): Promise<void> {
    if (!this.db) return;

    const titleEnBase64 = StringEncoder.encodedToBase64(titleEn)
    if (!titleEnBase64) return;

    const sql = `DELETE FROM ${Tables.Learn.NAME} WHERE ${Tables.Learn.Col.TITLE_EN} = ?`;
    await this.db.updateDb(sql, [titleEnBase64]);

    // 删除 DeleteWord 表中的记录
    const sqlDeleteWord = `DELETE FROM ${Tables.DeleteWord.NAME} WHERE ${Tables.DeleteWord.Col.TITLE_EN} = ?`;
    await this.db.updateDb(sqlDeleteWord, [titleEnBase64]);
  }

  // ====== DeleteWord 表操作 ======
  async setWordDeletedStatus(titleEn: string | null, deleted: boolean): Promise<void> {
    if (!this.db) return;
    if (!titleEn) return

    const titleEnBase64 = StringEncoder.encodedToBase64(titleEn)
    if (!titleEnBase64) return;

    if (deleted) {
      const sql = `REPLACE INTO ${Tables.DeleteWord.NAME} (${Tables.DeleteWord.Col.TITLE_EN}, ${Tables.DeleteWord.Col.DELETED}) VALUES (?, ?)`;
      await this.db.updateDb(sql, [titleEnBase64, WordUser.Deleted_Yes]);
    } else {
      const sql = `DELETE FROM ${Tables.DeleteWord.NAME} WHERE ${Tables.DeleteWord.Col.TITLE_EN} = ?`;
      await this.db.updateDb(sql, [titleEnBase64]);
    }
  }

  async isWordDeleted(titleEn: string): Promise<boolean> {
    if (!this.db) return false;

    const titleEnBase64 = StringEncoder.encodedToBase64(titleEn)
    if (!titleEnBase64) return false;

    const sql = `SELECT ${Tables.DeleteWord.Col.DELETED} FROM ${Tables.DeleteWord.NAME} WHERE ${Tables.DeleteWord.Col.TITLE_EN} = ?`;
    const result = await this.db.getData(sql, [titleEnBase64], (rs: relationalStore.ResultSet) => {
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

    const sql = `UPDATE ${Tables.Learn.NAME} SET ${Tables.Learn.Col.LEARN_TIMES} = 0`;
    await this.db.updateDb(sql);
  }

  // ====== 清空测试结果 ======
  async clearTestResults(): Promise<void> {
    if (!this.db) return;

    const sql = `UPDATE ${Tables.Learn.NAME}
    SET ${Tables.Learn.Col.CORRECTED_TIMES} = 0,
        ${Tables.Learn.Col.WRANG_TIMES} = 0,
        ${Tables.Learn.Col.LAST_RESULT} = ?`;

    await this.db.updateDb(sql, [SearchConstants.TEST_RESULT_NONE]);
  }

  // ====== 清空备忘录 ======
  async clearMemos(): Promise<void> {
    if (!this.db) return;

    const sql = `UPDATE ${Tables.Learn.NAME} SET ${Tables.Learn.Col.MEMO} = '', ${Tables.Learn.Col.SHARE_MEMOS} = ''`;
    await this.db.updateDb(sql);
  }

  // ====== 清空收藏等级 ======
  async clearFavorites(): Promise<void> {
    if (!this.db) return;

    const sql = `UPDATE ${Tables.Learn.NAME} SET ${Tables.Learn.Col.FAVORITE_LEVEL} = ?`;
    await this.db.updateDb(sql, [SearchConstants.FAVORITE_LEVEL_0]);
  }

  // ====== 清空复习列表 ======
  async clearReviewList(): Promise<void> {
    if (!this.db) return;

    const sql = `UPDATE ${Tables.Learn.NAME} SET ${Tables.Learn.Col.LAST_RESULT} = ?`;
    await this.db.updateDb(sql, [SearchConstants.TEST_RESULT_NONE]);
  }

  // ====== ResultSet 转对象 ======


  // ====== ResultSet 转对象 ======
  private createWordUserFromResultSet(rs: relationalStore.ResultSet): WordUser {
    const data = new WordUser();

    // ============================================================
    // MARK: - 基本属性
    // ============================================================
    data.titleEn        = ResultSetTool.decodeStringOnlyBase64(rs, Tables.Learn.Col.TITLE_EN)//rs.getString(rs.getColumnIndex(Tables.Learn.Col.TITLE_EN)) || "";
    data.favoriteLevel  = rs.getLong  (rs.getColumnIndex(Tables.Learn.Col.FAVORITE_LEVEL));
    data.learnTimes     = rs.getLong  (rs.getColumnIndex(Tables.Learn.Col.LEARN_TIMES));
    data.correctedTimes = rs.getLong  (rs.getColumnIndex(Tables.Learn.Col.CORRECTED_TIMES));
    data.wrangTimes     = rs.getLong  (rs.getColumnIndex(Tables.Learn.Col.WRANG_TIMES));
    data.lastResultType = rs.getLong  (rs.getColumnIndex(Tables.Learn.Col.LAST_RESULT));
    data.unitId         = rs.getLong  (rs.getColumnIndex(Tables.Learn.Col.UNIT_ID));
    data.partId         = rs.getLong  (rs.getColumnIndex(Tables.Learn.Col.PART_ID));

    data.wrangDate      = ResultSetTool.getDate(rs, Tables.Learn.Col.WRANG_DATE)

    data.memo           = rs.getString(rs.getColumnIndex(Tables.Learn.Col.MEMO));

    const shareMemosStr = rs.getString(rs.getColumnIndex(Tables.Learn.Col.SHARE_MEMOS));
    data.shareMemos     = AppUtility.getListFromJson(shareMemosStr);


    const deletedIdx    = rs.getColumnIndex(Tables.DeleteWord.Col.DELETED);
    data.deleted        = deletedIdx >= 0 && rs.getLong(deletedIdx) === WordUser.Deleted_Yes;

    return data;
  }


}