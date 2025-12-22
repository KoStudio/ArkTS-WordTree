import relationalStore from '@ohos.data.relationalStore';
import { ResImg, ResName, ResPath } from '../../../app/constants/ResPath';
import { AppLanguage } from '../../../common/components/Language/AppLanguage';
import { LanguageManager } from '../../../common/components/Language/LanguageManager';
import { CBookManager } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookManager';
import { CBookListName } from '../../../common/components/Sounds/Cloud/Download/CBook/CBookPath';
import { FileUtility } from '../../../common/utils/FileUtility';
import { DBAccessor } from "../../dbUtils/DBAccessor";
import { DBPrepareProtocol, DbPrepareUtils } from '../../dbUtils/DBPrepare';
import { ResultSetTool } from '../../dbUtils/ResultSetTool';
import { AppCfgManager } from '../../managers/servercfg/AppCfgManager';
import { BaseDict, Book, CigenData } from './Book';

namespace Table {
  export namespace Book {
    export const nameCns         = "BookCns";
    export const nameCnt         = "BookCns";

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

  export namespace BaseDict {
    export const name = 'BaseDict'

    export namespace  Col {
      export const dictId        = "item0";
      export const dictName      = "item1";
      export const textDb        = "item2";
      export const golds         = "item3";
      export const desciption    = "item4";
    }
  }

  export namespace CigenData {
    export const name = 'CigenData'

    export namespace  Col {
      export const cigenId        = "item0";
      export const cigenName      = "item1";
      export const textDb         = "item2";
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
  
  private get TableBookName(): string {
    if (LanguageManager.getCurrentLanguage() === AppLanguage.Traditional) {
      return Table.Book.nameCnt
    }
    return Table.Book.nameCns
  }

  async getAllBooks(): Promise<Book[] | null> {
    const sql = `SELECT * FROM ${this.TableBookName} ORDER BY ${Table.Book.Col.bookId}`;
    return await this.db.getDatas(sql, [], rs => this.createOneBookFromRs(rs));
  }

  async getBook(bookId: number): Promise<Book | null> {
    const sql = `SELECT * FROM ${this.TableBookName} WHERE ${Table.Book.Col.bookId} = ?`;
    return await this.db.getData(sql, [bookId], rs => this.createOneBookFromRs(rs));
  }

  async getBooks(categoryName: string): Promise<Book[] | null> {
    const sql = `SELECT * FROM ${this.TableBookName} WHERE ${Table.Book.Col.categoryName} = ?`;
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
  async getAllBaseDicts(): Promise<BaseDict[] | null> {
    const sql = `SELECT * FROM ${Table.BaseDict.name} ORDER BY ${Table.BaseDict.Col.dictId}`
    return await this.db.getDatas(sql, [], rs => this.createOneBaseDictFromRs(rs))
  }

  async getBaseDict(dictId: number): Promise<BaseDict | null> {
    const sql = `SELECT * FROM ${Table.BaseDict.name} WHERE ${Table.BaseDict.Col.dictId} = ?`
    return await this.db.getData(sql, [dictId], rs => this.createOneBaseDictFromRs(rs))
  }

  async getBaseDictByTextDb(textDb: string): Promise<BaseDict | null> {
    const sql = `SELECT * FROM ${Table.BaseDict.name} WHERE ${Table.BaseDict.Col.textDb} = ?`
    return await this.db.getData(sql, [textDb], rs => this.createOneBaseDictFromRs(rs))
  }

  /** BaseDict ResultSet → Model */
  private createOneBaseDictFromRs(rs: relationalStore.ResultSet): BaseDict {
    let dict        = new BaseDict()
    dict.dictId     = rs.getLong(rs.getColumnIndex(Table.BaseDict.Col.dictId))
    dict.dictName   = ResultSetTool.decodeString(rs, Table.BaseDict.Col.dictName)
    dict.textDb     = ResultSetTool.decodeString(rs, Table.BaseDict.Col.textDb)
    dict.golds      = rs.getLong(rs.getColumnIndex(Table.BaseDict.Col.golds))
    dict.desciption = ResultSetTool.decodeString(rs, Table.BaseDict.Col.desciption)
    return dict
  }

  async getAllCigenDatas(): Promise<CigenData[] | null> {
    const sql = `SELECT * FROM ${Table.CigenData.name} ORDER BY ${Table.CigenData.Col.cigenId}`
    return await this.db.getDatas(sql, [], rs => this.createOneCigenDataFromRs(rs))
  }

  async getCigenData(cigenId: number): Promise<CigenData | null> {
    const sql = `SELECT * FROM ${Table.CigenData.name} WHERE ${Table.CigenData.Col.cigenId} = ?`
    return await this.db.getData(sql, [cigenId], rs => this.createOneCigenDataFromRs(rs))
  }

  async getCigenDataByTextDb(textDb: string): Promise<CigenData | null> {
    const sql = `SELECT * FROM ${Table.CigenData.name} WHERE ${Table.CigenData.Col.textDb} = ?`
    return await this.db.getData(sql, [textDb], rs => this.createOneCigenDataFromRs(rs))
  }

  /** CigenData ResultSet → Model */
  private createOneCigenDataFromRs(rs: relationalStore.ResultSet): CigenData {
    let data       = new CigenData()
    data.cigenId   = rs.getLong(rs.getColumnIndex(Table.CigenData.Col.cigenId))
    data.cigenName = ResultSetTool.decodeString(rs, Table.CigenData.Col.cigenName)
    data.textDb    = ResultSetTool.decodeString(rs, Table.CigenData.Col.textDb)
    return data
  }
}