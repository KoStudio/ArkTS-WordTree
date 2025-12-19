import relationalStore from '@ohos.data.relationalStore';
import { getAppContext } from '../../../app/constants/AppContext';
import { ResImg, ResName, ResPath } from '../../../app/constants/ResPath';
import { CBookManager } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookManager';
import { CBookListName } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookPath';
import { DbFileUtility } from '../../../common/utils/DbFileUtility';
import { FileUtility } from '../../../common/utils/FileUtility';
import { DBAccessor } from "../../dbUtils/DBAccessor";
import { DBPrepareProtocol, DbPrepareUtils } from '../../dbUtils/DBPrepare';
import { ResultSetTool } from '../../dbUtils/ResultSetTool';
import { AppCfgManager } from '../../managers/servercfg/AppCfgManager';
import { Book } from './Book';


class BookTable {
  static readonly Name      = 'Book'
}

class BookCol {
  static readonly bookId          = "item0"
  static readonly bookName        = "item1"
  static readonly categoryName    = "item2"
  static readonly textDb          = "item3"
  static readonly golds           = "item4"
  static readonly unitsCount      = "item5"
  static readonly wordsCount      = "item6"
  static readonly visible         = "item7"
}

// 书籍数据模型
export class BookDbAccess implements DBPrepareProtocol {
  private static instance: BookDbAccess;
  // private db: DBAccessor;

  private constructor() {
    // this.db = new DBAccessor(ResName.Book.filePath, null);

    this.init()
  }

  private async init(){
    await DbPrepareUtils.prepareDbIfNeeds(this, ResName.Book)

    ///准备图片
    // this.prepareImgsIfNeeds()
  }

  private get dbPath(): string | null {
    /// 使用CBook的开关是否是ON， 并且 下载的Cbook是否存在
    if (AppCfgManager.shared.isCBook_Useable_is_ON()
      && CBookManager.shared.isExistBookDb(CBookListName)){
      return CBookManager.shared.cbookDbPath(CBookListName)
    }

    return ResName.Book.filePath
  }

  private get db(): DBAccessor {
    return new DBAccessor(this.dbPath, null);
  }

  // private  prepareImgsIfNeeds(){
  //   ResImg.allImages.forEach(async (res: ResPath, index: number) => {
  //     const toTargetPath   = res.filePath
  //     const fromAssetsPath = res.assetPath
  //
  //     //如果 db不存在，
  //     if (!FileUtility.isFileExistAt(toTargetPath)){
  //       // 则执行 同步copy
  //       await DbFileUtility.copyDatabaseFromAssetsIfNeeds(getAppContext(), fromAssetsPath, toTargetPath);
  //     }
  //   })
  //
  // }

  //删除Dbs，用于升级时
  removeDbs(){
    ResName.allDatabases.forEach(async (res: ResPath, index: number) => {
      FileUtility.deleteFileAt(res.filePath)
    })
  }

  //删除Imgs，用于升级时
  //  removeImgs(){
  //    ResImg.allImages.forEach(async (res: ResPath, index: number) => {
  //     FileUtility.deleteFileAt(res.filePath)
  //   })
  // }

  public static get shared(): BookDbAccess {
    if (!BookDbAccess.instance) {
      BookDbAccess.instance = new BookDbAccess();
    }
    return BookDbAccess.instance;
  }

  async isDbOpenable(): Promise<boolean> {
    return await this.getBook(1) != null
  }

  /**
   * 获取所有书籍
   * @returns Promise<OneBook[] | null> 书籍数组或null
   */
  async getAllBooks(): Promise<Book[] | null> {
    const sql = `SELECT * FROM ${BookTable.Name} ORDER BY ${BookCol.bookId}`;
    return await this.db.getDatas(sql, [], rs => this.createOneBookFromRs(rs));
  }

  /**
   * 根据ID获取单本书籍
   * @param bookId 书籍ID
   * @returns Promise<OneBook | null> 书籍对象或null
   */
  async getBook(bookId: number): Promise<Book | null> {
    const sql = `SELECT * FROM ${BookTable.Name} WHERE ${BookCol.bookId} = ?`;
    return await this.db.getData(sql, [bookId], rs => this.createOneBookFromRs(rs));
  }

  /**
   * 根据分类名称获取书籍
   * @param categoryName 分类名称
   * @returns Promise<Book[] | null> 书籍数组或null
   */
  async getBooks(categoryName: string): Promise<Book[] | null> {
    const sql = `SELECT * FROM ${BookTable.Name} WHERE ${BookCol.categoryName} = ?`;
    return await this.db.getDatas(sql, [categoryName], rs => this.createOneBookFromRs(rs));
  }

  /**
   * 从结果集创建书籍对象
   * @param rs 数据库结果集
   * @returns OneBook 书籍对象
   */
  private createOneBookFromRs(rs: relationalStore.ResultSet): Book {

    let book            = new Book()
    book.bookId         = rs.getLong(rs.getColumnIndex(BookCol.bookId))
    book.bookName       = ResultSetTool.decodeString(rs, BookCol.bookName)
    book.categoryName   = ResultSetTool.decodeString(rs, BookCol.categoryName)
    book.textDb         = ResultSetTool.decodeString(rs, BookCol.textDb)
    book.golds          = rs.getLong(rs.getColumnIndex(BookCol.golds))
    book.unitsCount     = rs.getLong(rs.getColumnIndex(BookCol.unitsCount))
    book.wordsCount     = rs.getLong(rs.getColumnIndex(BookCol.wordsCount))
    book.visible        = rs.getLong(rs.getColumnIndex(BookCol.visible)) === 1

    return book;
  }
}
