import { AppSettings } from "../../../app/constants/AppSettings"
import { DeviceUtil } from "../../../common/utils/DeviceUtils"
import { Http } from "../../networks/Http"
import { HttpUtils } from "../../networks/HttpUtils"
import { Route, Servers } from "../../networks/Server_Routes"
import { UserManager } from "../user/UserManager"

export class AdvicesSenderParamKey {

  static readonly appName    = "app_name"
  static readonly content    = "content"
  static readonly contact    = "contact"
  static readonly userId     = "user_id"
  static readonly deviceIDFV = "device_idfv"
  static readonly deviceType = "device_type"

}

/// 应用名称
const appName = AppSettings.App.appName

export class AdviceSender {

  static sendAdvice(advice: string, contact: string | null = null,  completion: (succeed: boolean, msg: string | null) => void){
    const url                                = `${Servers.getRouteUrl(Route.advice)}`
    const params: HttpUtils.HttpParams       = {};
    params[AdvicesSenderParamKey.appName]    = appName
    params[AdvicesSenderParamKey.content]    =  advice
    params[AdvicesSenderParamKey.contact]    =  contact ?? ""
    params[AdvicesSenderParamKey.userId]     = UserManager.shared.userId ?? ""
    params[AdvicesSenderParamKey.deviceIDFV] = DeviceUtil.getUUID()
    params[AdvicesSenderParamKey.deviceType] = DeviceUtil.getDeviceType()

    Http.send(url, HttpUtils.Method.POST, params, completion)
  }

}