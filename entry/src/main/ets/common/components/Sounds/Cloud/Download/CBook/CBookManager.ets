import { dAppCBookDbFolderPath, isDebugMode } from "../../../../../../app/constants/AppDefines";
import { createFolderIfNeeds } from "../../../../../../app/constants/AppFunctions";
import { AppCfgManager } from "../../../../../../models/managers/servercfg/AppCfgManager";
import { TimeToManager } from "../../../../../../models/managers/timeto/TimeToManager";
import { FileUtility } from "../../../../../utils/FileUtility";
import { NetWorkTool } from "../../../../../utils/NetworkUtils";
import { PathUtility } from "../../../../../utils/PathUtility";
import { getString } from "../../../../../utils/ResourceUtils";
import { Toast } from "../../../../../utils/Toast";
import { ZipTool } from "../../../../../utils/ZipTool";
import { CFileDownloadable } from "../CMetaInfo_CFile/CFileDownloadable";
import { CFileDownloader } from "../CMetaInfo_CFile/CFileDownloader";
import { CMetaInfo, CMetaInfoHelper } from "../CMetaInfo_CFile/CMetaInfo";
import { CMetaInfoManager } from "../CMetaInfo_CFile/CMetaInfoManager";
import { CBookDbPath, CBookListName } from "./CBookPath";


// MARK: - BookDb 前缀
const BookDbPrefix = "booksDb/v1/"; //以后有新版本时，直接修改相应的v1,v2,v3...

// MARK: - CBookManager 类
export class CBookManager {

  // 单例
  public static shared : CBookManager = new CBookManager();

  // 构造函数私有
  private constructor() {
    // downloader = CosDownloader.shared
    /// do nothing..
  }

  // 下载器
  private downloader        : CFileDownloadable = new CFileDownloader(BookDbPrefix);
  private cmetaInfoManager  : CMetaInfoManager  = new CMetaInfoManager("CMetaInfo_Book");

  // MARK: - BookDb functions

  /**
   * 启动更新 BookDb Check
   */
  public startUpdateBookCheckIfNeeds(baseName: string | null, title: string | null = null, finished: ((succeed: boolean, msg: string | null) => void) | null = null): void {
    if (!baseName) return;

    /// 判断网络 链接
    if (!NetWorkTool.checkInternetConnection(false)) return;

    if (baseName === CBookListName) { // CBookList 课本列表
      /// 开关是 ON
      if (!AppCfgManager.shared.isCBookList_AutoUpdateCheck_is_ON()) {
        Toast.showDebugMessage("CBookList自动更新Check..未启用");
        return;
      }
    } else { /// CBook 课本
      if (!AppCfgManager.shared.isCBook_AutoUpdateCheck_is_ON()) {
        Toast.showDebugMessage("CBook自动更新Check..未启用");
        return;
      }
    }

    const keyTimeTo               = this.cmetaInfoManager.getTimeToKeyFor(baseName);
    const autoUpdateCheckInterval = AppCfgManager.shared.getCBook_AutoUpdateCheck_Interval_Minutes();

    // 更新前记录 CBook 是否已存在
    const isExistedCBook          = this.isExistBookDb(baseName);

    /// 判断 时间间隔
    if (TimeToManager.isTimeToByName(keyTimeTo, autoUpdateCheckInterval)) {
      Toast.showDebugMessage(`CBook[${baseName}]自动更新Check..start..`);

      this.updateBookDbIfNeeds(baseName, (succeed, msg) => {
        if (succeed) {

          ///只有当CBook已经下载过一次后，再次更新才显示消息
          if (isExistedCBook) {
            Toast.showMessage(`${title ?? ""} ${$r('app.string.main_words_cbook_msg_update_succeed')}`);
          } else {
            ///首次下载CBook不显示消息，只显示DebugMessage
            Toast.showDebugMessage(`${title ?? ""} ${getString($r('app.string.main_words_cbook_msg_update_succeed'))}`);
          }
        } else {
          Toast.showDebugMessage(`[${baseName}]更新失败:${msg ?? ""}`);
        }
        finished?.(succeed, msg ?? null);
      });

      /// 记录刷新时间
      TimeToManager.saveTimeByName(keyTimeTo, true);
    }
  }

  /**
   * 更新指定 baseName 的 BookDb
   */
  public updateBookDbIfNeeds(baseName: string, finished: (succeed: boolean, msg: string | null) => void): void {

    ///这里不需要决断本地bundle是否存在，这样可难过服务器任意添加新的Book，只需要控制Book.sqlite即可。
    ///iOS和Android版本 也要去掉这个判断条件  by ko 2025.09.27
    // /// 判断本地 bundle 是否有？
    // const bundlePath = ResName.allDatabases.find(res => res.name === baseName)?.filePath;
    // if (!bundlePath || !FileUtility.isFileExistAt(bundlePath)) {
    //   finished(false, "Local bundle not found");
    //   return;
    // }

    /// 远程是否存在
    this.downloader.getFileMeta(new CBookDbPath(baseName).fileName, (info, msg) => {
      if (info) {
        // server 有
        this.isNeedUpdateBookDb(info).then((result: boolean)=>{
          if (result) {
            /// 需要更新，启动下载
            this.downloadBookDb(baseName, null, finished);
          } else {
            /// 不需要更新
            finished(false, "No needs to updates");
          }
        })
      } else {
        // Server 无
        finished(false, "No file founds." + msg ?? "");
      }
    });
  }

  /**
   * 下载指定 baseName 的 BookDb
   */
  public downloadBookDb(baseName: string, proccessing: ((percent: number) => void) | null = null, finished: (succeed: boolean, msg: string | null) => void): void {
    this.downloader.downloadFile(
      new CBookDbPath(baseName).fileName,
      (percent) => {
        proccessing?.(percent);
      },
      (url, info, msg) => {
        const zipPath    = url;
        const sqlitePath = new CBookDbPath(baseName).sqlite;

        if (zipPath && sqlitePath) {

          ///创建CBookIcon的目录
          let cbookFolder = PathUtility.getParentPathOf(sqlitePath)
          createFolderIfNeeds(cbookFolder)


          if (FileUtility.isFileExistAt(zipPath)) {
            if (FileUtility.isFileExistAt(sqlitePath)) {
              // 删除旧文件
              FileUtility.deleteFileAt(sqlitePath);
            }

            // 解压 注意：这里的路径是本地 Book 的目录
            ZipTool.unzipTo(zipPath, dAppCBookDbFolderPath).then().catch(()=>{

            })

            // 检查是否能打开
            if (!this.isCBookOpenable(baseName)) {
              this.removeBookDb(baseName);
              finished(false, "download finished, but can not open db, and has been removed");
              return;
            }

            if (info) {
              // 保存 Meta
              this.saveDbInfoMeta(info);
              finished(true, "download finished");
              return;
            }
          }
        }

        // 回调失败
        finished(false, `download failed for: ${baseName} ${msg ?? ""}`);
      }
    );
  }

  /**
   * 检查下载的 CBook 是否能正常打开
   */
  public async isCBookOpenable(baseName: string): Promise<boolean> {
    if (!this.isExistBookDb(baseName)) return false;

    if (baseName === CBookListName) {
      const book: Book | null = (await BookDbAccess.shared.getAllBooks())?.[0] ?? null;
      return book?.bookId != null;
    }

    const lesson = (await new LessonDbAccessor(baseName).getAllLessons())?.[0] ?? null;
    return lesson?.texts != null && lesson.texts !== "";
  }

  /**
   * 获取 CBookDb 路径
   */
  public cbookDbPath(baseName: string): string | null {
    return new CBookDbPath(baseName).sqlite;
  }

  /**
   * 删除 BookDb
   */
  public removeBookDb(baseName: string): void {
    const sqlitePath = new CBookDbPath(baseName).sqlite;
    if (sqlitePath && FileUtility.isFileExistAt(sqlitePath)) {
      FileUtility.deleteFileAt(sqlitePath);
    }
  }

  /**
   * 判断 BookDb 是否存在
   */
  public isExistBookDb(baseName: string): boolean {
    const sqlitePath = new CBookDbPath(baseName).sqlite;
    return sqlitePath ? FileUtility.isFileExistAt(sqlitePath) : false;
  }

  /**
   * 判断 BookDb 是否有更新
   */
  public async isNeedUpdateBookDb(info: CMetaInfo): Promise<boolean> {
    if (this.isExistBookDb(info.baseName!)) {
      return await this.cmetaInfoManager.isNeedUpdateForMeta(info);
    }
    return true; // 不存在，即表示要更新
  }

  // MARK: - BookDb Meta functions

  /**
   * 保存 BookDb 的 Meta
   */
  public saveDbInfoMeta(info: CMetaInfo): void {
    this.cmetaInfoManager.saveMetaInfo(info);
  }

  /**
   * 清空所有 CBook，以便可以重新刷新
   */
  public clearAllCBooks(): void {
    this.cmetaInfoManager.clearAll((fileName) => {
      this.removeBookDb(CMetaInfoHelper.baseName(fileName));
    });
  }

}