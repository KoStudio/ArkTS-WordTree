//
// Memo2.ets
// WordTree (HarmonyOS)
//
// 与 iOS `Memo2.swift` / Android `Memo2.kt` 一致（服务器笔记模型，snake_case JSON）。
//

import { UserManager } from '../user/UserManager'

// 服务器 memo JSON / HTTP 参数字段名（snake_case，与接口一致）
export class Memo2ParamKey {

  static readonly bookId      = 'book_id'
  static readonly bookName    = 'book_name'
  static readonly wordEn      = 'word_en'
  static readonly memoText    = 'memo_text'
  static readonly favCount    = 'fav_count'
  static readonly userId      = 'user_id'
  static readonly userName    = 'user_name'
  static readonly deviceIdfv  = 'device_idfv'
  static readonly deviceType  = 'device_type'
  static readonly snsType     = 'sns_type'
  static readonly createDate  = 'create_date'
  static readonly updateDate  = 'update_date'
  static readonly memoId      = 'memo_id'
  static readonly page        = 'page'
}

// 服务器 memo 接口返回的一条记录
export class Memo2 {

  memoId      : number | null = null
  bookId      : number | null = null
  bookName    : string | null = null
  wordEn      : string | null = null
  memoText    : string | null = null
  favCount    : number | null = null
  userId      : number | null = null
  userName    : string | null = null
  deviceType  : string | null = null
  snsType     : string | null = null
  createDate  : string | null = null
  updateDate  : string | null = null

  // json：单条对象；缺省为空模型
  constructor(json?: Record<string, Object>) {

    // 仅在有字典时解析字段
    if (json) {
      this.memoId     = (json[Memo2ParamKey.memoId] as number) ?? null
      this.bookId     = (json[Memo2ParamKey.bookId] as number) ?? null
      this.bookName   = (json[Memo2ParamKey.bookName] as string) ?? null
      this.wordEn     = (json[Memo2ParamKey.wordEn] as string) ?? null
      this.memoText   = (json[Memo2ParamKey.memoText] as string) ?? null
      this.favCount   = (json[Memo2ParamKey.favCount] as number) ?? null
      this.userId     = (json[Memo2ParamKey.userId] as number) ?? null
      this.userName   = (json[Memo2ParamKey.userName] as string) ?? null
      this.deviceType = (json[Memo2ParamKey.deviceType] as string) ?? null
      this.snsType    = (json[Memo2ParamKey.snsType] as string) ?? null
      this.createDate = (json[Memo2ParamKey.createDate] as string) ?? null
      this.updateDate = (json[Memo2ParamKey.updateDate] as string) ?? null
    }
  }

  // 判断是否是自己创建的笔记
  isSelfCreated(): boolean {

    const uid = this.userId
    const cur = UserManager.shared.userId

    // 未登录或笔记无 userId
    if (uid === null || cur === null) {
      return false
    }

    return uid === cur
  }

  // 复制并仅替换收藏数（列表行乐观更新用）
  withFavCount(fc: number): Memo2 {

    const r: Record<string, Object> = {}

    if (this.memoId !== null) {
      r[Memo2ParamKey.memoId] = this.memoId
    }
    if (this.bookId !== null) {
      r[Memo2ParamKey.bookId] = this.bookId
    }
    if (this.bookName !== null) {
      r[Memo2ParamKey.bookName] = this.bookName
    }
    if (this.wordEn !== null) {
      r[Memo2ParamKey.wordEn] = this.wordEn
    }
    if (this.memoText !== null) {
      r[Memo2ParamKey.memoText] = this.memoText
    }
    r[Memo2ParamKey.favCount] = fc
    if (this.userId !== null) {
      r[Memo2ParamKey.userId] = this.userId
    }
    if (this.userName !== null) {
      r[Memo2ParamKey.userName] = this.userName
    }
    if (this.deviceType !== null) {
      r[Memo2ParamKey.deviceType] = this.deviceType
    }
    if (this.snsType !== null) {
      r[Memo2ParamKey.snsType] = this.snsType
    }
    if (this.createDate !== null) {
      r[Memo2ParamKey.createDate] = this.createDate
    }
    if (this.updateDate !== null) {
      r[Memo2ParamKey.updateDate] = this.updateDate
    }

    return new Memo2(r)
  }
}
