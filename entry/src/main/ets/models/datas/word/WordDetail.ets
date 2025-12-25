import { Constants } from "../../../app/constants/Constants";
import { AppUtility } from "../../../common/utils/AppUtility";
import { NumberUtility } from "../../../common/utils/NumberUtility";
import { StringDealUtility } from "../../../common/utils/strings/StringDealUtility";
import { MapTransform, StringMapUtility } from "../../../common/utils/strings/StringMapUtility";
import { Word } from "./Word";

/**
 * WordDetail
 * 单词详情数据模型（继承 Word）
 */
export class WordDetail extends Word {


  // pronEn           : string | null = null;
  // pronUs           : string | null = null;

  // titleCn2         : string | null = null;
  // titleCn3         : string | null = null;
  wordImage        : string | null = null;
  wordChange       : string | null = null;
  synWords         : string | null = null;
  asynWords        : string | null = null;

  // exampleEn1       : string | null = null;
  // exampleCn1       : string | null = null;
  exampleEn2       : string | null = null;
  exampleCn2       : string | null = null;
  exampleEn3       : string | null = null;
  exampleCn3       : string | null = null;

  usedPhrase       : string | null = null;
  en2En            : string | null = null;

  discriminate     : string | null = null;
  private discriminate2 : string | null = null; // 去除重复后的缓存结果


  override async getWordDetail(): Promise<WordDetail | null> {
    return this
  }
  //
  // /**
  //  * 将多个中文释义合并为一个字符串（去重）
  //  */
  // getTitleCnsJoined(): string {
  //   const titles: string[] = [];
  //
  //   if (this.titleCn1) {
  //     titles.push(this.titleCn1);
  //   }
  //   if (this.titleCn2) {
  //     titles.push(this.titleCn2);
  //   }
  //   if (this.titleCn3) {
  //     titles.push(this.titleCn3);
  //   }
  //
  //   return AppUtility.getJoinedStringByRemovingDuplications(
  //     titles,
  //     Constants.TitleTextJp.wordsMaxPart
  //   );
  // }

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