import relationalStore from '@ohos.data.relationalStore';
import { ResName, ResPath } from '../../../app/constants/ResPath';
import { AppLanguage } from '../../../common/components/Language/AppLanguage';
import { LanguageManager } from '../../../common/components/Language/LanguageManager';
import { StringEncoder } from '../../../common/utils/strings/StringEncrypt';
import { DBAccessor } from '../../dbUtils/DBAccessor';
import { DB } from '../../dbUtils/DBConstants';
import { DbPrepareUtils } from '../../dbUtils/DBPrepare';
import { ResultSetTool } from '../../dbUtils/ResultSetTool';
import { BaseWord } from './BaseWord';

// ============================================================
// 数据库表结构定义
// ============================================================
namespace Table {
  export namespace Name {
    export const baseWord = "Word";
  }

  export namespace Col {
    export const idx      = "item0"; // 索引
    export const titleEn  = "item1"; // 英文
    export const pronEn   = "item2"; // 英式发音
    export const pronUs   = "item3"; // 美式发音
    export const titleCn1 = "item4"; // 中文释义1
    export const titleCn2 = "item5"; // 中文释义2
    export const titleCn3 = "item6"; // 中文释义3
  }
}


// ============================================================
// BaseWord 数据库访问类
// ============================================================
export class BaseWordDbAccess {
  private static instance: BaseWordDbAccess | null = null;
  private db: DBAccessor | null = null;

  public static get shared(): BaseWordDbAccess {
    if (!BaseWordDbAccess.instance) {
      BaseWordDbAccess.instance = new BaseWordDbAccess();
    }
    return BaseWordDbAccess.instance;
  }

  private constructor() {
    this.init();
  }

  async init(){
    // 只读数据库，isReadOnly设置为true
    this.db = new DBAccessor(this.dbPath, null, true);
    await DbPrepareUtils.prepareDbIfNeeds(this, this.getResPath());
  }

  private get dbPath(): string {
    return this.getResPath().filePath
  }

  private getResPath(): ResPath{
    if (LanguageManager.getCurrentLanguage() === AppLanguage.Traditional) {
      return ResName.BaseDict_Cnt
    }
    return ResName.BaseDict_Cns
  }


  // ==========================================================
  // 判断数据库能否打开（取第一条记录检查）
  // ==========================================================
  async isDbOpenable(): Promise<boolean> {
    return (await this.getBaseWordById(1)) !== null;
  }

  // ==========================================================
  // 根据 idx 查询 BaseWord
  // ==========================================================
  async getBaseWordById(idx: number): Promise<BaseWord | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${Table.Name.baseWord} WHERE ${Table.Col.idx} = ?`;
    return await this.db.getData(sql, [idx], rs => this.createBaseWordFromRs(rs));
  }

  // ==========================================================
  // 根据英文文本查询 BaseWord（带编码/去盐处理）
  // ==========================================================
  async getBaseWordByText(enText: string): Promise<BaseWord | null> {
    if (!this.db) return null;

    const encodedText = StringEncoder.encodedToBase64(enText);
    if (!encodedText) return null;

    const sql = `
      SELECT *
      FROM ${Table.Name.baseWord}
      WHERE SUBSTR(${Table.Col.titleEn}, ${DB.salt + 1}, LENGTH(${Table.Col.titleEn}) - ${DB.salt}) = ?
    `;
    return await this.db.getData(sql, [encodedText], rs => this.createBaseWordFromRs(rs));
  }

  // ==========================================================
  // 从 ResultSet 创建 BaseWord 对象
  // ==========================================================
  private createBaseWordFromRs(rs: relationalStore.ResultSet): BaseWord {
    const word    = new BaseWord();
    word.idx      = rs.getLong(rs.getColumnIndex(Table.Col.idx));
    word.titleEn  = ResultSetTool.decodeString(rs, Table.Col.titleEn);
    word.pronEn   = ResultSetTool.decodeString(rs, Table.Col.pronEn);
    word.pronUs   = ResultSetTool.decodeString(rs, Table.Col.pronUs);
    word.titleCn1 = ResultSetTool.decodeString(rs, Table.Col.titleCn1);
    word.titleCn2 = ResultSetTool.decodeString(rs, Table.Col.titleCn2);
    word.titleCn3 = ResultSetTool.decodeString(rs, Table.Col.titleCn3);
    return word;
  }

}