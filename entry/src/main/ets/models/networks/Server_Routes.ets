import { DebugFlg } from "../../app/debug/DebugFlg";

// 定义服务器地址常量类
class Address {
  // 生产环境服务器地址
  static readonly server: string = "http://vocabulary.dancishu.com";
  // 本地开发环境地址
  //static readonly local: string = "http://192.168.1.118:3004";//暂无Dev环境
}

// 定义路由枚举
export enum Route {

  advice                = "advice",
  user_data             = "user_data",
  login                 = "login",

  subscription          = "subscription",

}



export namespace  Servers {

  export const flavor: string = '_harmony'

  // 获取当前服务器地址
  export function  getAddress(): string {
    // 这里模拟Swift中的isDebug()判断
    // 实际开发中可以根据需要实现调试判断逻辑
    if (DebugFlg.isDebugMode()) {
      //return Address.local;
    }
    return Address.server;
  }

  // 获取指定路由的完整地址
  export function  getRouteAddress(route: Route): string {
    return `${Servers.getAddress()}/${route}`;
  }

  // 获取指定路由的URL对象
  // 注意：ArkTS/TypeScript中没有原生的URL类，通常使用字符串表示URL
  // 如果需要URL处理，可以使用第三方库或平台提供的API
  export function  getRouteUrl(route: Route): string {
    return Servers.getRouteAddress(route);
  }

  // 安全相关配置
  export class  Secure {
    static readonly appKey: string = "kkaGFybW9ueQ==" //已加密 鸿蒙
    static readonly appSecret: string = "ppbG1ia2Z5ZXJ0d2dqbFMzRjM4NWsuMzQkKzNvQCpyYWU5KTg0LcKlc2FkZmFzZGZkczU4anZvZ2ZkYXNnbjQ="//已加密 vocabulary
  }
}

