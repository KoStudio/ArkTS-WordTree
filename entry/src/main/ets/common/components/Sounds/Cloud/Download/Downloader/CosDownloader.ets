import common from '@ohos.app.ability.common';
import { CurrentBucket, CosService } from '../CDownloadable/CosService';
import { StringPyHelper } from '../../../../../utils/strings/StringPyHelper';
import { createFolderIfNeeds } from '../../../../../../app/constants/AppFunctions';
import { CosXmlBaseService, HttpProgress, PutObjectRequest, GetObjectRequest, UploadTask, DownloadTask, TransferConfig, CosError } from '@tencentcloud/cos';
import { CosXmlDownloadTaskResult } from '@tencentcloud/cos/src/main/ets/transfer/DownloadTask'

import { StringEncoder } from '../../../../../utils/strings/StringEncrypt';
import { DebugLog } from '../../../../../../app/debug/DebugLog';
import { FileUtility } from '../../../../../utils/FileUtility';
import { NetWorkTool } from '../../../../../utils/NetworkUtils';
import { logEvent } from '../../../../Logger/Logger';

// MARK: - COS配置常量
namespace CosConfig {
  export const soundPrefix: string = "STsounds/v1/";
}

// MARK: - 腾讯云下载器类
export class CosDownloader {
  // MARK: - 单例实例
  private static instance: CosDownloader = new CosDownloader();

  // MARK: - 私有属性
  private downloadingSet: Set<string> = new Set();
  // private downloadQueue: taskpool.TaskPool = new taskpool.TaskPool("com.ou.TencentCos.Downloader.Queue");

  // MARK: - 构造函数
  private constructor() {
    // 初始化腾讯云服务
    CosService.shared;
  }

  // 获取单例实例
  public static get shared(): CosDownloader {
    return this.instance;
  }

  // MARK: - 下载方法
  private async downloadData(text: string, finished: (data: Uint8Array | null, error: string | null) => void) {
    // 生成文件名，将文本转为拼音并转换为.mp3格式
    const fileName = `${StringPyHelper.convertUnicodeForPinyin(text)}.mp3`;

    // 缓存文件夹路径
    const context              = getContext() as common.UIAbilityContext;
    const downloadCacheFolder  = `${context.cacheDir}/CosDownloads`;
    const downloadFileUrl      = `${downloadCacheFolder}/${fileName}`;

    // 确保目标文件夹存在
    createFolderIfNeeds(downloadCacheFolder);

    // 存储桶名称，由 bucketname-appid 组成，appid 必须填入，可以在 COS 控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
    let bucket = CurrentBucket//"examplebucket-1250000000";

    //对象在存储桶中的位置标识符，即称对象键
    let cosPath = `${StringEncoder.removedSalt(CosConfig.soundPrefix)}${fileName}` // 对象键，是对象在 COS 上的完整路径 "exampleobject.txt";

    //本地文件路径
    let downloadPath = downloadFileUrl // 设置文件下载保存路径\n "本地文件路径";

    let request = new GetObjectRequest(bucket, cosPath, downloadPath);
    request.credential = CosService.shared.getCredential()
    let task: DownloadTask = CosXmlBaseService.default().download(request);
    // 下载进度回调
    task.onProgress = (progress: HttpProgress) => {
      // progress.complete 为当前已下载大小
      // progress.target 为总大小
    };
    task.onResult = {
      // 下载成功回调
      onSuccess: (request, result: CosXmlDownloadTaskResult) => {
        // todo 下载成功后的逻辑
        // 如果下载成功，解析结果
        if (!result.accessUrl){
          finished(null, "Download result is empty.")
          return
        }

        // 成功：尝试读取数据
        DebugLog.i("Download completed. Result: \(result)")

        // 尝试读取下载的文件数据
        this.readFileAsUint8Array(downloadFileUrl, (data: Uint8Array | null, error: string | null) => {

          if (data) {

            //下载成功 回调
            finished(data, null)

            // 下载完毕后，删除缓存文件
            FileUtility.deleteFileAt(result.accessUrl!)
          }else{
            finished(null, error)
          }

        })
      },

      //下载失败回调
      onFail: (request, error: CosError) => {
        // 错误处理：下载失败
        DebugLog.e(`Download error: ${error.message}`)
        finished(null, error.message ?? "Download error")

      }
    }
    //开始下载
    task.start();
    //暂停任务
    // task.pause();
    //恢复任务
    // task.resume();
    //取消任务
    // task.cancel();
  }

  // MARK: - 公共方法
  public async  startDownloadIfNeeds(
    text: string,
    finished: (data: Uint8Array | null, error: string | null) => void
  ) {
    // 校验text是否有效
    if (!text || text.trim().length === 0) {
      finished(null, "text is empty");
      return;
    }

    // 检查网络连接（需实现checkConnection方法）
    if (!NetWorkTool.checkInternetConnection()) {
      finished(null, "Network is not connectable");
      return;
    }

    const language = "zh_cn";
    const tag = `language:${language}, title:${text}`;

    // 检查是否已经在下载
    if (this.downloadingSet.has(tag)) {
      DebugLog.i(`Download for ${tag} is already in progress.`);
      finished(null, "Download is already in progress.");
      return;
    }

    // 标记当前任务正在下载
    this.downloadingSet.add(tag);
    DebugLog.i(`Start downloading sound for ${tag}...`);
    logEvent("Audio_Cos_Download") //日志

    // 执行下载
    await this.downloadData(text, (data, error) => {
      // 下载完成后回调
      finished(data, error);

      // 下载完成，移除标记
      this.downloadingSet.delete(tag);
    });
  }



  ///将下载文件读取为data
  readFileAsUint8Array(filePath: string, callback: (data: Uint8Array | null, error: string | null) => void): void {
    // fs.open(filePath, fs.OpenMode.READ_ONLY, (err, file) => {
    //   if (err) {
    //     callback(null, `打开文件失败: ${err.message}`);
    //     return;
    //   }
    //
    //   const arrayBuffer = new ArrayBuffer(1024 * 1024);
    //   fs.read(file.fd, arrayBuffer, (readErr, bytesRead) => {
    //     fs.close(file.fd);
    //     if (readErr) {
    //       callback(null, `读取文件失败: ${readErr.message}`);
    //     } else {
    //       callback(new Uint8Array(arrayBuffer, 0, bytesRead), null);
    //     }
    //   });
    // });
    FileUtility.readFileAsUint8Array(filePath, callback)
  }

}
