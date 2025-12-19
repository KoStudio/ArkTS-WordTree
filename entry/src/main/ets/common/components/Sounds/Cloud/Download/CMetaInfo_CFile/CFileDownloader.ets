import { StringPyHelper } from "../../../../../utils/strings/StringPyHelper";
import { CosService, CurrentBucket } from "../CDownloadable/CosService";
import { CFileDownloadable } from "./CFileDownloadable";
import { CMetaInfo } from "./CMetaInfo";
import { common } from "@kit.AbilityKit";
import { createFolderIfNeeds } from "../../../../../../app/constants/AppFunctions";
import { FileUtility } from "../../../../../utils/FileUtility";
import { DebugLog } from "../../../../../../app/debug/DebugLog";
import { NetWorkTool } from "../../../../../utils/NetworkUtils";
import {
  CosError,
  CosXmlBaseService,
  CosXmlDownloadTaskResult,
  CosXmlResult,
  DownloadTask,
  GetObjectRequest, HeadObjectRequest, HeadObjectResult,
  HttpProgress } from "@tencentcloud/cos";


// MARK: - 腾讯云文件下载器类
export class CFileDownloader implements CFileDownloadable {


  ///文件名 前辍
  private filePrefix: string;

  constructor(filePrefix: string) {
    this.filePrefix = filePrefix;

    // 初始化COS服务
    CosService.shared

  }

  // MARK: - COS文件元数据获取方法
  private getCFileMetaDataFromCos(fname: string, finished: (metaInfo: CMetaInfo | null, error: string | null) => void): void {
    // 生成文件名，将文本转为拼音并转换为.mp3格式
    const fileName     = StringPyHelper.convertUnicodeForPinyin(fname)

    // // 存储桶名称，格式为 BucketName-APPID    https://console.cloud.tencent.com/cos5/bucket
    let bucket         = CurrentBucket

    //对象在存储桶中的位置标识符，即称对象键
    let cosPath        = `${this.filePrefix}${fileName}` // 对象键，是对象在 COS 上的完整路径 "exampleobject.txt";


    let request        = new HeadObjectRequest(bucket, cosPath);
    request.credential = CosService.shared.getCredential()

    CosXmlBaseService.default().headObject(request).then((result: HeadObjectResult)=>{
      // result中包括http headers, x-cos-meta-*开头的header就是Object 的 Meta 信息。
      const info = this.getMetaInfoFromResult(fileName, result)
      finished(info, null);
    })
      .catch((e: Error)=>{
        finished(null, e.message ?? "")
      })

  }

  // MARK: - COS文件下载方法
  private downloadCFileFromCos(fname: string, proccessing: (progress: number) => void, finished:  (fileUrl: string | null, metaInfo: CMetaInfo | null, error: string | null) => void): void {

    // 生成文件名，将文本转为拼音并转换为.mp3格式
    const fileName             = StringPyHelper.convertUnicodeForPinyin(fname)

    // 缓存文件夹路径
    const context              = getContext() as common.UIAbilityContext;
    const downloadCacheFolder  = `${context.cacheDir}/CosDownloads`;
    const downloadFileUrl      = `${downloadCacheFolder}/${fileName}`;

    // 确保目标文件夹存在
    createFolderIfNeeds(downloadCacheFolder);

    ////删除缓存中旧的文件
    FileUtility.deleteFileAt(downloadFileUrl)

    // 存储桶名称，由 bucketname-appid 组成，appid 必须填入，可以在 COS 控制台查看存储桶名称。 https://console.cloud.tencent.com/cos5/bucket
    let bucket             = CurrentBucket//"examplebucket-1250000000";

    //对象在存储桶中的位置标识符，即称对象键
    let cosPath            = `${this.filePrefix}${fileName}` // 对象键，是对象在 COS 上的完整路径，如果带目录的话，格式为 "dir1/object1"

    //本地文件路径
    let downloadPath       = downloadFileUrl // 设置文件下载保存路径\n "本地文件路径";

    let request            = new GetObjectRequest(bucket, cosPath, downloadPath);
    request.credential     = CosService.shared.getCredential()
    let task: DownloadTask = CosXmlBaseService.default().download(request);
    // 下载进度回调
    task.onProgress        = (progress: HttpProgress) => {
      // progress.complete 为当前已下载大小
      // progress.target 为总大小
      proccessing(progress.complete)
    };
    task.onResult          = {
      // 下载成功回调
      onSuccess: (request, result: CosXmlDownloadTaskResult) => {
        // 如果下载成功，解析结果
        if (!result.accessUrl){
          finished(null, null, "Download result is empty.")
          return
        }

        //获取info
        const info = this.getMetaInfoFromResult(fileName, result)

        // 成功：尝试读取数据
        DebugLog.i("Download completed. Result: \(result)")

        //下载成功 回调
        finished(downloadFileUrl, info, null)

        // 下载完毕后，删除缓存文件
        FileUtility.deleteFileAt(result.accessUrl!)

      },

      //下载失败回调
      onFail: (request, error: CosError) => {
        // 错误处理：下载失败
        DebugLog.e(`Download error: ${error.message}`)
        finished(null, null, error.message ?? "Download error")

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

  // MARK: - CFileDownloadable接口实现

  /**
   * 获取文件元数据
   * @param fileName - 文件名
   * @param finished - 完成回调，返回元数据信息或错误信息
   */
  public getFileMeta(fileName: string, finished: (metaInfo: CMetaInfo | null, error: string | null) => void): void {
    // 校验文件名有效性
    if (!fileName || fileName.trim().length === 0) {
      finished(null, "文件名为空");
      return;
    }

    // 检查网络连接[9](@ref)
    if (!NetWorkTool.checkInternetConnection()) {
      finished(null, "网络不可用");
      return;
    }

    // 从COS获取元数据
    this.getCFileMetaDataFromCos(fileName, finished);
  }

  /**
   * 下载文件
   * @param fileName - 文件名
   * @param proccessing - 进度回调，返回当前下载进度百分比
   * @param finished - 完成回调，返回文件URL、元数据信息或错误信息
   */
  public downloadFile(fileName: string, proccessing: (progress: number) => void, finished: (fileUrl: string | null, metaInfo: CMetaInfo | null, error: string | null) => void): void {
    // 校验文件名有效性
    if (!fileName || fileName.trim().length === 0) {
      finished(null, null, "文件名为空");
      return;
    }

    // 检查网络连接
    if (!NetWorkTool.checkInternetConnection()) {
      finished(null, null, "网络不可用");
      return;
    }

    // 从COS下载文件
    this.downloadCFileFromCos(fileName, proccessing, finished);
  }

  /**
   * 从 COS 接口返回结果中解析 CMetaInfo
   * @param fileName 文件名（经过安全处理的名字）
   * @param result   COS SDK 返回的结果对象（需包含 headers）
   * @returns        CMetaInfo 实例
   */
  private getMetaInfoFromResult(fileName: string, result: CosXmlResult): CMetaInfo {
    // 这里尽量稳健地去读 header 值
    let lastModified  : string | null = null;
    let contentLength : number | null = null;

    if (result && result.headers) {
      const headers = result.headers as Record<string, string>;
      lastModified  = headers["last-modified"] ?? null;
      const lenStr  = headers["content-length"] ?? null;
      contentLength = lenStr ? parseInt(lenStr, 10) : null;
    }

    return new CMetaInfo(fileName, contentLength, lastModified);
  }

}