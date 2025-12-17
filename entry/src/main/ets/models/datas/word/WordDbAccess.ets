// WordDbAccess.ets
import relationalStore from '@ohos.data.relationalStore';
import { ResName, ResPath } from '../../../app/constants/ResPath';
import { DebugLog } from '../../../app/debug/DebugLog';
import { AppLanguage } from '../../../common/components/Language/AppLanguage';
import { LanguageManager } from '../../../common/components/Language/LanguageManager';
import { lang_en_us } from '../../../common/components/Sounds/Cloud/CSoundDbAccessor/CDBSound';
import { DBAccessor } from '../../dbUtils/DBAccessor';
import { DbPrepareUtils } from '../../dbUtils/DBPrepare';
import { ResultSetTool } from '../../dbUtils/ResultSetTool';
import { Word } from './Word';


// ============================================================
// 数据库表结构定义 - Word表
// ============================================================
namespace WordTable {
  export const NAME = "Word";

  export namespace Col {
    export const id            = "id";
    export const categoryId    = "categoryId";
    export const categoryName  = "categoryName";
    export const unitId        = "unitId";
    export const unitName      = "unitName";
    export const unitNo        = "unitNo";
    export const wordEn        = "wordEn";
    export const wordKind      = "wordKind";
    export const wordPronounce = "wordPronounce";
    export const wordJp        = "wordJp";
    export const exampleEn     = "exampleEn";
    export const exampleJp     = "exampleJp";
    export const redWord       = "redWord";
  }
}

/**
 * Word数据库访问类 - 只读访问基础单词数据
 * 类似Swift中的Repository模式或Kotlin中的DAO模式
 */
export class WordDbAccess {
  private static instance: WordDbAccess | null = null;
  private db: DBAccessor | null = null;

  // 单例模式，类似Swift的static let shared = WordDbAccess()
  public static get shared(): WordDbAccess {
    if (!WordDbAccess.instance) {
      WordDbAccess.instance = new WordDbAccess();
    }
    return WordDbAccess.instance;
  }

  private constructor() {
    this.init();
  }

  async init(){
    // 只读数据库，isReadOnly设置为true
    this.db = new DBAccessor(this.dbPath, null, true);
    await DbPrepareUtils.prepareDbIfNeeds(this, this.getResPath());
  }

  private get dbPath(): string {
      return this.getResPath().filePath
  }

  private getResPath(): ResPath {
    if (LanguageManager.getCurrentLanguage() === AppLanguage.Traditional) {
      return ResName.Word_Cnt
    }
    return ResName.Word_Cns
  }

  // ==========================================================
  // 基础查询方法
  // ==========================================================

  /**
   * 检查数据库是否可访问
   * 类似Kotlin中的suspend fun isDbAccessible(): Boolean
   */
  async isDbOpenable(): Promise<boolean> {
    const word = await this.getWordById(1);
    return word !== null;
  }

  /**
   * 根据ID查询单词
   * 类似Swift的func getWord(by id: Int) async -> Word?
   */
  async getWordById(id: number): Promise<Word | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${WordTable.NAME} WHERE ${WordTable.Col.id} = ?`;
    return await this.db.getData(sql, [id], (rs: relationalStore.ResultSet) => this.createWordFromResultSet(rs));
  }

  /**
   * 查询所有单词
   * 类似Kotlin的suspend fun getAllWords(): List<Word>
   */
  async getAllWords(): Promise<Word[] | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${WordTable.NAME}`;
    return await this.db.getDatas(sql, [], (rs: relationalStore.ResultSet) => this.createWordFromResultSet(rs));
  }

  /**
   * 根据分类ID查询单词
   */
  async getWordsByCategoryId(categoryId: number): Promise<Word[] | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${WordTable.NAME} WHERE ${WordTable.Col.categoryId} = ?`;
    return await this.db.getDatas(sql, [categoryId], (rs: relationalStore.ResultSet) => this.createWordFromResultSet(rs));
  }

  /**
   * 根据单元ID查询单词
   */
  async getWordsByUnitId(unitId: number): Promise<Word[] | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${WordTable.NAME} WHERE ${WordTable.Col.unitId} = ?`;
    return await this.db.getDatas(sql, [unitId], (rs: relationalStore.ResultSet) => this.createWordFromResultSet(rs));
  }


  /**
   * 从ResultSet创建Word对象
   * 类似Kotlin的private fun cursorToWord(cursor: Cursor): Word
   */
  private createWordFromResultSet(rs: relationalStore.ResultSet): Word {
    const word = new Word();

    try {
      const idIndex = rs.getColumnIndex(WordTable.Col.id);
      if (idIndex >= 0) word.id = rs.getLong(idIndex);

      const categoryIdIndex = rs.getColumnIndex(WordTable.Col.categoryId);
      if (categoryIdIndex >= 0) word.categoryId = rs.getLong(categoryIdIndex);

      const categoryNameIndex = rs.getColumnIndex(WordTable.Col.categoryName);
      if (categoryNameIndex >= 0) word.categoryName = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.categoryName);

      const unitIdIndex = rs.getColumnIndex(WordTable.Col.unitId);
      if (unitIdIndex >= 0) word.unitId = rs.getLong(unitIdIndex);

      const unitNameIndex = rs.getColumnIndex(WordTable.Col.unitName);
      if (unitNameIndex >= 0) word.unitName = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.unitName);

      const unitNoIndex = rs.getColumnIndex(WordTable.Col.unitNo);
      if (unitNoIndex >= 0) word.unitNo = rs.getLong(unitNoIndex);

      const wordEnIndex = rs.getColumnIndex(WordTable.Col.wordEn);
      if (wordEnIndex >= 0) word.wordEn = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.wordEn);

      const wordJpIndex = rs.getColumnIndex(WordTable.Col.wordJp);
      if (wordJpIndex >= 0) word.wordJp = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.wordJp);

      const wordKindIndex = rs.getColumnIndex(WordTable.Col.wordKind);
      if (wordKindIndex >= 0) word.wordKind = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.wordKind);

      const wordPronounceIndex = rs.getColumnIndex(WordTable.Col.wordPronounce);
      if (wordPronounceIndex >= 0) word.wordPronounce = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.wordPronounce);

      const exampleEnIndex = rs.getColumnIndex(WordTable.Col.exampleEn);
      if (exampleEnIndex >= 0) word.exampleEn = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.exampleEn)?.trim() || '';

      const exampleJpIndex = rs.getColumnIndex(WordTable.Col.exampleJp);
      if (exampleJpIndex >= 0) word.exampleJp = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.exampleJp);

      const redWordIndex = rs.getColumnIndex(WordTable.Col.redWord);
      if (redWordIndex >= 0) word.redWord = ResultSetTool.decodeStringOnlyBase64(rs, WordTable.Col.redWord);

    } catch (error) {
      DebugLog.e(`WordDbAccess: 创建Word对象失败 - ${error}`);
    }

    return word;
  }

  /**
   * 获取单词总数
   */
  async getWordsCount(): Promise<number> {
    if (!this.db) return 0;

    const sql = `SELECT COUNT(*) FROM ${WordTable.NAME}`;
    return await this.db.getCount(sql);
  }

  /**
   * 获取分类下的单词数量
   */
  async getWordsCountByCategory(categoryId: number): Promise<number> {
    if (!this.db) return 0;

    const sql = `SELECT COUNT(*) FROM ${WordTable.NAME} WHERE ${WordTable.Col.categoryId} = ?`;
    return await this.db.getCount(sql, [categoryId]);
  }

  /**
   * 获取单元下的单词数量
   */
  async getWordsCountByUnit(unitId: number): Promise<number> {
    if (!this.db) return 0;

    const sql = `SELECT COUNT(*) FROM ${WordTable.NAME} WHERE ${WordTable.Col.unitId} = ?`;
    return await this.db.getCount(sql, [unitId]);
  }
}