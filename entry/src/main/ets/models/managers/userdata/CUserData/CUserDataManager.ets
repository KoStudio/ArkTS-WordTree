//
//  CUserDataManager.ets
//  Zhika
//
//  Created by huminghua on 2022/1/9.
//  Copyright © 2022 huminghua. All rights reserved.
//

import fs from '@ohos.file.fs'
import { CosDownloaderUserData } from './CosDownloaderUserData'
import { ZipTool } from '../../../../common/utils/ZipTool'
import { FileUtility } from '../../../../common/utils/FileUtility'
import { PathUtility } from '../../../../common/utils/PathUtility'
import { DebugLog } from '../../../../app/debug/DebugLog'
import { createFolderIfNeeds } from '../../../../app/constants/AppFunctions'
import { UserData } from '../UserData'
import { UserDataManager } from '../UserDataManager'
import { UserDataEBook } from '../UserDataEBook'
import { BookManager, Book } from '../../../datas/book/BookManager'
import { EBookManager } from '../../ebook/EBookManager'
import { UserManager } from '../../user/UserManager'
import { EWordManager } from '../../eword/EWordManager'
import { WordUserDbAccess } from '../../../datas/myData/WordUserDbAccess'

// COS 备份/恢复：仅负责 COS 上传下载与本地 zip，Dcs 写回由 UserDataManager 完成
export class CUserDataManager {

  /////////////////////////////////////////////////////////////////////////////
  //使用Cos备份后的处理逻辑 by ko 2022.01.09
  // (1).备份：learnDb zip → COS，路径写回 Dcs 由 UserDataManager 完成
  // (2).恢复：从 Dcs 取路径后从 COS 下载并解压
  // (3).EBook：EBook 内容文件先上传/下载 COS，再 learnDb 同 CBook
  /////////////////////////////////////////////////////////////////////////////

  /**
   * 上传用户数据（CBook / EBook 分支入口）
   * @param completion 是否成功、错误文案回调
   */
  static upload(completion: (succeed: boolean, msg: string | null) => void): void {

    // 取当前用户 id
    const userId = UserManager.shared.userId

    // 未登录或无有效 id 则直接结束
    if (userId === null || userId === undefined || !UserManager.shared.isLogin()) {
      return
    }

    // 取当前书
    const book = BookManager.shared.currentBook

    // 无当前书则不上传
    if (book === null) {
      return
    }

    // WAL 异步收口后再走上传逻辑，避免 ZIP 早于 checkpoint
    void CUserDataManager.uploadAfterWalClosed(completion)
  }

  /**
   * WAL 合并完成后再执行上传（与 iOS / Android 备份顺序一致）
   * @param completion 上传结果回调
   */
  private static async uploadAfterWalClosed(
    completion: (succeed: boolean, msg: string | null) => void
  ): Promise<void> {

    // learn 主库 WAL 收口（WordUserDbAccess）
    await WordUserDbAccess.shared.closeWalIfNeeds()

    // learn 库 EWord 侧 WAL 收口（同一路径下幂等）
    await EWordManager.shared.closeWalIfNeeds()

    // 异步后再次校验登录态
    const userId = UserManager.shared.userId

    // 已登出则中止
    if (userId === null || userId === undefined || !UserManager.shared.isLogin()) {
      return
    }

    // 异步后再次取当前书
    const book = BookManager.shared.currentBook

    // 书已被切换或清空则中止
    if (book === null) {
      return
    }

    // EBook：先内容 zip 再 learnDb zip
    if (book.isEBook) {

      // 尚无服务端 EBook id：先 Dcs 建记录
      if (book.serverEBookId === null || book.serverEBookId === undefined) {

        // 无 serverEBookId：先 Dcs 创建记录，拿到 sid 后持久化，再走 EBook 内容 + learnDb 上传（首次创建 textDbAddr 留空）
        UserDataManager.createEBookRecord(book.bookName, null, book.unitsCount ?? 0, book.wordsCount ?? 0,
          (succeed: boolean, msg: string | null, bookId: number | null) => {

            // 创建失败
            if (!succeed || bookId === null || bookId === undefined) {
              completion(false, msg ?? 'create EBook failed')
              return
            }

            const sid = bookId

            book.serverEBookId = sid

            // 持久化当前书的 serverEBookId
            BookManager.shared.saveBook(book)

            // EBook 内容 zip→COS + Dcs 写回 text_db_addr，再 learnDb zip→COS
            CUserDataManager.uploadEBookContentThenLearnDb(userId, book, sid, completion)
          })

        return
      }

      // 已有 serverEBookId：直接走内容 + learnDb 上传
      CUserDataManager.uploadEBookContentThenLearnDb(userId, book, book.serverEBookId!, completion)
      return
    }

    // CBook：仅 learnDb 目录 zip → COS，路径写回 Dcs
    const bookIdForUpdate = book.bookId ?? 0

    CUserDataManager.uploadLearnDbOnly(userId, bookIdForUpdate, completion)
  }

  /**
   * EBook 内容 zip 上传 COS，写回 EBook 元数据，再上传 learnDb
   * @param userId Dcs / COS 维度用户 id
   * @param book 当前 EBook
   * @param bookIdForUpdate 写回 Dcs 用的 book id（server id）
   * @param completion 是否成功、错误文案回调
   */
  private static uploadEBookContentThenLearnDb(userId: number, book: Book, bookIdForUpdate: number,
    completion: (succeed: boolean, msg: string | null) => void): void {

    const textDbBaseName = book.textDb

    // 无教材库名则只上传 learnDb
    if (textDbBaseName === null || textDbBaseName === undefined) {
      CUserDataManager.uploadLearnDbOnly(userId, bookIdForUpdate, completion)
      return
    }

    // 调用：生成当前 EBook 的教材 sqlite 路径；步骤与 iOS `EBookManager.textDbPath(for:)` 一致
    const textDbPath = EBookManager.textDbPath(textDbBaseName)

    // 本地无教材库文件则只上传 learnDb
    if (!FileUtility.isFileExistAt(textDbPath)) {
      CUserDataManager.uploadLearnDbOnly(userId, bookIdForUpdate, completion)
      return
    }

    // 调用：将 textDb 单文件打为 zip；步骤与 iOS `ZipUtility.createZip(at:)` 一致
    void CUserDataManager.createZipForSingleFileAtPath(textDbPath).then((zipPath: string | null) => {

      // 打 zip 失败
      if (zipPath === null) {
        completion(false, 'Failed when create EBook content zip')
        return
      }

      const cosName = `ebook_${userId}_${bookIdForUpdate}.zip`

      // 2) zip 上传 COS
      CosDownloaderUserData.shared.uploadUserData(
        zipPath,
        cosName,
        (_p: number) => {
        },
        (succeed: boolean, objectName: string | undefined, errMsg: string | undefined) => {

          // 上传结束删除本地临时 zip
          FileUtility.deleteFileAt(zipPath)

          // COS 上传失败
          if (!succeed || objectName === null || objectName === undefined) {
            completion(false, errMsg ?? 'upload EBook content zip to COS failed')
            return
          }

          // 3) Dcs 写回 EBook 元数据：textDbAddr、bookName、unitsCount、wordsCount
          UserDataManager.updateEBookMeta(
            bookIdForUpdate,
            book.bookName,
            objectName,
            book.unitsCount ?? 0,
            book.wordsCount ?? 0,
            (ok: boolean, errMsg: string | null) => {

              // 元数据更新失败
              if (!ok) {
                completion(false, errMsg ?? 'update EBook meta failed')
                return
              }

              // 4) learnDb 目录 zip → COS + Dcs 写回 user_data_addr
              CUserDataManager.uploadLearnDbOnly(userId, bookIdForUpdate, completion)
            })
        })
    })
  }

  /**
   * 当前书 learnDb 目录 zip 上传 COS，路径写回 Dcs（CBook / EBook 共用）
   * @param userId Dcs 用户 id
   * @param bookIdForUpdate 对应 user_data / learn zip 名的 bookId
   * @param completion 是否成功、错误文案回调
   */
  private static uploadLearnDbOnly(userId: number, bookIdForUpdate: number,
    completion: (succeed: boolean, msg: string | null) => void): void {

    const localMainFolder = BookManager.getCurrentDirectoryOfUserDataForLearn()

    // 当前书用户数据目录缺失
    if (localMainFolder.length < 1) {
      completion(false, 'current book user data folder missing')
      return
    }

    // learnDb 目录打 zip（keepParentDirectory: true，解压时需取子目录）
    void ZipTool.createOneZip(localMainFolder).then((zipPath: string | null) => {

      // 本地 zip 失败
      if (zipPath === null) {
        completion(false, 'Failed when Create local zip data')
        return
      }

      const fileNameWithExt = `${userId}_${bookIdForUpdate}.zip`

      // zip 上传 COS，成功后 Dcs 写回 user_data_addr
      CosDownloaderUserData.shared.uploadUserData(
        zipPath,
        fileNameWithExt,
        (_p: number) => {
        },
        (succeed: boolean, objectName: string | undefined, msg: string | undefined) => {

          FileUtility.deleteFileAt(zipPath)

          // 上传成功则回写 Dcs
          if (succeed && objectName) {

            // Dcs UserData 表写回 learnDb zip 的 COS 路径
            CUserDataManager.updateUserData(userId, bookIdForUpdate, objectName, completion)
          } else {

            // 上传失败
            completion(false, msg ?? null)
          }
        })
    }).catch((_err: Error) => {

      // 打 zip 异常
      completion(false, 'Failed when Create local zip data')
    })
  }

  /**
   * 下载用户数据：EBook 先下教材再下 learnDb，否则仅 learnDb
   * @param userData 云端备份记录（含 COS 对象名）
   * @param onProgress COS 下载进度 0–100
   * @param completion 是否成功、错误文案回调
   */
  static download(
    userData: UserData,
    onProgress: (percent: number) => void,
    completion: (succeed: boolean, msg: string | null) => void
  ): void {

    const book = BookManager.shared.currentBook

    // 无当前书
    if (book === null) {
      completion(false, 'current book missing')
      return
    }

    // EBook 且具备 server 与 textDb：先下教材 sqlite 再下 learnDb
    if (book.hasServerEBookId && book.serverEBookId !== null && book.serverEBookId !== undefined && book.textDb) {

      const serverEBookId = book.serverEBookId
      const textDbPath    = EBookManager.textDbPath(book.textDb)

      CUserDataManager.downloadEBookContent(serverEBookId, textDbPath, (succeed: boolean, msg: string | null) => {

        // 教材包下载 / 解压失败
        if (!succeed) {
          completion(false, msg ?? 'download EBook content failed')
          return
        }

        // learnDb zip 下载并解压到当前书用户数据目录
        CUserDataManager.doDownloadLearnDb(userData, onProgress, (succeed: boolean, msg: string | null) => {

          // 恢复成功后刷新统计
          if (succeed && BookManager.shared.currentBook?.isEBook === true) {

            // 恢复后刷新 unitsCount / wordsCount（与本地添加单词后一致）
            void BookManager.shared.refreshBookCounts(textDbPath)
          }

          completion(succeed, msg)
        })
      })
    } else {

      // CBook 或 EBook 无 serverEBookId：仅下 learnDb zip 并解压
      CUserDataManager.doDownloadLearnDb(userData, onProgress, completion)
    }
  }

  /**
   * 从 Dcs 取 textDbAddr 后再从 COS 拉教材 zip 并解压
   * @param serverEBookId Dcs 上 EBook 主键
   * @param toTextDbPath 本地教材 sqlite 路径
   * @param completion 是否成功、错误文案回调
   */
  static downloadEBookContent(serverEBookId: number, toTextDbPath: string,
    completion: (succeed: boolean, msg: string | null) => void): void {

    // Dcs 取 EBook 记录的 text_db_addr（COS 对象名，如 ebook_6385_123.zip）
    UserDataManager.getEBookRecord(serverEBookId, (succeed: boolean, msg: string | null, list: UserDataEBook[] | null) => {

      // 拉取记录失败或列表空
      if (!succeed || list === null || list.length < 1) {
        completion(false, msg ?? 'get text_db_addr failed')
        return
      }

      const first = list[0]
      const addr  = first.textDbAddr

      // 无 COS 地址
      if (addr === null || addr === undefined || addr.length < 1) {
        completion(false, msg ?? 'get text_db_addr failed')
        return
      }

      CUserDataManager.downloadEBookZipThenUnzip(addr, toTextDbPath, completion)
    })
  }

  /**
   * 已知 COS 对象名时下载 EBook 内容 zip（列表项「下载备份」）
   * @param ebookDataAddr COS 上 zip 对象名
   * @param toTextDbPath 本地教材 sqlite 路径
   * @param completion 是否成功、错误文案回调
   */
  static downloadEBookContentFromCOS(ebookDataAddr: string, toTextDbPath: string,
    completion: (succeed: boolean, msg: string | null) => void): void {

    // 对象名为空
    if (!ebookDataAddr || ebookDataAddr.length < 1) {
      completion(false, 'text_db_addr empty')
      return
    }

    CUserDataManager.downloadEBookZipThenUnzip(ebookDataAddr, toTextDbPath, completion)
  }

  /**
   * COS 下载 EBook zip → 解压 → sqlite 移到目标路径
   * @param objectName COS 对象名
   * @param toTextDbPath 本地教材 sqlite 完整路径
   * @param completion 是否成功、错误文案回调
   */
  private static downloadEBookZipThenUnzip(objectName: string, toTextDbPath: string,
    completion: (succeed: boolean, msg: string | null) => void): void {

    const destDir        = FileUtility.deleteLastPathComponent(toTextDbPath)
    const downloadFolder = FileUtility.appendPathComponent(destDir, 'ebook_download')
    const zipPath        = FileUtility.appendPathComponent(downloadFolder, 'ebook.zip')

    FileUtility.deleteDirectoryAt(downloadFolder)

    createFolderIfNeeds(downloadFolder)

    // 下载 zip 到临时目录 ebook_download / ebook.zip
    CosDownloaderUserData.shared.downloadUserData(
      objectName,
      zipPath,
      (_p: number) => {
      },
      (succeed: boolean, _fp: string | undefined, msg: string | undefined) => {

        // COS 下载失败
        if (!succeed) {
          FileUtility.deleteDirectoryAt(downloadFolder)
          completion(false, msg ?? 'download EBook zip from COS failed')
          return
        }

        // 解压到同目录下 _unzip（ZipUtility.unZip 约定）
        void ZipTool.unzipTo(zipPath, FileUtility.appendPathComponent(downloadFolder, '_unzip')).then((unzipFolder: string | null) => {

          // 解压失败
          if (unzipFolder === null) {
            FileUtility.deleteFileAt(zipPath)
            FileUtility.deleteDirectoryAt(downloadFolder)
            completion(false, 'unzip EBook failed')
            return
          }

          // zip 内为单个 sqlite 文件（或位于一层子目录），找到后移到 toTextDbPath
          const unzippedFile = CUserDataManager.findSqliteFile(unzipFolder)

          // 未找到 sqlite
          if (unzippedFile === null) {
            FileUtility.deleteFileAt(zipPath)
            FileUtility.deleteDirectoryAt(unzipFolder)
            FileUtility.deleteDirectoryAt(downloadFolder)
            completion(false, 'no sqlite in EBook zip')
            return
          }

          try {

            // 目标已存在则先删
            if (FileUtility.isFileExistAt(toTextDbPath)) {
              FileUtility.deleteFileAt(toTextDbPath)
            }

            // 将解压出的 sqlite 移到目标路径，覆盖已有文件
            if (!FileUtility.moveFile(unzippedFile, toTextDbPath)) {
              FileUtility.deleteFileAt(zipPath)
              FileUtility.deleteDirectoryAt(unzipFolder)
              FileUtility.deleteDirectoryAt(downloadFolder)
              completion(false, 'move sqlite failed')
              return
            }

            FileUtility.deleteFileAt(zipPath)
            FileUtility.deleteDirectoryAt(unzipFolder)
            FileUtility.deleteDirectoryAt(downloadFolder)
            completion(true, null)
          } catch (e) {

            // 移动或清理异常
            FileUtility.deleteFileAt(zipPath)
            FileUtility.deleteDirectoryAt(unzipFolder)
            FileUtility.deleteDirectoryAt(downloadFolder)
            completion(false, `${e}`)
          }
        })
      })
  }

  /**
   * 在目录内查找 .sqlite 文件（当前层或递归子目录）
   * @param directoryPath 解压目录或子目录
   * @returns sqlite 绝对路径；未找到则 null
   */
  private static findSqliteFile(directoryPath: string): string | null {

    try {

      // 路径不可访问或不存在
      if (!fs.accessSync(directoryPath)) {
        return null
      }

      const stat = fs.statSync(directoryPath)

      // 非目录
      if (!stat.isDirectory()) {
        return null
      }

      const contents = fs.listFileSync(directoryPath)

      for (let i = 0; i < contents.length; i++) {
        const name     = contents[i]
        const fullPath = FileUtility.appendPathComponent(directoryPath, name)
        const st       = fs.statSync(fullPath)

        // 子目录则递归
        if (st.isDirectory()) {

          // 子目录内递归查找
          const found = CUserDataManager.findSqliteFile(fullPath)

          if (found !== null) {
            return found
          }
        } else if (name.toLowerCase().endsWith('.sqlite')) {

          // 当前层即 sqlite
          return fullPath
        }
      }
    } catch (e) {
      DebugLog.e(`[CUserDataManager] findSqliteFile: ${e}`)
    }

    return null
  }

  /**
   * 从 COS 下载 learnDb zip 并解压到当前书用户数据目录
   * @param userData 含 userDataAddr（COS 对象名）
   * @param onProgress 下载进度回调
   * @param completion 是否成功、错误文案回调
   */
  static doDownloadLearnDb(
    userData: UserData,
    onProgress: (percent: number) => void,
    completion: (succeed: boolean, msg: string | null) => void
  ): void {

    const userDataAddr = userData.userDataAddr
    const userId       = UserManager.shared.userId

    // userDataAddr / userId / 当前书 任一无效
    if (userDataAddr === null || userDataAddr === undefined || userDataAddr.length < 1
      || userId === null || userId === undefined || BookManager.shared.currentBook === null) {
      completion(false, 'userData or current book missing')
      return
    }

    const localMainFolder = BookManager.getCurrentDirectoryOfUserDataForLearn()

    // 本地用户数据目录路径无效
    if (localMainFolder.length < 1) {
      completion(false, 'user data folder missing')
      return
    }

    createFolderIfNeeds(localMainFolder)

    const fileName = FileUtility.getLastPathComponent(localMainFolder)

    // 下载到临时目录 xxx_download / xxx.zip，避免直接写当前书目录
    const myDataParentFolder  = FileUtility.deleteLastPathComponent(localMainFolder)
    const localDownloadFolder = FileUtility.appendPathComponent(myDataParentFolder, `${fileName}_download`)
    const localUrl            = `${localDownloadFolder}/${fileName}.zip`

    createFolderIfNeeds(localDownloadFolder)

    // COS 下载 learnDb zip（userDataAddr 即 userId_bookId.zip）
    CosDownloaderUserData.shared.downloadUserData(
      userDataAddr,
      localUrl,
      (percent: number) => {
        onProgress(percent)
      },
      (succeed: boolean, _fp: string | undefined, msg: string | undefined) => {

        // 下载成功则解压
        if (succeed) {
          void ZipTool.unzip(localUrl).then(async (unzipFolder: string | null) => {

            // 解压到 _unzip；zip 为 keepParentDirectory 打的，内有一层子目录，移入当前书目录
            if (unzipFolder === null) {
              FileUtility.deleteFileAt(localUrl)
              FileUtility.deleteDirectoryAt(localDownloadFolder)
              completion(false, 'unzip failed!')
              return
            }

            const names = FileUtility.listFileNames(unzipFolder)
            let moved   = false

            for (let i = 0; i < names.length; i++) {
              const subPath = FileUtility.appendPathComponent(unzipFolder, names[i])

              // 只处理 zip 内第一层目录（keepParentDirectory 约定）
              if (PathUtility.isDirectory(subPath)) {

                try {

                  // 目标目录已存在则清空
                  if (FileUtility.isFileExistAt(localMainFolder)) {
                    FileUtility.deleteDirectoryAt(localMainFolder)
                  }

                  // 将 zip 内唯一子目录整体移为当前书 learnDb 目录
                  await FileUtility.copyFolder(subPath, localMainFolder)
                  FileUtility.deleteDirectoryAt(subPath)
                  moved = true
                } catch (e) {
                  DebugLog.e(`${e}`)
                }

                break
              }
            }

            FileUtility.deleteDirectoryAt(unzipFolder)
            FileUtility.deleteDirectoryAt(localDownloadFolder)
            FileUtility.deleteFileAt(localUrl)

            // 是否成功迁入 learn 目录
            if (moved) {
              completion(true, 'download finished')
            } else {
              completion(false, 'unzip failed!')
            }
          })

          return
        }

        // 下载失败，清理临时目录
        FileUtility.deleteFileAt(localUrl)
        FileUtility.deleteDirectoryAt(localDownloadFolder)
        completion(false, `download failed: ${msg ?? ''}`)
      })
  }

  /**
   * Dcs 更新 user_data 中 learnDb zip 的 COS 路径
   * @param userId 用户 id
   * @param bookId 书 id
   * @param userDataAddr COS 对象名，可为 null
   * @param completion 是否成功、错误文案回调
   */
  private static updateUserData(userId: number, bookId: number, userDataAddr: string | null,
    completion: (succeed: boolean, msg: string | null) => void): void {

    UserDataManager.updateUserData(userId, bookId, userDataAddr, completion)
  }

  /**
   * 单文件 sqlite 包一层目录后打 zip（对齐 iOS ZipUtility.createZip(at:)）
   * @param srcPath 教材 sqlite 绝对路径
   * @returns zip 沙箱路径；失败则 null
   */
  private static async createZipForSingleFileAtPath(srcPath: string): Promise<string | null> {

    const baseName      = PathUtility.getLastComponentName(srcPath)
    const parentPath    = FileUtility.deleteLastPathComponent(srcPath)
    const jobId         = `${Date.now()}`
    const wrapperDir    = FileUtility.appendPathComponent(parentPath, `_ebook_up_${jobId}`)
    const sourceDir     = FileUtility.appendPathComponent(wrapperDir, 'inner')
    const resultZipPath = FileUtility.appendPathComponent(parentPath, `_ebook_up_${jobId}.zip`)

    // 调用：创建临时包裹目录；鸿蒙 `ZipTool.createOneZip(...)` 以目录为输入，这里用目录适配到 iOS 的“单文件打 zip”语义
    createFolderIfNeeds(sourceDir)

    const copiedFilePath = FileUtility.appendPathComponent(sourceDir, baseName)

    // 分支：先复制 sqlite 到临时目录；复制失败则结束
    if (!FileUtility.copyFile(srcPath, copiedFilePath)) {
      FileUtility.deleteDirectoryAt(wrapperDir)
      return null
    }

    // 调用：生成临时 zip；输出路径为 `sourceDir + ".zip"`，仍位于 wrapperDir 内
    const tempZipPath = await ZipTool.createOneZip(sourceDir)

    // 分支：打 zip 失败时直接清理临时目录
    if (tempZipPath === null) {
      FileUtility.deleteDirectoryAt(wrapperDir)
      return null
    }

    // 调用：将最终 zip 移到临时目录外；这样后续清理 wrapperDir 时不会把待上传 zip 一起删掉
    FileUtility.deleteFileAt(resultZipPath)

    // 分支：移动失败时清理临时目录并返回失败；这是鸿蒙端此前 `No such file or directory` 的根因点
    if (!FileUtility.moveFile(tempZipPath, resultZipPath)) {
      FileUtility.deleteDirectoryAt(wrapperDir)
      return null
    }

    // 调用：清理仅用于中转打包的临时目录；最终 zip 已独立保留在外层目录
    FileUtility.deleteDirectoryAt(wrapperDir)

    return resultZipPath
  }
}
