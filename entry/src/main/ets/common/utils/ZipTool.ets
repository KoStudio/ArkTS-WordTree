import zlib from '@ohos.zlib';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import { FileUtility } from './FileUtility';
import { PathUtility } from './PathUtility';
import { createFolderIfNeeds } from '../../app/constants/AppFunctions';
import { DebugLog } from '../../app/debug/DebugLog';


interface ZipEntry {
  src: string;
  dest: string;
}
/**
 * ZIP 压缩解压工具类
 * 使用 @ohos.zlib 实现沙箱目录下的文件压缩与解压
 */
export class ZipTool {

  // MARK: - 压缩目录
  static async createOneZip(
    srcPath: string,
    options?: zlib.Options
  ): Promise<string | null> {
    // 确保目标路径存在且为文件或文件夹
    if (!FileUtility.isFileExistAt(srcPath)) {
      return null
    }

    // 目标zip文件路径
    const zipPath = `${FileUtility.normalizePath(srcPath)}.zip`

    // 删除已存在的zip文件
    FileUtility.deleteFileAt(zipPath)

    if (await ZipTool.compressDir(srcPath, zipPath, options)) {
      return zipPath
    }else {
      return null
    }
  }



  /**
   * 压缩指定目录
   * @param sourceDir 源目录路径（沙箱路径）
   * @param destZip 目标ZIP文件路径（沙箱路径）
   * @param options 压缩选项（可选）
   * @returns Promise<boolean> 操作是否成功
   */
  static async compressDir(
    sourceDir: string,
    destZip: string,
    options?: zlib.Options
  ): Promise<boolean> {
    try {
      // 1. 验证源目录是否存在
      if (!fs.accessSync(sourceDir)) {
        //throw new Error(`Source directory not found: ${sourceDir}`);
        DebugLog.e(`Source directory not found: ${sourceDir}`)
        return false
      }


      const srcFolderName   = PathUtility.getLastComponentName(sourceDir)
      const srcParentFolder = FileUtility.deleteLastPathComponent(sourceDir)
      const srcWrapperDir   = FileUtility.appendPathComponent(srcParentFolder, `${srcFolderName}_wrapper`)
      const srcWrappedPath  = FileUtility.appendPathComponent(srcWrapperDir, srcFolderName)

      createFolderIfNeeds(srcWrapperDir)

      await FileUtility.copyFolder(sourceDir, srcWrappedPath)

      // 2. 设置默认压缩参数[1,4](@ref)
      const compressOptions: zlib.Options = options || {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
        memLevel: zlib.MemLevel.MEM_LEVEL_DEFAULT,
        strategy: zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT_STRATEGY
      };

      // 3. 执行压缩（异步Promise方案）[1,6](@ref)
      await zlib.compressFile(srcWrapperDir, destZip, compressOptions);

      //删除Wrapper
      FileUtility.deleteDirectoryAt(srcWrapperDir)

      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`压缩失败: [${error.code}] ${error.message}`);
      return false;
    }
  }

  // MARK: - 解压文件

  static async unzip(zipFile: string): Promise<string|null> {
    // 目标解压目录
    const parentFolder = FileUtility.deleteLastPathComponent(zipFile)
    const unZipFolder  = FileUtility.appendPathComponent(parentFolder, "_unzip")

    return ZipTool.unzipTo(zipFile, unZipFolder)

    // 删除已存在的解压目录
    // FileUtility.deleteFileAt(unZipFolder)

    // if (await ZipTool.decompress(zipFile, unZipFolder)) {
    //   return unZipFolder
    // }else{
    //   return null
    // }
  }

  ///解压文件 到指定 目录
  static async unzipTo(zipFile: string, unZipFolder: string): Promise<string | null> {

    // 删除已存在的解压目录
    FileUtility.deleteFileAt(unZipFolder)

    if (await ZipTool.decompress(zipFile, unZipFolder)) {
      return unZipFolder
    } else {
      return null
    }
  }

  /**
   * 解压ZIP文件到指定目录
   * @param zipFile ZIP文件路径（沙箱路径）
   * @param destDir 目标目录路径（沙箱路径）
   * @returns Promise<boolean> 操作是否成功
   */
  static async decompress(
    zipFile: string,
    destDir: string
  ): Promise<boolean> {
    try {
      // 1. 验证ZIP文件是否存在[1](@ref)
      if (!fs.accessSync(zipFile)) {
        throw new Error(`ZIP file not found: ${zipFile}`);
      }

      // 2. 创建目标目录（如果不存在）[2](@ref)
      if (!fs.accessSync(destDir)) {
        fs.mkdirSync(destDir, true);
      }

      // 3. 执行解压（无配置参数方案）[1,7](@ref)
      await zlib.decompressFile(zipFile, destDir);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`解压失败: [${error.code}] ${error.message}`);
      return false;
    }
  }

  // // MARK: - 工具方法
  // /**
  //  * 获取应用沙箱路径（Stage模型）
  //  * @returns 沙箱根目录路径
  //  */
  // static getSandboxPath(): string {
  //   const context = getContext() as common.UIAbilityContext;
  //   return context.filesDir;
  // }
}