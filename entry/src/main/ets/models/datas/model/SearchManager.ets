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
import { OnlineWordManager } from "../../managers/onlinesearch/OnlineWordManager";
import { OnlineWord } from "../../managers/onlinesearch/OnlineWord";
import { Word } from "../word/Word";
import call from "@ohos.telephony.call";
import { Toast } from "../../../common/utils/Toast";
import { getStringF } from "../../../common/utils/ResourceUtils";
import { SpeechRecordManager } from "../../../common/components/Speech/Recorder/SpeechRecordManager";
import { getAppContext } from "../../../app/constants/AppContext";
import { SimpleEventBus } from "../../../common/components/eventbus/SimpleEventBus";
import { BookManagerNotification } from "../book/BookManager";
import { PlanManager } from "../../managers/plan/plancurve/PlanManager";

// MARK: - 常量定义（类似Swift的static let或Kotlin的const val）
export class SearchConstants {
  // 测试结果常量
  static readonly TEST_RESULT_NONE   : number = 0;
  static readonly TEST_RESULT_CORRECT: number = 1;
  static readonly TEST_RESULT_WRONG  : number = 2;

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
  private parts                     : Part[]                    = [];
  private units                     : Unit[]                    = [];
  private allWords                  : WordUser[]                = [];

  private allCnTexts: Record<string, string>[] = []
  private refreshingTask: Promise<void> | null = null

  // MARK: - 私有构造函数
  private constructor() {
    this.initialize();
  }

  // MARK: - 初始化方法
  // 初始化：注册与 iOS/Android SearchManager 一致的书本事件监听，并首次加载缓存数据。
  // SearchManager 为全局单例常驻，不维护 on(...) 的解绑句柄。
  private initialize(): void {

    // 调用：监听书本切换（bookChanged）后，先 clear 再 rebuild（与 iOS/Android 一致）
    SimpleEventBus.on(BookManagerNotification.bookChanged, () => {
      void this.actionBookChanged()
    })

    // 调用：监听当前书更新（currentBookUpdated）后，先 clear 再 rebuild（与 iOS/Android 一致）
    SimpleEventBus.on(BookManagerNotification.currentBookUpdated, () => {
      void this.actionBookUpdated()
    })

    // 调用：监听书单更新（bookListUpdated）后，按 updated 同链路重建缓存
    SimpleEventBus.on(BookManagerNotification.bookListUpdated, () => {
      void this.actionBookUpdated()
    })

    // 调用：首次加载数据缓存
    void this.actionBookUpdated();

    // 调用：输出初始化日志
    DebugLog.d('SearchManager: 初始化完成');
  }

  getWordDbAccess(): WordDbAccess | null {
    const textDb = BookManager.shared.currentBook?.textDb
    if (!textDb) return null

    return new WordDbAccess(textDb)
  }

  /**
   * 刷新数据（在数据修改后调用）
   */
  async refreshData(): Promise<void> {
    // 对齐 iOS/Android：刷新时统一走 clear + rebuild，而非仅增量覆盖
    await this.actionBookUpdated();
  }

  // 与 iOS/Android SearchManager.clearDatas 对齐：清空全部内存缓存
  private clearDatas(): void {
    this.parts      = [];
    this.units      = [];
    this.allWords   = [];
    this.allCnTexts = [];
  }

  // 串行化重建任务，避免并发 refresh 造成缓存抖动
  private async rebuildCaches(): Promise<void> {
    if (this.refreshingTask) {
      await this.refreshingTask
      return
    }

    this.refreshingTask = (async () => {
      this.clearDatas()
      await this.loadWords()
    })()

    try {
      await this.refreshingTask
    } finally {
      this.refreshingTask = null
    }
  }

  // 对齐 iOS/Android actionBookChanged：切书后重建缓存
  private async actionBookChanged(): Promise<void> {
    await this.rebuildCaches()

    // 对齐 iOS/Android：切书后提示当前词书名称
    const bookName = BookManager.shared.currentBook?.bookName
    if (bookName) {
      Toast.showMessage(getStringF($r('app.string.books_msg_change_book'), bookName))
    }

    // 对齐 iOS/Android：切书后重新初始化 Plan
    // Harmony 当前无 reInit 命名方法，这里用 init() 重新加载当前 Plan 状态。
    void PlanManager.shared.init()
  }

  // 对齐 iOS/Android actionBookUpdated：当前书数据变化后重建缓存
  private async actionBookUpdated(): Promise<void> {
    await this.rebuildCaches()

    // 对齐 iOS/Android：当前书数据更新后重新初始化 Plan（无需 toast）
    // Harmony 当前无 reInit 命名方法，这里用 init() 重新加载当前 Plan 状态。
    void PlanManager.shared.init()
  }

  private async loadWords(): Promise<void> {
    // 并行获取数据，减少等待时间
    const results = await Promise.all([
      this.getWordDbAccess()?.getAllWords() || [],
      WordUserDbAccess.shared.getAllOnlineWords() || [],
      WordUserDbAccess.shared.getAllWordUsers() || []
    ]);

    const words       = results[0] || [];
    const wordsOnline = results[1] || []; 
    const wordUsers   = results[2] || [];

    // 合并所有基础单词
    const allBaseWords = words.concat(wordsOnline);
    
    // 优化：使用更高效的Map构建方式
    const userMap = new Map<string, WordUser>();
    for (let i = 0; i < wordUsers.length; i++) {
      const u = wordUsers[i];
      if (u.titleEn !== null) {
        userMap.set(u.titleEn, u);
      }
    }

    // 预分配数组空间，避免频繁扩容
    const merged: WordUser[] = new Array(allBaseWords.length);
    
    // 使用for循环替代map，减少函数调用开销
    for (let i = 0; i < allBaseWords.length; i++) {
      const w = allBaseWords[i];
      const existed = w.titleEn !== null ? userMap.get(w.titleEn) : null;

      if (existed) {
        // 覆盖基本字段
        existed.idx            = w.idx;
        existed.partId         = w.partId;
        existed.partName       = w.partName;
        existed.unitId         = w.unitId;
        existed.unitNo         = w.unitNo;
        existed.unitName       = w.unitName;
        existed.titleEn        = w.titleEn;
        existed.titleCn1       = w.titleCn1;
        // 释义 2/3、音标、例句仅存 WordDetail，合并 learn 记录时不写列表层

        merged[i] = existed;
      } else {
        // 没有用户记录 → 创建新的 WordUser（手动赋值）
        const newWord            = new WordUser();
        newWord.idx              = w.idx;
        newWord.partId           = w.partId;
        newWord.partName         = w.partName;
        newWord.unitId           = w.unitId;
        newWord.unitNo           = w.unitNo;
        newWord.unitName         = w.unitName;
        newWord.titleEn          = w.titleEn;
        newWord.titleCn1         = w.titleCn1;

        // 初始化用户字段
        newWord.favoriteLevel    = 0;
        newWord.learnTimes       = 0;
        newWord.correctedTimes   = 0;
        newWord.wrangTimes       = 0;
        newWord.lastResultType   = 0;
        newWord.wrangDate        = null;
        newWord.memo             = null;
        newWord.shareMemos       = [];
        newWord.deleted          = false;

        merged[i] = newWord;
      }
    }

    this.allWords = merged;

    // EWordOverride：与 iOS SearchManager._allWords 中 applyEWordOverrideMap(forWord:) 一致

    // 动态加载 EWord 模块，避免 SearchManager 与 EWordManager 静态循环依赖
    const ewm = await import('../../managers/eword/EWordManager');

    // 读取 learnDb 中全部覆盖（内部带缓存）
    const overrides = await ewm.EWordManager.shared.allOverridesCached();

    // 无任何覆盖记录则跳过合并（与 iOS `if !overrides.isEmpty`）
    if (Object.keys(overrides).length > 0) {
      for (let i = 0; i < this.allWords.length; i++) {
        const w = this.allWords[i];
        const en = w.titleEn;

        // 列表项缺少英文词则无法与覆盖表 key 对应
        if (en) {
          const om = overrides[en];

          // 该词无覆盖行则保持词库原值
          if (om) {

            // 列表层合并（与 iOS Word 一致，当前仅 titleCn1 等列表字段）
            w.applyEWordOverrideMap(om);
          }
        }
      }
    }

    // 构建分类和单元的数据结构
    this.preparePartsAndUnits();
  }
  /**
   * 构建分类和单元的数据结构
   */
  private preparePartsAndUnits(): void {
    this.parts = [];
    this.units = [];

    // 使用Map来快速查找和分组，避免重复遍历
    const unitMap = new Map<number, Unit>();
    const partMap = new Map<number, Part>();

    // 先按unitId和partId分组
    for (let i = 0; i < this.allWords.length; i++) {
      const word = this.allWords[i];
      const unitId = word.unitId || 0;
      const partId = word.partId || 0;
      
      // 处理单元
      if (!unitMap.has(unitId)) {
        const unit = this.createUnitFromWord(word);
        unitMap.set(unitId, unit);
        this.units.push(unit);
      }
      
      // 处理分类
      if (!partMap.has(partId)) {
        const part = this.createPartFromWord(word);
        partMap.set(partId, part);
        this.parts.push(part);
      }
    }

    // 将单词分配到对应的单元
    for (let i = 0; i < this.allWords.length; i++) {
      const word = this.allWords[i];
      const unitId = word.unitId || 0;
      const unit = unitMap.get(unitId);
      if (unit) {
        unit.words.push(word);
      }
    }

    // 将单元分配到对应的分类
    for (let i = 0; i < this.units.length; i++) {
      const unit = this.units[i];
      const partId = unit.partId || 0;
      const part = partMap.get(partId);
      if (part) {
        // 检查是否已存在，避免重复添加
        let exists = false;
        for (let j = 0; j < part.units.length; j++) {
          if (part.units[j].unitId === unit.unitId) {
            exists = true;
            break;
          }
        }
        if (!exists) {
          part.units.push(unit);
        }
      }
    }

    // 对parts和units进行排序
    this.sortPartsAndUnits();
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
   * 对parts和units进行排序
   */
  private sortPartsAndUnits(): void {
    // 对parts按partId升序排序
    this.parts.sort((a, b) => {
      return (a.partId || 0) - (b.partId || 0);
    });

    // 对units按unitId升序排序
    this.units.sort((a, b) => {
      return (a.unitId || 0) - (b.unitId || 0);
    });

    // 对每个part中的units按unitId排序
    for (let i = 0; i < this.parts.length; i++) {
      const part = this.parts[i];
      if (part.units && part.units.length > 0) {
        part.units.sort((a, b) => {
          return (a.unitId || 0) - (b.unitId || 0);
        });
      }
    }
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
   * 获取活跃单词的ID数组（未删除的单词）
   */
  getAliveWordIds(): number[] {
    return this.allWords
      .filter(word => !word.deleted)
      .map(word => word.idx ?? 0);
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


  ///获取 有笔记的单词
  getWordsWithMemos(): WordUser[] {
    return this.getAliveWords().filter(word => !!word.memo || (word.shareMemos?.length ?? 0) > 0
    )
  }

  ///获取 有录音的单词
  async getWordsWithRecord(): Promise<WordUser[]> {
    const recorder = new SpeechRecordManager()
    const result: WordUser[] = []

    // 先获取所有录音记录
    const allSounds = await recorder.getAllSounds()
    if (!allSounds || allSounds.length === 0) {
      return result
    }

    // 只遍历录音记录，查找对应的单词
    for (const sound of allSounds) {
      if (sound.name) {
        // 在活跃单词中查找对应单词
        for (const word of this.getAliveWords()) {
          if (word.titleEn === sound.name) {
            result.push(word)
            break // 找到后跳出内层循环
          }
        }
      }
    }

    return result
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
   * EWord 保存/恢复后，仅同步 allWords 中与 titleEn 相同的 WordUser 列表层（与 loadWords 后 applyEWordOverrideMap 语义一致）。
   * @param titleEn  英文词，用于定位 allWords 与查库
   * 说明：不负责 clearWordDetailCache；详情缓存由 currentBookUpdated 订阅方（如 DetailCardOne）或其它 UI 时机处理。
   */
  async syncWordMemoryByTitleEn(titleEn: string): Promise<void> {
    if (!titleEn || titleEn.length === 0) {
      return
    }

    // 1) 读取当前持久层中的基础词条数据（当前书 Word 表；若不存在再查在线临时表）。
    let latest = await this.getWordDbAccess()?.getWordDetailByTitleEn(titleEn) ?? null
    if (latest === null) {
      latest = await WordUserDbAccess.shared.getOnlineWordDetailByTitleEn(titleEn) ?? null
    }

    // 2) 读取该词覆盖并应用到列表层（与 allWords 初始化时 applyEWordOverrideMap 一致）。
    const ewm = await import('../../managers/eword/EWordManager')
    const overrideMap = await ewm.EWordManager.shared.loadOverrides(titleEn)

    // 3) 把最新值回写到内存中所有同 titleEn 对象，确保旧引用也被同步更新。
    for (let i = 0; i < this.allWords.length; i++) {
      const w = this.allWords[i]
      if (w.titleEn !== titleEn) {
        continue
      }

      if (latest !== null) {
        w.titleCn1   = latest.titleCn1
      }

      // 列表层覆盖（当前主要影响 titleCn1 等列表可见字段）
      w.applyEWordOverrideMap(overrideMap)
    }

    // 中文候选缓存依赖 titleCn 字段，编辑后需失效重建。
    this.allCnTexts = []
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
    // 与 Android 对齐：先改内存对象，再通过 WordUser 统一入口持久化
    word.changeFavorite(newLevel);
    await word.saveWordUserDatas();
  }

  /**
   * 增加单词的学习次数
   */
  async incrementLearnTimesForWord(word: WordUser): Promise<void> {
    word.incrementLearnTimes();
    await word.saveWordUserDatas();
  }

  /**
   * 增加单词的测试结果
   */
  async incrementTestResultForWord(word: WordUser, result: number): Promise<void> {
    word.incrementTestResult(result);
    await word.saveWordUserDatas();
  }

  /**
   * 保存单词的本地备忘录
   */
  async saveLocalMemoForWord(word: WordUser, memo: string): Promise<void> {
    word.memo = memo;
    await word.saveWordUserDatas();
  }

  // MARK: - 工具方法

  /**
   * 获取问题单词的所有可能文本（用于测试选项）
   */
  /**
   * 获取问题单词的所有可能文本（用于测试选项）
   * @param question         当前题目单词
   * @param isEnglishAnswer  true：答案是英文；false：答案是中文
   */
  async getAllTextForQuestionWord(question: WordUser, isEnglishAnswer : boolean): Promise<string[]> {

    const result: string[] = []

    // ====== 英文作为答案 ======
    if (isEnglishAnswer) {

      // 懒加载所有中英文映射
      if (this.allCnTexts.length === 0) {
        const textDb = BookManager.shared.currentBook?.textDb
        if (!textDb) return []

        const dbAccess  = new WordDbAccess(textDb)
        this.allCnTexts = await dbAccess.getAllCnTexts() ?? []
      }

      const questionCn = question.titleCn1ClippedShort ?? ''

      this.allCnTexts.forEach(map => {
        const cn1 = map['titleCn1'] ?? ''
        const cn2 = map['titleCn2'] ?? ''
        const cn3 = map['titleCn3'] ?? ''

        // 排除中文含义相同的单词（与 Java 行为一致）
        if (
          !cn1.includes(questionCn) &&
            !cn2.includes(questionCn) &&
            !cn3.includes(questionCn)
        ) {
          const en = map['titleEn']
          if (en) {
            result.push(en)
          }
        }
      })

    }
    // ====== 中文作为答案 ======
    else {

      // 直接使用当前书中的所有词
      this.getAliveWords().forEach(word => {
        if (word.titleCn1) {
          result.push(word.titleCn1ClippedShort)
        }
      })
    }

    DebugLog.d(`getAllTextForQuestionWord count: ${result.length}`)
    return result
  }

  searchWord(titleEn: string | null, callback: (word: WordUser | null) => void): void {
    if (!titleEn) {
      callback(null)
      return
    }

    /// 已经存在（内存中查找）
    for (const word of this.getAllWords()) {
      if (titleEn === word.titleEn) {
        callback(word)
        return
      }
    }

    /// online 查询
    OnlineWordManager.shared.loadWord(titleEn, async (succeed: boolean, msg: string | null, onlineWord: OnlineWord | null): Promise<void> => {

        if (onlineWord) {

          // 插入 online 临时 DB
          WordUserDbAccess.shared.insertOrUpdateOnlineDataForWord(onlineWord.asWordDetail())

          const word: WordUser = onlineWord.asWordUser()

          // 加入内存
          this.allWords.push(word)

          // ⚠️ 注意：不能重新生成 words 数据
          // 否则会替换先前的 word，引起数据混乱
          // by ko 2022.12.01
          callback(word)

          this.parts.length = 0
          this.units.length = 0

          // 构建分类和单元的数据结构
          this.preparePartsAndUnits();



        } else {

          // 回调失败
          callback(null)

          Toast.showMessage(msg)
        }
      }
    )
  }

}
