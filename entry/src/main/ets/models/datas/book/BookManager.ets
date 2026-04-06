// BookManager.ets — 与 iOS `BookManager2` 对齐（Preferences / 列表维护 / 路径工具）
import { Context } from '@kit.AbilityKit'
import preferences from '@ohos.data.preferences'
import { getAppContext } from '../../../app/constants/AppContext'
import { dMyDataFolderPath, MyDatas } from '../../../app/constants/AppDefines'
import { createFolderIfNeeds } from '../../../app/constants/AppFunctions'
import { DebugLog } from '../../../app/debug/DebugLog'
import { PathUtility } from '../../../common/utils/PathUtility'
import { Toast } from '../../../common/utils/Toast'
import { Book } from './Book'
import { WordDbAccess } from '../word/WordDbAccess'

// 供 EBookManager 等与 BookManager 同用的模块单一入口，避免直接 import `Book.ets` 时分析器循环依赖报错
export { Book }

class BookPrefKeys {
  /** 与 iOS `BookPrefKeys.Name` 一致 */
  static readonly Name          = 'Pref_Book2'
  /** 鸿蒙旧版曾用 `Pref_Book`，启动时迁移一次 `book_list` / `current_book` */
  static readonly LegacyName    = 'Pref_Book'

  static readonly kBOOK_LIST    = 'book_list'
  static readonly kCURRENT_BOOK = 'current_book'
}

/** 与 iOS `BookManager2.Notification` 名称一致（鸿蒙可选用 `emitter` 等订阅） */
export class BookManagerNotification {
  static readonly bookChanged        = 'BookManagerNotification_BookChanged'
  static readonly currentBookUpdated = 'BookManagerNotification_CurrentBookUpdated'
  static readonly bookListUpdated    = 'BookManager2Notification_BookListUpdated'
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

  @Trace public books       : Book[]      = []
  @Trace public currentBook : Book | null = null

  private pref: preferences.Preferences | null = null

  private constructor() {
    this.init()
  }

  init(): void {
    const context = getAppContext()
    this.pref = preferences.getPreferencesSync(context, {
      name: BookPrefKeys.Name
    })
    this.migrateFromLegacyPreferencesIfNeeded(context)
    this.restoreBooks()
    this.restoreCurrentBook()
  }

  /** 从旧 `Pref_Book` 迁移书本列表与当前书（与 iOS 升级后仍用 `Pref_Book2` 的策略一致） */
  private migrateFromLegacyPreferencesIfNeeded(context: Context): void {
    if (!this.pref) {
      return
    }
    const cur = this.pref.getSync(BookPrefKeys.kBOOK_LIST, '') as string
    if (cur && cur.length > 0) {
      return
    }
    const legacy = preferences.getPreferencesSync(context, { name: BookPrefKeys.LegacyName })
    const oldList = legacy.getSync(BookPrefKeys.kBOOK_LIST, '') as string
    if (!oldList || oldList.length === 0) {
      return
    }
    this.pref.putSync(BookPrefKeys.kBOOK_LIST, oldList)
    const oldCur = legacy.getSync(BookPrefKeys.kCURRENT_BOOK, '') as string
    if (oldCur && oldCur.length > 0) {
      this.pref.putSync(BookPrefKeys.kCURRENT_BOOK, oldCur)
    }
    this.pref.flushSync()
  }

  /** 将 `Book` 转为可 JSON 序列化的字典（与 iOS `bookToJSON`：仅包含有值字段） */
  private bookToPlain(book: Book): Record<string, Object> {
    const d: Record<string, Object> = {}
    if (book.bookId !== null && book.bookId !== undefined) {
      d['bookId'] = book.bookId
    }
    if (book.bookName !== null && book.bookName !== undefined) {
      d['bookName'] = book.bookName
    }
    if (book.categoryName !== null && book.categoryName !== undefined) {
      d['categoryName'] = book.categoryName
    }
    if (book.textDb !== null && book.textDb !== undefined) {
      d['textDb'] = book.textDb
    }
    if (book.golds !== null && book.golds !== undefined) {
      d['golds'] = book.golds
    }
    if (book.unitsCount !== null && book.unitsCount !== undefined) {
      d['unitsCount'] = book.unitsCount
    }
    if (book.wordsCount !== null && book.wordsCount !== undefined) {
      d['wordsCount'] = book.wordsCount
    }
    if (book.visible !== null && book.visible !== undefined) {
      d['visible'] = book.visible
    }
    if (book.serverEBookId !== null && book.serverEBookId !== undefined) {
      d['serverEBookId'] = book.serverEBookId
    }
    return d
  }

  saveBooks(): void {
    if (!this.pref) {
      return
    }
    const arr = this.books.map((b: Book) => this.bookToPlain(b))
    this.pref.putSync(BookPrefKeys.kBOOK_LIST, JSON.stringify(arr))
    this.pref.flushSync()
  }

  saveCurrentBook(): void {
    if (!this.pref) {
      return
    }
    if (this.currentBook) {
      this.pref.putSync(BookPrefKeys.kCURRENT_BOOK, JSON.stringify(this.bookToPlain(this.currentBook)))
    } else {
      this.pref.deleteSync(BookPrefKeys.kCURRENT_BOOK)
    }
    this.pref.flushSync()
  }

  private restoreBooks(): void {
    if (!this.pref) {
      return
    }

    const json = this.pref.getSync(BookPrefKeys.kBOOK_LIST, '') as string

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
    if (!this.pref) {
      return
    }

    const json = this.pref.getSync(BookPrefKeys.kCURRENT_BOOK, '') as string

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

  /**
   * 添加或更新一本书（与 iOS `saveBook`：按 bookId 替换或追加）
   */
  saveBook(book: Book): void {
    const idx = this.books.findIndex((b: Book) => b.bookId === book.bookId)
    if (idx >= 0) {
      const next = [...this.books]
      next[idx] = book
      this.books = next
    } else {
      this.books = [...this.books, book]
    }
    this.saveBooks()
  }

  removeBook(book: Book): void {
    this.books = this.books.filter(item => item.bookId !== book.bookId)

    if (this.currentBook && this.currentBook.bookId === book.bookId) {
      this.currentBook = null
      this.saveCurrentBook()
    }

    this.saveBooks()
  }

  /**
   * 根据 textDb 完整路径刷新对应书的 wordsCount、unitsCount（与 iOS `refreshBookCounts(forTextDbPath:)` 一致）
   */
  async refreshBookCounts(forTextDbPath: string): Promise<void> {
    const baseName = BookManager.baseNameFromTextDbPath(forTextDbPath)
    if (baseName === null) {
      DebugLog.e(`[BookManager] refreshBookCounts: invalid path ${forTextDbPath}`)
      return
    }
    const idx = this.books.findIndex((b: Book) => b.textDb === baseName)
    if (idx < 0) {
      DebugLog.e(`[BookManager] refreshBookCounts: no book for path ${forTextDbPath}`)
      return
    }
    const book = this.books[idx]
    book.wordsCount = await WordDbAccess.getWordsCountInTextDbAt(forTextDbPath)
    book.unitsCount = await WordDbAccess.getUnitsCountInTextDbAt(forTextDbPath)
    this.saveBook(book)
    if (this.currentBook?.bookId === book.bookId) {
      const synced = this.books.find((b: Book) => b.bookId === book.bookId)
      if (synced) {
        this.currentBook = synced
        this.saveCurrentBook()
      }
    }
  }

  /** 从 textDb 路径解析 baseName（与 iOS `EBookManager.baseName(fromTextDbPath:)` 等价；此处内联以避免 `BookManager` ↔ `EBookManager` 环依赖） */
  static baseNameFromTextDbPath(path: string): string | null {
    const name = PathUtility.getLastComponentName(path)
    if (!name.endsWith('.sqlite')) {
      return null
    }
    return name.substring(0, name.length - '.sqlite'.length)
  }

  /** 仅 EBook（与 iOS `eBooks` 一致） */
  get eBooks(): Book[] {
    return this.books.filter((b: Book) => b.isEBook)
  }

  /** 重命名书籍（与 iOS `renameBook(_:to:)` 语义一致；ArkTS 无外部参数名，第二参为 `newName`） */
  renameBook(book: Book, newName: string): void {
    const trimmed = newName.trim()
    if (!trimmed) {
      return
    }
    const idx = this.books.findIndex((b: Book) => b.bookId === book.bookId)
    if (idx >= 0) {
      const next = [...this.books]
      next[idx].bookName = trimmed
      this.books = next
    }
    if (this.currentBook && this.currentBook.bookId === book.bookId) {
      this.currentBook.bookName = trimmed
      this.saveCurrentBook()
    }
    this.saveBooks()
  }

  /**
   * 设置当前书（与 iOS `setCurrentBook`：切换时语义上对应 `bookChanged`；鸿蒙 UI 多依赖 `@Trace currentBook`）
   */
  setCurrentBook(book: Book | null): void {
    const oldId = this.currentBook?.bookId ?? null
    this.currentBook = book
    this.saveCurrentBook()
    const newId = book?.bookId ?? null
    if (oldId !== newId) {
      // 与 iOS `NotificationCenter.post(name: .bookChanged)` 对齐时可广播 `BookManagerNotification.bookChanged`
    }
  }

  // MARK: - User Data（learnDb），与 iOS `BookManager2` + ObjC UserDataManager 路径约定一致

  static getDirectoryOfUserData(): string {
    return dMyDataFolderPath
  }

  static getDirectoryOfUserDataForBook(book: Book): string {
    const folder = BookManager.getDirectoryOfUserData() + book.bookId + '/'
    createFolderIfNeeds(folder)
    return folder
  }

  static getPathOfUserDataForLearnWithBook(book: Book): string {
    return BookManager.getDirectoryOfUserDataForBook(book) + MyDatas.DBName
  }

  static getCurrentDirectoryOfUserData(): string {
    const book = BookManager.shared.currentBook
    if (book) {
      return BookManager.getDirectoryOfUserDataForBook(book)
    }
    Toast.showDebugMessage('getCurrentDirectoryOfUserData failed: current book is null')
    return ''
  }

  /** 当前书 learnDb 完整路径（与 iOS `getCurrentPathOfUserDataForLearn` 同名） */
  static getCurrentPathOfUserDataForLearn(): string {
    return BookManager.getCurrentPathOfUserData()
  }

  static getCurrentPathOfUserData(): string {
    const book = BookManager.shared.currentBook
    if (book) {
      return BookManager.getPathOfUserDataForLearnWithBook(book)
    }
    Toast.showDebugMessage('getCurrentPathOfUserData failed: current book is null')
    return ''
  }
}
