//
//  EWordManager.ets
//  WordTree
//
//  管理 learnDb 中 EWordOverride 表的读写，titleEn 编码与 TableOnline 一致（base64，无盐）。
//  （ArkTS 使用 `StringEncoder` 做 Base64，语义同 iOS `encodedString` / `decodedString`。）
//

import relationalStore from '@ohos.data.relationalStore'
import { BookManager } from '../../datas/book/BookManager'
import { StringEncoder } from '../../../common/utils/strings/StringEncrypt'
import { DBAccessor, ParamType } from '../../dbUtils/DBAccessor'
import { EWordOverrideTable } from './EWordOverrideTable'

//MARK: - EWordManager

export class EWordManager {
  static shared: EWordManager = new EWordManager()

  /// 全量覆盖缓存；外层 key 为解码后的 titleEn（与 iOS `cachedAllOverrides` 一致）
  private cachedAllOverrides: Record<string, Record<string, string>> | null = null

  private constructor() {
  }

  /// 当前课本 learnDb 路径（与 iOS `WordManager` + `DBAccessable` 使用的 learnDb 路径一致）
  private learnDbPath(): string | null {
    const p = BookManager.getCurrentPathOfUserData()

    if (p.length > 0) {
      return p
    }

    return null
  }

  /// 确保当前书 learnDb 及 EWordOverride 表存在（与 iOS `ensureLearnDbAndTable` → `createLearnDbIfNeeded` 等价）
  private async ensureLearnDbAndTable(): Promise<void> {
    const db = this.dbAccessor()

    if (!db) {
      return
    }

    await db.updateDb(EWordOverrideTable.createTableSQL)
  }

  /// 可写 learnDb 访问器（iOS 由 `DBAccessable` 协议内聚；Harmony 显式 `DBAccessor`）
  private dbAccessor(): DBAccessor | null {
    const path = this.learnDbPath()

    if (!path) {
      return null
    }

    return new DBAccessor(path, null, false)
  }

  /// 返回当前书所有 EWord 覆盖（按 titleEn 聚合）。内部带简单缓存，避免列表场景频繁访问 DB。
  async allOverridesCached(): Promise<Record<string, Record<string, string>>> {
    if (this.cachedAllOverrides !== null) {
      return this.cachedAllOverrides
    }

    const map = await this.loadAllOverrides()
    this.cachedAllOverrides = map

    return map
  }

  /// 失效覆盖缓存（在保存 / 删除覆盖后调用，下次访问时自动从 DB 重新加载）。
  private invalidateOverridesCache(): void {
    this.cachedAllOverrides = null
  }

  /// 备份前 WAL 收口（与 iOS `DBAccessable.closeWalIfNeeds` 一致；实现见 `DBAccessor.closeWalIfNeedsAtPath`）
  closeWalIfNeeds(): Promise<void> {
    return DBAccessor.closeWalIfNeedsAtPath(this.learnDbPath())
  }

  /// 保存一条覆盖：存在则更新，不存在则插入
  /// - Parameters:
  ///   - titleEn: 单词英文（未编码）
  ///   - fieldKey: 字段键，如 item9、root
  ///   - value: 新值
  /// - Returns: 是否成功
  async saveOverride(titleEn: string, fieldKey: string, value: string): Promise<boolean> {
    if (!titleEn || !fieldKey) {
      return false
    }

    const encoded = StringEncoder.encodedToBase64(titleEn)

    if (!encoded) {
      return false
    }

    await this.ensureLearnDbAndTable()

    const db = this.dbAccessor()
    const sql =
      `INSERT OR REPLACE INTO ${EWordOverrideTable.Table_Name} ` +
      `(${EWordOverrideTable.Col_TitleEnEncoded}, ${EWordOverrideTable.Col_FieldKey}, ${EWordOverrideTable.Col_Value}) ` +
      `VALUES (?, ?, ?)`
    const params: ParamType[] = [encoded, fieldKey, value]

    if (db) {
      await db.updateDb(sql, params)
    }

    this.invalidateOverridesCache()

    return true
  }

  /// 删除一条覆盖
  /// - Parameters:
  ///   - titleEn: 单词英文（未编码）
  ///   - fieldKey: 字段键
  /// - Returns: 是否成功
  async deleteOverride(titleEn: string, fieldKey: string): Promise<boolean> {
    if (!titleEn || !fieldKey) {
      return false
    }

    const encoded = StringEncoder.encodedToBase64(titleEn)

    if (!encoded) {
      return false
    }

    await this.ensureLearnDbAndTable()

    const db = this.dbAccessor()
    const sql =
      `DELETE FROM ${EWordOverrideTable.Table_Name} ` +
      `WHERE ${EWordOverrideTable.Col_TitleEnEncoded} = ? AND ${EWordOverrideTable.Col_FieldKey} = ?`

    if (db) {
      await db.updateDb(sql, [encoded, fieldKey])
    }

    this.invalidateOverridesCache()

    return true
  }

  /// 删除该词在 EWordOverride 表中的全部覆盖（用于「全部恢复」）
  /// - Parameter titleEn: 单词英文（未编码）
  /// - Returns: 是否成功
  async deleteAllOverrides(titleEn: string): Promise<boolean> {
    if (!titleEn) {
      return false
    }

    const encoded = StringEncoder.encodedToBase64(titleEn)

    if (!encoded) {
      return false
    }

    await this.ensureLearnDbAndTable()

    const db = this.dbAccessor()
    const sql =
      `DELETE FROM ${EWordOverrideTable.Table_Name} WHERE ${EWordOverrideTable.Col_TitleEnEncoded} = ?`

    if (db) {
      await db.updateDb(sql, [encoded])
    }

    this.invalidateOverridesCache()

    return true
  }

  /// 读取该词在 learnDb 中的全部覆盖，key 为 fieldKey，value 为覆盖值
  /// - Parameter titleEn: 单词英文（未编码）
  /// - Returns: [fieldKey: value]，无覆盖时为空
  async loadOverrides(titleEn: string): Promise<Record<string, string>> {
    if (!titleEn) {
      return {}
    }

    const encoded = StringEncoder.encodedToBase64(titleEn)

    if (!encoded) {
      return {}
    }

    await this.ensureLearnDbAndTable()

    const db = this.dbAccessor()

    if (!db) {
      return {}
    }

    const sql =
      `SELECT ${EWordOverrideTable.Col_FieldKey}, ${EWordOverrideTable.Col_Value} ` +
      `FROM ${EWordOverrideTable.Table_Name} WHERE ${EWordOverrideTable.Col_TitleEnEncoded} = ?`

    const rows = await db.getDatas<string[]>(sql, [encoded], (rs: relationalStore.ResultSet) => {
      const pair: string[] = []

      pair.push(rs.getString(0) ?? '')
      pair.push(rs.getString(1) ?? '')

      return pair
    })

    const map: Record<string, string> = {}

    if (!rows) {
      return map
    }

    for (let i = 0; i < rows.length; i++) {
      const r = rows[i]

      if (r.length >= 2) {
        map[r[0]] = r[1]
      }
    }

    return map
  }

  /// 读取当前书 learnDb 中所有词的覆盖，用于 SearchManager 合并
  /// - Returns: key 为解码后的 titleEn，value 为该词的 [fieldKey: value]
  async loadAllOverrides(): Promise<Record<string, Record<string, string>>> {
    await this.ensureLearnDbAndTable()

    const db = this.dbAccessor()

    if (!db) {
      return {}
    }

    const sql =
      `SELECT ${EWordOverrideTable.Col_TitleEnEncoded}, ${EWordOverrideTable.Col_FieldKey}, ${EWordOverrideTable.Col_Value} ` +
      `FROM ${EWordOverrideTable.Table_Name}`

    const rows = await db.getDatas<string[]>(sql, [], (rs: relationalStore.ResultSet) => {
      const triple: string[] = []

      triple.push(rs.getString(0) ?? '')
      triple.push(rs.getString(1) ?? '')
      triple.push(rs.getString(2) ?? '')

      return triple
    })

    const result: Record<string, Record<string, string>> = {}

    if (!rows) {
      return result
    }

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i]

      if (row.length < 3) {
        continue
      }

      const enc      = row[0]
      const fieldKey = row[1]
      const value    = row[2]
      const titleEn  = StringEncoder.decodedFromBase64(enc) ?? enc

      if (!result[titleEn]) {
        result[titleEn] = {}
      }

      result[titleEn][fieldKey] = value
    }

    return result
  }
}
