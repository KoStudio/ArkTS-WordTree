// 数组工具类
export class ArrayUtils {
  /**
   * 将数组转换为Set集合
   * @param array 要转换的数组
   * @returns 返回新的Set集合
   */

  static asSet<T>(arr: Array<T>): Set<T> {
    return new Set(arr);
  }

  /**
   * 返回新的打乱后的数组（不会改原数组）
   * @param array 原始数组
   */
  public static shuffled<T>(array: T[]): T[] {
    const arr = [...array];
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      // 使用临时变量代替解构赋值
      const tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
    }
    return arr;
  }

  /**
   * 原地打乱数组（会修改原数组）
   * @param array 原始数组，将直接被打乱
   */
  public static shuffle<T>(array: T[]): void {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const tmp = array[i];
      array[i] = array[j];
      array[j] = tmp;
    }
  }


  /**
   * 返回删除指定元素后的新数组，不修改原数组
   * @param array 原数组
   * @param item 要删除的元素
   * @returns 一个新数组，不包含指定元素
   */
  public static removed<T>(array: T[], item: T): T[] {
    return array.filter(i => i !== item)
  }

  /**
   * 从原数组中删除指定元素（按引用判断），会修改原数组
   * @param array 原数组
   * @param item 要删除的元素
   */
  public static remove<T>(array: T[], item: T): void {
    const index = array.indexOf(item)
    if (index !== -1) {
      array.splice(index, 1)
    }
  }

  /**
   * 从原数组中删除第一个满足条件的元素，会修改原数组
   * @param array 原数组
   * @param predicate 判断是否要删除的条件函数
   */
  public static removeBy<T>(array: T[], predicate: (item: T) => boolean): void {
    const index = array.findIndex(predicate)
    if (index !== -1) {
      array.splice(index, 1)
    }
  }

  /**
   * 去除数组中的重复元素，并保持原始顺序
   * @param array 原数组
   * @returns 去重后的新数组
   */
  static removedDuplicates<T>(array: T[]): T[] {
    const seenSet = new Set<T>();      // 用于快速判断元素是否已存在
    const resultArray: T[] = [];       // 存储去重后的结果

    for (const element of array) {
      if (!seenSet.has(element)) {   // 元素尚未出现过
        seenSet.add(element);      // 标记为已出现
        resultArray.push(element); // 添加到结果数组
      }
    }

    return resultArray;
  }


  /**
   * 检查两个字符串数组是否相同
   * @param arr1 第一个字符串数组
   * @param arr2 第二个字符串数组（可为空）
   * @returns 若两个数组长度相同且每个元素都一致，则返回 true，否则返回 false
   */
  static isSame(arr1: string[] | null | undefined, arr2: string[] | null | undefined): boolean {
    if (!arr1 || !arr2) {
      return false
    }

    if (arr1.length !== arr2.length) {
      return false
    }

    for (let i = 0; i < arr1.length; i++) {
      if (arr1[i] !== arr2[i]) {
        return false
      }
    }

    return true
  }

  /**
   * 查找元素在 all 中的索引（等价比较 ===）。
   * - 如果找到，返回第一个匹配项的索引。
   * - 如果没找到，返回数组的最后一个索引（all.length - 1）。
   * - 如果 all 为空或未传，返回 0（与原 Swift 逻辑一致）。
   *
   * @param item 要查找的元素
   * @param all  全部元素数组（按枚举顺序）
   */
  static indexOfAll<T>(item: T, all: T[]): number {
    if (!all || all.length === 0) return 0

    let row = 0
    for (let i = 0; i < all.length; i++) {
      row = i
      if (all[i] === item) {
        return i
      }
    }

    // 未找到：返回最后一个索引（与 Swift 原实现行为一致）
    return row
  }
}

