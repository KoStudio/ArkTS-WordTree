// BookManager.ts
import preferences from '@ohos.data.preferences'
import { getAppContext } from '../../../app/constants/AppContext'
import { BaseDict, Book, CigenData } from './Book'


class BookPrefKeys {
  static readonly Name               = 'Pref_Book'

  static readonly kBOOK_LIST         = 'book_list'
  static readonly kCURRENT_BOOK      = 'current_book'

  static readonly kBASEDICT_LIST     = 'basedict_list'
  static readonly kCURRENT_BASEDICT  = 'current_basedict'

  static readonly kCIGENDATA_LIST    = 'cigendata_list'
  static readonly kCURRENT_CIGENDATA = 'current_cigendata'
}

@ObservedV2
export class BookManager {

  private static instance: BookManager | null = null

  static get shared(): BookManager {
    if (!BookManager.instance) {
      BookManager.instance = new BookManager()
    }
    return BookManager.instance
  }


  @Trace public books            : Book[]           = []
  @Trace public currentBook      : Book | null      = null

  @Trace public baseDicts        : BaseDict[]       = []
  @Trace public currentBaseDict  : BaseDict | null  = null

  @Trace public cigenDatas       : CigenData[]      = []
  @Trace public currentCigenData : CigenData | null = null

  private pref: preferences.Preferences | null = null

  private constructor() { this.init(); }

  init() {
    const context = getAppContext()
    this.pref = preferences.getPreferencesSync(context, {
      name: BookPrefKeys.Name
    })

    this.restoreBooks()
    this.restoreCurrentBook()

    this.restoreBaseDicts()
    this.restoreCurrentBaseDict()

    this.restoreCigenDatas()
    this.restoreCurrentCigenData()
  }

  // ==========================================================
  // MARK: - Save
  // ==========================================================

  saveBooks(): void {
    if (!this.pref) return
    this.pref.put(BookPrefKeys.kBOOK_LIST, JSON.stringify(this.books))
    this.pref.flush()
  }

  saveCurrentBook(): void {
    if (!this.pref) return
    if (this.currentBook) {
      this.pref.put(BookPrefKeys.kCURRENT_BOOK, JSON.stringify(this.currentBook))
    } else {
      this.pref.delete(BookPrefKeys.kCURRENT_BOOK)
    }
    this.pref.flush()
  }

  saveBaseDicts(): void {
    if (!this.pref) return
    this.pref.put(BookPrefKeys.kBASEDICT_LIST, JSON.stringify(this.baseDicts))
    this.pref.flush()
  }

  saveCurrentBaseDict(): void {
    if (!this.pref) return
    if (this.currentBaseDict) {
      this.pref.put(
        BookPrefKeys.kCURRENT_BASEDICT,
        JSON.stringify(this.currentBaseDict)
      )
    } else {
      this.pref.delete(BookPrefKeys.kCURRENT_BASEDICT)
    }
    this.pref.flush()
  }

  saveCigenDatas(): void {
    if (!this.pref) return
    this.pref.put(BookPrefKeys.kCIGENDATA_LIST, JSON.stringify(this.cigenDatas))
    this.pref.flush()
  }

  saveCurrentCigenData(): void {
    if (!this.pref) return
    if (this.currentCigenData) {
      this.pref.put(
        BookPrefKeys.kCURRENT_CIGENDATA,
        JSON.stringify(this.currentCigenData)
      )
    } else {
      this.pref.delete(BookPrefKeys.kCURRENT_CIGENDATA)
    }
    this.pref.flush()
  }
  // ==========================================================
  // MARK: - Restore
  // ==========================================================

  private restoreBooks(): void {
    if (!this.pref) return

    const json = this.pref.getSync(
      BookPrefKeys.kBOOK_LIST,
      ''
    ) as string

    if (!json || json.length === 0) {
      this.books = []
      return
    }

    try {
      const arr = JSON.parse(json) as Object[]
      this.books = Book.fromArray(arr)
    } catch (e) {
      console.error('restoreBooks failed', e)
      this.books = []
    }
  }

  private restoreCurrentBook(): void {
    if (!this.pref) return

    const json = this.pref.getSync(
      BookPrefKeys.kCURRENT_BOOK,
      ''
    ) as string

    if (!json || json.length === 0) {
      this.currentBook = null
      return
    }

    try {
      const obj = JSON.parse(json) as Record<string, Object>
      this.currentBook = new Book(obj)
    } catch (e) {
      console.error('restoreCurrentBook failed', e)
      this.currentBook = null
    }
  }
  private restoreBaseDicts(): void {
    if (!this.pref) return

    const json = this.pref.getSync(
      BookPrefKeys.kBASEDICT_LIST,
      ''
    ) as string

    if (!json) {
      this.baseDicts = []
      return
    }

    try {
      const arr = JSON.parse(json) as Object[]
      this.baseDicts = BaseDict.fromArray(arr)
    } catch (e) {
      console.error('restoreBaseDicts failed', e)
      this.baseDicts = []
    }
  }

  private restoreCurrentBaseDict(): void {
    if (!this.pref) return

    const json = this.pref.getSync(
      BookPrefKeys.kCURRENT_BASEDICT,
      ''
    ) as string

    if (!json) {
      this.currentBaseDict = null
      return
    }

    try {
      const obj = JSON.parse(json) as Record<string, Object>
      this.currentBaseDict = new BaseDict(obj)
    } catch (e) {
      console.error('restoreCurrentBaseDict failed', e)
      this.currentBaseDict = null
    }
  }

  private restoreCigenDatas(): void {
    if (!this.pref) return

    const json = this.pref.getSync(
      BookPrefKeys.kCIGENDATA_LIST,
      ''
    ) as string

    if (!json) {
      this.cigenDatas = []
      return
    }

    try {
      const arr = JSON.parse(json) as Object[]
      this.cigenDatas = CigenData.fromArray(arr)
    } catch (e) {
      console.error('restoreCigenDatas failed', e)
      this.cigenDatas = []
    }
  }

  private restoreCurrentCigenData(): void {
    if (!this.pref) return

    const json = this.pref.getSync(
      BookPrefKeys.kCURRENT_CIGENDATA,
      ''
    ) as string

    if (!json) {
      this.currentCigenData = null
      return
    }

    try {
      const obj = JSON.parse(json) as Record<string, Object>
      this.currentCigenData = new CigenData(obj)
    } catch (e) {
      console.error('restoreCurrentCigenData failed', e)
      this.currentCigenData = null
    }
  }

  // ==========================================================
  // MARK: - API
  // ==========================================================

  setBooks(books: Book[]): void {
    this.books = books
    this.saveBooks()
  }

  setCurrentBook(book: Book | null): void {
    this.currentBook = book
    this.saveCurrentBook()
  }

  setBaseDicts(dicts: BaseDict[]): void {
    this.baseDicts = dicts
    this.saveBaseDicts()
  }

  setCurrentBaseDict(dict: BaseDict | null): void {
    this.currentBaseDict = dict
    this.saveCurrentBaseDict()
  }

  setCigenDatas(datas: CigenData[]): void {
    this.cigenDatas = datas
    this.saveCigenDatas()
  }

  setCurrentCigenData(data: CigenData | null): void {
    this.currentCigenData = data
    this.saveCurrentCigenData()
  }
}