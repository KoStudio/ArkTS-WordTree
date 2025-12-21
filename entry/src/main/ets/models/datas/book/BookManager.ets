// BookManager.ts
import preferences from '@ohos.data.preferences'
import { getAppContext } from '../../../app/constants/AppContext'
import { Book } from './Book'

// ============================================================
// MARK: - Preference Keys
// ============================================================
class BookPrefKeys {
  static readonly Name          = 'Pref_Book'
  static readonly kBOOK_LIST    = 'book_list'
  static readonly kCURRENT_BOOK = 'current_book'
}

// ============================================================
// MARK: - BookManager (Singleton)
// ============================================================
export class BookManager {

  // -----------------------------
  // Singleton
  // -----------------------------
  private static instance: BookManager | null = null

  static get shared(): BookManager {
    if (!BookManager.instance) {
      BookManager.instance = new BookManager()
    }
    return BookManager.instance
  }

  // -----------------------------
  // Data
  // -----------------------------
  public books       : Book[]      = []
  public currentBook : Book | null = null

  private pref: preferences.Preferences | null = null

  // -----------------------------
  // Init
  // -----------------------------
  private constructor() { this.init(); }

  init() {
    const context = getAppContext()
    this.pref = preferences.getPreferencesSync(context, {
      name: BookPrefKeys.Name
    })

    this.restoreBooks()
    this.restoreCurrentBook()
  }

  // ==========================================================
  // MARK: - Save
  // ==========================================================

  saveBooks(): void {
    if (!this.pref) return

    this.pref.put(
      BookPrefKeys.kBOOK_LIST,
      JSON.stringify(this.books)
    )
    this.pref.flush()
  }

  saveCurrentBook(): void {
    if (!this.pref) return

    if (this.currentBook) {
      this.pref.put(
        BookPrefKeys.kCURRENT_BOOK,
        JSON.stringify(this.currentBook)
      )
    } else {
      this.pref.delete(BookPrefKeys.kCURRENT_BOOK)
    }

    this.pref.flush()
  }

  // ==========================================================
  // MARK: - Restore (getSync)
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
}