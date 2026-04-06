import { BookManager } from "./BookManager"
// `EBookMinBookId` 见 `EBookConstants.ets`：`EBookManager` 已 import `Book`，若此处再 import `EBookManager` 取常量会形成环依赖；原因与 iOS 差异见该文件头注释
import { EBookMinBookId } from "../../managers/ebook/EBookConstants"

/**
 * 课本元数据，与 Android `Book2`、iOS `Book2` 对齐。
 * - textDb：在 CBook / EBook 体系中的 baseName（不含 `.sqlite` 后缀）；
 * - serverEBookId：仅 EBook 与服务器备份/索引关联时使用（与 Android `Book2.serverEBookId` 一致）。
 */
export class Book {

  bookId        : number  | null = null
  bookName      : string  | null = null
  categoryName  : string  | null = null
  textDb        : string  | null = null
  golds         : number  | null = null
  unitsCount    : number  | null = null
  wordsCount    : number  | null = null
  visible       : boolean | null = null
  /** 仅 EBook 使用：服务器 UserData_EBook.bookId，用于备份/恢复与「下载我备份的 EBook」（与 iOS `Book2.serverEBookId` 一致） */
  serverEBookId : number  | null = null

  /** 与 iOS `Book2` / `Identifiable` 的 `id` 一致，供列表/List 等使用 */
  get id(): number {
    return this.bookId ?? -1
  }

  static equals(lhs: Book, rhs: Book): boolean {
    return lhs.bookId === rhs.bookId;
  }

  constructor(json?: Record<string, Object>) {
    if (json) {
      this.bookId       = (json['bookId']       as number)  ?? null
      this.bookName     = (json['bookName']     as string)  ?? null
      this.categoryName = (json['categoryName'] as string)  ?? null
      this.textDb       = (json['textDb']       as string)  ?? null
      this.golds        = (json['golds']        as number)  ?? null
      this.unitsCount   = (json['unitsCount']   as number)  ?? null
      this.wordsCount   = (json['wordsCount']   as number)  ?? null
      this.visible      = (json['visible']      as boolean) ?? null
      // 与 Android `Book2` JSON：`optInt("serverEBookId")`，0 视为未绑定
      if (json['serverEBookId'] !== undefined && json['serverEBookId'] !== null) {
        const sid = json['serverEBookId'] as number
        this.serverEBookId = sid === 0 ? null : sid
      } else {
        this.serverEBookId = null
      }
    }
  }


  static fromArray(arr: Object[] | null): Book[] {
    if (!arr) return []
    return arr.map(o => new Book(o as Record<string, Object>))
  }

  get isCurrentBook(): boolean {
    return BookManager.shared.currentBook?.bookId === this.bookId
  }

  /** 是否为本地用户自建 EBook（与 iOS `Book2.isEBook` 一致：bookId >= EBookMinBookId） */
  get isEBook(): boolean {
    return (this.bookId ?? 0) >= EBookMinBookId
  }

  /** EBook 是否已关联服务器（与 iOS `Book2.hasServerEBookId` 一致） */
  get hasServerEBookId(): boolean {
    return this.isEBook && this.serverEBookId != null
  }
}

// BaseDict.ts
export class BaseDict {

  dictId        : number | null = null
  dictName      : string | null = null
  textDb        : string | null = null
  golds         : number | null = null
  desciption    : string | null = null

  static equals(lhs: BaseDict, rhs: BaseDict): boolean {
    return lhs.dictId === rhs.dictId
  }

  constructor(json?: Record<string, Object>) {
    if (json) {
      this.dictId     = (json['dictId']     as number) ?? null
      this.dictName   = (json['dictName']   as string) ?? null
      this.textDb     = (json['textDb']     as string) ?? null
      this.golds      = (json['golds']      as number) ?? null
      this.desciption = (json['desciption'] as string) ?? null
    }
  }

  static fromArray(arr: Object[] | null): BaseDict[] {
    if (!arr) return []
    return arr.map(o => new BaseDict(o as Record<string, Object>))
  }
}

// CigenData.ts
export class CigenData {

  cigenId    : number | null = null
  cigenName  : string | null = null
  textDb     : string | null = null

  static equals(lhs: CigenData, rhs: CigenData): boolean {
    return lhs.cigenId === rhs.cigenId
  }

  constructor(json?: Record<string, Object>) {
    if (json) {
      this.cigenId   = (json['cigenId']   as number) ?? null
      this.cigenName = (json['cigenName'] as string) ?? null
      this.textDb    = (json['textDb']    as string) ?? null
    }
  }

  static fromArray(arr: Object[] | null): CigenData[] {
    if (!arr) return []
    return arr.map(o => new CigenData(o as Record<string, Object>))
  }
}