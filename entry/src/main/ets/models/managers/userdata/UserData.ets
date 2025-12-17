/// 用于服务器上备份和恢复用户数据
export interface UserDataJson {
  user_id?        : number | null
  project_name?   : string | null
  app_name?       : string | null
  device_type?    : string | null
  data_json?      : string | null
  user_data_addr? : string | null
  create_date?    : Date | string | null
  update_date?    : Date | string | null
}


/// CodingKeys（保持 Kotlin 的结构）
export class UserDataKeys {
  static readonly userId        = "user_id"
  static readonly projectName   = "project_name"
  static readonly appName       = "app_name"
  static readonly deviceType    = "device_type"
  static readonly dataJson      = "data_json"
  static readonly userDataAddr  = "user_data_addr"
  static readonly createDate    = "create_date"
  static readonly updateDate    = "update_date"
}


/// 用户数据模型
export class UserData {
  userId        : number | null = null
  projectName   : string | null = null
  appName       : string | null = null
  deviceType    : string | null = null
  dataJson      : string | null = null
  userDataAddr  : string | null = null
  createDate    : Date   | null = null
  updateDate    : Date   | null = null

  static fromJson(json: UserDataJson): UserData {
    const obj        = new UserData()

    obj.userId        = json.user_id        ?? null
    obj.projectName   = json.project_name   ?? null
    obj.appName       = json.app_name       ?? null
    obj.deviceType    = json.device_type    ?? null
    obj.dataJson      = json.data_json      ?? null
    obj.userDataAddr  = json.user_data_addr ?? null

    // 日期可能是字符串，也可能是 Date，因此需要兼容处理
    const cd          = json.create_date
    const ud          = json.update_date

    obj.createDate    = cd ? new Date(cd) : null
    obj.updateDate    = ud ? new Date(ud) : null

    return obj
  }
}