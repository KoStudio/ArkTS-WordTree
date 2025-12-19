// MARK: - CMetaInfo 等价 ArkTS 实现
export class CMetaInfo {
  fileName     : string | null = null; // fullFileName: "Book.sqlite.zip", "hsk_1.jpg"
  sizeInBytes  : number | null = null; // 多少M
  updateDate   : string | null = null; // 更新日期

  constructor(fileName: string | null = null, sizeInBytes: number | null = null, updateDate: string | null = null) {
    this.fileName    = fileName;
    this.sizeInBytes = sizeInBytes;
    this.updateDate  = updateDate;
  }

  // 等价于 Swift 的 == 运算符
  static equals(lhs: CMetaInfo, rhs: CMetaInfo): boolean {
    return lhs.fileName === rhs.fileName;
  }

  /// 获取纯主文件名（第一个点之前的内容）
  /// - "Book.sqlite" → "Book"
  /// - "Book.sqlite.zip" → "Book"
  get baseName(): string | null {
    return this.fileName !== null ? CMetaInfoHelper.baseName(this.fileName) : null;
  }

  /// 获取主名+第一层扩展名（去除最外层扩展）
  /// - "Book.sqlite" → "Book"
  /// - "Book.sqlite.zip" → "Book.sqlite"
  get baseNameWithInnerExtension(): string | null {
    return this.fileName !== null ? CMetaInfoHelper.baseNameWithInnerExtension(this.fileName) : null;
  }
}

// MARK: - String Extension
export class CMetaInfoHelper {
  /// 获取纯主文件名（第一个点之前的内容）
  /// - "Book.sqlite" → "Book"
  /// - "Book.sqlite.zip" → "Book"
  static baseName(value: string): string {
    const dotIndex: number = value.indexOf(".");
    if (dotIndex === -1) {
      return value;
    }
    return value.substring(0, dotIndex);
  }

  /// 获取主名+第一层扩展名（去除最外层扩展）
  /// - "Book.sqlite" → "Book"
  /// - "Book.sqlite.zip" → "Book.sqlite"
  static baseNameWithInnerExtension(value: string): string {
    const parts: string[] = value.split(".");
    if (parts.length <= 1) {
      return value;
    }
    return parts.slice(0, parts.length - 1).join(".");
  }
}