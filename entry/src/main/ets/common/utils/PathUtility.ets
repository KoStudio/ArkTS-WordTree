// PathUtility.ets
import fs from '@ohos.file.fs';
import { AppConstants } from '../../app/constants/AppConstants';
import { getAppContext } from '../../app/constants/AppContext';

/**
 * 路径处理工具类
 * 提供与Java版PathUtility相同的功能，适配HarmonyOS API
 */
export class PathUtility {

  /**
   * 路径拼接工具函数（兼容多平台分隔符）
   * @param segments 要拼接的路径片段数组
   * @returns 标准化后的路径字符串（统一使用'/'分隔符）
   * @since 13
   * @example
   * // 返回 "foo/bar/baz"
   * PathUtils.join('foo', 'bar', 'baz');
   * // 处理多余分隔符（返回 "a/b/c"）
   * PathUtils.join('a/', '/b/', '/c');
   */
  static join(...segments: string[]): string {
    // 1. 使用数组join方法拼接路径（初始处理）
    let combinedPath = segments.join('/');

    // 2. 正则替换处理：
    // - 将连续多个'/'替换为单个'/'
    // - 兼容Windows风格的路径输入（如'a\\b'会被自动转为'a/b'）
    return combinedPath.replace(/\/+/g, '/');
  }

  /**
   * 移除路径末尾的斜杠（如果存在）
   * @param path 原始路径
   * @returns 处理后的路径
   */
  static removeLastSlashOfDirectoryIfExists(path: string | null): string | null {
    if (!path) return null;
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  /**
   * 从文件名中移除最后一个扩展名（即最后一个'.'及其之后的部分）
   * @param fileName 文件名（如 "book.hzkb" 或 "lesson-1.hzkb.bin"）
   * @returns 去除后缀的文件名（如 "book" 或 "lesson-1.hzkb"）
   * @example
  * PathUtility.removeSuffix("data.txt")      // => "data"
   * PathUtility.removeSuffix("archive.tar.gz") // => "archive.tar"
   * PathUtility.removeSuffix("noext")         // => "noext"
   */
  static removeSuffix(fileName: string | null): string | null {
    if (!fileName) return null;

    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0) {
      return fileName.substring(0, lastDotIndex);
    }
    return fileName;
  }

  /**
   * 获取父目录路径（始终以斜杠结尾）
   * @param path 文件/目录路径
   * @returns 父目录路径，格式为 "parentDir/"
   */
  static getParentPathOf(path: string): string {
    const lastSlashIndex = path.lastIndexOf('/');
    return lastSlashIndex >= 0 ? path.substring(0, lastSlashIndex + 1) : './';
  }
  /**
   * 提取database目录下的相对路径
   * @param fullPath 完整路径（如"/data/app/.../database/mydb/test.db"）
   * @param context 应用上下文
   * @returns 相对路径（如"mydb/test.db"）
   */
  static getRelativeDatabasePath(fullPath: string): string {
    // const dbDir = getAppContext().databaseDir + '/'; // 确保结尾有斜杠
    const dbDir = AppConstants.rdbPath

    // 标准化路径格式（兼容Windows风格斜杠）
    const normalizedFull = fullPath.replace(/\\/g, '/');
    const normalizedDir = dbDir.replace(/\\/g, '/');

    // 验证路径是否合法
    if (!normalizedFull.startsWith(normalizedDir)) {
      throw new Error('路径不属于应用数据库目录');
    }

    // 提取相对路径部分
    return normalizedFull.slice(normalizedDir.length);
  }
  /**
   * 获取路径的最后组成部分（文件或目录名）
   * @param filePath 完整路径
   * @returns 最后一级名称
   */
  static getLastComponentName(filePath: string): string {
    if (!filePath) throw new Error('Path cannot be null');

    // 处理以斜杠结尾的目录路径
    if (filePath.endsWith('/')) {
      const trimmed = filePath.substring(0, filePath.length - 1);
      const lastSlash = trimmed.lastIndexOf('/');
      return lastSlash >= 0 ? trimmed.substring(lastSlash + 1) : trimmed;
    }

    // 普通文件路径
    const lastSlash = filePath.lastIndexOf('/');
    return lastSlash >= 0 ? filePath.substring(lastSlash + 1) : filePath;
  }

  /**
   * 获取文件扩展名
   * @param fileName 文件名
   * @returns 扩展名（不含点），如无扩展名返回原字符串
   */
  static getExtension(fileName: string | null): string | null {
    if (!fileName) return null;

    const point = fileName.lastIndexOf('.');
    return point !== -1 ? fileName.substring(point + 1) : fileName;
  }

  /**
   * 检查路径是否为目录
   * @param path 目标路径
   * @returns 是否为目录
   */
  static isDirectory(path: string): boolean {
    try {
      const stat = fs.statSync(path);
      return stat.isDirectory();
    } catch {
      return false;
    }
  }

  /**
   * 检查路径是否存在
   * @param path 目标路径
   * @returns 是否存在
   */
  static isExists(path: string): boolean {
    try {
      fs.accessSync(path);
      return true;
    } catch {
      return false;
    }
  }
}