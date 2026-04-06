//
//  learnDb 中 EWordOverride 表：按 titleEn（Base64，无盐）+ fieldKey 存用户覆盖值。
//  与 iOS `EWordOverrideTable.swift` 一致。

export class EWordOverrideTable {
  static readonly Table_Name             : string = 'EWordOverride'
  /** 与 WordOnlineTemp 中 titleEn 编码一致：仅 Base64，无盐 */
  static readonly Col_TitleEnEncoded     : string = 'titleEnEncoded'
  /** 字段键，如 item9、root */
  static readonly Col_FieldKey           : string = 'fieldKey'
  static readonly Col_Value              : string = 'value'

  /** 建表 DDL，供 WordUserDbAccess 等与 iOS `EWordOverrideTable.createTableSQL` 对齐处执行 */
  static readonly createTableSQL: string =
    `CREATE TABLE IF NOT EXISTS ${EWordOverrideTable.Table_Name} (
      ${EWordOverrideTable.Col_TitleEnEncoded} TEXT NOT NULL,
      ${EWordOverrideTable.Col_FieldKey} TEXT NOT NULL,
      ${EWordOverrideTable.Col_Value} TEXT,
      PRIMARY KEY (${EWordOverrideTable.Col_TitleEnEncoded}, ${EWordOverrideTable.Col_FieldKey})
    )`
}
