import { Constants } from "../../../app/constants/Constants";

export interface DealTransform {
  transform(partStr: string): string | null;
}

export class StringDealUtility {

  /// 查找英文单字
  public static matchEnWords(srcStr: string | null): Array<string> {
    const RegEnword: string = "([A-Za-z']+)";
    return StringDealUtility.match(srcStr, RegEnword);
  }

  /// 匹配正则表达式
  public static match(srcStr: string | null, reg: string): Array<string> {
    const list: Array<string> = [];

    if (srcStr !== null) {
      const pattern: RegExp = new RegExp(reg, 'g');
      let matcher: RegExpExecArray | null;

      while ((matcher = pattern.exec(srcStr)) !== null) {
        const start: number = matcher.index;
        const end  : number = start + matcher[0].length;

        const text: string = srcStr.substring(start, end);
        list.push(text);
      }
    }

    return list;
  }

  /// 合并字符串列表
  public static getJoinedTextsFromList(
    list      : Array<string> | null,
    seperator : string
  ): string | null {

    if (list === null) {
      return null;
    }

    let result: string = '';
    for (let i = 0; i < list.length; i++) {
      if (i !== 0) {
        result += seperator;
      }
      result += list[i];
    }
    return result;
  }

  /// 去重（默认分隔符）
  public static removedDuplications(srcStr: string): string | null {
    return StringDealUtility.removedDuplicationsBySep(
      srcStr,
      Constants.TitleTextJp.wordsSperator,
      Constants.TitleTextJp.wordsSubSperator
    );
  }

  /// 去重（按指定的符号分割后，去除重复的内容）
  public static removedDuplicationsBySep(
    srcStr       : string,
    seperator    : string,
    subSeperator : string
  ): string | null {

    const tempList: Array<string> = [];
    return StringDealUtility.deal(
      srcStr,
      seperator,
      subSeperator,
      new RemoveDuplicateTransform(tempList)
    );
  }

  /// 截取指定长度（默认最大部分数）
  public static clipIfNeeds(srcStr: string): string | null {
    return StringDealUtility.clipIfNeedsWithMax(
      srcStr,
      Constants.TitleTextJp.wordsMaxPart
    );
  }

  /// 截取指定长度（可指定 maxParts）
  public static clipIfNeedsWithMax(
    srcStr   : string,
    maxParts : number
  ): string | null {
    return StringDealUtility.clipIfNeedsFull(
      srcStr,
      Constants.TitleTextJp.wordsSperator,
      Constants.TitleTextJp.wordsSubSperator,
      maxParts
    );
  }

  /// 对于太长的翻译，截取指定长度[按分隔符]的部分
  public static clipIfNeedsFull(
    srcStr       : string,
    seperator    : string,
    subSeperator : string,
    maxParts     : number
  ): string | null {

    const tempList: Array<string> = [];
    return StringDealUtility.deal(
      srcStr,
      seperator,
      subSeperator,
      new ClipTransform(tempList, maxParts)
    );
  }

  /// 按指定的分隔符和子分隔符进行 split 之后，对每一段子字符进行 transform
  private static deal(
    srcStr       : string,
    seperator    : string,
    subSeperator : string,
    transform    : DealTransform
  ): string | null {

    const array   : Array<string> = srcStr.split(seperator);
    const distList: Array<string> = [];

    for (const subStr of array) {
      const subArray    : Array<string> = subStr.split(subSeperator);
      const distSubList : Array<string> = [];

      for (const str of subArray) {
        const tranStr = transform.transform(str);
        if (tranStr !== null) {
          distSubList.push(tranStr);
        }
      }

      if (distSubList.length > 0) {
        distList.push(
          StringDealUtility.getJoinedTextsFromList(distSubList, subSeperator) as string
        );
      }
    }

    return StringDealUtility.getJoinedTextsFromList(distList, seperator);
  }
}

/// 内部类：去重 Transform
class RemoveDuplicateTransform implements DealTransform {
  private tempList: Array<string>;

  constructor(tempList: Array<string>) {
    this.tempList = tempList;
  }

  public transform(partStr: string): string | null {
    const s: string = partStr.trim();
    if (s.length > 0 && !this.tempList.includes(s)) {
      this.tempList.push(s);
      return s; // 判断重复
    }
    return null;
  }
}

/// 内部类：截断 Transform
class ClipTransform implements DealTransform {
  private tempList: Array<string>;
  private maxParts: number;

  constructor(tempList: Array<string>, maxParts: number) {
    this.tempList = tempList;
    this.maxParts = maxParts;
  }

  public transform(partStr: string): string | null {
    const s: string = partStr.trim();
    if (s.length > 0 && this.tempList.length < this.maxParts) {
      this.tempList.push(s);
      return s; // 判断重复
    }
    return null;
  }
}