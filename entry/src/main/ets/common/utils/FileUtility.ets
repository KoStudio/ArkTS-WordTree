// FileUtils.ets
import fs from '@ohos.file.fs';
import { fileIo, fileUri } from "@kit.CoreFileKit"
import { getAppContext } from '../../app/constants/AppContext';
import { createFolderIfNeeds } from '../../app/constants/AppFunctions';
import { AppSettings } from '../../app/constants/AppSettings';
import { DiskStatus } from '../../app/constants/DiskStatus';
import { DebugLog } from '../../app/debug/DebugLog';
import { Toast } from './Toast';
import { PathUtility } from './PathUtility';


/**
 * 文件操作工具类
 */
export class FileUtility {
  // MARK: - 基础文件操作
  /** 判断文件是否存在 */
  static isFileExistAt(path: string | null): boolean {
    if (!path) return false;
    try {
      return fs.accessSync(path);  // 直接返回比较结果
    } catch (e) {
      return false;
    }
  }

  /** 删除文件 */
  static deleteFileAt(path: string | null): boolean {
    if (!path) return false;
    try {
      if (fs.accessSync(path)) {
        fs.unlinkSync(path);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /** 递归删除目录 */
  static deleteDirectoryAt(path: string | null): boolean {
    if (!path) return false;

    let dirPath = path.endsWith('/') ? path : path + '/';
    try {
      const stat = fs.statSync(dirPath);
      if (!stat.isDirectory) return false;

      const files = fs.listFileSync(dirPath);
      let success = true;

      files.forEach(file => {
        const fullPath = dirPath + file;
        const fileStat = fs.statSync(fullPath);

        if (fileStat.isFile()) {
          if (!FileUtility.deleteFileAt(fullPath)) success = false;
        } else if (fileStat.isDirectory()) {
          if (!FileUtility.deleteDirectoryAt(fullPath)) success = false;
        }
      });

      if (success) {
        fs.rmdirSync(dirPath)
      }
      return success

    } catch (e) {
      return false;
    }
  }

  /**
   * 递归拷贝目录（使用标准API）
   * @param sourceDir 源目录路径（沙箱路径）
   * @param targetDir 目标目录路径（沙箱路径）
   * @returns Promise<boolean>
   */
  static async copyFolder(sourceDir: string, targetDir: string): Promise<boolean> {
    try {
      // 1. 验证源目录（使用statSync获取完整属性）
      const stat = fs.statSync(sourceDir);
      if (!stat?.isDirectory()) {
        //throw new Error(`Source not directory: ${sourceDir}`);
        DebugLog.e(`Source not directory: ${sourceDir}`)
        return false
      }

      // 2. 创建目标目录（递归创建）
      createFolderIfNeeds(targetDir)


      // 3. 使用listFile获取目录内容（标准API）
      const entries = fs.listFileSync(sourceDir);
      for (const entry of entries) {
        const sourcePath = `${sourceDir}/${entry}`;
        const targetPath = `${targetDir}/${entry}`;
        const entryStat = fs.statSync(sourcePath);

        if (entryStat.isDirectory()) {
          // 递归处理子目录
          await FileUtility.copyFolder(sourcePath, targetPath);
        } else {
          // 文件拷贝（同步接口）
          await fs.copyFile(sourcePath, targetPath);
        }
      }
      return true;
    } catch (err) {
      DebugLog.e(`[FileUtils] 拷贝失败: ${err.message}`)
      return false;
    }
  }

  /**
   * 文件拷贝（支持进度回调）
   * @param sourcePath 源文件路径
   * @param targetPath 目标路径
   * @param bufferSize 缓冲区大小
   * @param onProgress 进度回调（0-100）
   */
  private static async copyFileWithProgress(
    sourcePath: string,
    targetPath: string,
    bufferSize: number,
    onProgress?: (percent: number) => void
  ): Promise<void> {
    const readStream = fs.createStreamSync(sourcePath, 'r');
    const writeStream = fs.createStreamSync(targetPath, 'w+');
    const fileSize = fs.statSync(sourcePath).size;
    let copiedSize = 0;

    try {
      const buffer = new ArrayBuffer(bufferSize);
      let bytesRead: number;

      while ((bytesRead = readStream.readSync(buffer)) > 0) {
        writeStream.writeSync(buffer.slice(0, bytesRead));
        copiedSize += bytesRead;

        // 触发进度回调
        if (onProgress) {
          const percent = Math.floor((copiedSize / fileSize) * 100);
          onProgress(percent > 100 ? 100 : percent);
        }
      }
    } finally {
      readStream.closeSync();
      writeStream.closeSync();
    }
  }

  /** 移动文件 */
  static copyFile(fromPath: string, toPath: string): boolean {
    try {
      if (fs.accessSync(fromPath)) {
        fs.copyFileSync(fromPath, toPath);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /** 移动文件 */
  static moveFile(fromPath: string, toPath: string): boolean {
    try {
      if (fs.accessSync(fromPath)) {
        fs.copyFileSync(fromPath, toPath);
        fs.unlinkSync(fromPath);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /** 创建目录（递归） */
  static createFolderIfNeeds(path: string): void {
    try {
      if (!fs.accessSync(path)) {
        fs.mkdirSync(path, true);
      }

    } catch (e) {
      console.error(`创建目录失败: ${JSON.stringify(e)}`);
    }
  }




  // 检查磁盘空间是否足够（带Toast提示）
  static  checkDiskSpace(needMegas: number = AppSettings.App.minDisk): boolean {
    if (!FileUtility.isDiskSpaceEnough(needMegas)) {
      Toast.showMessage($r('app.string.sys_msg_disk_space_not_enough'))
      return false;
    }
    return true;
  }

  // 判断磁盘空间是否足够（纯计算）
  static  isDiskSpaceEnough(needMegas: number = AppSettings.App.minDisk): boolean {
    const diskSpace: number = DiskStatus.getAvailableBytesForDataDirectorySync(getAppContext())
    const needs: number = needMegas * 1024 * 1024;
    DebugLog.d(`diskSpace: ${diskSpace}, needs: ${needs}`);
    return diskSpace > needs;
  }

  /**
   * 规范化路径字符串（去除末尾的/）
   * @param path 待处理的路径字符串
   * @returns 规范化后的路径
   */
  static normalizePath(path: string): string {
    // 检查路径非空且以/结尾
    if (path && path.endsWith('/')) {
      return path.substring(0, path.length - 1); // 去除最后一个字符
    }
    return path;
  }

  // 获取路径的最后一部分（相当于Swift的lastPathComponent）
  static  getLastPathComponent(path: string): string {
    // 处理路径分隔符（兼容Windows和Unix风格）
    const normalizedPath = path.replace(/\\/g, '/');

    // 移除末尾的斜杠（如果有）
    const trimmedPath = normalizedPath.endsWith('/')
      ? normalizedPath.slice(0, -1)
      : normalizedPath;

    // 获取最后一个斜杠后的内容
    const lastSlashIndex = trimmedPath.lastIndexOf('/');

    return lastSlashIndex === -1
      ? trimmedPath  // 没有斜杠则返回整个字符串
      : trimmedPath.substring(lastSlashIndex + 1);
  }

  /**
   * 删除路径的最后一级（类似Swift的deletingLastPathComponent）
   * @param path 原始路径
   * @returns 上级目录路径
   */
  static deleteLastPathComponent(path: string): string {
    // 统一路径分隔符为Unix风格
    const normalizedPath = path.replace(/\\/g, '/');

    // 移除末尾的冗余分隔符
    const trimmedPath = normalizedPath.endsWith('/')
      ? normalizedPath.slice(0, -1)
      : normalizedPath;

    // 获取最后一个分隔符前的所有内容
    const lastSlashIndex = trimmedPath.lastIndexOf('/');

    return lastSlashIndex === -1
      ? ''  // 无上级目录时返回空字符串
      : trimmedPath.substring(0, lastSlashIndex);
  }

  /**
   * 路径拼接（类似Swift的appendingPathComponent）
   * @param basePath 基础路径
   * @param component 要追加的路径组件
   * @returns 拼接后的完整路径
   */
  static appendPathComponent(basePath: string, component: string): string {
    // 统一路径分隔符为Unix风格
    const normalizedBase = basePath.replace(/\\/g, '/');
    const normalizedComp = component.replace(/\\/g, '/');

    // 移除基础路径末尾的冗余分隔符
    const trimmedBase = normalizedBase.endsWith('/')
      ? normalizedBase.slice(0, -1)
      : normalizedBase;

    // 移除组件开头的冗余分隔符
    const trimmedComp = normalizedComp.startsWith('/')
      ? normalizedComp.slice(1)
      : normalizedComp;

    return `${trimmedBase}/${trimmedComp}`;
  }

  /**
   * 目录下的文件名列表
   * @param dirPath 目录路径
   * @returns 文件名数组
   */
  static listFileNames(dirPath: string): string[] {
    const files = fs.listFileSync(dirPath);
    return files.map(file => {
      return file.substring(file.lastIndexOf('/') + 1);
    });
  }

  ///将下载文件读取为data
  static readFileAsUint8Array(filePath: string, callback: (data: Uint8Array | null, error: string | null) => void): void {
    fs.open(filePath, fs.OpenMode.READ_ONLY, (err, file) => {
      if (err) {
        callback(null, `打开文件失败: ${err.message}`);
        return;
      }

      const arrayBuffer = new ArrayBuffer(1024 * 1024);
      fs.read(file.fd, arrayBuffer, (readErr, bytesRead) => {
        fs.close(file.fd);
        if (readErr) {
          callback(null, `读取文件失败: ${readErr.message}`);
        } else {
          callback(new Uint8Array(arrayBuffer, 0, bytesRead), null);
        }
      });
    });
  }
  /**
   * 读取文本文件内容为字符串
   * 类似于Kotlin的 `val string: String = File(filePath).readText()`
   * @param filePath - 要读取的文件的完整路径
   * @returns 文件的文本内容
   */
  async readFileAsString(filePath: string): Promise<string> {
    try {
      // 使用fs.readText直接读取文件内容为字符串[6](@ref)
      let content: string = await fs.readText(filePath);
      console.info('File read successfully.');
      return content;
    } catch (error) {
      // 错误处理，例如文件不存在或无权限
      console.error(`Error reading file,message: ${error}`);
      throw new Error(error);
    }
  }

  /**
   * 从外部应用传入的路径（如微信）复制文件到应用的临时目录
   * 支持 file:// 前缀与大文件（分块读取）
   * @param srcPath 外部应用传入的文件路径或URI
   * @returns 成功则返回复制后的临时文件完整路径，否则返回 null
   */

  static async copyToTempDir(sourceUri: string): Promise<string | null> {
    if (!sourceUri) return null;

    try {
      // 获取应用 cache 目录
      const context = getAppContext();
      const tempDir = context.cacheDir + '/temp_folder';
      // 创建临时目录（如果不存在）
      try {
        await fileIo.mkdir(tempDir);
      } catch (e) {
        // 目录已存在则忽略
      }

      const targetFileName = PathUtility.getLastComponentName(sourceUri)
      const targetPath = `${tempDir}/${targetFileName}`;

      // 打开源文件
      const input = await fileIo.open(sourceUri, fileIo.OpenMode.READ_ONLY);
      // 创建目标文件
      const output = await fileIo.open(targetPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE);

      const bufferSize = 64 * 1024; // 64KB 缓冲
      const buffer = new ArrayBuffer(bufferSize);

      let bytesRead = 0;
      do {
        bytesRead = await fileIo.read(input.fd, buffer);
        if (bytesRead > 0) {
          await fileIo.write(output.fd, buffer.slice(0, bytesRead));
        }
      } while (bytesRead > 0);

      // 关闭文件
      await fileIo.close(input.fd);
      await fileIo.close(output.fd);

      return targetPath;
    } catch (err) {
      console.error('copyToTempDir failed:', err);
      return null;
    }
  }


}
