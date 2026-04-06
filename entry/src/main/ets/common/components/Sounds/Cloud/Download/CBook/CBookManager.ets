//
//  CBookManager.ets
//  WordTree (HarmonyOS)
//
//  与 iOS CBookManager.swift 对齐：云端课本/BookList/BaseDict/Cigen 库的下载、校验、Meta、通知。
//

import { dAppCBookDbFolderPath, isDebugMode } from '../../../../../../app/constants/AppDefines'
import { createFolderIfNeeds } from '../../../../../../app/constants/AppFunctions'
import { Book, BookManager, BookManagerNotification } from '../../../../../../models/datas/book/BookManager'
import { BookDbAccess } from '../../../../../../models/datas/book/BookDbAccess'
import { WordDbAccess } from '../../../../../../models/datas/word/WordDbAccess'
import { AppCfgManager } from '../../../../../../models/managers/servercfg/AppCfgManager'
import { TimeToManager } from '../../../../../../models/managers/timeto/TimeToManager'
import { SimpleEventBus } from '../../../../eventbus/SimpleEventBus'
import { FileUtility } from '../../../../../utils/FileUtility'
import { NetWorkTool } from '../../../../../utils/NetworkUtils'
import { PathUtility } from '../../../../../utils/PathUtility'
import { getString } from '../../../../../utils/ResourceUtils'
import { Toast } from '../../../../../utils/Toast'
import { ZipTool } from '../../../../../utils/ZipTool'
import { CFileDownloadable } from '../CMetaInfo_CFile/CFileDownloadable'
import { CFileDownloader } from '../CMetaInfo_CFile/CFileDownloader'
import { CMetaInfo, CMetaInfoHelper } from '../CMetaInfo_CFile/CMetaInfo'
import { CMetaInfoManager } from '../CMetaInfo_CFile/CMetaInfoManager'
import {
  CBookDbPath,
  CBookListName,
  CCigenDataName_Cns,
  CCigenDataName_Cnt,
  CBaseDictName_Cns,
  CBaseDictName_Cnt,
  getCBaseDictName,
  getCCigenDataName,
} from './CBookPath'

// 与 iOS `NSNotification.Name` 字符串一致，供 SimpleEventBus 订阅（`CBookManager` 下载成功后广播）
export namespace CBookManagerNotification {
  export const currentBaseDictUpdated: string = 'BaseDictManager2Notification_CurrentBaseDictUpdated'
  export const currentCigenDataUpdated: string = 'CigenDataManager2Notification_CurrentCigenDataUpdated'
}

// 以后有新版本时，直接修改相应的 v1,v2,v3...（与 iOS `BookDbPrefix` 一致）
const BookDbPrefix = 'booksDb/v1/'

export class CBookManager {

  public static shared: CBookManager = new CBookManager()

  private constructor() {
    // downloader = CosDownloader
    // do nothing..
  }

  private downloader: CFileDownloadable       = new CFileDownloader(BookDbPrefix)
  private cmetaInfoManager: CMetaInfoManager  = new CMetaInfoManager('CMetaInfo_Book')

  // MARK: - BookDb functions

  // 启动更新 BookDb Check；title：更新成功时拼接提示；forceDownload：忽略时间间隔
  public startUpdateBookCheckIfNeeds(
    baseName: string | null,
    title: string | null = null,
    forceDownload: boolean = false,
    proccessing: ((percent: number) => void) | null = null,
    finished: ((succeed: boolean, msg: string | null) => void) | null = null
  ): void {
    if (!baseName) {
      return
    }

    // 判断网络链接
    if (!NetWorkTool.checkInternetConnection(false)) {
      return
    }

    if (baseName === CBookListName) {
      // CBookList 课本列表；开关是 ON
      if (!AppCfgManager.shared.isCBookList_AutoUpdateCheck_is_ON()) {
        // Toast.showDebugMessage("CBookList自动更新Check..未启用")
        return
      }
    } else {
      // CBook 课本；开关是 ON
      if (!AppCfgManager.shared.isCBook_AutoUpdateCheck_is_ON()) {
        // Toast.showDebugMessage("CBook自动更新Check..未启用")
        return
      }
    }

    const keyTimeTo = this.cmetaInfoManager.getTimeToKeyFor(baseName)
    let autoUpdateCheckInterval = AppCfgManager.shared.getCBook_AutoUpdateCheck_Interval_Minutes()

    // 调试用（与 iOS `isDebug()` 下 interval=0 一致）
    if (isDebugMode) {
      autoUpdateCheckInterval = 0
    }

    // 更新前记录 CBook 是否已存在（已下载过）
    const isExistedCBook = this.isExistBookDb(baseName)

    // 判断时间间隔
    if (forceDownload || TimeToManager.isTimeToByName(keyTimeTo, autoUpdateCheckInterval)) {
      // Toast.showDebugMessage(`CBook[${baseName}]自动更新Check..start..`)

      this.updateBookDbIfNeeds(baseName, proccessing, (succeed, msg) => {
        if (succeed) {
          // 只有当 CBook 已经下载过一次后，再次更新才显示消息
          if (isExistedCBook) {
            Toast.showMessage(`${title ?? ''} ${$r('app.string.main_words_cbook_msg_update_succeed')}`)
          } else {
            // 首次下载 CBook 不显示消息，只显示 DebugMessage
            Toast.showDebugMessage(`${title ?? ''} ${getString($r('app.string.main_words_cbook_msg_update_succeed'))}`)
          }
        } else {
          if (msg !== 'No needs to updates') {
            Toast.showDebugMessage(`[${baseName}]更新失败:${msg ?? ''}`)
          }
        }
        finished?.(succeed, msg ?? null)
      })

      // 记录刷新时间
      TimeToManager.saveTimeByName(keyTimeTo, true)
    }
  }

  // 更新指定 baseName 的 BookDb（与 iOS 一致：不依赖本地 bundle 是否存在）
  public updateBookDbIfNeeds(
    baseName: string,
    proccessing: ((percent: number) => void) | null = null,
    finished: (succeed: boolean, msg: string | null) => void
  ): void {
    this.downloader.getFileMeta(new CBookDbPath(baseName).fileName, (info, msg) => {
      if (info) {
        // server 有
        void this.isNeedUpdateBookDb(info).then((need: boolean) => {
          if (need) {
            // 需要更新，启动下载
            this.downloadBookDb(baseName, proccessing, finished)
          } else {
            // 不需要更新
            finished(false, 'No needs to updates')
          }
        })
      } else {
        // Server 无
        finished(false, 'No file founds.')
      }
    })
  }

  // 下载指定 baseName 的 BookDb
  public downloadBookDb(
    baseName: string,
    proccessing: ((percent: number) => void) | null = null,
    finished: (succeed: boolean, msg: string | null) => void
  ): void {
    this.downloader.downloadFile(
      new CBookDbPath(baseName).fileName,
      (percent) => {
        proccessing?.(percent)
      },
      async (url, info, msg) => {
        const zipPath = url
        const sqlitePath = new CBookDbPath(baseName).sqlite

        if (zipPath && sqlitePath) {
          // 创建 CBook 目录（与 iOS 解压目标目录一致）
          const cbookFolder = PathUtility.getParentPathOf(sqlitePath)
          createFolderIfNeeds(cbookFolder)

          if (FileUtility.isFileExistAt(zipPath)) {
            if (FileUtility.isFileExistAt(sqlitePath)) {
              // 删除旧的
              FileUtility.deleteFileAt(sqlitePath)
            }

            // 解压：注意路径是本地 Book 目录（与 iOS `ZipUtility.unZip` 目标一致）
            await ZipTool.unzipTo(zipPath, dAppCBookDbFolderPath)

            // 检查是否能打开
            if (!(await this.isCBookOpenable(baseName))) {
              this.removeBookDb(baseName)
              finished(false, 'down load finished,but can not open db, and has been removed')
              return
            }

            if (info) {
              // 保存 Meta
              await this.saveDbInfoMetaAsync(info)

              // 当前课本对应的 CBook 已更新（与 iOS `BookManager2.Notification.currentBookUpdated` 一致）
              if (baseName === BookManager.shared.currentBook?.textDb) {
                SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)
              }

              // 当前 BaseDict 对应的 CBook 已更新
              if (baseName === getCBaseDictName()) {
                SimpleEventBus.emit(CBookManagerNotification.currentBaseDictUpdated)
              }

              // 当前 CigenData 对应的 CBook 已更新
              if (baseName === getCCigenDataName()) {
                SimpleEventBus.emit(CBookManagerNotification.currentCigenDataUpdated)
              }

              finished(true, 'download finished')
              return
            }
          }
        }

        finished(false, `download failed for:${baseName} ${msg ?? ''}`)
      }
    )
  }

  // 检查下载的 CBook 是否能正常打开（与 iOS `CBookManager.isCBookOpenable` 分支与委托方式一致）
  public async isCBookOpenable(baseName: string): Promise<boolean> {
    if (!this.isExistBookDb(baseName)) {
      return false
    }

    if (baseName === CBookListName) {
      const book: Book | null = (await BookDbAccess.shared.getAllBooks())?.[0] ?? null
      return book?.bookId != null
    }

    // BaseDict：委托 `BaseWordManager.isOpenable(for:)` → 鸿蒙 `BaseWordDbAccess.isOpenableForDownloadedBaseName`
    if (baseName === CBaseDictName_Cns || baseName === CBaseDictName_Cnt) {
      const mod = await import('../../../../../../models/datas/basedict/BaseWordDbAccess')
      return await mod.BaseWordDbAccess.isOpenableForDownloadedBaseName(baseName)
    }

    // CigenData：委托 `CigenWordManager.isOpenable(for:)` → 鸿蒙 `CigenWordDbAccess.isOpenableForDownloadedBaseName`
    if (baseName === CCigenDataName_Cns || baseName === CCigenDataName_Cnt) {
      const mod = await import('../../../../../../models/datas/cigen/CigenWordDbAccess')
      return await mod.CigenWordDbAccess.isOpenableForDownloadedBaseName(baseName)
    }

    // 普通课本：委托 `WordManager.isOpenable(for:)`（`COUNT(*)` on Word 表）
    const count = await new WordDbAccess(baseName).getWordsCount()
    return count > 0
  }

  public cbookDbPath(baseName: string): string | null {
    return new CBookDbPath(baseName).sqlite
  }

  // 删除 BookDb
  public removeBookDb(baseName: string): void {
    const sqlitePath = new CBookDbPath(baseName).sqlite
    if (sqlitePath && FileUtility.isFileExistAt(sqlitePath)) {
      FileUtility.deleteFileAt(sqlitePath)
    }
  }

  // 判断 BookDb 是否存在
  public isExistBookDb(baseName: string): boolean {
    const sqlitePath = new CBookDbPath(baseName).sqlite
    return sqlitePath ? FileUtility.isFileExistAt(sqlitePath) : false
  }

  // 判断 BookDb 是否有更新
  public async isNeedUpdateBookDb(info: CMetaInfo): Promise<boolean> {
    const bn = info.fileName ? CMetaInfoHelper.baseName(info.fileName) : ''
    if (bn && this.isExistBookDb(bn)) {
      return await this.cmetaInfoManager.isNeedUpdateForMeta(info)
    }
    return true
  }

  // MARK: - BookDb Meta functions

  // 保存 BookDb 的 Meta
  public saveDbInfoMeta(info: CMetaInfo): void {
    void this.cmetaInfoManager.saveMetaInfo(info)
  }

  private async saveDbInfoMetaAsync(info: CMetaInfo): Promise<void> {
    await this.cmetaInfoManager.saveMetaInfo(info)
  }

  // 清空所有 CBook，以便可以重新刷新
  public clearAllCBooks(): void {
    void this.cmetaInfoManager.clearAll((fileName: string) => {
      this.removeBookDb(CMetaInfoHelper.baseName(fileName))
    })
  }
}
