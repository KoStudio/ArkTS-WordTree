// SimpleDownloader.ets
import common from '@ohos.app.ability.common';
import request from '@ohos.request';
import { BusinessError } from '@ohos.base';
import { getAppContext } from '../../../app/constants/AppContext';

/**
 * 下载结果接口
 * @property {string} filePath - 文件下载后的存储路径
 * @property {request.DownloadTask} downloadTask - 下载任务实例，用于控制下载过程
 */
export interface SimpleDownloaderResult {
  filePath: string;
  downloadTask: request.DownloadTask;
}

/**
 * 简单下载器工具类
 * 基于 @ohos.request 模块封装文件下载功能，支持下载控制和管理
 * @example
 * const downloader = new SimpleDownloader();
 * const result = await downloader.downloadToPath(url, path);
 */
export class SimpleDownloader {

  /**
   * 下载文件到指定路径
   * @param {string} url - 要下载的文件URL地址
   * @param {string} targetPath - 文件下载后的存储路径（完整路径）
   * @returns {Promise<SimpleDownloaderResult>} 包含文件路径和下载任务实例的Promise对象
   * @throws {BusinessError} 下载失败时抛出错误
   * @example
   * const result = await downloader.downloadToPath(
   *   'https://example.com/file.zip',
   *   '/data/storage/el2/base/files/downloads/file.zip'
   * );
   */
  async downloadToPath(url: string, targetPath: string): Promise<SimpleDownloaderResult> {
    return new Promise<SimpleDownloaderResult>((resolve, reject) => {
      try {
        const context = getAppContext();

        // 创建下载任务
        request.downloadFile(context, {
          url: url,
          filePath: targetPath
        }).then((downloadTask: request.DownloadTask) => {

          // 构建返回结果
          const result: SimpleDownloaderResult = {
            filePath: targetPath,
            downloadTask: downloadTask
          };

          // 监听下载完成事件
          downloadTask.on('complete', () => {
            console.info('下载任务完成');
            resolve(result);
          });

          // 监听下载失败事件
          downloadTask.on('fail', (err: number) => {
            const error: BusinessError = {
              code: err,
              message: `下载失败，错误码: ${err}`,
              name: 'DownloadError'
            };
            console.error(`下载失败: ${JSON.stringify(error)}`);
            reject(error);
          });

        }).catch((error: BusinessError) => {
          console.error(`创建下载任务失败: ${JSON.stringify(error)}`);
          reject(error);
        });

      } catch (error) {
        console.error(`下载初始化失败: ${JSON.stringify(error)}`);
        reject(error as BusinessError);
      }
    });
  }

  /**
   * 暂停下载任务
   * @param {request.DownloadTask} downloadTask - 要暂停的下载任务实例
   * @returns {Promise<boolean>} 暂停操作结果的Promise，true表示成功
   * @throws {BusinessError} 暂停失败时抛出错误
   */
  async pauseDownload(downloadTask: request.DownloadTask): Promise<boolean> {
    return new Promise<boolean>((resolve, reject) => {
      downloadTask.suspend((error: BusinessError, result: boolean) => {
        if (error) {
          console.error(`暂停下载任务失败. Code: ${error.code}, message: ${error.message}`);
          reject(error);
        } else {
          console.info('暂停下载任务成功');
          resolve(result);
        }
      });
    });
  }

  /**
   * 恢复下载任务
   * @param {request.DownloadTask} downloadTask - 要恢复的下载任务实例
   * @returns {Promise<boolean>} 恢复操作结果的Promise，true表示成功
   * @throws {BusinessError} 恢复失败时抛出错误
   */
  async resumeDownload(downloadTask: request.DownloadTask): Promise<boolean> {
    return new Promise<boolean>((resolve, reject) => {
      downloadTask.restore((error: BusinessError, result: boolean) => {
        if (error) {
          console.error(`恢复下载任务失败. Code: ${error.code}, message: ${error.message}`);
          reject(error);
        } else {
          console.info('恢复下载任务成功');
          resolve(result);
        }
      });
    });
  }

  /**
   * 删除下载任务
   * @param {request.DownloadTask} downloadTask - 要删除的下载任务实例
   * @returns {Promise<boolean>} 删除操作结果的Promise，true表示成功
   * @throws {BusinessError} 删除失败时抛出错误
   */
  async deleteDownload(downloadTask: request.DownloadTask): Promise<boolean> {
    return new Promise<boolean>((resolve, reject) => {
      downloadTask.delete((error: BusinessError, result: boolean) => {
        if (error) {
          reject(error);
        } else {
          resolve(result);
        }
      });
    });
  }
}