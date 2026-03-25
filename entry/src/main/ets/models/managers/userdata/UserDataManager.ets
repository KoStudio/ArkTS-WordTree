import { UserData, UserDataCodingKeys, UserDataJson } from './UserData';
import { UserManager } from '../user/UserManager';
import { Route, Servers } from '../../networks/Server_Routes';
import { HttpUtils } from '../../networks/HttpUtils';
import { Http } from '../../networks/Http';
import { dAppName, dMyDataFolderPath } from '../../../app/constants/AppDefines';
import { ZipTool } from '../../../common/utils/ZipTool';
import { CosDownloaderUserData } from './CosDownloaderUserData';
import { DebugLog } from '../../../app/debug/DebugLog';
import { FileUtility } from '../../../common/utils/FileUtility';
import { createFolderIfNeeds } from '../../../app/constants/AppFunctions';
import { PathUtility } from '../../../common/utils/PathUtility';
import { SearchModifier } from '@kit.ArkUI';
import { BookManager } from '../../datas/book/BookManager';


// MARK: - 用户数据管理器
export class UserDataManager {

  // MARK: - 用户数据加载
  /**
   * 加载用户数据记录（对齐 iOS `UserDataManager2.loadUserData`）
   *
   * 关键点：
   * 1. 需要携带 `user_id` + `book_id` + `app_name` 参数请求 `user_data`。
   * 2. 未登录 / 当前书不存在时：与 iOS 的 `guard ... else { return }` 对齐，直接 return（不回调错误）。
   * 3. iOS 的 eBook 分支依赖 `serverEBookId` 字段；鸿蒙版 `Book` 模型当前缺少对应字段。
   *    - 这里用 `bookId >= 201` 近似识别 eBook（阈值与其他鸿蒙项目保持一致）。
   *    - 用 `book.textDb` 是否存在近似判断“该 eBook 是否已在服务器建过索引”（无索引则直接返回空数组）。
   * @param completion 完成回调（是否成功、错误信息、用户数据数组）
   */
  static loadUserData(completion:(succeed: boolean, msg: string | null, userDataJsons: UserDataJson[] | null) => void) {
    const userId = UserManager.shared.userId;
    // 对齐 iOS：guard userId/login/book else { return }（不回调错误）
    if (!UserManager.shared.isLogin() || userId == null) {
      return;
    }

    const book = BookManager.shared.currentBook;
    if (!book) {
      return;
    }

    const bookId = book.bookId ?? 0;
    if (bookId < 1) {
      return;
    }

    // iOS：如果是 eBook 但没有 serverEBookId，则直接返回空数组（success = true，不发起请求）
    // 由于鸿蒙版缺少 serverEBookId，这里用本地特征进行近似判断（保持控制流一致）。
    const isEBook = bookId >= 201; // 与其它鸿蒙项目的 EBookConstant.Add_BookIdFirst 对齐
    const hasServerEBookId = !isEBook ? true : (book.textDb != null && book.textDb.length > 0);
    if (isEBook && !hasServerEBookId) {
      completion(true, null, []);
      return;
    }

    const url                               = `${Servers.getRouteUrl(Route.user_data)}`
    const params: HttpUtils.HttpParams      = {};
    // 对齐 iOS/Android：请求参数包含 user_id + book_id + app_name
    params[UserDataCodingKeys.userId]       = userId.toString();
    params[UserDataCodingKeys.bookId]       = bookId.toString();
    params[UserDataCodingKeys.appName]      = dAppName

    Http.request(url, HttpUtils.Method.GET, params, completion)
  }

  // MARK: - 数据上传
  /**
   * 上传用户数据到云端
   * @param completion 完成回调（是否成功、错误信息）
   */
  static upload(completion: (success: boolean, error: string | null) => void) {
    const userId = UserManager.shared.userId;
    if (!UserManager.shared.isLogin()) {
      completion(false, "User not logged in");
      return;
    }

    const bookId = BookManager.shared.currentBook?.bookId ?? 0
    if (bookId < 1) {
      completion(false, "Book is not selected")
      return;
    }

    // 1. 获取本地数据目录
    const localMainFolder     = BookManager.getCurrentDirectoryOfUserData()//dMyDataFolderPath

    // 2. 创建ZIP压缩文件
    ZipTool.createOneZip(localMainFolder).then((zipPath) => {

      if (!zipPath){
        completion(false, "Failed to create ZIP file");
        return
      }

      // 3. 上传到腾讯云COS
      CosDownloaderUserData.shared.uploadUserData(
        zipPath,
        `${userId}_${bookId}.zip`,
        (progress) => {
          DebugLog.i(`Uploading... ${progress}%`);
        },
        (success, objectName, error) => {
          // 4. 无论上传结果如何，删除临时ZIP文件
          FileUtility.deleteFileAt(zipPath)

          if (success && objectName) {

            ///保存数据地址到服务器
            const url                                     = `${Servers.getRouteUrl(Route.user_data)}/update`
            const params: HttpUtils.HttpParams            = {};
            params[UserDataCodingKeys.userId]             = userId!.toString()
            params[UserDataCodingKeys.bookId]             = bookId!.toString()
            params[UserDataCodingKeys.userDataAddr]       = objectName
            params[UserDataCodingKeys.appName]            = dAppName

            Http.send(url, HttpUtils.Method.POST, params, completion)

          } else {
            completion(false, error?.toString() ?? 'upload failed at: ' + zipPath);
          }
        }
      );
    }).catch((err: Error) => {
      completion(false, "Failed to create ZIP file");
    })


  }

  // MARK: - 数据下载
  /**
   * 下载用户数据
   * @param userData 用户数据对象
   * @param onProgress 进度回调
   * @param completion 完成回调
   */
  static download(
    userData: UserData,
    onProgress: (progress: number) => void,
    completion: (success: boolean, error: string | null) => void
  ) {
    const userId = UserManager.shared.userId;
    const userDataAddr = userData.userDataAddr;

    if (!userId || !userDataAddr) {
      completion(false, "Invalid user data");
      return;
    }

    const bookId = BookManager.shared.currentBook?.bookId ?? 0
    if (bookId < 1) {
      completion(false, "Book is not selected")
      return;
    }

    const localMainFolder     = BookManager.getCurrentDirectoryOfUserData()//dMyDataFolderPath
    const fileName            = FileUtility.getLastPathComponent(localMainFolder)
    const myDataParentFolder  = FileUtility.deleteLastPathComponent(localMainFolder)
    const localDownloadFolder = FileUtility.appendPathComponent(myDataParentFolder, `${fileName}_download`)
    const localUrl            = `${localDownloadFolder}/${fileName}.zip`;

    // 创建下载目录
    createFolderIfNeeds(localDownloadFolder);

    // 2. 下载数据
    CosDownloaderUserData.shared.downloadUserData(
      userDataAddr,
      localUrl,
      onProgress,
      (success, filePath, error) => {
        if (!success) {
          completion(false, error?.toString() ?? 'Download failed at:' + localUrl);
          return;
        }

        // 3. 解压ZIP文件
        ZipTool.unzip(localUrl).then(async unzipFolder => {
          if (!unzipFolder) {
            completion(false, "Failed to unzip file");
            return;
          }

          // 删除旧的本地数据
          FileUtility.deleteDirectoryAt(localMainFolder)

          // 移动解压后的文件到主目录
          const contents = FileUtility.listFileNames(unzipFolder)
          for (const subDir of contents) {
            const subDirPath = FileUtility.appendPathComponent(unzipFolder, subDir)
            if (PathUtility.isDirectory(subDirPath)){
              await FileUtility.copyFolder(subDirPath, localMainFolder)
            }
          }

          // 清理临时文件
          FileUtility.deleteDirectoryAt(localDownloadFolder)

          //成功 回调
          completion(true, "Download and extraction completed successfully")

        }).catch((err: Error) => {
          completion(false, "Failed to unzip file：" + err.message);
        })

      }
    );
  }

}