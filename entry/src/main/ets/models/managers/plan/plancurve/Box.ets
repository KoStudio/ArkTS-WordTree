import { DistanceFromBase } from "./BoxType";

/**
 * 日份中的一个Box
 */
export class Box {
  // MARK: - 私有属性

  /**
   * x: 相距此Piece的base的 距离(天数) (start from 0)
   */
  private _distance: DistanceFromBase;

  /**
   * pieceNo
   */
  private _pieceNo: number;

  // MARK: - Getter 方法

  /**
   * 获取距离
   */
  get distance(): DistanceFromBase {
    return this._distance;
  }

  /**
   * 获取piece编号
   */
  get pieceNo(): number {
    return this._pieceNo;
  }

  /**
   * y: 第几天 (start from 0)
   */
  get num(): number {
    return this.pieceNo + this.distance;
  }

  // MARK: - 构造函数

  /**
   * 构造函数
   * @param distance - 距离天数
   * @param pieceNo - 片段编号
   */
  constructor(distance: DistanceFromBase, pieceNo: number) {
    this._distance = distance;
    this._pieceNo = pieceNo;
  }

  // MARK: - Equatable 等价比较

  /**
   * 判断两个Box是否相等
   * @param other - 另一个Box对象
   */
  equals(other: Box): boolean {
    return this.distance === other.distance && this.num === other.num;
  }

  // MARK: - Comparable 比较

  /**
   * 比较两个Box的大小
   * @param other - 另一个Box对象
   */
  compareTo(other: Box): number {
    if (this.num === other.num) {
      return this.distance - other.distance;
    } else {
      return this.num - other.num;
    }
  }

  /**
   * 判断是否小于另一个Box
   * @param other - 另一个Box对象
   */
  lessThan(other: Box): boolean {
    return this.compareTo(other) < 0;
  }

  // MARK: - Hashable 哈希

  /**
   * 获取哈希值
   */
  hashCode(): number {
    const str = `distance${this.distance}_num${this.num}`;
    return this.hashString(str);
  }

  /**
   * 字符串哈希辅助方法
   * @param str - 输入字符串
   */
  private hashString(str: string): number {
    let hash = 0;
    if (str.length === 0) return hash;

    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 转换为32位整数
    }

    return hash;
  }

  /**
   * 转换为字符串表示
   */
  toString(): string {
    return `Box(distance: ${this.distance}, num: ${this.num}, pieceNo: ${this.pieceNo})`;
  }
}

// MARK: - BoxHelper：Box相关的辅助函数
export class BoxHelper {
  /**
   * 比较两个Box对象是否相等
   * @param lhs - 左侧Box对象
   * @param rhs - 右侧Box对象
   */
  static equals(lhs: Box, rhs: Box): boolean {
    return lhs.equals(rhs);
  }

  /**
   * 比较两个Box对象的大小
   * @param lhs - 左侧Box对象
   * @param rhs - 右侧Box对象
   */
  static compare(lhs: Box, rhs: Box): number {
    return lhs.compareTo(rhs);
  }

  /**
   * 对Box数组进行排序
   * @param boxes - Box数组
   */
  static sortBoxes(boxes: Box[]): Box[] {
    return boxes.sort((a, b) => a.compareTo(b));
  }

  /**
   * 判断Box数组中是否包含某个Box
   * @param boxes - Box数组
   * @param box - 要查找的Box
   */
  static contains(boxes: Box[], box: Box): boolean {
    return boxes.some(b => b.equals(box));
  }
}

