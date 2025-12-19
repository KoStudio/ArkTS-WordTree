import { BaseWordConstants } from "./BaseWordConstants";

/// DealTransform 回调类型
type DealTransform = (partStr: string) => string | null;

/**
 * Created by huminghua on 2017/10/31.
 */

export class StringDealUtilityForBaseWord {

  ///查找英文单字
  static matchEnWords(srcStr: string | null): Array<string> {
    const RegEnword = "([A-Za-z']+)";
    return StringDealUtilityForBaseWord.matchRegex(srcStr, RegEnword);
  }

  ///匹配正则表达式
  static matchRegex(srcStr: string | null, reg: string): Array<string> {
    const list: Array<string> = [];

    if (srcStr !== null) {
      const pattern = new RegExp(reg, "g");
      const matches = srcStr.matchAll(pattern);

      for (const m of matches) {
        if (m.index !== undefined) {
          const text = srcStr.substring(m.index, m.index + m[0].length);
          list.push(text);
        }
      }
    }

    return list;
  }

  /// 合并字符串列表
  static joinTexts(list: Array<string> | null, seperator: string): string | null {
    if (list === null) {
      return null;
    }
    return list.join(seperator);
  }

  public static removedDuplications(srcStr: string | null): string | null {
    return StringDealUtilityForBaseWord.removedDuplicationsWithSeperator(
      srcStr,
      BaseWordConstants.TitleTextJp.wordsSperator,
      BaseWordConstants.TitleTextJp.wordsSubSperator
    );
  }

  ///去重（按指定的符号分割后，去除重复的内容）
  public static removedDuplicationsWithSeperator(
    srcStr: string | null,
    seperator: string,
    subSeperator: string
  ): string | null {

    if (srcStr === null) {
      return null;
    }

    const tempList: Array<string> = [];

    return StringDealUtilityForBaseWord.dealInternal(
      srcStr,
      seperator,
      subSeperator,
      (partStr: string) => {
        const s = partStr.trim();
        if (s.length > 0 && !tempList.includes(s)) {
          tempList.push(s);
          return s; //判断重复
        }
        return null;
      }
    );
  }

  public static clipIfNeeds(srcStr: string | null): string | null {
    return StringDealUtilityForBaseWord.clipIfNeedsMaxParts(
      srcStr,
      BaseWordConstants.TitleTextJp.wordsMaxPart
    );
  }

  public static clipIfNeedsMaxParts(srcStr: string | null, maxParts: number): string | null {
    return StringDealUtilityForBaseWord.clipIfNeedsFull(
      srcStr,
      BaseWordConstants.TitleTextJp.wordsSperator,
      BaseWordConstants.TitleTextJp.wordsSubSperator,
      maxParts
    );
  }

  ///对于太长的翻译，截取指定长度[按“；”分隔]的 部分
  public static clipIfNeedsFull(
    srcStr: string | null,
    seperator: string,
    subSeperator: string,
    maxParts: number
  ): string | null {

    if (srcStr === null) {
      return null;
    }

    const tempList: Array<string> = [];

    return StringDealUtilityForBaseWord.dealInternal(
      srcStr,
      seperator,
      subSeperator,
      (partStr: string) => {
        const s = partStr.trim();
        if (s.length > 0 && tempList.length < maxParts) {
          tempList.push(s);
          return s; //判断重复
        }
        return null;
      }
    );
  }

  /// 按指定的分隔符和子分隔符进行split之后，对每一段子字符进行transform
  private static dealInternal(
    srcStr: string,
    seperator: string,
    subSeperator: string,
    transform: DealTransform
  ): string {

    const array = srcStr.split(seperator);
    const distList: Array<string> = [];

    for (const subStr of array) {
      const subArray = subStr.split(subSeperator);
      const distSubList: Array<string> = [];

      for (const str of subArray) {
        const tranStr = transform(str);
        if (tranStr !== null) {
          distSubList.push(tranStr);
        }
      }

      if (distSubList.length > 0) {
        distList.push(distSubList.join(subSeperator));
      }
    }

    return distList.join(seperator);
  }
}