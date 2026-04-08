// WordDbAccess.ets
import relationalStore from '@ohos.data.relationalStore';
import { dAppEBookFolderPath } from '../../../app/constants/AppDefines';
import { ResName, ResPath } from '../../../app/constants/ResPath';
import { DebugLog } from '../../../app/debug/DebugLog';
import { AppLanguage } from '../../../common/components/Language/AppLanguage';
import { LanguageManager } from '../../../common/components/Language/LanguageManager';
import { CBookManager } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookManager';
import { FileUtility } from '../../../common/utils/FileUtility';
import { StringEncoder } from '../../../common/utils/strings/StringEncrypt';
import { DBAccessor, ParamType } from '../../dbUtils/DBAccessor';
import { DB } from '../../dbUtils/DBConstants';
import { DBPrepareProtocol, DbPrepareUtils } from '../../dbUtils/DBPrepare';
import { ResultSetTool } from '../../dbUtils/ResultSetTool';
import { AppCfgManager } from '../../managers/servercfg/AppCfgManager';
import { Part, Unit } from '../model/Part_Unit';
import { Word } from './Word';
import { WordDetail } from './WordDetail';

export namespace WordTable {
  export const Table_Name         = "Word";
  export const TableOnline_Name   = "WordOnlineTemp";

  export namespace Col {
    export const IDX          = "item0";
    export const PARTID       = "item1";
    export const PARTNAME     = "item2";
    export const UNITID       = "item3";
    export const UNITNAME     = "item4";
    export const UNITNO       = "item5";
    export const TITLEEN      = "item6";
    export const PRONEN       = "item7";
    export const PRONUS       = "item8";
    export const TITLECN1     = "item9";
    export const TITLECN2     = "item10";
    export const TITLECN3     = "item11";
    export const WORDIMAGE    = "item12";
    export const WORDCHANGE   = "item13";
    export const SYNWORDS     = "item14";
    export const ASYNWORDS    = "item15";
    export const EXAMPLEEN1   = "item16";
    export const EXAMPLECN1   = "item17";
    export const EXAMPLEEN2   = "item18";
    export const EXAMPLECN2   = "item19";
    export const EXAMPLEEN3   = "item20";
    export const EXAMPLECN3   = "item21";
    export const USEDPHRASE   = "item22";
    export const EN2EN        = "item23";
    export const DISCRIMINATE = "item24";
  }
}

// 与 Android `WordManager.WordPartUnitInfo` 字段一致；iOS 侧同名 API 仅返回 partName/unitName 用于弹窗，鸿蒙与 Android 一并带出 id 便于扩展

export interface WordPartUnitInfo {
  partId   : number
  partName : string
  unitId   : number
  unitName : string
}

export class WordDbAccess implements DBPrepareProtocol {
  private textDb: string | null;
  // private db: DBAccessor | null = null;

  constructor(textDb: string | null) {
    this.textDb = textDb;

    if (this.resDb) {
      //this.db = new DBAccessor(this.resDb.filePath, null);
    }

    this.init();
  }

  private get dbPath(): string | null {
    if (!this.textDb) {
      return null
    }

    /// 使用CBook的开关是否是ON， 并且 下载的Cbook是否存在
    if (AppCfgManager.shared.isCBook_Useable_is_ON()
      && CBookManager.shared.isExistBookDb(this.textDb)){
      return CBookManager.shared.cbookDbPath(this.textDb)
    }

    // 本地 EBook：`textDb` 为 baseName（如 ebook_1001），路径与 iOS `EBookManager.textDb(for:)` / Android `EBookManager.textDbPath` 一致（仅用 AppDefines，避免与 EBookManager 循环引用）
    const ebookSqlitePath = `${dAppEBookFolderPath}${this.textDb}.sqlite`
    if (FileUtility.isFileExistAt(ebookSqlitePath)) {
      return ebookSqlitePath
    }

    return this.resDb?.filePath ?? null
  }

  private get db(): DBAccessor {
    return new DBAccessor(this.dbPath, null);
  }

  private get resDb(): ResPath | null {
    return this.textDb ? ResName.allDatabases.find((it) => it.name === this.textDb) ?? null : null;
  }

  private async init(){
    if (this.resDb) {
      await DbPrepareUtils.prepareDbIfNeeds(this, this.resDb)
    }
  }

  async isDbOpenable(): Promise<boolean> {
    const word = await this.getWordById(1);
    return word !== null;
  }

  async getWordById(id: number): Promise<Word | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${WordTable.Table_Name} WHERE ${WordTable.Col.IDX} = ?`;
    return await this.db.getData(sql, [id], (rs: relationalStore.ResultSet) => this.createWordFromResultSet(rs));
  }

  async getAllWords(): Promise<Word[] | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${WordTable.Table_Name}`;
    return await this.db.getDatas(sql, [], (rs: relationalStore.ResultSet) => this.createWordFromResultSet(rs));
  }

  async getWordsByPartId(partId: number): Promise<Word[] | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${WordTable.Table_Name} WHERE ${WordTable.Col.PARTID} = ?`;
    return await this.db.getDatas(sql, [partId], (rs: relationalStore.ResultSet) => this.createWordFromResultSet(rs));
  }

  async getWordsByUnitId(unitId: number): Promise<Word[] | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${WordTable.Table_Name} WHERE ${WordTable.Col.UNITID} = ?`;
    return await this.db.getDatas(sql, [unitId], (rs: relationalStore.ResultSet) => this.createWordFromResultSet(rs));
  }


  async getWordsCount(): Promise<number> {
    if (!this.db) return 0;
    const sql = `SELECT COUNT(*) FROM ${WordTable.Table_Name}`;
    return await this.db.getCount(sql);
  }

  async getWordsCountByPart(partId: number): Promise<number> {
    if (!this.db) return 0;
    const sql = `SELECT COUNT(*) FROM ${WordTable.Table_Name} WHERE ${WordTable.Col.PARTID} = ?`;
    return await this.db.getCount(sql, [partId]);
  }

  async getWordsCountByUnit(unitId: number): Promise<number> {
    if (!this.db) return 0;
    const sql = `SELECT COUNT(*) FROM ${WordTable.Table_Name} WHERE ${WordTable.Col.UNITID} = ?`;
    return await this.db.getCount(sql, [unitId]);
  }

  async getWordDetailByTitleEn(titleEn: string | null): Promise<WordDetail | null> {
    if (!this.db || !titleEn) return null;

    const titleEnBase64 = StringEncoder.encodedToBase64(titleEn)
    if (!titleEnBase64) return null;


    const sql = `SELECT * FROM ${WordTable.Table_Name}
                  WHERE
                    SUBSTR(${WordTable.Col.TITLEEN}, ${DB.salt} + 1, LENGTH(${WordTable.Col.TITLEEN}) - ${DB.salt})
                  = ? LIMIT 1`;
    return await this.db.getData(sql, [titleEnBase64], (rs: relationalStore.ResultSet) => this.createWordDetailFromResultSet(rs));
  }

  async getAllCnTexts(): Promise<Record<string, string>[] | null> {
    if (!this.db) return [];

    const sql = `
    SELECT
      ${WordTable.Col.TITLEEN},
      ${WordTable.Col.TITLECN1},
      ${WordTable.Col.TITLECN2},
      ${WordTable.Col.TITLECN3}
    FROM ${WordTable.Table_Name}
  `;

    return await this.db.getDatas(
      sql,
      [],
      (rs: relationalStore.ResultSet): Record<string, string> => {
        const map: Record<string, string> = {};

        try {
          map['titleEn']  = ResultSetTool.decodeString(rs, WordTable.Col.TITLEEN)  ?? '';
          map['titleCn1'] = ResultSetTool.decodeString(rs, WordTable.Col.TITLECN1) ?? '';
          map['titleCn2'] = ResultSetTool.decodeString(rs, WordTable.Col.TITLECN2) ?? '';
          map['titleCn3'] = ResultSetTool.decodeString(rs, WordTable.Col.TITLECN3) ?? '';
        } catch (error) {
          DebugLog.e(`WordDbAccess.getAllCnTexts 解析失败: ${error}`);
        }

        return map;
      }
    );
  }

  private createWordFromResultSet(rs: relationalStore.ResultSet): Word {
    const word = new Word();

    try {
      word.idx      = rs.getLong(rs.getColumnIndex(WordTable.Col.IDX));
      word.partId   = rs.getLong(rs.getColumnIndex(WordTable.Col.PARTID));
      word.partName = ResultSetTool.decodeString(rs, WordTable.Col.PARTNAME);
      word.unitId   = rs.getLong(rs.getColumnIndex(WordTable.Col.UNITID));
      word.unitName = ResultSetTool.decodeString(rs, WordTable.Col.UNITNAME);
      word.unitNo   = rs.getLong(rs.getColumnIndex(WordTable.Col.UNITNO));
      word.titleEn  = ResultSetTool.decodeString(rs, WordTable.Col.TITLEEN);
      word.pronEn   = ResultSetTool.decodeString(rs, WordTable.Col.PRONEN);
      word.pronUs   = ResultSetTool.decodeString(rs, WordTable.Col.PRONUS);
      word.titleCn1 = ResultSetTool.decodeString(rs, WordTable.Col.TITLECN1);
      word.exampleEn1 = ResultSetTool.decodeString(rs, WordTable.Col.EXAMPLEEN1);
      word.exampleCn1 = ResultSetTool.decodeString(rs, WordTable.Col.EXAMPLECN1);

      if (!word.unitName) {
        word.unitName = `Unit${word.unitId}`
      }

    } catch (error) {
      DebugLog.e(`WordDbAccess: 创建Word对象失败 - ${error}`);
    }

    return word;
  }

  /**
   * 在指定路径创建一个仅包含 Word 表的空数据库（供 EBook 使用）。
   * 与 iOS `WordManager.createEBookDbIfNeeded(at:)`、Android `WordManager.createEBookDbIfNeeded` 一致；
   * 表结构与本文 `WordTable` 及本类其它查询所用列名完全一致（item0 ~ item24）。
   * 访问方式：使用 `DBAccessor` + `updateDb`，与本类实例方法通过 `this.db` 访问的风格一致（此处为指定路径的可写连接）。
   *
   * @param path sqlite 文件完整路径（如 …/EBookDatas/ebook_1001.sqlite）
   * @returns 执行建表 DDL 成功为 true（与 iOS 在 `updateDb` 后不额外校验即返回 true 的策略对齐；失败时 `updateDb` 返回 false）
   */
  static async createEBookDbIfNeeded(path: string): Promise<boolean> {
    const access = new DBAccessor(path, null, false)
    const sql =
      `CREATE TABLE IF NOT EXISTS "${WordTable.Table_Name}"(` +
        `"${WordTable.Col.IDX}" INTEGER,` +
        `"${WordTable.Col.PARTID}" INTEGER,` +
        `"${WordTable.Col.PARTNAME}" TEXT,` +
        `"${WordTable.Col.UNITID}" INTEGER,` +
        `"${WordTable.Col.UNITNAME}" TEXT,` +
        `"${WordTable.Col.UNITNO}" INTEGER,` +
        `"${WordTable.Col.TITLEEN}" TEXT,` +
        `"${WordTable.Col.PRONEN}" TEXT,` +
        `"${WordTable.Col.PRONUS}" TEXT,` +
        `"${WordTable.Col.TITLECN1}" TEXT,` +
        `"${WordTable.Col.TITLECN2}" TEXT,` +
        `"${WordTable.Col.TITLECN3}" TEXT,` +
        `"${WordTable.Col.WORDIMAGE}" TEXT,` +
        `"${WordTable.Col.WORDCHANGE}" TEXT,` +
        `"${WordTable.Col.SYNWORDS}" TEXT,` +
        `"${WordTable.Col.ASYNWORDS}" TEXT,` +
        `"${WordTable.Col.EXAMPLEEN1}" TEXT,` +
        `"${WordTable.Col.EXAMPLECN1}" TEXT,` +
        `"${WordTable.Col.EXAMPLEEN2}" TEXT,` +
        `"${WordTable.Col.EXAMPLECN2}" TEXT,` +
        `"${WordTable.Col.EXAMPLEEN3}" TEXT,` +
        `"${WordTable.Col.EXAMPLECN3}" TEXT,` +
        `"${WordTable.Col.USEDPHRASE}" TEXT,` +
        `"${WordTable.Col.EN2EN}" TEXT,` +
        `"${WordTable.Col.DISCRIMINATE}" TEXT` +
        `)`
    return await access.updateDb(sql)
  }

  private createWordDetailFromResultSet(rs: relationalStore.ResultSet): WordDetail {
    const wordDetail = new WordDetail();

    try {
      wordDetail.idx        = rs.getLong(rs.getColumnIndex(WordTable.Col.IDX));
      wordDetail.partId     = rs.getLong(rs.getColumnIndex(WordTable.Col.PARTID));
      wordDetail.partName   = ResultSetTool.decodeString(rs, WordTable.Col.PARTNAME);
      wordDetail.unitId     = rs.getLong(rs.getColumnIndex(WordTable.Col.UNITID));
      wordDetail.unitName   = ResultSetTool.decodeString(rs, WordTable.Col.UNITNAME);
      wordDetail.unitNo     = rs.getLong(rs.getColumnIndex(WordTable.Col.UNITNO));
      wordDetail.titleEn    = ResultSetTool.decodeString(rs, WordTable.Col.TITLEEN);
      wordDetail.pronEn     = ResultSetTool.decodeString(rs, WordTable.Col.PRONEN);
      wordDetail.pronUs     = ResultSetTool.decodeString(rs, WordTable.Col.PRONUS);
      wordDetail.titleCn1   = ResultSetTool.decodeString(rs, WordTable.Col.TITLECN1);
      wordDetail.titleCn2   = ResultSetTool.decodeString(rs, WordTable.Col.TITLECN2);
      wordDetail.titleCn3   = ResultSetTool.decodeString(rs, WordTable.Col.TITLECN3);
      wordDetail.wordImage  = ResultSetTool.decodeString(rs, WordTable.Col.WORDIMAGE);
      wordDetail.wordChange = ResultSetTool.decodeString(rs, WordTable.Col.WORDCHANGE);
      wordDetail.synWords   = ResultSetTool.decodeString(rs, WordTable.Col.SYNWORDS);
      wordDetail.asynWords  = ResultSetTool.decodeString(rs, WordTable.Col.ASYNWORDS);
      wordDetail.exampleEn1 = ResultSetTool.decodeString(rs, WordTable.Col.EXAMPLEEN1);
      wordDetail.exampleCn1 = ResultSetTool.decodeString(rs, WordTable.Col.EXAMPLECN1);
      wordDetail.exampleEn2 = ResultSetTool.decodeString(rs, WordTable.Col.EXAMPLEEN2);
      wordDetail.exampleCn2 = ResultSetTool.decodeString(rs, WordTable.Col.EXAMPLECN2);
      wordDetail.exampleEn3 = ResultSetTool.decodeString(rs, WordTable.Col.EXAMPLEEN3);
      wordDetail.exampleCn3 = ResultSetTool.decodeString(rs, WordTable.Col.EXAMPLECN3);
      wordDetail.usedPhrase = ResultSetTool.decodeString(rs, WordTable.Col.USEDPHRASE);
      wordDetail.en2En      = ResultSetTool.decodeString(rs, WordTable.Col.EN2EN);
      wordDetail.discriminate = ResultSetTool.decodeString(rs, WordTable.Col.DISCRIMINATE);

      if (!wordDetail.unitName) {
        wordDetail.unitName = `Unit${wordDetail.unitId}`
      }

    } catch (error) {
      DebugLog.e(`WordDbAccess: 创建WordDetail对象失败 - ${error}`);
    }

    return wordDetail;
  }

  /** 与 iOS `WordManager.getWordsCount(inTextDbAt:)` 一致：`path` 为 textDb.sqlite 完整路径 */
  static async getWordsCountInTextDbAt(path: string): Promise<number> {
    const accessor = new DBAccessor(path, null)
    const sql = `SELECT COUNT(*) FROM ${WordTable.Table_Name}`
    return await accessor.getCount(sql, [])
  }

  /** 与 iOS `WordManager.getUnitsCount(inTextDbAt:)` 一致 */
  static async getUnitsCountInTextDbAt(path: string): Promise<number> {
    const accessor = new DBAccessor(path, null)
    const sql = `SELECT COUNT(DISTINCT ${WordTable.Col.UNITID}) FROM ${WordTable.Table_Name}`
    return await accessor.getCount(sql, [])
  }

  /**
   * 将在线词条写入指定 textDb.sqlite 的 Word 表（EBook 加词）。
   * @param path  textDb 完整路径
   * @param word  词条详情（通常来自 `OnlineWord.asWordDetail()`）
   * @returns     是否执行成功
   */
  static async insertOrReplaceWordDetailAtTextDbPath(path: string, word: WordDetail): Promise<boolean> {

    const titleEn = word.titleEn

    if (titleEn === null || titleEn === undefined || titleEn.length < 1) {
      return false
    }

    const titleEnBase64: string | null = word.titleEnEncodeToBase64

    if (titleEnBase64 === null) {
      return false
    }

    const titleRow: string | null = word.titleEnEncodeAndAddSalt

    if (titleRow === null) {
      return false
    }

    const accessor = new DBAccessor(path, null, false)
    const maxIdx   = await accessor.getMax(WordTable.Col.IDX, WordTable.Table_Name)
    const nextIdx  = maxIdx + 1

    word.idx       = nextIdx
    word.partId    = 1
    word.partName  = '默认'
    word.unitId    = 1
    word.unitName  = '默认'
    word.unitNo    = 1

    const sqlDelete: string = `
        DELETE FROM ${WordTable.Table_Name}
        WHERE SUBSTR(
            ${WordTable.Col.TITLEEN},
            ${DB.salt} + 1,
            LENGTH(${WordTable.Col.TITLEEN}) - ${DB.salt}
        ) = ?
    `;

    const sqlInsert: string = `
        INSERT INTO ${WordTable.Table_Name} (
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
      titleRow,
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
      StringEncoder.encodeAndAddSalt(word.exampleCn1),
      StringEncoder.encodeAndAddSalt(word.exampleEn2),
      StringEncoder.encodeAndAddSalt(word.exampleCn2),
      StringEncoder.encodeAndAddSalt(word.exampleEn3),
      StringEncoder.encodeAndAddSalt(word.exampleCn3),
      StringEncoder.encodeAndAddSalt(word.usedPhrase),
      StringEncoder.encodeAndAddSalt(word.en2En),
      StringEncoder.encodeAndAddSalt(word.discriminate)
    ];

    const ok1 = await accessor.updateDb(sqlDelete, [titleEnBase64])
    const ok2 = await accessor.updateDb(sqlInsert, paramsInsert)

    return ok1 && ok2
  }

  /// 指定 textDb 下全部 Part（与 iOS `WordManager.getAllParts(inTextDbAt:)` 一致）
  static async getAllParts(inTextDbAt: string): Promise<Part[]> {

    const accessor = new DBAccessor(inTextDbAt, null)
    const sql      = `
      SELECT DISTINCT
        ${WordTable.Col.PARTID},
        ${WordTable.Col.PARTNAME}
      FROM ${WordTable.Table_Name}
      ORDER BY ${WordTable.Col.PARTID} ASC
    `

    const list = await accessor.getDatas(sql, [], (rs: relationalStore.ResultSet): Part => {

      const part       = new Part()
      part.partId      = rs.getLong(rs.getColumnIndex(WordTable.Col.PARTID))
      part.partName    = ResultSetTool.decodeString(rs, WordTable.Col.PARTNAME) ?? `Part${part.partId}`

      return part
    }) ?? []

    const seen   = new Set<number>()
    const result : Part[] = []

    for (const p of list) {

      if (!seen.has(p.partId)) {
        seen.add(p.partId)
        result.push(p)
      }
    }

    return result
  }

  /// 指定 textDb 下某 Part 的全部 Unit（与 iOS `WordManager.getUnitsByPartId(_:inTextDbAt:)` 一致）
  static async getUnitsByPartId(partId: number, inTextDbAt: string): Promise<Unit[]> {

    const accessor = new DBAccessor(inTextDbAt, null)
    const sql      = `
      SELECT DISTINCT
        ${WordTable.Col.UNITID},
        ${WordTable.Col.UNITNAME},
        ${WordTable.Col.PARTID}
      FROM ${WordTable.Table_Name}
      WHERE ${WordTable.Col.PARTID} = ?
      ORDER BY ${WordTable.Col.UNITID} ASC
    `

    const list = await accessor.getDatas(sql, [partId], (rs: relationalStore.ResultSet): Unit => {

      const unit       = new Unit()
      unit.unitId      = rs.getLong(rs.getColumnIndex(WordTable.Col.UNITID))
      unit.unitName    = ResultSetTool.decodeString(rs, WordTable.Col.UNITNAME) ?? `Unit${unit.unitId}`
      unit.partId      = rs.getLong(rs.getColumnIndex(WordTable.Col.PARTID))

      return unit
    }) ?? []

    const seen   = new Set<number>()
    const result : Unit[] = []

    for (const u of list) {

      if (!seen.has(u.unitId)) {
        seen.add(u.unitId)
        result.push(u)
      }
    }

    return result
  }

  /// 指定 textDb 下最大 PartId（与 iOS `WordManager.getMaxPartId(inTextDbAt:)` 一致）
  static async getMaxPartId(inTextDbAt: string): Promise<number> {

    const accessor = new DBAccessor(inTextDbAt, null)

    return await accessor.getMax(WordTable.Col.PARTID, WordTable.Table_Name)
  }

  /// 指定 textDb 下最大 UnitId（与 iOS `WordManager.getMaxUnitId(inTextDbAt:)` 一致）
  static async getMaxUnitId(inTextDbAt: string): Promise<number> {

    const accessor = new DBAccessor(inTextDbAt, null)

    return await accessor.getMax(WordTable.Col.UNITID, WordTable.Table_Name)
  }

  /// 某 Unit 单词数（与 iOS `WordManager.getWordsCountByUnitId(_:inTextDbAt:)` 一致）
  static async getWordsCountByUnitId(unitId: number, inTextDbAt: string): Promise<number> {

    const accessor = new DBAccessor(inTextDbAt, null)
    const sql      = `SELECT COUNT(*) FROM ${WordTable.Table_Name} WHERE ${WordTable.Col.UNITID} = ?`

    return await accessor.getCount(sql, [unitId])
  }

  /// 按英文查重（与 Android `WordManager.getWordPartUnitIfExists` / iOS `getWordPartUnitIfExists` 一致；`WHERE` 与 iOS 相同 SUBSTR+Base64，`SELECT` 四列与 Android 一致）
  static async getWordPartUnitIfExists(titleEn: string, inTextDbAt: string): Promise<WordPartUnitInfo | null> {

    const trimmed = titleEn.trim()

    if (trimmed.length < 1) {
      return null
    }

    const titleEnBase64 = StringEncoder.encodedToBase64(trimmed)

    if (titleEnBase64 === null) {
      return null
    }

    const accessor = new DBAccessor(inTextDbAt, null)
    const sql      = `
      SELECT
        ${WordTable.Col.PARTID},
        ${WordTable.Col.PARTNAME},
        ${WordTable.Col.UNITID},
        ${WordTable.Col.UNITNAME}
      FROM ${WordTable.Table_Name}
      WHERE SUBSTR(
        ${WordTable.Col.TITLEEN},
        ${DB.salt} + 1,
        LENGTH(${WordTable.Col.TITLEEN}) - ${DB.salt}
      ) = ?
      LIMIT 1
    `

    return await accessor.getData(sql, [titleEnBase64], (rs: relationalStore.ResultSet): WordPartUnitInfo => {

      const partId   = rs.getLong(rs.getColumnIndex(WordTable.Col.PARTID))
      const unitId   = rs.getLong(rs.getColumnIndex(WordTable.Col.UNITID))
      const partName = ResultSetTool.decodeString(rs, WordTable.Col.PARTNAME) ?? ''
      const unitName = ResultSetTool.decodeString(rs, WordTable.Col.UNITNAME) ?? ''

      return {
        partId   : partId,
        partName : partName,
        unitId   : unitId,
        unitName : unitName
      }
    })
  }

  /// 写入指定 textDb 的 Word 表（与 iOS `WordManager.insertWordDetail(_:intoTextDbAt:)` 一致；成功后刷新书本统计）
  static async insertWordDetail(detail: WordDetail, intoTextDbAt: string): Promise<boolean> {

    const titleEn = detail.titleEn

    if (titleEn === null || titleEn === undefined || titleEn.length < 1) {
      return false
    }

    const titleEnBase64: string | null = detail.titleEnEncodeToBase64

    if (titleEnBase64 === null) {
      return false
    }

    const titleRow: string | null = detail.titleEnEncodeAndAddSalt

    if (titleRow === null) {
      return false
    }

    const accessor = new DBAccessor(intoTextDbAt, null, false)
    const nextIdx  = (await accessor.getMax(WordTable.Col.IDX, WordTable.Table_Name)) + 1

    const sqlDelete = `
      DELETE FROM ${WordTable.Table_Name}
      WHERE SUBSTR(
        ${WordTable.Col.TITLEEN},
        ${DB.salt} + 1,
        LENGTH(${WordTable.Col.TITLEEN}) - ${DB.salt}
      ) = ?
    `

    const sqlInsert = `
      INSERT INTO ${WordTable.Table_Name} (
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
    `

    const params = [
      nextIdx,
      detail.partId ?? 1,
      StringEncoder.encodeAndAddSalt(detail.partName),
      detail.unitId ?? 1,
      StringEncoder.encodeAndAddSalt(detail.unitName),
      detail.unitNo ?? 1,
      titleRow,
      StringEncoder.encodeAndAddSalt(detail.pronEn),
      StringEncoder.encodeAndAddSalt(detail.pronUs),
      StringEncoder.encodeAndAddSalt(detail.titleCn1),
      StringEncoder.encodeAndAddSalt(detail.titleCn2),
      StringEncoder.encodeAndAddSalt(detail.titleCn3),
      StringEncoder.encodeAndAddSalt(detail.wordImage),
      StringEncoder.encodeAndAddSalt(detail.wordChange),
      StringEncoder.encodeAndAddSalt(detail.synWords),
      StringEncoder.encodeAndAddSalt(detail.asynWords),
      StringEncoder.encodeAndAddSalt(detail.exampleEn1),
      StringEncoder.encodeAndAddSalt(detail.exampleCn1),
      StringEncoder.encodeAndAddSalt(detail.exampleEn2),
      StringEncoder.encodeAndAddSalt(detail.exampleCn2),
      StringEncoder.encodeAndAddSalt(detail.exampleEn3),
      StringEncoder.encodeAndAddSalt(detail.exampleCn3),
      StringEncoder.encodeAndAddSalt(detail.usedPhrase),
      StringEncoder.encodeAndAddSalt(detail.en2En),
      StringEncoder.encodeAndAddSalt(detail.discriminate)
    ]

    const okDelete = await accessor.updateDb(sqlDelete, [titleEnBase64])
    const okInsert = await accessor.updateDb(sqlInsert, params)

    if (!okDelete || !okInsert) {
      return false
    }

    // 动态 import，避免 `WordDbAccess` ↔ `BookManager` 静态循环依赖（与 `Word.ets` 引 EWordManager 一致）
    const bm = await import('../book/BookManager')
    await bm.BookManager.shared.refreshBookCounts(intoTextDbAt)

    return true
  }

  /**
   * 与 iOS `WordManager.updateWordField`：更新 EBook textDb 中 Word 表指定列（列名为 item8～item24 等）。
   * @param textDbPath  textDb.sqlite 完整路径
   * @param titleEn     单词英文（未编码）
   * @param fieldKey    列名，须为 Word 表中已存在列（与 `EWordEditableField` 的 raw 值一致）
   * @param value       新明文值（内部会做 encodeAndAddSalt）
   */
  static async updateWordField(textDbPath: string, titleEn: string, fieldKey: string, value: string): Promise<boolean> {
    const allowed: string[] = [
      WordTable.Col.PRONEN,
      WordTable.Col.PRONUS,
      WordTable.Col.TITLECN1,
      WordTable.Col.TITLECN2,
      WordTable.Col.TITLECN3,
      WordTable.Col.WORDIMAGE,
      WordTable.Col.WORDCHANGE,
      WordTable.Col.SYNWORDS,
      WordTable.Col.ASYNWORDS,
      WordTable.Col.EXAMPLEEN1,
      WordTable.Col.EXAMPLECN1,
      WordTable.Col.EXAMPLEEN2,
      WordTable.Col.EXAMPLECN2,
      WordTable.Col.EXAMPLEEN3,
      WordTable.Col.EXAMPLECN3,
      WordTable.Col.USEDPHRASE,
      WordTable.Col.EN2EN,
      WordTable.Col.DISCRIMINATE
    ]

    // 非法列名直接拒绝，避免 SQL 注入
    if (allowed.indexOf(fieldKey) < 0) {
      return false
    }

    const titleEnEncoded: string | null = StringEncoder.encodedToBase64(titleEn)

    // titleEn 无法 Base64 编码则无法匹配 WHERE 条件
    if (!titleEnEncoded) {
      return false
    }

    const encodedValue: string | null = StringEncoder.encodeAndAddSalt(value)

    if (encodedValue === null) {
      return false
    }

    const sql =
      `UPDATE ${WordTable.Table_Name} SET "${fieldKey}" = ? WHERE SUBSTR(` +
      `${WordTable.Col.TITLEEN}, ${DB.salt} + 1, LENGTH(${WordTable.Col.TITLEEN}) - ${DB.salt}` +
      `) = ?`
    const accessor = new DBAccessor(textDbPath, null, false)

    // 执行 UPDATE（与 insertWordDetail 相同的 SUBSTR+Base64 匹配方式）
    return await accessor.updateDb(sql, [encodedValue, titleEnEncoded])
  }
}