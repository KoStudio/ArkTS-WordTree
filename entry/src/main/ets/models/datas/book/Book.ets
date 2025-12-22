import { BookManager } from "./BookManager"


export class Book {

  bookId        : number  | null = null
  bookName      : string  | null = null
  categoryName  : string  | null = null
  textDb        : string  | null = null
  golds         : number  | null = null
  unitsCount    : number  | null = null
  wordsCount    : number  | null = null
  visible       : boolean | null = null


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
    }
  }


  static fromArray(arr: Object[] | null): Book[] {
    if (!arr) return []
    return arr.map(o => new Book(o as Record<string, Object>))
  }

  get isCurrentBook(): boolean {
    return BookManager.shared.currentBook?.bookId === this.bookId
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