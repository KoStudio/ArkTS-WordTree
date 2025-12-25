import { WordDetail }       from '../../datas/word/WordDetail'
import { Word }             from '../../datas/word/Word'
import { BaseWordDbAccess } from '../../datas/basedict/BaseWordDbAccess'

// MARK: - Constant 常量类
/**
 * OnlineWord 常量定义
 * 包含业务相关的固定值常量
 */
export class Constant {
  /** baseDict 的 idx 也是从 1 开始的，Word 中的 idx 也是从 1 开始的，
   *  两者有重复的可能，所以这里在 baseWord 的 idx 上加固定值 */
  static readonly Idx_     = 100000

  /** 固定为 999 */
  static readonly PartId   = 999

  /** 固定为 0 */
  static readonly UnitId   = 0

  /** 固定为 0 */
  static readonly UnitNo   = 0

  static readonly PartName = '#Cache'
  static readonly UnitName = '#Online'
}

// MARK: - CodingKeys 编码键类
/**
 * OnlineWord JSON 编码键定义
 * 包含与服务器 API 交互时使用的键名
 */
export class CodingKeys {
  static readonly TitleEn      = 'title_en'
  static readonly PronEn       = 'pron_en'
  static readonly PronUs       = 'pron_us'
  static readonly TitleCn1     = 'title_cn1'
  static readonly TitleCn2     = 'title_cn2'
  static readonly TitleCn3     = 'title_cn3'
  static readonly WordChange   = 'word_change'
  static readonly SynWords     = 'syn_words'
  static readonly AsynWords    = 'asyn_words'
  static readonly ExampleEn1   = 'example_en1'
  static readonly ExampleCn1   = 'example_cn1'
  static readonly ExampleEn2   = 'example_en2'
  static readonly ExampleCn2   = 'example_cn2'
  static readonly ExampleEn3   = 'example_en3'
  static readonly ExampleCn3   = 'example_cn3'
  static readonly UsedPhase    = 'used_phase'
  static readonly En2en        = 'en2en'
  static readonly Discriminate = 'discriminate'
}

// MARK: - OnlineWord 数据模型
export class OnlineWord {
  titleEn       : string | null = null
  pronEn        : string | null = null
  pronUs        : string | null = null
  titleCn1      : string | null = null
  titleCn2      : string | null = null
  titleCn3      : string | null = null
  wordChange    : string | null = null
  synWords      : string | null = null
  asynWords     : string | null = null
  exampleEn1    : string | null = null
  exampleCn1    : string | null = null
  exampleEn2    : string | null = null
  exampleCn2    : string | null = null
  exampleEn3    : string | null = null
  exampleCn3    : string | null = null
  usedPhase     : string | null = null
  en2en         : string | null = null
  discriminate  : string | null = null

  constructor(json?: Record<string, Object>) {
    if (!json) return

    this.titleEn      = (json[CodingKeys.TitleEn]      as string) ?? null
    this.pronEn       = (json[CodingKeys.PronEn]       as string) ?? null
    this.pronUs       = (json[CodingKeys.PronUs]       as string) ?? null
    this.titleCn1     = (json[CodingKeys.TitleCn1]     as string) ?? null
    this.titleCn2     = (json[CodingKeys.TitleCn2]     as string) ?? null
    this.titleCn3     = (json[CodingKeys.TitleCn3]     as string) ?? null
    this.wordChange   = (json[CodingKeys.WordChange]   as string) ?? null
    this.synWords     = (json[CodingKeys.SynWords]     as string) ?? null
    this.asynWords    = (json[CodingKeys.AsynWords]    as string) ?? null
    this.exampleEn1   = (json[CodingKeys.ExampleEn1]   as string) ?? null
    this.exampleCn1   = (json[CodingKeys.ExampleCn1]   as string) ?? null
    this.exampleEn2   = (json[CodingKeys.ExampleEn2]   as string) ?? null
    this.exampleCn2   = (json[CodingKeys.ExampleCn2]   as string) ?? null
    this.exampleEn3   = (json[CodingKeys.ExampleEn3]   as string) ?? null
    this.exampleCn3   = (json[CodingKeys.ExampleCn3]   as string) ?? null
    this.usedPhase    = (json[CodingKeys.UsedPhase]    as string) ?? null
    this.en2en        = (json[CodingKeys.En2en]        as string) ?? null
    this.discriminate = (json[CodingKeys.Discriminate] as string) ?? null
  }

  static fromArray(arr: Object[] | null): OnlineWord[] {
    if (!arr) return []
    return arr.map(o => new OnlineWord(o as Record<string, Object>))
  }

  /// 将 OnlineWord 转换成 Word，用于查询返回
  async asWord(): Promise<Word> {
    const word   = new Word()

    word.idx     = await this.getIdx()   // 不能为 0，录音时需要此 idx
    word.partId  = Constant.PartId
    word.partName= Constant.PartName
    word.unitId  = Constant.UnitId
    word.unitName= Constant.UnitName
    word.unitNo  = Constant.UnitNo
    word.titleEn = this.titleEn
    word.titleCn1= this.titleCn1

    return word
  }

  /// 将 OnlineWord 转换成 WordDetail，用于写入 DB
  async asWordDetail(): Promise<WordDetail> {
    const wordDetail      = new WordDetail()

    wordDetail.idx        = await this.getIdx()
    wordDetail.partId     = Constant.PartId
    wordDetail.partName   = Constant.PartName
    wordDetail.unitId     = Constant.UnitId
    wordDetail.unitName   = Constant.UnitName
    wordDetail.unitNo     = Constant.UnitNo
    wordDetail.titleEn    = this.titleEn
    wordDetail.pronEn     = this.pronEn
    wordDetail.pronUs     = this.pronUs
    wordDetail.titleCn1   = this.titleCn1
    wordDetail.titleCn2   = this.titleCn2
    wordDetail.titleCn3   = this.titleCn3
    wordDetail.wordImage  = null
    wordDetail.wordChange = this.wordChange
    wordDetail.synWords   = this.synWords
    wordDetail.asynWords  = this.asynWords
    wordDetail.exampleEn1 = this.exampleEn1
    wordDetail.exampleCn1 = this.exampleCn1
    wordDetail.exampleEn2 = this.exampleEn2
    wordDetail.exampleCn2 = this.exampleCn2
    wordDetail.exampleEn3 = this.exampleEn3
    wordDetail.exampleCn3 = this.exampleCn3
    wordDetail.usedPhrase = this.usedPhase
    wordDetail.en2En      = this.en2en
    wordDetail.discriminate = this.discriminate

    return wordDetail
  }

  /// 获取本地 baseWord 中对应的 idx
  async getIdx(): Promise<number> {
    const title = this.titleEn
    if (!title) return 0

    const baseWord = await BaseWordDbAccess.shared.getBaseWordByText(title)
    if (baseWord) {
      return Constant.Idx_ + (baseWord.idx ?? 0)
    }

    const hashCode = this._stringHashCode(title)
    return Constant.Idx_ * 10 + (Math.abs(hashCode) % (Constant.Idx_ * 10))
  }

  /// 字符串 hashCode 实现
  private _stringHashCode(str: string): number {
    let hash = 0
    if (str.length === 0) return hash

    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i)
      hash       = ((hash << 5) - hash) + char
      hash       = hash & hash
    }
    return hash
  }
}