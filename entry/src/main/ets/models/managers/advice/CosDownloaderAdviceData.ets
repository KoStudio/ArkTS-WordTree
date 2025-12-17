import { CurrentBucket, CosService } from '../../../common/components/Sounds/Cloud/Download/CDownloadable/CosService';
import { DebugLog } from '../../../app/debug/DebugLog';
import { CosError, CosXmlBaseService, CosXmlUploadTaskResult, HttpProgress, PutObjectRequest,
  UploadTask } from '@tencentcloud/cos';

// MARK: - 常量定义
namespace CosConfig {
  // 用户数据在COS上的存储路径前缀
  export const UserDataPrefix: string = "app_upload/adviceData/";
}

// MARK: - 腾讯云上传下载服务类
export class CosDownloaderAdviceData {
  // MARK: - 单例实例
  private static instance: CosDownloaderAdviceData = new CosDownloaderAdviceData();

  // MARK: - 构造函数
  private constructor() {
    // 初始化腾讯云服务
    CosService.shared;
  }

  // 获取单例实例
  public static get shared(): CosDownloaderAdviceData {
    return this.instance;
  }

  // MARK: - 文件上传方法
  /**
   * 上传用户数据到腾讯云COS
   * @param filePath 本地文件路径
   * @param toName 上传后的文件名（例如：101.png）
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
        finished(true, `https://zhikabucket-1256782283.cos.ap-shanghai.myqcloud.com/${CosConfig.UserDataPrefix}${toName}`);
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

}