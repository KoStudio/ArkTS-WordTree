export class NumberUtility {

  /// 判断是否为整数
  public static isInt(str: string | null): boolean {
    if (str === null) {
      return false;
    }

    // 支持可选正负号
    const regEx: RegExp = /^[\+\-]?\d+$/;

    return regEx.test(str);
  }
}