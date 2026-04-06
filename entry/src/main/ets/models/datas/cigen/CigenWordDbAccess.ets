//
// CigenWordDbAccess.ets
// WordTree (HarmonyOS)
//
// 与 iOS `CigenWordManager.swift` 对齐：表结构、SQL、路径（CBook 优先 / bundle）、打开校验。
// （iOS 文件头曾标注 Excel 工具生成；鸿蒙仅同步数据层逻辑与注释语义。）
//

import { relationalStore } from '@kit.ArkData'
import { ResName, ResPath } from '../../../app/constants/ResPath'
import { CBookDbPath, getCCigenDataName } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookPath'
import { CBookManager } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookManager'
import { AppLanguage } from '../../../common/components/Language/AppLanguage'
import { LanguageManager } from '../../../common/components/Language/LanguageManager'
import { FileUtility } from '../../../common/utils/FileUtility'
import { StringEncoder } from '../../../common/utils/strings/StringEncrypt'
import { DBAccessor } from '../../dbUtils/DBAccessor'
import { DB } from '../../dbUtils/DBConstants'
import { DbPrepareUtils, DBPrepareProtocol } from '../../dbUtils/DBPrepare'
import { ResultSetTool } from '../../dbUtils/ResultSetTool'
import { AppCfgManager } from '../../managers/servercfg/AppCfgManager'
import { CigenWord } from './CigenWord'

// MARK: - Cgcz / CWord / CSameRoot（与 iOS `CigenWordManager` 私有 struct 一致）
export namespace CigenTable {

  export namespace Cgcz {
    export const table = 'Cgcz'
    export const cid   = 'item0'
    export const vid   = 'item1'
    export const desc  = 'item2'
  }

  export namespace CWord {
    export const table    = 'CWord'
    export const idx      = 'item0'
    export const cid      = 'item1'
    export const titleEn  = 'item2'
    export const mnemonic = 'item3'
  }

  export namespace CSameRoot {
    export const table    = 'CSameRoot'
    export const idx      = 'item0'
    export const titleEn  = 'item1'
    export const sameRoot = 'item2'
  }
}

export class CigenWordDbAccess implements DBPrepareProtocol {

  private static instance: CigenWordDbAccess | null = null

  public static get shared(): CigenWordDbAccess {
    if (!CigenWordDbAccess.instance) {
      CigenWordDbAccess.instance = new CigenWordDbAccess()
    }
    return CigenWordDbAccess.instance
  }

  private constructor() {
    void this.init()
  }

  // 语言切换等场景下重新 prepare（与 LanguageManager.resetDatas 配合）
  public async init(): Promise<void> {
    await DbPrepareUtils.prepareDbIfNeeds(this, this.getResPath())
  }

  // 当前语言对应的内置资源（简体 CigenData_Cns / 繁体 CigenData_Cnt）
  private getResPath(): ResPath {
    if (LanguageManager.getCurrentLanguage() === AppLanguage.Traditional) {
      return ResName.Cigen_Cnt
    }
    return ResName.Cigen_Cns
  }

  // 与 iOS `CigenWordManager.cigenDbPath` 一致：总开关 ON 且已下载则走 CBook，否则 bundle 解压路径
  private get dbPath(): string {
    if (AppCfgManager.shared.isCBook_Useable_is_ON()
      && CBookManager.shared.isExistBookDb(getCCigenDataName())) {
      const p = CBookManager.shared.cbookDbPath(getCCigenDataName())
      if (p) {
        return p
      }
    }
    return this.getResPath().filePath
  }

  private get db(): DBAccessor {
    return new DBAccessor(this.dbPath, null, true)
  }

  // DbPrepareUtils：校验目标路径库是否可打开
  async isDbOpenable(dbPath: string): Promise<boolean> {
    const acc = new DBAccessor(dbPath, null, true)
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
    `
    const rows = await acc.getDatas(sql, [1], rs => this.createCigenWordFromRs(rs))

    return rows != null
  }

  // 与 iOS `CigenWordManager.isDbOpenable()` 一致：以 cid=1 能否查到记录为准
  async isCurrentStoreOpenable(): Promise<boolean> {
    return (await this.getCigenWordsByCid(1)) !== null
  }

  /**
   * 下载 CBook 后校验 Cigen 库（与 iOS `CigenWordManager.isOpenable(for:)`：CWord 表 count 大于 0）
   */
  static async isOpenableForDownloadedBaseName(baseName: string): Promise<boolean> {
    const sqlitePath = new CBookDbPath(baseName).sqlite
    if (!sqlitePath || !FileUtility.isFileExistAt(sqlitePath)) {
      return false
    }
    const acc = new DBAccessor(sqlitePath, null, true)
    const n   = await acc.getCount(`SELECT COUNT(*) FROM ${CigenTable.CWord.table}`, [])
    return n > 0
  }

  // 根据英文查词根（多表联查列别名与 iOS 一致，避免重名）
  async getCigenWordsByText(enText: string): Promise<Array<CigenWord> | null> {
    const encoded = StringEncoder.encodedToBase64(enText)
    if (!encoded) {
      return null
    }

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
    `

    return await this.db.getDatas(sql, [encoded], rs => this.createCigenWordFromRs(rs))
  }

  async getCigenWordsByCid(cid: number): Promise<Array<CigenWord> | null> {
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
    `

    return await this.db.getDatas(sql, [cid], rs => this.createCigenWordFromRs(rs))
  }

  async getSameRootStringByText(enText: string): Promise<string | null> {
    const encoded = StringEncoder.encodedToBase64(enText)
    if (!encoded) {
      return null
    }

    const sql = `
      SELECT ${CigenTable.CSameRoot.sameRoot}
      FROM ${CigenTable.CSameRoot.table}
      WHERE SUBSTR(
        ${CigenTable.CSameRoot.titleEn},
        ${DB.salt + 1},
        LENGTH(${CigenTable.CSameRoot.titleEn}) - ${DB.salt}
      ) = ?
    `

    return await this.db.getData(
      sql,
      [encoded],
      rs => ResultSetTool.decodeString(rs, CigenTable.CSameRoot.sameRoot)
    )
  }

  private createCigenWordFromRs(rs: relationalStore.ResultSet): CigenWord {
    const word = new CigenWord()

    word.idx      = rs.getLong(rs.getColumnIndex('CWord_idx'))
    word.cid      = rs.getLong(rs.getColumnIndex('CWord_cid'))
    word.vid      = rs.getLong(rs.getColumnIndex('Cgcz_vid'))
    word.titleEn  = ResultSetTool.decodeString(rs, 'CWord_titleEn')
    word.mnemonic = ResultSetTool.decodeString(rs, 'CWord_mnemonic')
    word.desc     = ResultSetTool.decodeString(rs, 'Cgcz_desc')

    return word
  }
}
