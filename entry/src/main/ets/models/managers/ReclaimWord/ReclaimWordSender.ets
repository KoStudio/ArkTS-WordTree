import { AppSettings } from "../../../app/constants/AppSettings"
import { DeviceUtil } from "../../../common/utils/DeviceUtils"
import { UserManager } from "../user/UserManager"
import { Http } from "../../networks/Http"
import { HttpUtils } from "../../networks/HttpUtils"
import { Route, Servers } from "../../networks/Server_Routes"


export class ReclaimWordSenderParamKey {

  static readonly bookId     = "book_id"
  static readonly bookName   = "book_name"
  static readonly word       = "word"
  static readonly content    = "content"
  static readonly deviceIDFV = "device_idfv"
  static readonly deviceType = "device_type"
  static readonly userId     = "user_id"
  static readonly userName   = "user_name"

}

/// 应用名称
const appName = AppSettings.App.appName

export class ReclaimWordSender {

  static sendReclaimWord(bookId: number, bookName: string, word: string, content: string, completion: (succeed: boolean, msg: string | null) => void){
    const url                                = `${Servers.getRouteUrl(Route.reclaimWord)}`
    const params: HttpUtils.HttpParams       = {};
    params[ReclaimWordSenderParamKey.bookId]     = bookId.toString()
    params[ReclaimWordSenderParamKey.bookName]   = bookName
    params[ReclaimWordSenderParamKey.word]       = word

    params[ReclaimWordSenderParamKey.content]    = content
    params[ReclaimWordSenderParamKey.userId]     = UserManager.shared.userId ?? ""
    params[ReclaimWordSenderParamKey.userName]   = UserManager.shared.userName ?? ""
    params[ReclaimWordSenderParamKey.deviceIDFV] = DeviceUtil.getUUID()
    params[ReclaimWordSenderParamKey.deviceType] = DeviceUtil.getDeviceType()

    Http.send(url, HttpUtils.Method.POST, params, completion)
  }

}