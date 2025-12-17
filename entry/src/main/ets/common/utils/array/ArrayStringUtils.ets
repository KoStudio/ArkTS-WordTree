// 字符串数组扩展
export class ArrayWords {
  /**
   * 如果有词语，需要用空格连接，全部是单字汉字时，直接连接
   * 如：
   *      有词语:  [中国, 今天，大，家里, 人口]  -> "中国 今天 大 家里 人口"
   *   全部是单字:  [中，国，人]           -> "中国人"
   * @param seperator 默认是半角空格
   */
  static joinedWordsString(arr: string[], seperator: string = " "): string {
    // 如果只有一个词语时
    if (arr.length === 1 && arr.filter(item => item.trim().length > 1).length > 0) {
      // 如果只有一个词语时，因为不会有空格连接，所以会被当成单个的字显示如：[中国] →　[中] [国]
      // 所以，需要在后面添加空格再返回：如："中国" -> "中国 "
      return arr.join('') + seperator;
    }

    return arr.filter(item => item.trim().length > 1).length > 0
      ? arr.join(seperator)
      : arr.join('');
  }

  /**
   * 判断是否含有词语
   */
  static containsWords(arr: string[]): boolean {
    return arr.filter(item => item.trim().length > 1).length > 0;
  }

  /**
   * 根据indexInArray计算出，此页的第一个字在text字中的index
   * @param indexInArray 数组中的索引
   */
  static getFirstCharIndex(arr: string[], indexInArray: number): number {
    if (indexInArray >= arr.length) {
      return -1;
    }

    let index = 0;
    for (let i = 0; i < indexInArray; i++) {
      index += arr[i].length;
    }

    return index;
  }

  /**
   * 根据 texts 数组计算全局字符索引
   *
   * - texts: 每个元素是一段文本（例如每页或每条）
   * - textIndex: 指定属于 texts 的第几个元素（0-based）
   * - charIndexInAText: 在该文本内的字符索引（0-based）
   *
   * 返回值：
   * - 成功：返回全局索引（从 0 开始计数）
   * - 参数非法或越界：返回 -1
   */
  static getCharIndexInAllTexts(texts: string[], textIndex: number, charIndexInAText: number): number {
    // 参数基本校验
    if (!Array.isArray(texts)) return -1;
    if (texts.length === 0) return -1;
    if (!Number.isInteger(textIndex) || !Number.isInteger(charIndexInAText)) return -1;
    if (textIndex < 0 || textIndex >= texts.length) return -1;

    const targetText = texts[textIndex] ?? "";
    const targetLen = targetText.length;

    // charIndexInAText 必须在目标文本范围内
    if (charIndexInAText < 0 || charIndexInAText >= targetLen) return -1;

    // 先把目标文本内的索引作为初值，然后累加此前所有文本的长度
    let globalIndex = charIndexInAText;
    for (let i = 0; i < textIndex; i++) {
      globalIndex += (texts[i] ?? "").length;
    }

    return globalIndex;
  }

}

// 字符串扩展
export class StringWords {
  /**
   * 中间有空格，分割为词语数组。无空格则分割为汉字数组
   *      有空格:  "中国 今天 大 家里 好的"  ->  [中国, 今天，大，家里，好的]
   *   有一个空格:  "中国 "            ->  [中国]
   *
   *   全部是单字:  "中国人"           ->  [中，国，人]
   *      无空格:  "中国"             ->  [中, 国]
   */
  static splitToWordsArray(str: string, separator: string = " "): string[] {
    if (str.includes(separator)) {
      return str.split(separator).filter(item => item.length > 0);
    } else {
      return Array.from(str);
    }
  }

  /**
   * 判断是否含有词语
   */
  static containsWords(str: string): boolean {
    return str.includes(" ")
      ? str.split(" ").filter(item => item.length > 1).length > 0
      : false;
  }
}