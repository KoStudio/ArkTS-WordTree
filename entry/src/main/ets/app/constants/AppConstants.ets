// AppConstants.ets

import { getAppContext } from './AppContext';
import fs from '@ohos.file.fs';

/**
 * 应用常量配置
 * 对应Kotlin的object AppConstants
 */
export class AppConstants {
  // 应用程序文档根目录名称
  private static readonly APP_DOCUMENT: string = "app_Document";

  private static readonly APP_DATABASE: string = "app_Database";//必须是rdb开头的目录

  //应用程序Database目录
  private static readonly APP_RDB: string      = "rdb";//必须是rdb开头的目录


  /**
   * 获取应用文档根目录路径（以斜杠结尾）
   * 对应Kotlin的val basePath: String
   * @returns string 路径字符串，格式如 "/data/app/el2/100/base/com.example/app_Document/"
   */
  static get docBasePath(): string {
    const context = getAppContext()
    // HarmonyOS的目录结构不同，使用filesDir作为基础路径
    return `${context.filesDir}/${this.APP_DOCUMENT}/`;
  }

  ///返回应用的所有sqlite的主目录 ../entry/rdb/app_Database/
  static get dataBasePath(): string {
    // HarmonyOS的目录结构不同，使用databaseDir作为基础路径
    return `${this.rdbPath}${this.APP_DATABASE}/`;//
  }

  ///返回固定的rdb路径../entry/rdb/
  static get rdbPath(): string {
    const context = getAppContext()
    // HarmonyOS的目录结构不同，使用databaseDir作为基础路径
    return `${context.databaseDir}/${this.APP_RDB}/`;
  }
}