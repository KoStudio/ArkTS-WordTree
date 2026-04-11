import { Constants } from "../../../app/constants/Constants";
import { AppUtility } from "../../../common/utils/AppUtility";
import { NumberUtility } from "../../../common/utils/NumberUtility";
import { StringDealUtility } from "../../../common/utils/strings/StringDealUtility";
import { MapTransform, StringMapUtility } from "../../../common/utils/strings/StringMapUtility";
import { EWordEditableField } from "../../managers/eword/EWordEditManager";
import { Word } from "./Word";

/**
 * WordDetail
 * 单词详情数据模型（继承 Word）
 */
export class WordDetail extends Word {

  // 以下字段仅详情层持有（Word 列表模型已去掉，与 iOS/Android 一致）
  pronEn            : string | null = null;
  pronUs            : string | null = null;
  titleCn2          : string | null = null;
  titleCn3          : string | null = null;
  exampleEn1        : string | null = null;
  exampleCn1        : string | null = null;

  wordImage         : string | null = null;
  wordChange        : string | null = null;
  synWords          : string | null = null;
  asynWords         : string | null = null;

  exampleEn2        : string | null = null;
  exampleCn2        : string | null = null;
  exampleEn3        : string | null = null;
  exampleCn3        : string | null = null;

  usedPhrase        : string | null = null;
  en2En             : string | null = null;

  discriminate      : string | null = null;
  private discriminate2 : string | null = null; // 去除重复后的缓存结果

  /** EWord 扩展：词根、同根词（与 iOS WordDetail 一致；仅存 Override / 展示用） */
  root              : string | null = null;
  cognates          : string | null = null;


  override async getWordDetail(): Promise<WordDetail | null> {
    return this
  }

  /**
   * 按可编辑字段取当前展示值（与 iOS `WordDetail.value(for:)` 一致，供 EWord 编辑页用）。
   * @param field                    字段枚举
   * @param rootDisplayFromCigens    无 root 覆盖时与详情页一致的词根助记文案（Cigen 拼接）
   * @param sameRootDescFallback     无 cognates 覆盖时的同根词展示 fallback
   */
  valueForField(field: EWordEditableField, rootDisplayFromCigens: string, sameRootDescFallback: string): string {
    const dedup = this.getDiscriminateRemovedDuplications()

    switch (field) {
      case EWordEditableField.pronUs:
        return this.pronUs ?? ''

      case EWordEditableField.titleCn1:
        return this.titleCn1 ?? ''

      case EWordEditableField.titleCn2:
        return this.titleCn2 ?? ''

      case EWordEditableField.titleCn3:
        return this.titleCn3 ?? ''

      case EWordEditableField.wordChange:
        return this.wordChange ?? ''

      case EWordEditableField.synWords:
        return this.synWords ?? ''

      case EWordEditableField.asynWords:
        return this.asynWords ?? ''

      case EWordEditableField.exampleEn1:
        return this.exampleEn1 ?? ''

      case EWordEditableField.exampleCn1:
        return this.exampleCn1 ?? ''

      case EWordEditableField.exampleEn2:
        return this.exampleEn2 ?? ''

      case EWordEditableField.exampleCn2:
        return this.exampleCn2 ?? ''

      case EWordEditableField.exampleEn3:
        return this.exampleEn3 ?? ''

      case EWordEditableField.exampleCn3:
        return this.exampleCn3 ?? ''

      case EWordEditableField.usedPhrase:
        return this.usedPhrase ?? ''

      case EWordEditableField.en2En:
        return this.en2En ?? ''

      // 详情页用 discriminateRemovedDuplications，编辑页保持一致
      case EWordEditableField.discriminate:
        return (dedup ?? this.discriminate) ?? ''

      case EWordEditableField.root:
        return (this.root ?? rootDisplayFromCigens) || ''

      case EWordEditableField.cognates:
        return (this.cognates ?? sameRootDescFallback) || ''

      default:
        return ''
    }
  }

  /**
   * 详情层合并 EWordOverride（与 iOS `WordDetail.applyEWordOverrideMap(forDetail:)` 一致）。
   * @param map fieldKey（item* / root / cognates）到覆盖展示值的映射
   */
  override applyEWordOverrideMap(map: Record<string, string>): void {
    const fk = (f: EWordEditableField): string => f as string;
    const keys = Object.keys(map);

    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = map[key];

      // 未定义的值不覆盖模型字段
      if (value === undefined) {
        continue;
      }

      switch (key) {
        // item8 美音
        case fk(EWordEditableField.pronUs):
          this.pronUs = value;
          break;

        // item9～11 中文释义
        case fk(EWordEditableField.titleCn1):
          this.titleCn1 = value;
          break;
        case fk(EWordEditableField.titleCn2):
          this.titleCn2 = value;
          break;
        case fk(EWordEditableField.titleCn3):
          this.titleCn3 = value;
          break;

        // item13 单词变形
        case fk(EWordEditableField.wordChange):
          this.wordChange = value;
          break;

        // item14～15 近义 / 反义
        case fk(EWordEditableField.synWords):
          this.synWords = value;
          break;
        case fk(EWordEditableField.asynWords):
          this.asynWords = value;
          break;

        // item16～21 例句
        case fk(EWordEditableField.exampleEn1):
          this.exampleEn1 = value;
          break;
        case fk(EWordEditableField.exampleCn1):
          this.exampleCn1 = value;
          break;
        case fk(EWordEditableField.exampleEn2):
          this.exampleEn2 = value;
          break;
        case fk(EWordEditableField.exampleCn2):
          this.exampleCn2 = value;
          break;
        case fk(EWordEditableField.exampleEn3):
          this.exampleEn3 = value;
          break;
        case fk(EWordEditableField.exampleCn3):
          this.exampleCn3 = value;
          break;

        // item22 常用短语
        case fk(EWordEditableField.usedPhrase):
          this.usedPhrase = value;
          break;

        // item23 英英释义
        case fk(EWordEditableField.en2En):
          this.en2En = value;
          break;

        // item24 详细说明（需清空辨析缓存）
        case fk(EWordEditableField.discriminate):
          this.discriminate = value;
          this.discriminate2 = null;
          break;

        // 扩展：词根
        case fk(EWordEditableField.root):
          this.root = value;
          break;

        // 扩展：同根词
        case fk(EWordEditableField.cognates):
          this.cognates = value;
          break;

        // 未知键忽略，兼容未来字段
        default:
          break;
      }
    }
  }

  // 合并释义 1～3（与 Android WordDetail.getTitleCnsJoined 对齐；列表 Word 不提供此方法）
  getTitleCnsJoined(): string {
    const titles: string[] = [];

    if (this.titleCn1) {
      titles.push(this.titleCn1);
    }
    if (this.titleCn2) {
      titles.push(this.titleCn2);
    }
    if (this.titleCn3) {
      titles.push(this.titleCn3);
    }

    return AppUtility.getJoinedStringByRemovingDuplications(
      titles,
      Constants.TitleTextJp.wordsMaxPart
    );
  }

  /**
   * 从词形变化中提取英文单词
   */
  getWordChangeEnWords(): string[] {
    return StringDealUtility.matchEnWords(this.wordChange);
  }

  /**
   * 获取需要高亮 / 标记的文本集合
   */
  getMarkTexts(): string[] {
    const markTexts: string[] = [];

    // 来自词形变化
    markTexts.push(...this.getWordChangeEnWords());

    // 将短语拆分（空格 & "-"）
    if (this.titleEn) {
      const wordTexts = this.titleEn.replace(/-/g, " ").split(" ");
      for (const str of wordTexts) {
        markTexts.push(str);
      }

      // 原始短语
      markTexts.push(this.titleEn);
    }

    return markTexts;
  }

  // ============================================================
  // MARK: - Discriminate 处理
  // ============================================================

  /**
   * 获取去重后的辨析说明（带缓存）
   */
  getDiscriminateRemovedDuplications(): string | null {
    if (!this.discriminate2) {
      this.discriminate2 = this.removedDuplicationsForDiscriminate();
    }
    return this.discriminate2;
  }

  /**
   * 对 discriminate 文本进行去重处理
   */
  private removedDuplicationsForDiscriminate(): string | null {
    if (!this.discriminate || this.discriminate.length === 0) {
      return this.discriminate;
    }

    // ------------------------------------------------------------
    // 这些 / 這些 / 这两 / 這兩 前加换行，便于后续去重
    // ------------------------------------------------------------
    let desc = this.discriminate
      .replace("这些", "\n这些")
      .replace("這些", "\n這些")
      .replace("这两", "\n这两")
      .replace("這兩", "\n這兩");

    // ------------------------------------------------------------
    // 处理类似：2. 3. 这类编号，确保从第二项开始换行
    // ------------------------------------------------------------
    class NumberedLineTransform implements MapTransform {
      transform(partStr: string | null): string | null {
        if (!partStr || partStr.length <= 1) {
          return partStr;
        }

        const dotIndex = partStr.indexOf(".");
        if (dotIndex > 0) {
          const numIndex = dotIndex - 1;
          const head = partStr.substring(numIndex, dotIndex);

          if (NumberUtility.isInt(head)) {
            const num = parseInt(head, 10);
            if (num > 1) {
              return partStr.replace(`${head}.`, `\n${head}.`);
            }
          }
        }

        return partStr;
      }
    }

    const transformInstance = new NumberedLineTransform();
    desc = StringMapUtility.map(desc, "\n", transformInstance);

    // ------------------------------------------------------------
    // 以换行符为单位去除重复项
    // ------------------------------------------------------------
    return StringMapUtility.removedDuplications(desc, "\n");
  }
}