import { ResName, ResPath } from "../../../app/constants/ResPath";
import { AppLanguage } from "../../../common/components/Language/AppLanguage";
import { LanguageManager } from "../../../common/components/Language/LanguageManager";
import { StringEncoder } from "../../../common/utils/strings/StringEncrypt";
import { DBAccessor } from "../../dbUtils/DBAccessor";
import { DbPrepareUtils } from "../../dbUtils/DBPrepare";
import { ResultSetTool } from "../../dbUtils/ResultSetTool";
import { CigenWord } from "./CigenWord";
import { relationalStore } from "@kit.ArkData";
import { DB } from "../../dbUtils/DBConstants";

// CigenWordTables.ts
export namespace CigenTable {

  // ============================================================
  // Cgcz 表
  // ============================================================
  export namespace Cgcz {
    export const table     = 'Cgcz';
    export const cid       = 'item0';
    export const vid       = 'item1';
    export const desc      = 'item2';
  }

  // ============================================================
  // CWord 表
  // ============================================================
  export namespace CWord {
    export const table     = 'CWord';
    export const idx       = 'item0';
    export const cid       = 'item1';
    export const titleEn   = 'item2';
    export const mnemonic  = 'item3';
  }

  // ============================================================
  // CSameRoot 表
  // ============================================================
  export namespace CSameRoot {
    export const table     = 'CSameRoot';
    export const idx       = 'item0';
    export const titleEn   = 'item1';
    export const sameRoot  = 'item2';
  }
}


export class CigenWordDbAccess {
  private static instance: CigenWordDbAccess | null = null;
  private db: DBAccessor | null = null;

  public static get shared(): CigenWordDbAccess {
    if (!CigenWordDbAccess.instance) {
      CigenWordDbAccess.instance = new CigenWordDbAccess();
    }
    return CigenWordDbAccess.instance;
  }

  private constructor() {
    this.init();
  }

  async init() {
    // 只读数据库，isReadOnly设置为true
    this.db = new DBAccessor(this.dbPath, null, true);
    await DbPrepareUtils.prepareDbIfNeeds(this, this.getResPath());
  }

  private get dbPath(): string {
    return this.getResPath().filePath;
  }


  private getResPath(): ResPath{
    if (LanguageManager.getCurrentLanguage() === AppLanguage.Traditional) {
      return ResName.Cigen_Cnt
    }
    return ResName.Cigen_Cns
  }

  // ==========================================================
  // 判断数据库能否打开（取第一条记录检查）
  // ==========================================================
  async isDbOpenable(): Promise<boolean> {
    return (await this.getCigenWordsByCid(1)) !== null;
  }
  // ============================================================
  // 根据英文查询词根
  // ============================================================
  async getCigenWordsByText(enText: string): Promise<Array<CigenWord> | null> {
    if (!this.db) return null;

    const encoded = StringEncoder.encodedToBase64(enText);
    if (!encoded) return null;

    const sql = `
      SELECT
        a.${CigenTable.CWord.idx}       AS CWord_idx,
        a.${CigenTable.CWord.cid}       AS CWord_cid,
        a.${CigenTable.CWord.titleEn}   AS CWord_titleEn,
        a.${CigenTable.CWord.mnemonic}  AS CWord_mnemonic,
        b.${CigenTable.Cgcz.vid}        AS Cgcz_vid,
        b.${CigenTable.Cgcz.desc}       AS Cgcz_desc
      FROM ${CigenTable.CWord.table} a
      LEFT JOIN ${CigenTable.Cgcz.table} b
        ON a.${CigenTable.CWord.cid} = b.${CigenTable.Cgcz.cid}
      WHERE SUBSTR(
        a.${CigenTable.CWord.titleEn},
        ${DB.salt + 1},
        LENGTH(a.${CigenTable.CWord.titleEn}) - ${DB.salt}
      ) = ?
    `;

    return await this.db.getDatas(sql, [encoded], rs => this.createCigenWordFromRs(rs));
  }

  // ============================================================
  // 根据 CID 查询
  // ============================================================
  async getCigenWordsByCid(cid: number): Promise<Array<CigenWord> | null> {
    if (!this.db) return null;

    const sql = `
      SELECT
        a.${CigenTable.CWord.idx}       AS CWord_idx,
        a.${CigenTable.CWord.cid}       AS CWord_cid,
        a.${CigenTable.CWord.titleEn}   AS CWord_titleEn,
        a.${CigenTable.CWord.mnemonic}  AS CWord_mnemonic,
        b.${CigenTable.Cgcz.vid}        AS Cgcz_vid,
        b.${CigenTable.Cgcz.desc}       AS Cgcz_desc
      FROM ${CigenTable.CWord.table} a
      LEFT JOIN ${CigenTable.Cgcz.table} b
        ON a.${CigenTable.CWord.cid} = b.${CigenTable.Cgcz.cid}
      WHERE a.${CigenTable.CWord.cid} = ?
    `;

    return await this.db.getDatas(sql, [cid], rs => this.createCigenWordFromRs(rs));
  }

  // ============================================================
  // 同根词描述
  // ============================================================
  async getSameRootStringByText(enText: string): Promise<string | null> {
    if (!this.db) return null;

    const encoded = StringEncoder.encodedToBase64(enText);
    if (!encoded) return null;

    const sql = `
      SELECT ${CigenTable.CSameRoot.sameRoot}
      FROM ${CigenTable.CSameRoot.table}
      WHERE SUBSTR(
        ${CigenTable.CSameRoot.titleEn},
        ${DB.salt + 1},
        LENGTH(${CigenTable.CSameRoot.titleEn}) - ${DB.salt}
      ) = ?
    `;

    return await this.db.getData(
      sql,
      [encoded],
      rs => ResultSetTool.decodeString(rs, CigenTable.CSameRoot.sameRoot)
    );
  }

  // ============================================================
  // ResultSet -> CigenWord
  // ============================================================
  private createCigenWordFromRs(rs: relationalStore.ResultSet): CigenWord {
    const word = new CigenWord();

    word.idx      = rs.getLong(rs.getColumnIndex('CWord_idx'));
    word.cid      = rs.getLong(rs.getColumnIndex('CWord_cid'));
    word.vid      = rs.getLong(rs.getColumnIndex('Cgcz_vid'));
    word.titleEn  = ResultSetTool.decodeString(rs, 'CWord_titleEn');
    word.mnemonic = ResultSetTool.decodeString(rs, 'CWord_mnemonic');
    word.desc     = ResultSetTool.decodeString(rs, 'Cgcz_desc');

    return word;
  }

}