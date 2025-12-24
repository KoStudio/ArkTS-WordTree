import fs from '@ohos.file.fs';
import { CosXmlBaseService, HttpProgress, PutObjectRequest, GetObjectRequest,
  UploadTask, DownloadTask, CosError, CosXmlUploadTaskResult } from '@tencentcloud/cos';
import { CurrentBucket, CosService } from '../../../common/components/Sounds/Cloud/Download/CDownloadable/CosService';
import { FileUtility } from '../../../common/utils/FileUtility';
import { DebugLog } from '../../../app/debug/DebugLog';

// MARK: - 常量定义
namespace CosConfig {
  // 用户数据在COS上的存储路径前缀
  export const UserDataPrefix: string = "app_upload/userData/";
}

// MARK: - 腾讯云上传下载服务类
export class CosDownloaderUserData {
  // MARK: - 单例实例
  private static instance: CosDownloaderUserData = new CosDownloaderUserData();

  // MARK: - 构造函数
  private constructor() {
    // 初始化腾讯云服务
    CosService.shared;
  }

  // 获取单例实例
  public static get shared(): CosDownloaderUserData {
    return this.instance;
  }

  // MARK: - 文件上传方法
  /**
   * 上传用户数据到腾讯云COS
   * @param filePath 本地文件路径
   * @param toName 上传后的文件名（例如：101.zip）
   * @param proccessing 上传进度回调（0-100）
   * @param finished 完成回调（是否成功、文件路径、错误信息）
   */
  public uploadUserData(
    filePath: string,
    toName: string,
    proccessing: (progress: number) => void,
    finished: (success: boolean, filePath?: string, error?: string) => void
  ) {

    // 存储桶名称，由 bucketname-appid 组成，appid 必须填入，可以在 COS 控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
    let bucket  = CurrentBucket

    //对象在存储桶中的位置标识符，即称对象键
    let cosPath = `${CosConfig.UserDataPrefix}${toName}`

    //本地文件路径
    let srcPath = filePath

    let request = new PutObjectRequest(bucket, cosPath, srcPath);
    request.credential = CosService.shared.getCredential()
    const task: UploadTask = CosXmlBaseService.default().upload(request);

    // 6. 设置进度监听
    task.onProgress = (progress: HttpProgress) => {
      // 计算上传百分比（0-100）
      const percent = Math.floor((progress.complete / progress.target) * 100);
      proccessing(percent);
    };

    // 7. 设置任务结果回调
    task.onResult = {
      // 上传成功处理
      onSuccess: (request, result: CosXmlUploadTaskResult) => {
        DebugLog.i(`Upload succeeded at: ${result.accessUrl}`);
        finished(true, `${CosConfig.UserDataPrefix}${toName}`);
      },

      // 上传失败处理
      onFail: (request, error: CosError) => {
        DebugLog.e(`Upload failed: ${error.message}`);
        finished(false, undefined, error.message ?? "Upload error");
      }
    };

    //开始上传
    task.start();
    //暂停任务
    // task.pause();
    //恢复任务
    // task.resume();
    //取消任务
    // task.cancel();
  }

  // MARK: - 文件下载方法
  /**
   * 从腾讯云COS下载用户数据
   * @param objectName COS上的文件路径（例如：app_upload/userData_whitecard/101.zip）
   * @param toPath 本地保存路径
   * @param proccessing 下载进度回调（0-100）
   * @param finished 完成回调（是否成功、文件路径、错误信息）
   */
  public downloadUserData(
    objectName: string,
    toPath: string,
    proccessing: (progress: number) => void,
    finished: (success: boolean, filePath?: string, error?: string) => void
  ) {
    // 删除缓存中的旧文件
    FileUtility.deleteFileAt(toPath)


    // 存储桶名称，由 bucketname-appid 组成，appid 必须填入，可以在 COS 控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
    let bucket = CurrentBucket//"examplebucket-1250000000";

    //对象在存储桶中的位置标识符，即称对象键
    let cosPath = objectName

    //本地文件路径
    let downloadPath = toPath

    let request = new GetObjectRequest(bucket, cosPath, downloadPath);
    request.credential = CosService.shared.getCredential()
    let task: DownloadTask = CosXmlBaseService.default().download(request);

    // 监听下载进度
    task.onProgress = (progress: HttpProgress) => {
      // 计算下载百分比（0-100）
      const percent = Math.floor((progress.complete / progress.target) * 100);
      proccessing(percent);
    };

    // 8. 设置任务结果回调
    task.onResult = {
      // 下载成功处理
      onSuccess: (request, result) => {
        // 验证文件是否存在
        if (FileUtility.isFileExistAt(toPath)) {
          finished(true, toPath);
        } else {
          finished(false, undefined, "Downloaded file does not exist");
        }
      },

      // 下载失败处理
      onFail: (request, error: CosError) => {
        DebugLog.e(`Download failed: ${error.message}`);
        finished(false, undefined, error.message ?? "Download error");
      }
    };

    // 9. 开始下载任务
    task.start();
  }
}