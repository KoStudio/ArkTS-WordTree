// BookManager.ts
import preferences from '@ohos.data.preferences'
import { getAppContext } from '../../../app/constants/AppContext'
import { dAppCBookDbFolderPath, dMyDataFolderPath, MyDatas } from '../../../app/constants/AppDefines'
import { createFolderIfNeeds } from '../../../app/constants/AppFunctions'
import { CBookDbPath } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookPath'
import { Toast } from '../../../common/utils/Toast'
import { BaseDict, Book, CigenData } from './Book'


class BookPrefKeys {
  static readonly Name               = 'Pref_Book'

  static readonly kBOOK_LIST         = 'book_list'
  static readonly kCURRENT_BOOK      = 'current_book'
}

class BookConstant {
  static readonly FILE_BOOK_TEXTDB    = "textDb.sqlite"
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


  private pref: preferences.Preferences | null = null

  private constructor() { this.init(); }

  init() {
    const context = getAppContext()
    this.pref = preferences.getPreferencesSync(context, {
      name: BookPrefKeys.Name
    })

    this.restoreBooks()
    this.restoreCurrentBook()

  }

  saveBooks(): void {
    if (!this.pref) return
    this.pref.putSync(BookPrefKeys.kBOOK_LIST, JSON.stringify(this.books))
    this.pref.flushSync()
  }

  saveCurrentBook(): void {
    if (!this.pref) return
    if (this.currentBook) {
      this.pref.putSync(BookPrefKeys.kCURRENT_BOOK, JSON.stringify(this.currentBook))
    } else {
      this.pref.deleteSync(BookPrefKeys.kCURRENT_BOOK)
    }
    this.pref.flush()
  }


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

  saveBook(book: Book){
    this.books.push(book)
    this.saveBooks()
  }

  removeBook(book: Book): void {
    // 1️⃣ 从 books 列表中过滤掉该 Book
    this.books = this.books.filter(item => item.bookId !== book.bookId)

    // 2️⃣ 如果当前选中的书正是被删除的那本，也要清空
    if (this.currentBook && this.currentBook.bookId === book.bookId) {
      this.currentBook = null
      this.saveCurrentBook()
    }

    // 3️⃣ 保存 books
    this.saveBooks()
  }


  setCurrentBook(book: Book | null): void {
    this.currentBook = book
    this.saveCurrentBook()
  }

/*
  ///not using..可以直接使用dAppCBookDbFolderPath
  static getDirectoryPathForBook(book: Book): string {
    ///.../app_Document/Books/1/
    // return dAppCBookDbFolderPath + book.bookId + "/"

    ///因为使用的是CBook，所以全部是：~/app_Database/CBookDatas/
    return dAppCBookDbFolderPath
  }

  ///not using ..可以直接使用CBookDbPath
  static getPathOfTextDbForBook(book: Book): string {
    ///.../app_Document/Books/1/textDb.sqlite
     //return BookManager.getDirectoryPathForBook(book) + BookConstant.FILE_BOOK_TEXTDB

    ///因为使用的是CBook，所以全部是：~/app_Database/CBookDatas/CET4_Sub1.sqlite
    return (new CBookDbPath(book.textDb || '')).baseName
  }
*/
  // example:..~/app_Database/MyDatas/
  static getDirectoryOfUserData(): string {
    return dMyDataFolderPath
  }

  // example:..~/app_Database/MyDatas/1/
  static getDirectoryOfUserDataForBook(book: Book): string {
     const folder = BookManager.getDirectoryOfUserData() + book.bookId + '/'
     createFolderIfNeeds(folder);
     return folder
  }

  // example:..~/app_Database/MyDatas/bookId/learnDb.sqlite
  static getPathOfUserDataForLearnWithBook(book: Book): string {
    return BookManager.getDirectoryOfUserDataForBook(book) + MyDatas.DBName
  }

  // example:..~/app_Database/MyDatas/1/learnDb.sqlite
  static getCurrentDirectoryOfUserData(): string {
    const book = BookManager.shared.currentBook
    if (book) {
      return BookManager.getDirectoryOfUserDataForBook(book)
    }
    Toast.showDebugMessage('getCurrentDirectoryOfUserData failed: current book is null')
    return ''
  }

  // example:..~/app_Database/MyDatas/1/learnDb.sqlite
  static getCurrentPathOfUserData(): string {
    const book = BookManager.shared.currentBook
    if (book) {
      return BookManager.getPathOfUserDataForLearnWithBook(book)
    }
    Toast.showDebugMessage('getCurrentPathOfUserData failed: current book is null')
    return ''
  }

}