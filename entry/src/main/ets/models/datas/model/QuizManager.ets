import { DebugLog } from "../../../app/debug/DebugLog";
import { WordUser } from "../myData/WordUser";
import { Part, Unit } from "./Part_Unit";
import { Mistake } from "./Mistake";
import { SearchConstants, SearchManager } from "./SearchManager";

export enum QuizType {
  Unit,      // 单元测验
  All,       // 全部测验
  Category,  // 分类测验
  Mistake,   // 错题测验
  Favorite,  // 收藏测验
  Review,    // 复习测验
  Custom     // 自定义测验
}

export enum QuestionMode {
  Normal,     // 普通模式
  Challenge,  // 挑战模式
  Spell       // 拼写模式
}

// 使用常量枚举 (Const Enum) - 推荐用于性能
export enum QuestionSpeed {
  Slow   = 10,    // 单位：秒
  Normal = 8,
  Fast   = 5
}

export enum QuestionOrder {
  SerialNo, // 顺序出题
  Random      // 随机出题
}


export enum QuestionType {
  Eiwa, // 英→日
  Waei  // 日→英
}


class QuizConstants {
  // 问题速度常量（单位：毫秒）
  // static readonly QUESTION_SPEED_SLOW: number    = 10 * 1000;   // 慢速：10秒
  // static readonly QUESTION_SPEED_NORMAL: number  = 8 * 1000;     // 常速：8秒
  // static readonly QUESTION_SPEED_FAST: number    = 5 * 1000;     // 快速：5秒

  // 默认值常量
  static readonly DEFAULT_QUESTION_COUNT: number = 10;          // 默认题目数量
  static readonly DEFAULT_INTERVAL: number       = 1 * 1000;    // 默认间隔时间：1秒

  // 评分标准常量
  static readonly SCORE_WELL_DONE: number        = 85;  // 优秀：85%
  static readonly SCORE_GOOD: number             = 60;  // 良好：60%

  // 测试结果常量
  static readonly TEST_RESULT_NONE: number       = 0;   // 未测试
  static readonly TEST_RESULT_CORRECT: number    = 1;   // 正确
  static readonly TEST_RESULT_WRONG: number      = 2;   // 错误 注意WordTree这里是2，不是-1
}


export class QuizManager {
  // MARK: - 单例实例（类似Swift的static let shared）
  private static instance: QuizManager | null = null;

  /**
   * 获取单例实例
   * 类似Swift的static let shared = QuizManager()
   */
  public static get shared(): QuizManager {
    if (!QuizManager.instance) {
      QuizManager.instance = new QuizManager();
    }
    return QuizManager.instance;
  }

  // MARK: - 实例属性
  // 当前测验状态
  public showingIndex: number          = -1;                    // 当前显示题目的索引
  public showingQuestion: WordUser | null = null;              // 当前显示的问题
  public correctIndexOfAnswers: number = -1;                    // 正确答案的索引

  // 单词列表
  public scopeWords: WordUser[]        = [];                    // 范围单词列表
  public questionWords: WordUser[]     = [];                    // 问题单词列表
  public wrongWords: WordUser[]        = [];                    // 错误单词列表
  public correctWords: WordUser[]      = [];                    // 正确单词列表

  // 测验配置
  public quizType: QuizType            = QuizType.All; // 测验类型
  public questionMode: QuestionMode    = QuestionMode.Normal; // 问题模式
  public questionCount: number         = QuizConstants.DEFAULT_QUESTION_COUNT; // 问题数量
  public questionSpeed: QuestionSpeed  = QuestionSpeed.Normal//QuizConstants.QUESTION_SPEED_NORMAL; // 问题速度
  public questionOrder: QuestionOrder  = QuestionOrder.SerialNo; // 问题顺序
  public questionType: QuestionType    = QuestionType.Eiwa; // 问题类型
  public questionPronounce: boolean    = false;                // 是否发音
  public interval: number              = QuizConstants.DEFAULT_INTERVAL; // 间隔时间

  // 测验数据源
  public unit: Unit | null              = null;                 // 当前单元（用于单元测验）
  public units: Unit[]                  = [];                   // 单元列表（用于全部测验）
  public categories: Part[]         = [];                   // 分类列表（用于分类测验）
  public favorites: number[]            = [];                   // 收藏等级列表（用于收藏测验）
  public mistake: Mistake               = Mistake.mistake_All;  // 错误次数（用于错题测验）
  public wrangDate: Date | null         = null;                 // 错误日期（用于复习测验）
  public customWords: WordUser[]        = [];                   // 自定义单词列表（用于自定义测验）


  private constructor() {
  }

  prepareRun(): void {
    this.showingIndex          = -1;
    this.correctIndexOfAnswers = -1;
    this.showingQuestion       = null;
    this.wrongWords            = [];
    this.correctWords          = [];
  }


  clearQuiz(): void {
    this.showingIndex          = -1;
    this.showingQuestion       = null;
    this.correctIndexOfAnswers = -1;

    // 清空数组（使用length = 0性能更好）
    this.scopeWords.length     = 0;
    this.questionWords.length  = 0;
    this.wrongWords.length     = 0;
    this.correctWords.length   = 0;

    // 清空其他引用
    this.unit                  = null;
    this.units.length          = 0;
    this.categories.length     = 0;
    this.favorites.length      = 0;
    this.customWords.length    = 0;

    this.mistake            = 0;
    this.wrangDate             = null;
  }

  // MARK: - 测验创建和管理

  createNewQuiz(): WordUser[] | null {
    if (this.scopeWords.length === 0) {
      DebugLog.e('Error: createNewQuiz >> scopeWords为空');
      return null;
    }
    return this.createNewQuizWithWords(this.scopeWords);
  }


  createNewQuizWithWords(wordsSrc: WordUser[]): WordUser[] {
    this.questionWords.length = 0; // 清空现有问题

    // 根据测验类型调整题目数量
    this.questionCount = (this.quizType === QuizType.Unit ||
      this.quizType === QuizType.Custom)
      ? wordsSrc.length
      : this.questionCount;

    let selectedWords: WordUser[] = [];

    // 根据题目顺序选择单词
    switch (this.questionOrder) {
      case QuestionOrder.SerialNo:
        selectedWords = this.getSortedListFromList(wordsSrc, this.questionCount);
        break;
      case QuestionOrder.Random:
        selectedWords = this.getRandomListFromList(wordsSrc, this.questionCount);
        break;
      default:
        selectedWords = this.getSortedListFromList(wordsSrc, this.questionCount);
        break;
    }

    this.questionWords.push(...selectedWords);
    return [...this.questionWords]; // 返回副本
  }

  addWrongWord(wrongWord: WordUser): void {
    if (!this.wrongWords.some(word => word.idx === wrongWord.idx)) {
      this.wrongWords.push(wrongWord);
    }
  }

  addCorrectWord(correctWord: WordUser): void {
    if (!this.correctWords.some(word => word.idx === correctWord.idx)) {
      this.correctWords.push(correctWord);
    }
  }

  nextQuestion(): WordUser | null {
    this.showingIndex++;
    this.correctIndexOfAnswers = -1;

    if (this.showingIndex < 0 || this.showingIndex >= this.questionWords.length) {
      DebugLog.e(`_showingIndex: ${this.showingIndex} 越界!!!`);
      return null;
    }

    this.showingQuestion = this.questionWords[this.showingIndex];
    return this.showingQuestion;
  }


  getAnswerTextOfShowingQuestion(): string[] {
    if (!this.showingQuestion) {
      return [];
    }

    const answerCount = this.questionMode === QuestionMode.Challenge ? 8 : 4;
    const answerTexts: string[] = new Array(answerCount).fill('');

    // 获取正确答案文本
    const isTextEn: boolean = this.questionType === QuestionType.Waei;
    const correctText: string = isTextEn
      ? (this.showingQuestion.titleEn || '')
      : (this.showingQuestion.wordJpClippedString || '');

    // 随机选择正确答案位置
    this.correctIndexOfAnswers = Math.floor(Math.random() * answerCount);
    answerTexts[this.correctIndexOfAnswers] = correctText;

    // 获取所有可能的文本（这里需要实现获取备选答案的逻辑）
    const allTextList: string[] = this.getAllTextForQuestionWord(this.showingQuestion, isTextEn);

    // 填充错误答案
    const wrongAnswers: string[] = [];
    const usedTexts = new Set<string>([correctText]);

    while (wrongAnswers.length < answerCount - 1 && allTextList.length > 0) {
      const randomIndex = Math.floor(Math.random() * allTextList.length);
      const wrongText   = allTextList[randomIndex];

      if (!usedTexts.has(wrongText)) {
        wrongAnswers.push(wrongText);
        usedTexts.add(wrongText);
        allTextList.splice(randomIndex, 1);
      }
    }

    // 填充答案数组
    let wrongAnswerIndex = 0;
    for (let i = 0; i < answerCount; i++) {
      if (i !== this.correctIndexOfAnswers && wrongAnswerIndex < wrongAnswers.length) {
        answerTexts[i] = wrongAnswers[wrongAnswerIndex];
        wrongAnswerIndex++;
      }
    }

    return answerTexts;
  }

  passToNext(): void {
    if (this.showingQuestion) {
      this.showingQuestion.lastResultType = QuizConstants.TEST_RESULT_NONE;
    }
  }


  checkAnswer(answerIndex: number): boolean {
    const result = answerIndex === this.correctIndexOfAnswers;
    if (this.showingQuestion) {
      // 这里需要调用SearchManager更新测试结果
      const resultType = result ? QuizConstants.TEST_RESULT_CORRECT : QuizConstants.TEST_RESULT_WRONG;
      SearchManager.shared.incrementTestResultForWord(this.showingQuestion, resultType);
    }
    return result;
  }

  checkSpell(text: string): boolean {
    if (text && text.length > 0 && this.showingQuestion && this.showingQuestion.titleEn) {
      const correctTitle = this.showingQuestion.titleEn.trim().toLowerCase();
      const isCorrect = text.trim().toLowerCase() === correctTitle;

      if (this.showingQuestion) {
        const resultType = isCorrect ? QuizConstants.TEST_RESULT_CORRECT : QuizConstants.TEST_RESULT_WRONG;
        SearchManager.shared.incrementTestResultForWord(this.showingQuestion, resultType);
      }

      return isCorrect;
    }
    return false;
  }

  loadScopeWords(): WordUser[] {
    // 清空现有范围单词（等价 ObjC: [_scopeWords removeAllObjects];）
    this.scopeWords.length = 0;

    switch (this.quizType) {

      case QuizType.Unit:
        if (this.unit) {
          this.scopeWords.push(...this.unit.aliveWords);
        }
        break;

      case QuizType.All:
        for (const unit of this.units) {
          this.scopeWords.push(...unit.aliveWords);
        }
        break;

      case QuizType.Category:
        for (const category of this.categories) {
          // 对应 ObjC: wordsWithCategory:
          const words = SearchManager.shared.getWordsByPartId(category.partId);
          if (words && words.length > 0) {
            this.scopeWords.push(...words);
          }
        }
        break;

      case QuizType.Favorite: {
        // ObjC：遍历所有 aliveWords，再按 this.favorites 中的等级筛选
        const allWords: WordUser[] = SearchManager.shared.getAliveWords();
        for (const word of allWords) {
          for (const favLevel of this.favorites) {
            // 假设 word.favoriteLevel 与 ObjC 的类型一致
            if (word.favoriteLevel === (favLevel as number)) {
              this.scopeWords.push(word);
              break;
            }
          }
        }
        break;
      }

      case QuizType.Mistake: {
        // ObjC：遍历所有 aliveWords，根据 this.wrangTimes 的位掩码筛选
        const allWords: WordUser[] = SearchManager.shared.getAliveWords();
        for (const word of allWords) {
          // WrangTimes_1_Only 等常量在项目中应已定义，按 ObjC 逐项判断
          if ((this.mistake & Mistake.mistake_1_Only) === Mistake.mistake_1_Only) {
            if (word.wrangTimes === 1) {
              this.scopeWords.push(word);
              continue;
            }
          }

          if ((this.mistake & Mistake.mistake_1_3) === Mistake.mistake_1_3) {
            if (word.wrangTimes > 1 && word.wrangTimes <= 3) {
              this.scopeWords.push(word);
              continue;
            }
          }

          if ((this.mistake & Mistake.mistake_3_5) === Mistake.mistake_3_5) {
            if (word.wrangTimes > 3 && word.wrangTimes <= 5) {
              this.scopeWords.push(word);
              continue;
            }
          }

          if ((this.mistake & Mistake.mistake_5_10) === Mistake.mistake_5_10) {
            if (word.wrangTimes > 5 && word.wrangTimes <= 10) {
              this.scopeWords.push(word);
              continue;
            }
          }

          if ((this.mistake & Mistake.mistake_10_Over) === Mistake.mistake_10_Over) {
            if (word.wrangTimes > 10) {
              this.scopeWords.push(word);
              continue;
            }
          }
        }
        break;
      }

      case QuizType.Review: {
        let hasDate = false;
        let year    = 0, month = 0, day = 0;

        if (this.wrangDate instanceof Date) {
          hasDate = true;
          year    = this.wrangDate.getFullYear();
          month   = this.wrangDate.getMonth() + 1; // JS 月从0开始，ObjC 的 month 是 1..12
          day     = this.wrangDate.getDate();
        }

        if (hasDate) {
          const allWords: WordUser[] = SearchManager.shared.getAliveWords();
          for (const word of allWords) {
            if (word.lastResultType === QuizConstants.TEST_RESULT_WRONG /*kResult_Failed*/) {
              if (word.wrangYear === year && word.wrangMonth === month && word.wrangDay === day) {
                this.scopeWords.push(word);
              }
            }
          }
        }
        break;
      }

      case QuizType.Custom:
        if (this.customWords && this.customWords.length > 0) {
          this.scopeWords.push(...this.customWords);
        }
        break;

      default:
        break;
    }

    DebugLog.d(`loadScopeWord: ${this.scopeWords.length}`);
    // ObjC 返回的是内部数组对象 (_scopeWords)，此处亦返回原数组以保持等价行为
    return this.scopeWords;
  }


  private getRandomListFromList<T>(listSrc: T[], requestCount: number): T[] {
    if (!listSrc || listSrc.length === 0) {
      DebugLog.e('getRandomListFromList错误: listSrc为空');
      return [];
    }

    const listAll = [...listSrc]; // 创建副本
    const randomMaxSize = Math.min(requestCount, listAll.length);
    const listRandom: T[] = [];

    while (listRandom.length < randomMaxSize && listAll.length > 0) {
      const randomIndex = Math.floor(Math.random() * listAll.length);
      listRandom.push(listAll[randomIndex]);
      listAll.splice(randomIndex, 1);
    }

    return listRandom;
  }

  private getSortedListFromList(listSrc: WordUser[], requestCount: number): WordUser[] {
    // 按ID排序
    const sortedList = [...listSrc].sort((a, b) => (a.idx || 0) - (b.idx || 0));
    return sortedList.slice(0, Math.min(requestCount, sortedList.length));
  }


  private getAllTextForQuestionWord(word: WordUser, isEnglish: boolean): string[] {
    return SearchManager.shared.getAllTextForQuestionWord(word, isEnglish)
  }


  private isListContainsString(list: string[], str: string): boolean {
    return list.some(item => item === str);
  }


  get score(): number {
    if (this.questionWords.length === 0) return 0;
    return Math.round((this.correctWords.length / this.questionWords.length) * 100);
  }

  public nextUnit(): Unit | null {

    if (this.unit == null) {
      return null;
    } else {
      const allUnits: Unit[] = SearchManager.shared.getAliveUnits()

      for (let i = 0; i < allUnits.length; i++) {
        const unit: Unit = allUnits[i];
        if (this.unit.unitId === unit.unitId        // 当前 unit
          && i !== allUnits.length - 1) {             // 不是最后一个时
          this.unit = allUnits[i + 1]
          return unit                    // 返回下一个 unit
        }
      }

      return null;
    }
  }

  /**
   * 获取当前测验的评语图片资源
   * 类似Swift的static func或Kotlin的伴生对象方法
   */
   getCommentImage(score: number): Resource {
    if (score >= QuizConstants.SCORE_WELL_DONE) {
      return $r('app.media.quiz_result_well')
    } else if (score >= QuizConstants.SCORE_GOOD) {
      return $r('app.media.quiz_result_good');
    } else {
      return $r('app.media.quiz_result_bad');
    }
  }


  getCommentText(score: number): ResourceStr {
    if (score >= QuizConstants.SCORE_WELL_DONE) {
      return $r('app.string.quiz_result_score_comment_welldone')
    } else if (score >= QuizConstants.SCORE_GOOD) {
      return $r('app.string.quiz_result_score_comment_good')
    } else {
      return $r('app.string.quiz_result_score_comment_studyharder')
    }
  }

  getCommentColorResource(score: number): ResourceColor {
    if (score >= QuizConstants.SCORE_WELL_DONE) {
      return $r('app.color.color_quiz_result_welldone')
    } else if (score >= QuizConstants.SCORE_GOOD) {
      return $r('app.color.color_quiz_result_good')
    } else {
      return $r('app.color.color_quiz_result_studyharder')
    }
  }
}