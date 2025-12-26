import { DBAccessor } from "../../dbUtils/DBAccessor";
import { BookManager } from "../book/BookManager";


// MARK: - WordUser 数据库访问类
export abstract class UserDbSuperAccess {

  protected  db: DBAccessor | null = null;

  abstract createDbIfNeeds()

  constructor() {
    this.refreshDb()
  }

  getDbFolder(): string {
    return BookManager.getCurrentDirectoryOfUserData()
  }

  getDbPath(): string {
    return BookManager.getCurrentPathOfUserData()
  }

  refreshDb(): void {
    this.db = new DBAccessor(this.getDbPath(), null, false);
    this.createDbIfNeeds();
  }
}