//
//  EBookManager.ets
//  WordTree
//
//  创建和维护本地 EBook（用户自建词汇本）的非 UI 逻辑。
//
//  设计约束：
//  - 不修改现有 BookList/CBook 结构，只在本地创建额外的 Book 记录和 textDb/learnDb（Book 与 iOS `Book2` 对应）；
//  - EBook 的 textDb 表结构与 WordManager.WordTable 完全一致（表名 "Word" + item0~item24）；
//  - learnDb.sqlite 中的 EWordTable 由 WordManager.refreshDb() 统一保证存在；
//  - 不在此处区分「当前书」的展示逻辑，只负责底层存储和 Book 元数据。
//

import { dAppEBookFolderPath } from '../../../app/constants/AppDefines'
import { createFolderIfNeeds } from '../../../app/constants/AppFunctions'
import { DebugLog } from '../../../app/debug/DebugLog'
import { FileUtility } from '../../../common/utils/FileUtility'
import { PathUtility } from '../../../common/utils/PathUtility'
import { Book, BookManager } from '../../datas/book/BookManager'
import { WordDbAccess } from '../../datas/word/WordDbAccess'
import { EBookMinBookId } from './EBookConstants'

// 管理本地 EBook（用户自建词汇本）的创建与底层存储
export class EBookManager {

  static shared: EBookManager = new EBookManager()

  private constructor() {
  }

  // 本地 EBook 使用的最小 bookId（避免与服务器下发的 CBook 冲突）
  // 备份上传时，服务器上的 ServerBookId 从 10001 开始
  // 数值定义在 `EBookConstants.ets`（与 iOS 写在类上的 `static let` 不同，原因见该文件头注释）
  static get EBookMinBookId(): number {
    return EBookMinBookId
  }

  // 根据 textDb 的 baseName 生成对应的 EBook textDb.sqlite 完整路径；例如 baseName 为 "ebook_1001" 时对应 dAppEBookFolderPath/ebook_1001.sqlite（与 iOS `dAppEBookFolderURL`…`.path` 等价）
  static textDbPath(forBaseName: string): string {
    return `${dAppEBookFolderPath}${forBaseName}.sqlite`
  }

  // 从 textDb 完整路径反推 baseName（供 BookManager.refreshBookCounts 等使用；与 iOS `BookManager2.refreshBookCounts` 等价）
  static baseName(fromTextDbPath: string): string | null {
    const name = PathUtility.getLastComponentName(fromTextDbPath)
    if (!name.endsWith('.sqlite')) {
      return null
    }
    return name.substring(0, name.length - '.sqlite'.length)
  }

  // MARK: - Public API

  // 删除本地 EBook 的 textDb 文件（若存在）。与 iOS `BooksLocalView.confirmRemove` 中对 EBook 分支的文件删除逻辑等价，此处收口为静态方法供鸿蒙列表层调用。
  static removeLocalTextDbIfExists(forBaseName: string): void {
    const p = EBookManager.textDbPath(forBaseName)
    if (FileUtility.isFileExistAt(p)) {
      FileUtility.deleteFileAt(p)
    }
  }

  // 创建新的本地 EBook 对应 Book 并生成 textDb.sqlite；参数：bookName 书名，categoryName 可选；返回新建的 Book 或 null；learnDb 由 BookManager / WordManager 首次访问时自动创建（与 iOS `BookManager2`/WordManager 一致）
  async createLocalEBook(bookName: string, categoryName: string | null = null): Promise<Book | null> {
    // 1. 生成新的本地 bookId（从 EBookMinBookId 开始递增，避免与服务器下发的 CBook 冲突）
    const existingIds: number[] = BookManager.shared.books
      .map((b: Book) => b.bookId ?? 0)
      .filter((id: number) => id >= EBookManager.EBookMinBookId)
    const nextId: number = Math.max((existingIds.length > 0 ? Math.max(...existingIds) : 0) + 1, EBookManager.EBookMinBookId)

    // 2. 为 EBook 生成唯一的 textDb 标识（baseName）
    const textDbBaseName = `ebook_${nextId}`

    // 3. 在 EBook 专用目录下创建对应的 sqlite，物理位置独立于 CBookDatas
    const textDbPath = EBookManager.textDbPath(textDbBaseName)
    // iOS 侧由 FMDB/文件 API 隐式建父目录；鸿蒙 relationalStore 需先保证目录存在
    createFolderIfNeeds(dAppEBookFolderPath)

    if (!FileUtility.isFileExistAt(textDbPath)) {
      if (!(await this.createEmptyWordDatabaseAtPath(textDbPath))) {
        DebugLog.e('[EBookManager] createLocalEBook failed when creating textDb')
        return null
      }
    }

    // 4. 构造 Book 元数据
    const book = new Book()
    book.bookId        = nextId
    book.bookName      = bookName
    book.categoryName  = categoryName
    book.textDb        = textDbBaseName
    book.golds         = 0
    book.unitsCount    = 0
    book.wordsCount    = 0
    book.visible       = true
    book.serverEBookId = null

    // 5. 保存到 BookManager（仅本地 Preferences，与 iOS `BookManager2` + UserDefaults 等价；不影响服务器 BookList）
    BookManager.shared.saveBook(book)

    return book
  }

  // MARK: - Private Helpers

  // 在指定路径创建一个仅包含 Word 表的空数据库，表结构与 WordManager.WordTable 一致（与 iOS `WordManager.sharedManager.createEBookDbIfNeeded` 等价；鸿蒙为 `WordDbAccess.createEBookDbIfNeeded`）
  private async createEmptyWordDatabaseAtPath(path: string): Promise<boolean> {
    return await WordDbAccess.createEBookDbIfNeeded(path)
  }
}
