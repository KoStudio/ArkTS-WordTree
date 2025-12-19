import { Http } from '../../networks/Http'
import { HttpUtils } from '../../networks/HttpUtils'
import { Servers, Route } from '../../networks/Server_Routes'
import { UserManager } from '../user/UserManager'


// === ServerCfg 数据模型 ===
export class ServerCfg {
  key   : string | null = null
  name  : string | null = null
  value : number | null = null

  constructor(json?: Record<string, Object>) {
    if (json) {
      this.key   = (json['key']   as string) ?? null
      this.name  = (json['name']  as string) ?? null
      this.value = (json['value'] as number) ?? null
    }
  }

  static fromArray(arr: Object[] | null): ServerCfg[] {
    if (!arr) return []
    return arr.map(o => new ServerCfg(o as Record<string, Object>))
  }
}

// === ServerCfgManager 管理器 ===
export class ServerCfgManager {
  // 获取所有 ServerCfg
  static loadServerCfgs(completion: (success: boolean, msg: string | null, cfgs: ServerCfg[] | null) => void): void {
    const params: HttpUtils.HttpParams = {}

    const url = Servers.getRouteUrl(Route.servercfg)

    Http.request(url, HttpUtils.Method.GET, params, (succeed: boolean, msg: string | null, result: Object[] | null) => {
      const cfgs = result ? ServerCfg.fromArray(result) : null
      completion(succeed, msg, cfgs)
    })
  }

  // // 获取所有 Admin ServerCfg
  // static loadAdminServerCfgs(completion: (success: boolean, msg: string | null, cfgs: ServerCfg[] | null) => void): void {
  //   const params: HttpUtils.HttpParams = {}
  //
  //   const url = Servers.getRouteUrl(Route.servercfgAdmin)
  //
  //   Http.request(url, HttpUtils.Method.GET, params, (succeed: boolean, msg: string | null, result: Object[] | null) => {
  //     const cfgs = result ? ServerCfg.fromArray(result) : null
  //     completion(succeed, msg, cfgs)
  //   })
  // }
  //
  // // Admin 更新 ServerCfg，服务器端会验证身份
  // static update(key: string, value: string, completion: (success: boolean, msg: string | null) => void): void {
  //   const userId = UserManager.shared.userId
  //   if (userId == null) {
  //     completion(false, "用户未登录")
  //     return
  //   }
  //
  //   const params: HttpUtils.HttpParams = {}
  //   params['userId'] = userId
  //   params['key']    = key
  //   params['value']  = value
  //
  //   const url = Servers.getRouteUrl(Route.servercfgAdminUpate)
  //
  //   Http.request(url, HttpUtils.Method.POST, params, (succeed: boolean, msg: string | null, _result: Object[] | null) => {
  //     completion(succeed, msg)
  //   })
  // }
}