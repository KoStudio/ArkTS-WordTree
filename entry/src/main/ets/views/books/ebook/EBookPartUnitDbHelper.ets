import relationalStore from '@ohos.data.relationalStore'
import { StringEncoder } from '../../../common/utils/strings/StringEncrypt'
import { DB } from '../../../models/dbUtils/DBConstants'
import { DBAccessor } from '../../../models/dbUtils/DBAccessor'
import { ResultSetTool } from '../../../models/dbUtils/ResultSetTool'
import { WordDetail } from '../../../models/datas/word/WordDetail'
import { WordTable } from '../../../models/datas/word/WordDbAccess'

export interface EBookPartItem {
  partId   : number
  partName : string
}

export interface EBookUnitItem {
  unitId   : number
  unitName : string
}

export interface EBookWordPartUnit {
  partId   : number
  partName : string
  unitId   : number
  unitName : string
}

export class EBookPartUnitDbHelper {

  /**
   * 读取目标 textDb 中全部 Part（按 partId 升序去重）
   * @param textDbPath textDb.sqlite 完整路径
   */
  static async getAllParts(textDbPath: string): Promise<EBookPartItem[]> {

    const accessor = new DBAccessor(textDbPath, null)
    const sql      = `
      SELECT
        ${WordTable.Col.PARTID}   AS pid,
        ${WordTable.Col.PARTNAME} AS pname
      FROM ${WordTable.Table_Name}
      GROUP BY ${WordTable.Col.PARTID}
      ORDER BY ${WordTable.Col.PARTID} ASC
    `

    const rows = await accessor.getDatas(sql, [], (rs: relationalStore.ResultSet): EBookPartItem => {

      const partId   = rs.getLong(rs.getColumnIndex('pid'))
      const partName = ResultSetTool.decodeString(rs, 'pname') ?? `Part${partId}`

      return {
        partId   : partId,
        partName : partName
      }
    })

    return rows ?? []
  }

  /**
   * 读取某 Part 下全部 Unit（按 unitId 升序去重）
   * @param textDbPath textDb.sqlite 完整路径
   * @param partId     PartId
   */
  static async getUnitsByPartId(textDbPath: string, partId: number): Promise<EBookUnitItem[]> {

    const accessor = new DBAccessor(textDbPath, null)
    const sql      = `
      SELECT
        ${WordTable.Col.UNITID}   AS uid,
        ${WordTable.Col.UNITNAME} AS uname
      FROM ${WordTable.Table_Name}
      WHERE ${WordTable.Col.PARTID} = ?
      GROUP BY ${WordTable.Col.UNITID}
      ORDER BY ${WordTable.Col.UNITID} ASC
    `

    const rows = await accessor.getDatas(sql, [partId], (rs: relationalStore.ResultSet): EBookUnitItem => {

      const unitId   = rs.getLong(rs.getColumnIndex('uid'))
      const unitName = ResultSetTool.decodeString(rs, 'uname') ?? `Unit${unitId}`

      return {
        unitId   : unitId,
        unitName : unitName
      }
    })

    return rows ?? []
  }

  /**
   * 查询当前最大 PartId
   * @param textDbPath textDb.sqlite 完整路径
   */
  static async getMaxPartId(textDbPath: string): Promise<number> {

    const accessor = new DBAccessor(textDbPath, null)
    const value    = await accessor.getMax(WordTable.Col.PARTID, WordTable.Table_Name)

    return value
  }

  /**
   * 查询当前最大 UnitId
   * @param textDbPath textDb.sqlite 完整路径
   */
  static async getMaxUnitId(textDbPath: string): Promise<number> {

    const accessor = new DBAccessor(textDbPath, null)
    const value    = await accessor.getMax(WordTable.Col.UNITID, WordTable.Table_Name)

    return value
  }

  /**
   * 统计某 Unit 当前已有单词数
   * @param textDbPath textDb.sqlite 完整路径
   * @param unitId     UnitId
   */
  static async getWordsCountByUnitId(textDbPath: string, unitId: number): Promise<number> {

    const accessor = new DBAccessor(textDbPath, null)
    const sql      = `SELECT COUNT(*) FROM ${WordTable.Table_Name} WHERE ${WordTable.Col.UNITID} = ?`

    return await accessor.getCount(sql, [unitId])
  }

  /**
   * 按英文词判断目标库中是否已存在，存在则返回其 Part/Unit 信息
   * @param textDbPath textDb.sqlite 完整路径
   * @param titleEn    英文词
   */
  static async getWordPartUnitIfExists(textDbPath: string, titleEn: string): Promise<EBookWordPartUnit | null> {

    const titleEnBase64 = StringEncoder.encodedToBase64(titleEn)

    if (titleEnBase64 === null) {
      return null
    }

    const accessor = new DBAccessor(textDbPath, null)
    const sql      = `
      SELECT
        ${WordTable.Col.PARTID}   AS pid,
        ${WordTable.Col.PARTNAME} AS pname,
        ${WordTable.Col.UNITID}   AS uid,
        ${WordTable.Col.UNITNAME} AS uname
      FROM ${WordTable.Table_Name}
      WHERE SUBSTR(
        ${WordTable.Col.TITLEEN},
        ${DB.salt} + 1,
        LENGTH(${WordTable.Col.TITLEEN}) - ${DB.salt}
      ) = ?
      LIMIT 1
    `

    return await accessor.getData(sql, [titleEnBase64], (rs: relationalStore.ResultSet): EBookWordPartUnit => {

      const partId   = rs.getLong(rs.getColumnIndex('pid'))
      const partName = ResultSetTool.decodeString(rs, 'pname') ?? `Part${partId}`
      const unitId   = rs.getLong(rs.getColumnIndex('uid'))
      const unitName = ResultSetTool.decodeString(rs, 'uname') ?? `Unit${unitId}`

      return {
        partId   : partId,
        partName : partName,
        unitId   : unitId,
        unitName : unitName
      }
    })
  }

  /**
   * 将词条写入目标库（先删同英文，再按指定 Part/Unit 插入）
   * @param textDbPath textDb.sqlite 完整路径
   * @param detail     待保存词条
   */
  static async insertWordDetail(textDbPath: string, detail: WordDetail): Promise<boolean> {

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

    const accessor = new DBAccessor(textDbPath, null, false)
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

    return okDelete && okInsert
  }
}
