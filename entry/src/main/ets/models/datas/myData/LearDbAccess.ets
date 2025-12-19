// // ============================================================
// // Learn 数据库表结构定义
// // ============================================================
// import { Learn } from "./Learn"
// import { relationalStore } from "@kit.ArkData"
// import { DebugLog } from "../../../app/debug/DebugLog"
// import { DBAccessor } from "../../dbUtils/DBAccessor"
// import { createFolderIfNeeds } from "../../../app/constants/AppFunctions"
//
// export namespace Tables {
//
//   // MARK: - Learn 表
//   export namespace Learn {
//     export const NAME = "Learn"
//
//     export namespace Col {
//       export const TITLE_EN        = "titleEn"
//       export const LEARN_TIMES     = "learnTimes"
//       export const CORRECTED_TIMES = "correctedTimes"
//       export const WRANG_TIMES     = "wrangTimes"
//       export const FAVORITE_LEVEL  = "favoriteLevel"
//       export const LAST_RESULT     = "lastResult"
//       export const WRANG_DATE      = "wrangDate"
//       export const UNIT_ID         = "unitId"
//       export const PART_ID         = "partId"
//       export const MEMO            = "memo"
//       export const SHARE_MEMOS     = "shareMemos"
//     }
//   }
//
//   // MARK: - DeleteWord 表
//   export namespace DeleteWord {
//     export const NAME = "DeleteWord"
//
//     export namespace Col {
//       export const TITLE_EN = "titleEn"
//       export const DELETED  = "deleted"
//     }
//   }
//
//   // MARK: - OnlineWord 临时表
//   export namespace OnlineWord {
//     export const NAME = "WordOnline"
//
//     export namespace Col {
//       export const IDX            = "idx"
//       export const PART_ID        = "partId"
//       export const PART_NAME      = "partName"
//       export const UNIT_ID        = "unitId"
//       export const UNIT_NAME      = "unitName"
//       export const UNIT_NO        = "unitNo"
//       export const TITLE_EN       = "titleEn"
//       export const PRON_EN        = "pronEn"
//       export const PRON_US        = "pronUs"
//       export const TITLE_CN1      = "titleCn1"
//       export const TITLE_CN2      = "titleCn2"
//       export const TITLE_CN3      = "titleCn3"
//       export const WORD_IMAGE     = "wordImage"
//       export const WORD_CHANGE    = "wordChange"
//       export const SYN_WORDS      = "synWords"
//       export const ASYN_WORDS     = "asynWords"
//       export const EXAMPLE_EN1    = "exampleEn1"
//       export const EXAMPLE_CN1    = "exampleCn1"
//       export const EXAMPLE_EN2    = "exampleEn2"
//       export const EXAMPLE_CN2    = "exampleCn2"
//       export const EXAMPLE_EN3    = "exampleEn3"
//       export const EXAMPLE_CN3    = "exampleCn3"
//       export const USED_PHRASE    = "usedPhrase"
//       export const EN2EN          = "en2en"
//       export const DISCRIMINATE   = "discriminate"
//     }
//   }
// }
//
// export class LearnDbAccess {
//
//   private static instance: LearnDbAccess
//   private db: DBAccessor | null = null
//
//   // MARK: - 构造
//   private constructor() {
//     createFolderIfNeeds(dMyDataFolderPath)
//     this.db = new DBAccessor(dMyDataFilePath, null, false)
//     this.createDbIfNeeds()
//   }
//
//   // MARK: - 单例
//   static get shared(): LearnDbAccess {
//     if (!LearnDbAccess.instance) {
//       LearnDbAccess.instance = new LearnDbAccess()
//     }
//     return LearnDbAccess.instance
//   }
//
//   refreshDb(): void {
//     this.createDbIfNeeds()
//   }
//
//   // MARK: - 创建表（完全等价 Java createLearnDbIfNeeded）
//   private createDbIfNeeds(): void {
//     if (!this.db) return
//
//     const sqlLearn = `
//       CREATE TABLE IF NOT EXISTS ${Tables.Learn.NAME} (
//         ${Tables.Learn.Col.TITLE_EN}        TEXT PRIMARY KEY NOT NULL,
//         ${Tables.Learn.Col.LEARN_TIMES}     INTEGER NOT NULL,
//         ${Tables.Learn.Col.CORRECTED_TIMES} INTEGER NOT NULL,
//         ${Tables.Learn.Col.WRANG_TIMES}     INTEGER NOT NULL,
//         ${Tables.Learn.Col.FAVORITE_LEVEL}  INTEGER NOT NULL,
//         ${Tables.Learn.Col.LAST_RESULT}     INTEGER NOT NULL,
//         ${Tables.Learn.Col.WRANG_DATE}      TIMESTAMP,
//         ${Tables.Learn.Col.UNIT_ID}         INTEGER NOT NULL,
//         ${Tables.Learn.Col.PART_ID}         INTEGER NOT NULL,
//         ${Tables.Learn.Col.MEMO}            TEXT,
//         ${Tables.Learn.Col.SHARE_MEMOS}     TEXT
//       )
//     `
//
//     const sqlDeleteWord = `
//       CREATE TABLE IF NOT EXISTS ${Tables.DeleteWord.NAME} (
//         ${Tables.DeleteWord.Col.TITLE_EN} TEXT PRIMARY KEY NOT NULL,
//         ${Tables.DeleteWord.Col.DELETED}  INTEGER NOT NULL
//       )
//     `
//
//     const sqlOnlineWord = `
//       CREATE TABLE IF NOT EXISTS ${Tables.OnlineWord.NAME} (
//         ${Tables.OnlineWord.Col.IDX}          INTEGER,
//         ${Tables.OnlineWord.Col.PART_ID}      INTEGER,
//         ${Tables.OnlineWord.Col.PART_NAME}    TEXT,
//         ${Tables.OnlineWord.Col.UNIT_ID}      INTEGER,
//         ${Tables.OnlineWord.Col.UNIT_NAME}    TEXT,
//         ${Tables.OnlineWord.Col.UNIT_NO}      INTEGER,
//         ${Tables.OnlineWord.Col.TITLE_EN}     TEXT,
//         ${Tables.OnlineWord.Col.PRON_EN}      TEXT,
//         ${Tables.OnlineWord.Col.PRON_US}      TEXT,
//         ${Tables.OnlineWord.Col.TITLE_CN1}    TEXT,
//         ${Tables.OnlineWord.Col.TITLE_CN2}    TEXT,
//         ${Tables.OnlineWord.Col.TITLE_CN3}    TEXT,
//         ${Tables.OnlineWord.Col.WORD_IMAGE}   TEXT,
//         ${Tables.OnlineWord.Col.WORD_CHANGE}  TEXT,
//         ${Tables.OnlineWord.Col.SYN_WORDS}    TEXT,
//         ${Tables.OnlineWord.Col.ASYN_WORDS}   TEXT,
//         ${Tables.OnlineWord.Col.EXAMPLE_EN1}  TEXT,
//         ${Tables.OnlineWord.Col.EXAMPLE_CN1}  TEXT,
//         ${Tables.OnlineWord.Col.EXAMPLE_EN2}  TEXT,
//         ${Tables.OnlineWord.Col.EXAMPLE_CN2}  TEXT,
//         ${Tables.OnlineWord.Col.EXAMPLE_EN3}  TEXT,
//         ${Tables.OnlineWord.Col.EXAMPLE_CN3}  TEXT,
//         ${Tables.OnlineWord.Col.USED_PHRASE}  TEXT,
//         ${Tables.OnlineWord.Col.EN2EN}        TEXT,
//         ${Tables.OnlineWord.Col.DISCRIMINATE} TEXT
//       )
//     `
//
//     try {
//       this.db.updateDb(sqlLearn)
//       this.db.updateDb(sqlDeleteWord)
//       this.db.updateDb(sqlOnlineWord)
//     } catch (e) {
//       DebugLog.e("LearnDbAccess >>> createDbIfNeeds", `${e}`)
//     }
//   }
//
//   // MARK: - 保存 / 更新 Learn
//   async saveLearn(learn: Learn): Promise<void> {
//     if (!this.db) return
//
//     const sql = `
//       REPLACE INTO ${Tables.Learn.NAME} (
//         ${Tables.Learn.Col.TITLE_EN},
//         ${Tables.Learn.Col.LEARN_TIMES},
//         ${Tables.Learn.Col.CORRECTED_TIMES},
//         ${Tables.Learn.Col.WRANG_TIMES},
//         ${Tables.Learn.Col.FAVORITE_LEVEL},
//         ${Tables.Learn.Col.LAST_RESULT},
//         ${Tables.Learn.Col.WRANG_DATE},
//         ${Tables.Learn.Col.UNIT_ID},
//         ${Tables.Learn.Col.PART_ID},
//         ${Tables.Learn.Col.MEMO},
//         ${Tables.Learn.Col.SHARE_MEMOS}
//       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
//     `
//
//     const params: ParamType[] = [
//       learn.titleEn,
//       learn.learnTimes,
//       learn.correctedTimes,
//       learn.wrangTimes,
//       learn.favoriteLevel,
//       learn.lastResult,
//       learn.wrangDate,
//       learn.unitId,
//       learn.partId,
//       learn.memo,
//       learn.shareMemos
//     ]
//
//     await this.db.updateDb(sql, params)
//   }
//
//   // MARK: - 查询
//   async getLearnByTitleEn(titleEn: string): Promise<Learn | null> {
//     if (!this.db) return null
//
//     const sql = `
//       SELECT * FROM ${Tables.Learn.NAME}
//       WHERE ${Tables.Learn.Col.TITLE_EN} = ?
//     `
//
//     return await this.db.getData(sql, [titleEn], (rs: relationalStore.ResultSet) => {
//       return new Learn({
//         titleEn:        rs.getString(rs.getColumnIndex(Tables.Learn.Col.TITLE_EN)),
//         learnTimes:     rs.getLong(rs.getColumnIndex(Tables.Learn.Col.LEARN_TIMES)),
//         correctedTimes: rs.getLong(rs.getColumnIndex(Tables.Learn.Col.CORRECTED_TIMES)),
//         wrangTimes:     rs.getLong(rs.getColumnIndex(Tables.Learn.Col.WRANG_TIMES)),
//         favoriteLevel:  rs.getLong(rs.getColumnIndex(Tables.Learn.Col.FAVORITE_LEVEL)),
//         lastResult:     rs.getLong(rs.getColumnIndex(Tables.Learn.Col.LAST_RESULT)),
//         wrangDate:      rs.getLong(rs.getColumnIndex(Tables.Learn.Col.WRANG_DATE)),
//         unitId:         rs.getLong(rs.getColumnIndex(Tables.Learn.Col.UNIT_ID)),
//         partId:         rs.getLong(rs.getColumnIndex(Tables.Learn.Col.PART_ID)),
//         memo:           rs.getString(rs.getColumnIndex(Tables.Learn.Col.MEMO)),
//         shareMemos:     rs.getString(rs.getColumnIndex(Tables.Learn.Col.SHARE_MEMOS))
//       })
//     })
//   }
// }