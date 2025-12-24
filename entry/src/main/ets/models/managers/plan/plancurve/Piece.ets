

// MARK: - Piece 类定义
/**
 * 片段
 */
export class Piece {
  // MARK: - 私有属性

  /**
   * 第几个piece
   */
  private _pieceNo: number;

  /**
   * 每个piece中的wordId
   */
  private _wordIds: number[];

  // MARK: - Getter 方法

  /**
   * 获取piece编号
   */
  get pieceNo(): number {
    return this._pieceNo;
  }

  /**
   * 获取wordIds数组
   */
  get wordIds(): number[] {
    return this._wordIds;
  }

  // MARK: - 构造函数

  /**
   * 构造函数
   * @param pieceNo - piece编号
   * @param wordIds - wordIds数组
   */
  constructor(pieceNo: number, wordIds: number[]) {
    this._pieceNo = pieceNo;
    this._wordIds = wordIds;
  }

  // MARK: - 内存操作（Operation in memo）

  /**
   * 从内存中添加wordId
   * @param wordId - 要添加的wordId
   */
  appendMem(wordId: number): void {
    this._wordIds.push(wordId);
  }

  /**
   * 从内存中删除wordId
   * @param wordId - 要删除的wordId
   */
  removeMem(wordId: number): void {
    const index = this._wordIds.indexOf(wordId);
    if (index !== -1) {
      this._wordIds.splice(index, 1);
    }
  }

  // MARK: - 等价比较（Equatable）

  /**
   * 判断两个Piece对象是否相等
   * @param other - 另一个Piece对象
   */
  equals(other: Piece): boolean {
    return this.pieceNo === other.pieceNo;
  }

  // MARK: - 比较（Comparable）

  /**
   * 比较两个Piece对象的大小
   * @param other - 另一个Piece对象
   */
  compareTo(other: Piece): number {
    return this.pieceNo - other.pieceNo;
  }

  /**
   * 判断是否小于另一个Piece对象
   * @param other - 另一个Piece对象
   */
  lessThan(other: Piece): boolean {
    return this.compareTo(other) < 0;
  }

  // MARK: - 哈希（Hashable）

  /**
   * 获取哈希值
   */
  hashCode(): number {
    return this.hashString(this.pieceNo.toString());
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
    return `Piece(pieceNo: ${this.pieceNo}, wordIds: [${this.wordIds.join(', ')}])`;
  }
}
