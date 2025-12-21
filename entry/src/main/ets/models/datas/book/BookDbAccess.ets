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

namespace Table {
  export namespace Book {
    export const name            = "BookCns";

    export namespace Col {
      export const bookId        = "item0";
      export const bookName      = "item1";
      export const categoryName  = "item2";
      export const textDb        = "item3";
      export const golds         = "item4";
      export const unitsCount    = "item5";
      export const wordsCount    = "item6";
      export const visible       = "item7";
    }
  }
}

export class BookDbAccess implements DBPrepareProtocol {
  private static instance: BookDbAccess;

  private constructor() {
    this.init()
  }

  private async init() {
    await DbPrepareUtils.prepareDbIfNeeds(this, ResName.Book)
  }

  private get dbPath(): string | null {
    if (AppCfgManager.shared.isCBook_Useable_is_ON()
      && CBookManager.shared.isExistBookDb(CBookListName)) {
      return CBookManager.shared.cbookDbPath(CBookListName)
    }

    return ResName.Book.filePath
  }

  private get db(): DBAccessor {
    return new DBAccessor(this.dbPath, null);
  }

  removeDbs() {
    ResName.allDatabases.forEach(async (res: ResPath, index: number) => {
      FileUtility.deleteFileAt(res.filePath)
    })
  }

  public static get shared(): BookDbAccess {
    if (!BookDbAccess.instance) {
      BookDbAccess.instance = new BookDbAccess();
    }
    return BookDbAccess.instance;
  }

  async isDbOpenable(): Promise<boolean> {
    return await this.getBook(1) != null
  }

  async getAllBooks(): Promise<Book[] | null> {
    const sql = `SELECT * FROM ${Table.Book.name} ORDER BY ${Table.Book.Col.bookId}`;
    return await this.db.getDatas(sql, [], rs => this.createOneBookFromRs(rs));
  }

  async getBook(bookId: number): Promise<Book | null> {
    const sql = `SELECT * FROM ${Table.Book.name} WHERE ${Table.Book.Col.bookId} = ?`;
    return await this.db.getData(sql, [bookId], rs => this.createOneBookFromRs(rs));
  }

  async getBooks(categoryName: string): Promise<Book[] | null> {
    const sql = `SELECT * FROM ${Table.Book.name} WHERE ${Table.Book.Col.categoryName} = ?`;
    return await this.db.getDatas(sql, [categoryName], rs => this.createOneBookFromRs(rs));
  }

  private createOneBookFromRs(rs: relationalStore.ResultSet): Book {
    let book          = new Book();
    book.bookId       = rs.getLong(rs.getColumnIndex(Table.Book.Col.bookId));
    book.bookName     = ResultSetTool.decodeString(rs, Table.Book.Col.bookName);
    book.categoryName = ResultSetTool.decodeString(rs, Table.Book.Col.categoryName);
    book.textDb       = ResultSetTool.decodeString(rs, Table.Book.Col.textDb);
    book.golds        = rs.getLong(rs.getColumnIndex(Table.Book.Col.golds));
    book.unitsCount   = rs.getLong(rs.getColumnIndex(Table.Book.Col.unitsCount));
    book.wordsCount   = rs.getLong(rs.getColumnIndex(Table.Book.Col.wordsCount));
    book.visible      = rs.getLong(rs.getColumnIndex(Table.Book.Col.visible)) === 1;

    return book;
  }
}