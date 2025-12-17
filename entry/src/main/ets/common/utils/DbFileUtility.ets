// ==== 文件工具模块 ====
// 导入必要的HarmonyOS模块
import fs from '@ohos.file.fs';          // 文件系统模块
import common from '@ohos.app.ability.common'; // 上下文模块
import { BusinessError } from '@ohos.base';    // 错误类型
import zlib from '@ohos.zlib';           // 压缩解压模块
import { DebugLog } from '../../app/debug/DebugLog';

/**
 * 数据库文件操作回调接口
 * 用于异步操作完成时的回调通知
 */
export interface DBFileCallback {
  completion: () => void;  // 操作完成时调用的方法
}

/**
 * 文件工具类
 * 提供数据库文件拷贝、ZIP解压等常用文件操作方法
 */
export class DbFileUtility {
  // ==================== 公有方法 ====================

  /**
   * 同步方式从资源目录拷贝数据库文件到指定位置
   * @param context Ability上下文 - 提供资源访问能力
   * @param fromPath 源文件路径（相对于resources/rawfile目录）
   * @param toPath 目标文件绝对路径
   */
  // static async copyDatabaseFromAssetsIfNeeds(context: common.Context, fromPath: string, toPath: string) {
  //  await DbFileUtility.copyDatabaseFromAssetsIfNeeds(context, fromPath, toPath, false, null);
  // }

  /**
   * 从资源目录拷贝文件到指定位置（支持同步/异步模式）
   * @param context Ability上下文
   * @param fromPath 源文件路径
   * @param toPath 目标路径
   * @param async 是否异步执行
   * @param callback 操作完成回调（异步模式下有效）
   */
  static async copyDatabaseFromAssetsIfNeeds(context: common.Context, fromPath: string, toPath: string) {
    // 检查目标文件是否已存在
    const dbExist = DbFileUtility.checkDataBaseExists(toPath);

    if (!dbExist) {
      // 定义拷贝操作
      // const copyAction = async () => {
      //   try {
      //     await DbFileUtility.doCopy(context, fromPath, toPath);
      //     console.log(`文件拷贝成功: ${fromPath} -> ${toPath}`);
      //     callback?.completion();
      //   } catch (err) {
      //     console.error(`文件拷贝失败: ${err.message}`);
      //   }
      // };

      // 根据模式执行
      // async ? setTimeout(copyAction, 0) :
      // await copyAction();

      await DbFileUtility.doCopy(context, fromPath, toPath);
      DebugLog.d(`文件拷贝成功: ${fromPath} -> ${toPath}`);
      // callback?.completion();

    } else {
      DebugLog.d(`文件已存在，跳过拷贝: ${toPath}`);
      // callback?.completion();
    }
  }

  // ==================== 私有方法 ====================

  /**
   * 执行实际的文件拷贝操作
   * @param context Ability上下文
   * @param fromPath 源文件路径
   * @param toPath 目标路径
   */
  private static async doCopy(context: common.Context, fromPath: string, toPath: string): Promise<void> {
    try {
      // 确保目标目录存在
      DbFileUtility.createFolderIfNeeds(toPath);

      const ext = DbFileUtility.getFileExtension(fromPath).toLowerCase();
      const data: Uint8Array = await context.resourceManager.getRawFileContent(fromPath);

      if (ext === 'zip') {
        // ZIP 文件特殊处理
        await DbFileUtility.handleZipFile(data, toPath, context);
        return;
      }

      // 普通文件直接写入
      await new Promise<void>((resolve, reject) => {
        try {
          const fd = fs.openSync(toPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
          fs.write(fd.fd, data.buffer, (err) => {
            fs.closeSync(fd); // 无论是否出错都应关闭
            if (err) {
              DebugLog.e(`Failed to write file ${toPath}: ${err.message}`);
              reject(err);
            } else {
              resolve();
            }
          });
        } catch (error) {
          DebugLog.e(`Failed to open file ${toPath}: ${error.message}`);
          reject(error);
        }
      });

    } catch (err) {
      DebugLog.e(`doCopy failed from "${fromPath}" to "${toPath}": ${err.message}`);
      throw new Error('文件拷贝失败');
    }
  }

  /**
   * 处理ZIP文件（使用HarmonyOS官方解压API）
   * @param zipData ZIP文件数据
   * @param targetPath 解压目标路径
   */
  private static async handleZipFile(
    zipData: Uint8Array,
    targetPath: string,
    context: common.Context
  ): Promise<void> {
    const tempPath = `${context.cacheDir}/temp_${Date.now()}.zip`;

    // 使用标准异步API写入
    await new Promise<void>((resolve, reject) => {
      const fd = fs.openSync(tempPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      fs.write(fd.fd, zipData.buffer, (err) => {
        fs.closeSync(fd);
        err ? reject(err) : resolve();
      });
    });

    // 解压操作
    await new Promise<void>((resolve, reject) => {
      const dirPath = DbFileUtility.getFolderPath(targetPath)
      zlib.decompressFile(tempPath, dirPath, (err) => {
        fs.unlink(tempPath, () => {}); // 清理临时文件
        err ? reject(err) : resolve();
      });
    });
  }

  /**
   * 检查数据库文件是否存在
   * @param dbPath 数据库文件路径
   * @returns 文件存在返回true，否则返回false
   */
  private static checkDataBaseExists(dbPath: string): boolean {
    try {
      return fs.accessSync(dbPath);
    } catch {
      return false;
    }
  }

  /**
   * 创建目录（如果不存在）
   * @param path 文件或目录路径
   */
  private static createFolderIfNeeds(path: string): void {
    try {
      // 如果是文件路径，则获取其父目录
      const dirPath = DbFileUtility.getFolderPath(path)//path.endsWith('/') ? path : path.substring(0, path.lastIndexOf('/') + 1);

      // 递归创建目录
      fs.mkdirSync(dirPath, true);
    } catch (err) {
      if (err.code !== 13900015) { // 忽略"目录已存在"错误
        console.error(`目录创建失败: ${err.message}`);
      }
    }
  }

  /**
   * 获取文件扩展名（不带点）
   * @param filename 文件名
   * @returns 文件扩展名（小写）
   */
  private static getFileExtension(filename: string): string {
    const dotIndex = filename.lastIndexOf('.');
    return dotIndex === -1 ? '' : filename.substring(dotIndex + 1).toLowerCase();
  }

  private static getFolderPath(path: string): string {
    const dirPath = path.endsWith('/') ? path : path.substring(0, path.lastIndexOf('/') + 1);
    return dirPath
  }
}