//
//  BooksDownloadsManager.ets
//  WordTree
//
//  记录每本 Book 被下载后的次数，上报至 Dcs BookDownload 表（iPhoneDownloads / AndroidDownloads / HarmonyDownloads）。
//  与 iOS `BooksDownloadsManager.swift` 对齐。
//

import { dAppName } from '../../../../app/constants/AppDefines'
import { DebugLog } from '../../../../app/debug/DebugLog'
import { Http } from '../../../networks/Http'
import { HttpUtils } from '../../../networks/HttpUtils'
import { Servers, Route } from '../../../networks/Server_Routes'
import { Book } from '../Book'

/** 平台标识，与服务器 BookDownload 表字段对应 */
export enum BooksDownloadsPlatform {
  iPhone = 'iPhone',
  Android = 'Android',
  Harmony = 'Harmony',
}

class ParamKey {
  static readonly bookId: string = 'book_id'
  static readonly bookName: string = 'book_name'
  static readonly platform: string = 'platform'
  static readonly appName: string = 'app_name'
}

export class BooksDownloadsManager {
  private static get currentPlatform(): BooksDownloadsPlatform {
    return BooksDownloadsPlatform.Harmony
  }

  private static get appName(): string {
    return dAppName
  }

  /**
   * 上报一次课本下载（与 iOS `BooksDownloadsManager.recordDownload` 一致）
   * @param book 被下载的课本
   * @param completion 可选；成功 (true, null)，失败 (false, msg)
   */
  static recordDownload(book: Book, completion?: (succeed: boolean, msg: string | null) => void): void {
    const bookId = book.bookId
    if (bookId === null || bookId === undefined) {
      completion?.(false, 'bookId is null')
      return
    }

    const params: HttpUtils.HttpParams = {}
    params[ParamKey.bookId] = bookId
    params[ParamKey.bookName] = book.bookName ?? ''
    params[ParamKey.platform] = BooksDownloadsManager.currentPlatform
    params[ParamKey.appName] = BooksDownloadsManager.appName

    const url = `${Servers.getRouteUrl(Route.book_download)}/increment`

    Http.send(url, HttpUtils.Method.POST, params, (succeed: boolean, msg: string | null) => {
      if (!succeed) {
        DebugLog.e(`BooksDownloads recordDownload failed: ${msg ?? ''}`)
      }
      completion?.(succeed, msg)
    })
  }
}
