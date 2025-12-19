import { StringDealUtility } from "./StringDealUtility";


export class StringMapUtility {

  /// 按指定的分隔符split之后去除重复项
  /// 返回的结果是按原来的seperator合并的
  public static removedDuplications(
    srcStr    : string,
    seperator : string
  ): string {
    return StringMapUtility.removedDuplicationsWithTrim(srcStr, seperator, true);
  }

  /// 按指定的分隔符split之后去除重复项
  /// 返回的结果是按原来的seperator合并的
  public static removedDuplicationsWithTrim(
    srcStr              : string,
    seperator           : string,
    trimedBeforeCompare : boolean
  ): string {

    const array : Array<string> = [];

    const transform = new RemoveDuplicateTransform(array, trimedBeforeCompare);
    return StringMapUtility.map(srcStr, seperator, transform);
  }

  /// 按指定的分隔符split之后进行transform，如：去除重复项
  /// 返回的结果是按原来的seperator合并的
  public static map(
    srcStr    : string,
    seperator : string,
    transform : MapTransform
  ): string {

    const array    : Array<string> = srcStr.split(seperator);
    const distList : Array<string> = [];

    for (const str of array) {
      const tranStr = transform.transform(str);
      if (tranStr !== null) {
        distList.push(tranStr);
      }
    }

    return StringDealUtility.getJoinedTextsFromList(distList, seperator) as string;
  }
}

/// 内部类：去重 Transform
class RemoveDuplicateTransform implements MapTransform {
  private tempList          : Array<string>;
  private trimBeforeCompare : boolean;

  constructor(tempList: Array<string>, trimBeforeCompare: boolean) {
    this.tempList = tempList;
    this.trimBeforeCompare = trimBeforeCompare;
  }

  public transform(partStr: string | null): string | null {
    if (partStr === null) {
      return null;
    }

    const str = this.trimBeforeCompare ? partStr.trim() : partStr;
    if (str.length === 0) {
      return null;
    }

    if (!this.tempList.includes(str)) {
      this.tempList.push(str);
      return str;
    } else {
      return null;
    }
  }
}

/// 与 Java interface MapTransform 等价
export interface MapTransform {
  transform(partStr: string | null): string | null;
}