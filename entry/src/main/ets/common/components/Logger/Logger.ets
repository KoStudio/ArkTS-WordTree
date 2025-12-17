import { init, InternalPlugin, onEventObject, preInit, setLogEnabled } from "@umeng/analytics";
import { Context } from "@kit.AbilityKit";
import { isDebugMode } from "../../../app/constants/AppDefines";

export class Logger {

  ///添加abilityStage工程文件，例如entry/src/main/ets/abilityStage/MyAbilityStage.ets
  /// 在AppScope/resources/rawfile/umconfig.json中配置umid，
  static preInit(context: Context){
    preInit({context: context.getApplicationContext(), plugins:[new InternalPlugin()]})
    setLogEnabled(isDebugMode)
  }

  static initilaze(){
    init()
  }

  static logEvent(eventName: string, params?: Record<string, string | number>){

    onEventObject(eventName, params)
  }
}

export function logEvent(eventName: string, params?: Record<string, string | number>){
  Logger.logEvent(eventName, params)
}
