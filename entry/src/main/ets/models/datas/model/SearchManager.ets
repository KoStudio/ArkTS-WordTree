import { DebugFlg } from "../../../app/debug/DebugFlg";
import { DebugLog } from "../../../app/debug/DebugLog";
import { SectionDatas } from "../../../common/utils/array/SectionDatas";
import { TEUtility } from "../../../common/utils/TEUtility";
import { BookManager } from "../book/BookManager";
import { WordUser } from "../myData/WordUser";
import { WordUserDbAccess } from "../myData/WordUserDbAccess";
import { WordDbAccess } from "../word/WordDbAccess";
import { Part, Unit } from "./Part_Unit";
import { Mistake, MistakeHelper } from "./Mistake";

// MARK: - 常量定义（类似Swift的static let或Kotlin的const val）
export class SearchConstants {
  // 测试结果常量
  static readonly TEST_RESULT_NONE   : number = 0;
  static readonly TEST_RESULT_CORRECT: number = 1;
  static readonly TEST_RESULT_WRONG  : number = -1;

  // 收藏等级常量
  static readonly FAVORITE_LEVEL_0: number     = 0;
  static readonly FAVORITE_LEVEL_1: number     = 1;
  static readonly FAVORITE_LEVEL_2: number     = 2;
  static readonly FAVORITE_LEVEL_3: number     = 3;
  static readonly FAVORITE_LEVEL_4: number     = 4;
  static readonly FAVORITE_LEVEL_5: number     = 5;

  // 分类ID常量
  // static readonly CATEGORY_ID_LEVEL_1: number  = 1;
  // static readonly CATEGORY_ID_LEVEL_2: number  = 2;
  // static readonly CATEGORY_ID_LEVEL_3: number  = 3;
  static readonly PART_ID_ALL    : number  = -1;

  // 错误次数分段常量
  // static readonly WRANG_TIMES_0: number        = 0;
  // static readonly WRANG_TIMES_1_ONLY: number   = 1 << 0;
  // static readonly WRANG_TIMES_1_3: number      = 1 << 1;
  // static readonly WRANG_TIMES_3_5: number      = 1 << 2;
  // static readonly WRANG_TIMES_5_10: number     = 1 << 3;
  // static readonly WRANG_TIMES_10_OVER: number  = 1 << 4;
  // static readonly WRANG_TIMES_ALL: number      =
  //   SearchConstants.WRANG_TIMES_1_ONLY | SearchConstants.WRANG_TIMES_1_3 |
  //   SearchConstants.WRANG_TIMES_3_5 | SearchConstants.WRANG_TIMES_5_10 | SearchConstants.WRANG_TIMES_10_OVER;
}


export class SearchManager {
  // MARK: - 单例实现（类似Swift的static let shared）
  private static instance: SearchManager | null = null;

  public static get shared(): SearchManager {
    if (!SearchManager.instance) {
      SearchManager.instance = new SearchManager();
    }
    return SearchManager.instance;
  }

  // MARK: - 私有属性
  private parts: Part[] = [];
  private units: Unit[] = [];
  private allWords: WordUser[] = [];

  // MARK: - 私有构造函数
  private constructor() {
    this.initialize();
  }

  // MARK: - 初始化方法
  private initialize(): void {
    this.loadDataStructures();
    DebugLog.d('SearchManager: 初始化完成');
  }

  /**
   * 刷新数据（在数据修改后调用）
   */
  refreshData(): void {
    this.loadDataStructures();
  }

  private async loadDataStructures(): Promise<void> {
    const textDb      = BookManager.shared.currentBook?.textDb ?? null

    const words     = await (new WordDbAccess(textDb)).getAllWords() || [];
    const wordUsers = await WordUserDbAccess.shared.getAllWordUsers() || [];

    const userMap   = new Map<string, WordUser>();
    for (const u of wordUsers) {
      if (u.titleEn !== null) {
        userMap.set(u.titleEn, u);
      }
    }

    const merged: WordUser[] = words.map(w => {
      const existed = w.titleEn !== null ? userMap.get(w.titleEn) : null;

      if (existed) {
        // 覆盖基本字段
        existed.titleEn        = w.titleEn;
        existed.titleCn1        = w.titleCn1;
        // existed.wordKind      = w.wordKind;
        existed.pronEn = w.pronEn;
        existed.exampleEn1     = w.exampleEn1;
        existed.exampleCn1     = w.exampleCn1;
        // existed.redWord       = w.redWord;
        existed.unitId        = w.unitId;
        existed.unitNo        = w.unitNo;
        existed.unitName      = w.unitName;
        existed.partId    = w.partId;
        existed.partName  = w.partName;
        return existed;
      }

      // 没有用户记录 → 创建新的 WordUser（手动赋值）
      const newWord = new WordUser();
      newWord.idx            = w.idx;
      newWord.unitId        = w.unitId;
      newWord.unitNo        = w.unitNo;
      newWord.partId    = w.partId;
      newWord.partName  = w.partName;
      newWord.titleEn        = w.titleEn;
      newWord.titleCn1        = w.titleCn1;
      // newWord.wordKind      = w.wordKind;
      newWord.pronEn = w.pronEn;
      newWord.exampleEn1     = w.exampleEn1;
      newWord.exampleCn1     = w.exampleCn1;
      // newWord.redWord       = w.redWord;
      newWord.unitName      = w.unitName;

      // 初始化用户字段
      newWord.favoriteLevel  = 0;
      newWord.learnTimes     = 0;
      newWord.correctedTimes = 0;
      newWord.wrangTimes     = 0;//(Math.random() * 100 % 12);

      ///调试用
      if (DebugFlg.isDebugMode()) {
        // newWord.favoriteLevel  = ((Math.round(Math.random() * 100)) % 5 === 1 ? 0 : 1)
        // newWord.learnTimes     = ((Math.round(Math.random() * 100)) % 5 === 1 ? 0 : 1)
        // newWord.wrangTimes     = (Math.random() * 100 % 12)
        // newWord.correctedTimes = ((Math.round(Math.random() * 100)) % 5 === 1 ? 0 : 1)
      }

      newWord.lastResultType = 0;
      // newWord.wrangYear      = 0;
      // newWord.wrangMonth     = 0;
      // newWord.wrangDay       = 0;
      newWord.wrangDate      = null
      newWord.memo           = null;
      newWord.shareMemos     = []
      newWord.deleted        = false;

      return newWord;
    });

    this.allWords = merged;

    // 构建分类和单元的数据结构
    this.buildPartsAndUnits();
  }

  /**
   * 构建分类和单元的数据结构
   */
  private buildPartsAndUnits(): void {
    this.parts = [];
    this.units      = [];

    let currentUnitId     : number   | null = -1;
    let currentCategoryId : number   | null = -1;
    let currentUnit       : Unit     | null = null;
    let currentCategory   : Part | null = null;

    // 使用函数式编程处理数据构建
    this.allWords.forEach(word => {
      // 单元变化时创建新单元
      if (currentUnitId !== word.unitId) {
        currentUnitId = word.unitId;
        currentUnit   = this.createUnitFromWord(word);
        this.units.push(currentUnit);
      }

      // 分类变化时创建新分类
      if (currentCategoryId !== word.partId) {
        currentCategoryId = word.partId;
        currentCategory   = this.createPartFromWord(word);
        this.parts.push(currentCategory);
      }

      // 将单词添加到当前单元
      if (currentUnit) {
        currentUnit.words.push(word);
      }

      // 将单元添加到当前分类（如果尚未添加）
      if (currentCategory && currentUnit) {
        const unitExists = currentCategory.units.some(u => u.unitId === currentUnit!.unitId);
        if (!unitExists) {
          currentCategory.units.push(currentUnit);
        }
      }
    });
  }

  /**
   * 从单词创建单元对象
   */
  private createUnitFromWord(word: WordUser): Unit {
    const unit      = new Unit();
    unit.unitId     = word.unitId || 0;
    unit.unitNo     = word.unitNo || 0;
    unit.unitName   = word.unitName || '';
    unit.partId     = word.partId || 0;
    unit.words      = [];
    return unit;
  }

  /**
   * 从单词创建分类对象
   */
  private createPartFromWord(word: WordUser): Part {
    const part        = new Part();
    part.partId       = word.partId || 0;
    part.partName     = word.partName  || '';
    part.units        = [];
    return part;
  }


  /**
   * 获取所有单元
   * 类似Swift的var allUnits: [Unit] { get }
   */
  getAllUnits(): Unit[] {
    return [...this.units]; // 返回副本以避免外部修改
  }

  /**
   * 获取所有分类
   */
  getAllPart(): Part[] {
    return [...this.parts];
  }

  /**
   * 获取所有单词
   */
  getAllWords(): WordUser[] {
    return [...this.allWords];
  }

  /**
   * 获取活跃单词（未删除的单词）
   */
  getAliveWords(): WordUser[] {
    return this.allWords.filter(word => !word.deleted);
  }

  /**
   * 获取活跃单元（包含未删除单词的单元）
   */
  getAliveUnits(): Unit[] {
    return this.units.filter(unit => unit.aliveWords.length > 0);
  }

  /**
   * 获取活跃分类（包含活跃单元的分类）
   */
  getAliveParts(): Part[] {
    return this.parts.filter(part => part.aliveUnits.length > 0);
  }

  /**
   * 获取已删除的单词
   */
  getDeletedWords(): WordUser[] {
    return this.allWords.filter(word => word.deleted);
  }

  /**
   * 根据单元ID获取单元
   */
  getUnitById(unitId: number): Unit | undefined {
    return this.units.find(unit => unit.unitId === unitId);
  }

  /**
   * 根据分类ID获取分类
   */
  getPartById(partId: number): Part | undefined {
    return this.parts.find(part => part.partId === partId);
  }

  /**
   * 根据分类ID获取单词
   */
  getWordsByPartId(partId: number): WordUser[] {
    if (partId === SearchConstants.PART_ID_ALL) {
      return this.getAliveWords();
    }

    const part = this.getPartById(partId);
    return part ? part.aliveWords : [];
  }

  getWordsWithIds(ids: number[]): WordUser[] {
    const array: WordUser[] = [];
    const liveWords: WordUser[] = this.getAliveWords();

    for (const word of liveWords) {
      if (ids.includes(word.idx ?? 0)) {
        array.push(word);
      }
    }

    return array;
  }

  /**
   * 根据单元ID获取单词
   */
  getWordsByUnitId(unitId: number): WordUser[] {
    const unit = this.getUnitById(unitId);
    return unit ? unit.aliveWords : [];
  }

  /**
   * 根据单词ID获取单词
   */
  getWordById(id: number): WordUser | undefined {
    return this.allWords.find(word => word.idx === id);
  }

  /**
   * 获取已学习的单词
   */
  getLearnedWords(): WordUser[] {
    const learnedWords: WordUser[] = [];
    const aliveUnits = this.getAliveUnits();

    aliveUnits.forEach(unit => {
      learnedWords.push(...unit.learnedWords);
    });

    return learnedWords;
  }

  /**
   * 获取正确回答的单词
   */
  getCorrectedWords(): WordUser[] {
    const correctedWords: WordUser[] = [];
    const aliveUnits = this.getAliveUnits();

    aliveUnits.forEach(unit => {
      correctedWords.push(...unit.correctedWords);
    });

    return correctedWords;
  }

  /**
   * 获取错误回答的单词
   */
  getWrongWords(): WordUser[] {
    const wrongWords: WordUser[] = [];
    const aliveUnits = this.getAliveUnits();

    aliveUnits.forEach(unit => {
      wrongWords.push(...unit.wrongWords);
    });

    return wrongWords;
  }


  /**
   * 获取按分类分段的单元数据
   */
  getUnitsSectionedByPart(partId: number): SectionDatas<string, Unit> {
    const sectionedDatas = new SectionDatas<string, Unit>();

    if (partId === SearchConstants.PART_ID_ALL) {
      this.parts.forEach(part => {
        if (part.aliveUnits.length > 0) {
          sectionedDatas.addSectionWithDatas(part.partName, part.aliveUnits);
        }
      });
    } else {
      const part = this.getPartById(partId);
      if (part && part.aliveUnits.length > 0) {
        sectionedDatas.addSectionWithDatas(part.partName, part.aliveUnits);
      }
    }

    return sectionedDatas;
  }

  /**
   * 获取复习用的分段单词数据
   */
  getReviewSectionedWords(): SectionDatas<string, WordUser> {
    const sectionWords = new SectionDatas<string,WordUser>();
    const reviewWords = this.allWords.filter(word =>
    word.lastResultType === SearchConstants.TEST_RESULT_WRONG && !word.deleted
    );

    // 按错误日期排序（降序）
    const sortedWords = reviewWords.sort((a, b) => {
      if (a.wrangYear !== b.wrangYear) return b.wrangYear - a.wrangYear;
      if (a.wrangMonth !== b.wrangMonth) return b.wrangMonth - a.wrangMonth;
      return b.wrangDay - a.wrangDay;
    });

    // 添加到分段数据
    sortedWords.forEach(word => {
      if (word.wrangYear && word.wrangMonth && word.wrangDay) {
        const dateString = word.wrangDateString;
        sectionWords.addSectionWithData(dateString, word);
      }
    });

    return sectionWords;
  }

  ///获取所有收藏级别（去重并排序）
  public getAllFavorites(): number[] {
    let favorites: number[] = [];

    for (let word of this.getAliveWords()) {
      if (word.favoriteLevel > 0 && !word.isDeleted()) {  // 未删除
        if (!favorites.includes(word.favoriteLevel)) {   // 去重
          favorites.push(word.favoriteLevel);
        }
      }
    }

    // 排序（升序）
    favorites.sort((a, b) => {
      return a - b;
    });

    return favorites;
  }

  public getAllMistakes(): Mistake[] {
    let mistakes: Mistake[] = [];

    for (let word of this.getAliveWords()) {
      if (!word.isDeleted()) { // 未删除

        const times = word.wrangTimes;

        if (times === 1) {
          if (!mistakes.includes(Mistake.mistake_1_Only)) {
            mistakes.push(Mistake.mistake_1_Only);
          }
        } else if (times > 1 && times <= 3) {
          if (!mistakes.includes(Mistake.mistake_1_3)) {
            mistakes.push(Mistake.mistake_1_3);
          }
        } else if (times > 3 && times <= 5) {
          if (!mistakes.includes(Mistake.mistake_3_5)) {
            mistakes.push(Mistake.mistake_3_5);
          }
        } else if (times > 5 && times <= 10) {
          if (!mistakes.includes(Mistake.mistake_5_10)) {
            mistakes.push(Mistake.mistake_5_10);
          }
        } else if (times > 10) {
          if (!mistakes.includes(Mistake.mistake_10_Over)) {
            mistakes.push(Mistake.mistake_10_Over);
          }
        }

        // 已经集齐五个分类，提前结束
        if (mistakes.length === 5) {
          break;
        }
      }
    }

    // 排序（与 CompareUtility.compare 即 object1 - object2 等效）
    mistakes.sort((a, b) => a - b);

    return mistakes;
  }

  // MARK: - Mistake 统计
  public getMistakesWithCount(): [number, [Mistake, number][]] {
    const mistakesCnt: [Mistake, number][] = [
      [Mistake.mistake_1_Only, 0],
      [Mistake.mistake_1_3,    0],
      [Mistake.mistake_3_5,    0],
      [Mistake.mistake_5_10,   0],
      [Mistake.mistake_10_Over,0]
    ]

    let words            = this.getAliveWords()
    let cntWrangTimesAll = 0

    words.forEach((word, index) => {
      for (let i = 0; i < mistakesCnt.length; i++) {
        if (MistakeHelper.fromWrongTimes(word.wrangTimes) === mistakesCnt[i][0]) {
          mistakesCnt[i] = [mistakesCnt[i][0], mistakesCnt[i][1] + 1]
          break
        }
      }

      if (word.wrangTimes > 0) {
        cntWrangTimesAll++;
      }
    })
    return [cntWrangTimesAll, mistakesCnt]
  }

  //////querys

  // 快速搜索算法
  public querySearch(searchText: string): WordUser[] {
    const lowerSearch = searchText.toLowerCase();
    let   aliveWords  = this.getAliveWords();

    return aliveWords.filter(word => {
      const en = (word.titleEn || '').toLowerCase();
      const jp = word.titleCn1 || '';

      // 优先检查开头匹配，速度更快
      return en.startsWith(lowerSearch) ||
      jp.startsWith(searchText) ||
      en.includes(lowerSearch) ||
      jp.includes(searchText);
    });
  }

  /**
   * 安全比较器：按 wordEn 忽略大小写排序（不使用 localeCompare 的 options）
   */
  private compareByWordEn(a: WordUser, b: WordUser): number {
    const A : string = (a.titleEn || '').toLowerCase();
    const B : string = (b.titleEn || '').toLowerCase();

    if (A < B) return -1;
    if (A > B) return  1;
    return 0;
  }

  /**
   * 按英文首字母进行分段（abc 分组）
   * isStill = true：仅返回未测试（lastResultType = NONE）的单词
   * searchText 可选：模糊查询（仅匹配 wordEn 与 wordJp）
   */
  queryForCharGroup(filtedWords: WordUser[], isStill: boolean): SectionDatas<string, WordUser> {
    const sectionWords = new SectionDatas<string, WordUser>();

    // 排序：按英文字母排序（忽略大小写）
    filtedWords.sort((a, b) => this.compareByWordEn(a, b));

    filtedWords.forEach(word => {
      // 仅保留未测试单词（isStill = true）
      if (isStill && word.lastResultType !== SearchConstants.TEST_RESULT_NONE) {
        return;
      }

      const firstChar: string = ((word.titleEn || '').substring(0, 1) || '#').toLowerCase();
      sectionWords.addSectionWithData(firstChar, word);
    });

    return sectionWords;
  }

  /**
   * 按 partId 进行分段（CategoryName → Words）
   * searchText 可选：模糊查询（仅匹配 wordEn 与 wordJp）
   */
  queryForPart(filtedWords: WordUser[]): SectionDatas<string, WordUser> {
    const sectionWords = new SectionDatas<string, WordUser>();


    // 排序：先按 partId，然后按 wordEn
    filtedWords.sort((a, b) => {
      const aCat : number = a.partId ?? 0;
      const bCat : number = b.partId ?? 0;

      if (aCat !== bCat) {
        return aCat - bCat;
      }

      const A : string = (a.titleEn || '').toLowerCase();
      const B : string = (b.titleEn || '').toLowerCase();

      if (A < B) return -1;
      if (A > B) return  1;
      return 0;
    });

    filtedWords.forEach(word => {
      sectionWords.addSectionWithData(word.partName ?? '', word);
    });

    return sectionWords;
  }

  /**
   * 按 favoriteLevel 分段（倒序）
   * searchText 可选：模糊查询（仅匹配 wordEn 与 wordJp）
   * 仅包含 favoriteLevel > 0 的单词（与 Java 行为一致）
   */
  queryForFavorite(filtedWords: WordUser[]): SectionDatas<string, WordUser> {
    const sectionWords = new SectionDatas<string, WordUser>();

    // 倒序排序：favoriteLevel 大的在前
    filtedWords.sort((a, b) => {
      const A : number = a.favoriteLevel ?? 0;
      const B : number = b.favoriteLevel ?? 0;
      return B - A;  // 降序
    });

    filtedWords.forEach(word => {
      if ((word.favoriteLevel ?? 0) > 0) {
        const key = TEUtility.getFavoriteStarTextString(word.favoriteLevel)//`Fav等级 ${word.favoriteLevel}`;
        sectionWords.addSectionWithData(key, word);
      }
    });

    return sectionWords;
  }

  /**
   * 按 wrangTimes 倒序分段
   * searchText 可选：模糊查询（仅匹配 wordEn 与 wordJp）
   * 仅包含 wrangTimes > 0 的单词（与 Java 行为一致）
   */
  queryForWrangTimes(filtedWords: WordUser[]): SectionDatas<string, WordUser> {
    const sectionWords = new SectionDatas<string, WordUser>();

    filtedWords.sort((a, b) => {
      const A : number = a.wrangTimes ?? 0;
      const B : number = b.wrangTimes ?? 0;
      return B - A;  // 降序
    });

    filtedWords.forEach(word => {
      if ((word.wrangTimes ?? 0) > 0) {
        const mistake = MistakeHelper.fromWrongTimes(word.wrangTimes)//`错 ${word.wrangTimes} 次`;
        const key     = MistakeHelper.localizedName(mistake)
        sectionWords.addSectionWithData(key, word);
      }
    });

    return sectionWords;
  }



  // MARK: - 数据操作和方法

  /**
   * 清空学习次数
   */
  async deleteLearnTimes(): Promise<void> {
    this.allWords.forEach(word => {
      word.learnTimes = 0;
    });
    await WordUserDbAccess.shared.clearLearnTimes()
  }

  /**
   * 清空测试结果
   */
  async deleteTestResults(): Promise<void> {
    this.allWords.forEach(word => {
      word.correctedTimes = 0;
      word.wrangTimes = 0;
      word.lastResultType = SearchConstants.TEST_RESULT_NONE;
    });
    await WordUserDbAccess.shared.clearTestResults();
  }

  /**
   * 清空备忘录
   */
  async deleteMemo(): Promise<void> {
    this.allWords.forEach(word => {
      word.memo = '';
    });
    await WordUserDbAccess.shared.clearMemos();
  }

  /**
   * 清空收藏状态
   */
  async deleteFavorites(): Promise<void> {
    this.allWords.forEach(word => {
      word.favoriteLevel = SearchConstants.FAVORITE_LEVEL_0;
    });
    await WordUserDbAccess.shared.clearFavorites();
  }

  /**
   * 清空复习列表
   */
  async deleteReviewList(): Promise<void> {
    this.allWords.forEach(word => {
      word.lastResultType = SearchConstants.TEST_RESULT_NONE;
    });
    await WordUserDbAccess.shared.clearReviewList();
  }

  /**
   * 清空已删除单词标记
   */
  async deleteDeletedWords(): Promise<void> {
    this.allWords.forEach(word => {
      word.deleted = false;
    });
    await WordUserDbAccess.shared.clearDeletedWords();
  }

  /**
   * 更改单词的收藏等级
   */
  async changeFavoriteLevelForWord(word: WordUser, newLevel: number): Promise<void> {
    word.favoriteLevel = newLevel;
    await WordUserDbAccess.shared.saveWordUser(word);
  }

  /**
   * 增加单词的学习次数
   */
  async incrementLearnTimesForWord(word: WordUser): Promise<void> {
    word.incrementLearnTimes();
    await WordUserDbAccess.shared.saveWordUser(word);
  }

  /**
   * 增加单词的测试结果
   */
  async incrementTestResultForWord(word: WordUser, result: number): Promise<void> {
    word.incrementTestResult(result);
     await WordUserDbAccess.shared.saveWordUser(word);
  }

  /**
   * 保存单词的本地备忘录
   */
  async saveLocalMemoForWord(word: WordUser, memo: string): Promise<void> {
    word.memo = memo;
     await WordUserDbAccess.shared.saveWordUser(word);
  }

  // MARK: - 工具方法

  /**
   * 获取问题单词的所有可能文本（用于测试选项）
   */
  getAllTextForQuestionWord(question: WordUser, isEnglishAnswer: boolean): string[] {
    const texts: string[] = [];
    const questionTextJp = question.wordJpClippedString;

    this.allWords.forEach(word => {
      if (isEnglishAnswer) {
        // 英→日测试时，排除与问题文本日语相同的单词
        if (questionTextJp !== word.wordJpClippedString) {
          texts.push(word.titleEn || '');
        }
      } else {
        // 日→英测试时，使用日语的裁剪文本
        texts.push(word.wordJpClippedString);
      }
    });

    return texts;
  }


}
