// 导入必要的模块
import { getString, getStringF } from '../../../../common/utils/ResourceUtils';
import { Box } from './Box'; // 假设Box类已在其他文件中定义
import { DistanceFromBase } from './BoxType'; // 假设BoxType已在其他文件中定义

// MARK: - DayOf 类定义
/**
 * 日份
 */
export class DayOf {
  // MARK: - 私有属性

  /**
   * 第几天 (start from 0)
   */
  private _num: number;

  /**
   * 每天的Box的List
   */
  private _boxes: Box[];

  // MARK: - Getter 方法

  /**
   * 获取天数编号
   */
  get num(): number {
    return this._num;
  }

  /**
   * 获取boxes数组
   */
  get boxes(): Box[] {
    return this._boxes;
  }

  // MARK: - 构造函数

  /**
   * 构造函数
   * @param num - 天数编号
   * @param boxes - boxes数组
   */
  constructor(num: number, boxes: Box[]) {
    this._num = num;
    this._boxes = boxes;
  }

  // MARK: - 计算属性（days相关）

  /**
   * 当前(今天)是第几天, 如：第1天
   */
  get numString(): string {
    // return "第\(num + 1)天";
    return getStringF($r("app.string.dayof_num_string") ,this.num + 1)
  }

  // MARK: - 内存操作（Operation in memo）

  /**
   * 添加box到内存
   * @param box - 要添加的box
   */
  appendMemBox(box: Box): void {
    this._boxes.push(box);
  }

  /**
   * 从内存中添加多个boxes
   * @param boxes - 要添加的boxes数组
   */
  appendMemBoxes(boxes: Box[]): void {
    this._boxes.push(...boxes);
  }

  /**
   * 从内存中删除box
   * @param box - 要删除的box
   */
  removeMemBox(box: Box): void {
    const index = this._boxes.findIndex(b => b.equals(box));
    if (index !== -1) {
      this._boxes.splice(index, 1);
    }
  }

  // MARK: - 等价比较（Equatable）

  /**
   * 判断两个DayOf对象是否相等
   * @param other - 另一个DayOf对象
   */
  equals(other: DayOf): boolean {
    return this.num === other.num;
  }

  // MARK: - 比较（Comparable）

  /**
   * 比较两个DayOf对象的大小
   * @param other - 另一个DayOf对象
   */
  compareTo(other: DayOf): number {
    return this.num - other.num;
  }

  /**
   * 判断是否小于另一个DayOf对象
   * @param other - 另一个DayOf对象
   */
  lessThan(other: DayOf): boolean {
    return this.compareTo(other) < 0;
  }

  // MARK: - 工具函数（Utils functions）

  /**
   * 获取distances
   * @param forReview - true: 只取复习, false: 只取学习, null: 全部
   */
  distances(forReview: boolean | null = null): DistanceFromBase[] {
    const distances = this._boxes.map(box => box.distance);

    if (forReview !== null) {
      if (forReview) {
        // 只取复习（距离不为0）
        return distances.filter(distance => distance !== 0);
      } else {
        // 只取学习（距离为0）
        return distances.filter(distance => distance === 0);
      }
    }

    // 返回全部
    return distances;
  }

  /**
   * 获取pieceNos
   * @param distances - 可选的distances数组，用于过滤
   */
  pieceNos(distances: DistanceFromBase[] | null = null): number[] {
    if (distances) { // && distances.length > 0
      const distanceSet = new Set(distances);
      return this._boxes
        .filter(box => distanceSet.has(box.distance))
        .map(box => box.pieceNo);
    } else {
      return this._boxes.map(box => box.pieceNo);
    }
  }

  // MARK: - 调试描述（CustomDebugStringConvertible）

  /**
   * 获取调试描述信息
   */
  toString(): string {
    let s = `第${this.num}天: `;
    this._boxes.forEach(box => {
      s += `(pieceNo: ${box.pieceNo}, distance: ${box.distance})， `;
    });
    return s;
  }
}
