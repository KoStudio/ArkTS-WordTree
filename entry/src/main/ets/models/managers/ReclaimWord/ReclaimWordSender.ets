//
// ReclaimWordSender.ets
// WordTree (HarmonyOS)
//
// 与 iOS `ReclaimWordSender.swift`、Android `ReclaimWordSender.kt` 对齐：POST `reclaim_word` 及表单字段。
//

import { AppSettings } from '../../../app/constants/AppSettings'
import { DeviceUtil } from '../../../common/utils/DeviceUtils'
import { Http } from '../../networks/Http'
import { HttpUtils } from '../../networks/HttpUtils'
import { Route, Servers } from '../../networks/Server_Routes'
import { UserManager } from '../user/UserManager'

// Http 参数名，与服务器端、iOS `ParamKey` 一致
class ReclaimWordSenderParamKey {

  static readonly bookId     = 'book_id'
  static readonly bookName   = 'book_name'
  static readonly word       = 'word'
  static readonly content    = 'content'
  static readonly deviceIDFV = 'device_idfv'
  static readonly deviceType = 'device_type'
  static readonly userId     = 'user_id'
  static readonly userName   = 'user_name'
  static readonly appName    = 'app_name'
}

export class ReclaimWordSender {

  // bookId：课本 ID；bookName：课本名称；word：单词；content：正文；completion：是否成功、服务端消息
  static sendReclaimWord(
    bookId: number,
    bookName: string,
    word: string,
    content: string,
    completion: (succeed: boolean, msg: string | null) => void
  ): void {

    const url   = `${Servers.getRouteUrl(Route.reclaimWord)}`
    const params: HttpUtils.HttpParams = {}

    params[ReclaimWordSenderParamKey.bookId]     = bookId
    params[ReclaimWordSenderParamKey.bookName]   = bookName
    params[ReclaimWordSenderParamKey.word]       = word
    params[ReclaimWordSenderParamKey.content]    = content

    // 与 iOS `DcsUserManager.shared.userId`（Int?）对应；鸿蒙未登录时用 0（与常见整型约定一致）
    params[ReclaimWordSenderParamKey.userId]     = UserManager.shared.userId ?? 0
    params[ReclaimWordSenderParamKey.userName]   = UserManager.shared.userName ?? ''

    params[ReclaimWordSenderParamKey.deviceIDFV] = DeviceUtil.getUUID()
    params[ReclaimWordSenderParamKey.deviceType] = DeviceUtil.getDeviceType()

    // 与 iOS `dAppName`、Android `dAppName` 一致
    params[ReclaimWordSenderParamKey.appName]    = AppSettings.App.appName

    // 与 iOS `Http.request(..., handle:)`（仅解析 succeed / msg）一致

    Http.send(url, HttpUtils.Method.POST, params, completion)
  }
}
