// WordDbAccess.ets
import relationalStore from '@ohos.data.relationalStore';
import { ResName, ResPath } from '../../../app/constants/ResPath';
import { DebugLog } from '../../../app/debug/DebugLog';
import { AppLanguage } from '../../../common/components/Language/AppLanguage';
import { LanguageManager } from '../../../common/components/Language/LanguageManager';
import { StringEncoder } from '../../../common/utils/strings/StringEncrypt';
import { DBAccessor } from '../../dbUtils/DBAccessor';
import { DbPrepareUtils } from '../../dbUtils/DBPrepare';
import { ResultSetTool } from '../../dbUtils/ResultSetTool';
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

export class WordDbAccess {
  private static instance: WordDbAccess | null = null;
  private db: DBAccessor | null = null;

  public static get shared(): WordDbAccess {
    if (!WordDbAccess.instance) {
      WordDbAccess.instance = new WordDbAccess();
    }
    return WordDbAccess.instance;
  }

  private constructor() {
    this.init();
  }

  async init() {
    this.db = new DBAccessor(this.dbPath, null, true);
    await DbPrepareUtils.prepareDbIfNeeds(this, this.getResPath());
  }

  private get dbPath(): string {
    return this.getResPath().filePath;
  }

  private getResPath(): ResPath {
    return LanguageManager.getCurrentLanguage() === AppLanguage.Traditional
      ? ResName.Word_Cnt
      : ResName.Word_Cns;
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


    const sql = `SELECT * FROM ${WordTable.Table_Name} WHERE ${WordTable.Col.TITLEEN} = ? LIMIT 1`;
    return await this.db.getData(sql, [titleEnBase64], (rs: relationalStore.ResultSet) => this.createWordDetailFromResultSet(rs));
  }

  private createWordFromResultSet(rs: relationalStore.ResultSet): Word {
    const word = new Word();

    try {
      word.idx      = rs.getLong(rs.getColumnIndex(WordTable.Col.IDX));
      word.partId   = rs.getLong(rs.getColumnIndex(WordTable.Col.PARTID));
      word.partName = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.PARTNAME);
      word.unitId   = rs.getLong(rs.getColumnIndex(WordTable.Col.UNITID));
      word.unitName = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.UNITNAME);
      word.unitNo   = rs.getLong(rs.getColumnIndex(WordTable.Col.UNITNO));
      word.titleEn  = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.TITLEEN);
      word.pronEn   = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.PRONEN);
      word.pronUs   = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.PRONUS);
      word.titleCn1 = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.TITLECN1);
      word.exampleEn1 = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.EXAMPLEEN1);
      word.exampleCn1 = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.EXAMPLECN1);
    } catch (error) {
      DebugLog.e(`WordDbAccess: 创建Word对象失败 - ${error}`);
    }

    return word;
  }

  private createWordDetailFromResultSet(rs: relationalStore.ResultSet): WordDetail {
    const wordDetail = new WordDetail();

    try {
      wordDetail.idx        = rs.getLong(rs.getColumnIndex(WordTable.Col.IDX));
      wordDetail.partId     = rs.getLong(rs.getColumnIndex(WordTable.Col.PARTID));
      wordDetail.partName   = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.PARTNAME);
      wordDetail.unitId     = rs.getLong(rs.getColumnIndex(WordTable.Col.UNITID));
      wordDetail.unitName   = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.UNITNAME);
      wordDetail.unitNo     = rs.getLong(rs.getColumnIndex(WordTable.Col.UNITNO));
      wordDetail.titleEn    = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.TITLEEN);
      wordDetail.pronEn     = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.PRONEN);
      wordDetail.pronUs     = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.PRONUS);
      wordDetail.titleCn1   = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.TITLECN1);
      wordDetail.titleCn2   = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.TITLECN2);
      wordDetail.titleCn3   = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.TITLECN3);
      wordDetail.wordImage  = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.WORDIMAGE);
      wordDetail.wordChange = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.WORDCHANGE);
      wordDetail.synWords   = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.SYNWORDS);
      wordDetail.asynWords  = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.ASYNWORDS);
      wordDetail.exampleEn1 = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.EXAMPLEEN1);
      wordDetail.exampleCn1 = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.EXAMPLECN1);
      wordDetail.exampleEn2 = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.EXAMPLEEN2);
      wordDetail.exampleCn2 = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.EXAMPLECN2);
      wordDetail.exampleEn3 = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.EXAMPLEEN3);
      wordDetail.exampleCn3 = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.EXAMPLECN3);
      wordDetail.usedPhrase = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.USEDPHRASE);
      wordDetail.en2En      = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.EN2EN);
      wordDetail.discriminate = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.DISCRIMINATE);
    } catch (error) {
      DebugLog.e(`WordDbAccess: 创建WordDetail对象失败 - ${error}`);
    }

    return wordDetail;
  }
}