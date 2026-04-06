//
// InstructionManager.ets
// WordTree (HarmonyOS)
//
// 与 iOS `InstructionManager.swift` 对齐；Http 回调与解析方式参考 `ServerCfgManager.loadServerCfgs`。
//

import { Http } from '../../networks/Http'
import { HttpUtils } from '../../networks/HttpUtils'
import { Route, Servers } from '../../networks/Server_Routes'
import { Instruction } from './Instruction'

export class InstructionManager {

  // needAll：true 时附带 all=1 拉取全量；completion：是否成功、提示、Instruction 列表
  static loadInstructions(
    needAll: boolean = false,
    completion: (succeed: boolean, msg: string | null, list: Instruction[] | null) => void
  ): void {
    const params: HttpUtils.HttpParams = {}

    if (needAll) {
      params['all'] = '1'
    }

    const url = Servers.getRouteUrl(Route.instruction)

    Http.request(url, HttpUtils.Method.GET, params, (succeed: boolean, msg: string | null, result: Object[] | null) => {

      const list = result ? Instruction.fromArray(result) : null

      completion(succeed, msg, list)
    })
  }

  // idx：指定 Instruction 主键；completion：是否成功、提示、单条（无数据时为 null）
  static loadInstruction(
    idx: number,
    completion: (succeed: boolean, msg: string | null, one: Instruction | null) => void
  ): void {
    const params: HttpUtils.HttpParams = {}

    params['idx'] = idx

    const url = Servers.getRouteUrl(Route.instruction)

    Http.request(url, HttpUtils.Method.GET, params, (succeed: boolean, msg: string | null, result: Object[] | null) => {

      if (!succeed || !result || result.length === 0) {
        completion(succeed, msg, null)
        return
      }

      completion(succeed, msg, new Instruction(result[0] as Record<string, Object>))
    })
  }
}
