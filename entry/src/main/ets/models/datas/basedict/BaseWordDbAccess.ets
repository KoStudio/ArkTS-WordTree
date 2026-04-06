import relationalStore from '@ohos.data.relationalStore'
import { ResName, ResPath } from '../../../app/constants/ResPath'
import { CBookDbPath, getCBaseDictName } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookPath'
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
import { BaseWord } from './BaseWord'

// 与 iOS `BaseWordManager` 中 `BaseDictTable` 一致
namespace Table {
  export namespace Name {
    export const baseWord = 'Word'
  }

  export namespace Col {
    export const idx      = 'item0'
    export const titleEn  = 'item1'
    export const pronEn   = 'item2'
    export const pronUs   = 'item3'
    export const titleCn1 = 'item4'
    export const titleCn2 = 'item5'
    export const titleCn3 = 'item6'
  }
}

// 与 iOS `BaseWordManager` 对齐：路径优先云端 BaseDict（CBook），否则 bundle 解压路径
export class BaseWordDbAccess implements DBPrepareProtocol {

  private static instance: BaseWordDbAccess | null = null

  public static get shared(): BaseWordDbAccess {
    if (!BaseWordDbAccess.instance) {
      BaseWordDbAccess.instance = new BaseWordDbAccess()
    }
    return BaseWordDbAccess.instance
  }

  private constructor() {
    void this.init()
  }

  // 语言切换等场景下重新 prepare（与 LanguageManager.resetDatas 配合）
  public async init(): Promise<void> {
    await DbPrepareUtils.prepareDbIfNeeds(this, this.getResPath())
  }

  // 当前语言对应的内置资源（简体 BaseDict.sqlite / 繁体 BaseDict_Cnt.sqlite）
  private getResPath(): ResPath {
    if (LanguageManager.getCurrentLanguage() === AppLanguage.Traditional) {
      return ResName.BaseDict_Cnt
    }
    return ResName.BaseDict_Cns
  }

  // 与 iOS `BaseWordManager.baseDictDbPath` 一致：总开关 ON 且已下载则走 CBook 路径，否则 bundle 路径
  private get dbPath(): string {
    if (AppCfgManager.shared.isCBook_Useable_is_ON()
      && CBookManager.shared.isExistBookDb(getCBaseDictName())) {
      const p = CBookManager.shared.cbookDbPath(getCBaseDictName())
      if (p) {
        return p
      }
    }

    return this.getResPath().filePath
  }

  private get db(): DBAccessor {
    return new DBAccessor(this.dbPath, null, true)
  }

  // DbPrepareUtils 校验沙箱库是否可打开
  async isDbOpenable(dbPath: string): Promise<boolean> {
    const acc = new DBAccessor(dbPath, null, true)
    const sql = `SELECT * FROM ${Table.Name.baseWord} WHERE ${Table.Col.idx} = ?`

    const row = await acc.getData(sql, [1], rs => this.createBaseWordFromRs(rs))

    return row !== null
  }

  // 与 iOS `BaseWordManager.isDbOpenable()` 一致：当前路径下能否读到 idx=1
  async isCurrentStoreOpenable(): Promise<boolean> {
    return (await this.getBaseWordById(1)) !== null
  }

  /**
   * 下载 CBook 后校验某 baseName 的 BaseDict 能否打开（与 iOS `BaseWordManager.isOpenable(for:)` 一致）。
   * 仅依赖路径与表结构，避免再引入 CBookManager 回调查询。
   */
  static async isOpenableForDownloadedBaseName(baseName: string): Promise<boolean> {
    const sqlitePath = new CBookDbPath(baseName).sqlite

    if (!sqlitePath || !FileUtility.isFileExistAt(sqlitePath)) {
      return false
    }

    const acc = new DBAccessor(sqlitePath, null, true)
    const n   = await acc.getCount(`SELECT COUNT(*) FROM ${Table.Name.baseWord}`, [])

    return n > 0
  }

  async getBaseWordById(idx: number): Promise<BaseWord | null> {
    const sql = `SELECT * FROM ${Table.Name.baseWord} WHERE ${Table.Col.idx} = ?`

    return await this.db.getData(sql, [idx], rs => this.createBaseWordFromRs(rs))
  }

  async getBaseWordByText(enText: string): Promise<BaseWord | null> {
    const encodedText = StringEncoder.encodedToBase64(enText)

    if (!encodedText) {
      return null
    }

    const sql = `
      SELECT *
      FROM ${Table.Name.baseWord}
      WHERE SUBSTR(${Table.Col.titleEn}, ${DB.salt + 1}, LENGTH(${Table.Col.titleEn}) - ${DB.salt}) = ?
    `

    return await this.db.getData(sql, [encodedText], rs => this.createBaseWordFromRs(rs))
  }

  private createBaseWordFromRs(rs: relationalStore.ResultSet): BaseWord {
    const word    = new BaseWord()

    word.idx      = rs.getLong(rs.getColumnIndex(Table.Col.idx))
    word.titleEn  = ResultSetTool.decodeString(rs, Table.Col.titleEn)
    word.pronEn   = ResultSetTool.decodeString(rs, Table.Col.pronEn)
    word.pronUs   = ResultSetTool.decodeString(rs, Table.Col.pronUs)
    word.titleCn1 = ResultSetTool.decodeString(rs, Table.Col.titleCn1)
    word.titleCn2 = ResultSetTool.decodeString(rs, Table.Col.titleCn2)
    word.titleCn3 = ResultSetTool.decodeString(rs, Table.Col.titleCn3)

    return word
  }
}
