//
//  UserData.ets
//  与 iOS `UserData.swift` 一致：Dcs 备份/恢复用的 user_data 记录
//

import { DateUtils } from '../../../common/utils/DateUtils'


// 与 iOS `UserData.CodingKeys` 字段名一致（请求/解析 JSON 键）
export class UserDataCodingKeys {

  static readonly userId       = 'user_id'
  static readonly bookId       = 'book_id'
  static readonly userDataAddr = 'user_data_addr'
  static readonly appName      = 'app_name'
  static readonly createDate   = 'create_date'
  static readonly updateDate   = 'update_date'
}


// Dcs 返回的一行 JSON（蛇形命名；与 iOS `Decodable` 解码键一致）
export class UserDataJson {
  user_id?:         number | null = null
  book_id?:         number | null = null
  user_data_addr?:  string | null = null
  app_name?:        string | null = null
  create_date?:     string | null = null
  update_date?:     string | null = null
}


// 用于本地业务：服务器备份与恢复用户数据（与 iOS `UserData` 存储字段一致；`appName` 仅出现在 JSON，不参与属性存储）
export class UserData {

  userId:         number | null = null
  bookId:         number | null = null
  userDataAddr:   string | null = null
  createDate:     Date | null   = null
  updateDate:     Date | null   = null

  constructor() {
  }

  /**
   * 从 Dcs JSON 行构造（与 iOS `init(from decoder:)` 字段一致）
   * @param json 服务端原始字段
   */
  static fromJson(json: UserDataJson): UserData {

    const data = new UserData()

    data.userId       = json.user_id ?? null
    data.bookId       = json.book_id ?? null
    data.userDataAddr = json.user_data_addr ?? null

    // 与 iOS：`DateUtility.getDateFromUTCString` → 鸿蒙 `DateUtils.toDateFromUTC`
    if (json.create_date !== null && json.create_date !== undefined && json.create_date.length > 0) {
      data.createDate = DateUtils.toDateFromUTC(json.create_date)
    }

    if (json.update_date !== null && json.update_date !== undefined && json.update_date.length > 0) {
      data.updateDate = DateUtils.toDateFromUTC(json.update_date)
    }

    return data
  }
}
