//
// Memo2.ets
// WordTree (HarmonyOS)
//
// 与 iOS `Memo2.swift` / Android `Memo2.kt` 一致（服务器笔记模型，snake_case JSON）。
//

import { UserManager } from '../user/UserManager'

// 服务器 memo 接口返回的一条记录
export class Memo2 {

  memoId    : number | null = null
  bookId    : number | null = null
  bookName  : string | null = null
  wordEn    : string | null = null
  memoText  : string | null = null
  favCount  : number | null = null
  userId    : number | null = null
  userName  : string | null = null
  deviceType: string | null = null
  snsType   : string | null = null
  createDate: string | null = null
  updateDate: string | null = null

  // json：单条对象；缺省为空模型
  constructor(json?: Record<string, Object>) {

    // 仅在有字典时解析字段
    if (json) {
      this.memoId     = (json['memo_id'] as number) ?? null
      this.bookId     = (json['book_id'] as number) ?? null
      this.bookName   = (json['book_name'] as string) ?? null
      this.wordEn     = (json['word_en'] as string) ?? null
      this.memoText   = (json['memo_text'] as string) ?? null
      this.favCount   = (json['fav_count'] as number) ?? null
      this.userId     = (json['user_id'] as number) ?? null
      this.userName   = (json['user_name'] as string) ?? null
      this.deviceType = (json['device_type'] as string) ?? null
      this.snsType    = (json['sns_type'] as string) ?? null
      this.createDate = (json['create_date'] as string) ?? null
      this.updateDate = (json['update_date'] as string) ?? null
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
      r['memo_id'] = this.memoId
    }
    if (this.bookId !== null) {
      r['book_id'] = this.bookId
    }
    if (this.bookName !== null) {
      r['book_name'] = this.bookName
    }
    if (this.wordEn !== null) {
      r['word_en'] = this.wordEn
    }
    if (this.memoText !== null) {
      r['memo_text'] = this.memoText
    }
    r['fav_count'] = fc
    if (this.userId !== null) {
      r['user_id'] = this.userId
    }
    if (this.userName !== null) {
      r['user_name'] = this.userName
    }
    if (this.deviceType !== null) {
      r['device_type'] = this.deviceType
    }
    if (this.snsType !== null) {
      r['sns_type'] = this.snsType
    }
    if (this.createDate !== null) {
      r['create_date'] = this.createDate
    }
    if (this.updateDate !== null) {
      r['update_date'] = this.updateDate
    }

    return new Memo2(r)
  }
}
