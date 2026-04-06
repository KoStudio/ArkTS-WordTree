import { DateUtils } from '../../../common/utils/DateUtils'

// Dcs `user_data_ebook` 单条 JSON（显式类型，满足 arkts-no-any-unknown）
export interface UserDataEBookJson {
  user_id?: string
  book_id?: number | string
  book_name?: string
  text_db_addr?: string
  units_count?: number
  words_count?: number
  create_date?: string
  update_date?: string
  app_name?: string
}

// 与 Dcs `user_data_ebook` 接口字段一致（与 iOS `UserDataEBook.CodingKeys` 对齐）
export class UserDataEBookKeys {
  static readonly userId     = 'user_id'
  static readonly bookId     = 'book_id'
  static readonly bookName   = 'book_name'
  static readonly textDbAddr = 'text_db_addr'
  static readonly unitsCount = 'units_count'
  static readonly wordsCount = 'words_count'
  static readonly appName    = 'app_name'
  static readonly createDate = 'create_date'
  static readonly updateDate = 'update_date'
}

// 服务器 UserData_EBook 记录（「下载我备份的 EBook」列表项）
export class UserDataEBook {
  bookId      : number | null = null
  userId      : string | null = null
  bookName    : string | null = null
  textDbAddr  : string | null = null
  unitsCount  : number | null = null
  wordsCount  : number | null = null
  createDate  : Date | null = null
  updateDate  : Date | null = null

  static fromJson(json: UserDataEBookJson | null): UserDataEBook | null {

    if (json === null) {
      return null
    }

    const item         = new UserDataEBook()
    const bid          = json.book_id
    const uid          = json.user_id
    const uc           = json.units_count
    const wc           = json.words_count

    if (typeof bid === 'number') {
      item.bookId      = bid
    } else if (typeof bid === 'string') {
      const parsed     = parseInt(bid, 10)
      item.bookId      = Number.isNaN(parsed) ? null : parsed
    } else {
      item.bookId      = null
    }
    item.userId        = typeof uid === 'string' ? uid : null
    item.bookName      = typeof json.book_name === 'string' ? json.book_name : null
    item.textDbAddr    = typeof json.text_db_addr === 'string' ? json.text_db_addr : null
    item.unitsCount    = typeof uc === 'number' ? uc : null
    item.wordsCount    = typeof wc === 'number' ? wc : null

    const cd           = json.create_date
    const ud           = json.update_date

    if (typeof cd === 'string' && cd.length > 0) {
      item.createDate  = DateUtils.toDateFromUTC(cd)
    }

    if (typeof ud === 'string' && ud.length > 0) {
      item.updateDate  = DateUtils.toDateFromUTC(ud)
    }

    return item
  }

  static fromJsonArray(arr: UserDataEBookJson[] | null): UserDataEBook[] {

    if (arr === null || arr.length < 1) {
      return []
    }

    const out: UserDataEBook[] = []

    for (let i = 0; i < arr.length; i++) {
      const one = UserDataEBook.fromJson(arr[i])

      if (one !== null) {
        out.push(one)
      }
    }

    return out
  }
}
