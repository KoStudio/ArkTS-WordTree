/**
 * 文件大小工具类
 * 提供额外的文件大小相关功能
 */
export class FileSizeUtils {
  /**
   * 格式化文件大小（带单位）
   * @param bytes - 字节数
   * @param decimalPlaces - 小数位数 (默认1位)
   * @returns 格式化的字符串
   */
  static formatBytes(bytes: number, decimalPlaces: number = 1): string {
    if (bytes === 0) return '0B';

    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(decimalPlaces)) + sizes[i];
  }

  /**
   * 解析文件大小字符串为字节数
   * @param sizeString - 文件大小字符串 (如: "1.5MB", "1024KB")
   * @returns 字节数
   */
  static parseSizeString(sizeString: string): number {
    const units: Record<string, number> = {
      'B': 1,
      'KB': 1024,
      'MB': 1024 * 1024,
      'GB': 1024 * 1024 * 1024,
      'TB': 1024 * 1024 * 1024 * 1024
    };

    const match = sizeString.match(/^([\d.]+)\s*([A-Za-z]+)$/);
    if (!match) throw new Error('Invalid size format');

    const value = parseFloat(match[1]);
    const unit = match[2].toUpperCase();

    if (!units[unit]) throw new Error(`Unknown unit: ${unit}`);

    return value * units[unit];
  }
}

///使用示例：
// console.log(FileSizeUtils.formatBytes(1536)); // "1.5KB"
// console.log(FileSizeUtils.parseSizeString("2.5MB")); // 返回 2621440