// import { BusinessError } from '@ohos.base';
// import { IQQOpenApi, QQOpenApiFactory, AuthResult, AuthResultType, AuthResponse, ApiCallback,
//   OpenApiConfig } from '@tencent/qq-open-sdk';
// import { AppSettings } from '../../../../app/constants/AppSettings';
// import { DebugLog } from '../../../../app/debug/DebugLog';
// import { SnsOneUser } from '../../user/User';
// import { Want } from '@kit.AbilityKit';
// import { SnsOneLoginCallback } from '../wx/WxLoginManager';
// import Fetch, { FetchResponse } from '@system.fetch';
// import json from '@ohos.util.json';
//
// /////////////////////////////////////////////////////////////////////////
// ///
// /// QQ登录官方文档
// ///https://wiki.connect.qq.com/harmonyos_sdk环境搭建
// // https://wiki.connect.qq.com/使用authorization_code获取access_token#:~:text=Step2：通过Authorization%20Code获取Access%20Token
// /// 关键步骤：
// ///   1.在华为AppGallery Connect上
// ///                创建AppLinks: 如: https://www.dancishu.com(Zhika暂时使用) ，
// ///                    （要在www.dancishu.com下添加.well-known/applinking.json）
// ///                                       {
// ///                                         "applinking": {
// ///                                         "apps": [
// ///                                         {
// ///                                           "appIdentifier": "6917583818702073612"//zhika，需要在当前签名下，从此应用中获取，参考BundleUtils.getBundleAppIdentifier()
// ///                                         }
// ///                                         ]
// ///                                       }
// ///                                       }
// ///    2.在QQ互联平台配置：
// ///             AppLinks,bundleName,fingerprint的md5,(需要在当前的签名下，从此应用中获取，参考BundleUtils.getBundleAppIdentifier())
// ///           如果，跳转到QQ后，点击“同意”，时出现错误提示“未注册鸿蒙应用，前往官网注册”时，需要联系QQ客服，重新上线一下应用才行。
// ///
// ///   3.配置module.json5中的：entities，actions，uris, querySchemes <参考注释:QQ登录配置>
// ///   4. EntryAbility的onNewWant中添加： QQLoginManager.shared.handleResult(want)
// ///
// ///
// /// by ko 2025.11.25
// ///
// /////////////////////////////////////////////////////////////////////////
//
// // QQ登录管理类
// export class QQLoginManager {
//   private static instance: QQLoginManager | null = null;
//
//   // 从应用配置中获取，这里需要替换为实际的AppId
//   private APP_ID: number = Number(AppSettings.CfgQQ.AppId);
//
//   private iQQOpenApi: IQQOpenApi | null = null;
//   private SnsOneLoginCallback: SnsOneLoginCallback | null = null;
//
//   // 单例模式
//   public static get shared(): QQLoginManager {
//     if (!QQLoginManager.instance) {
//       QQLoginManager.instance = new QQLoginManager();
//       QQLoginManager.instance.init();
//     }
//     return QQLoginManager.instance;
//   }
//
//   private init(): void {
//     try {
//       let openApiOption: OpenApiConfig = {
//         forceEnableWeb: false,
//         autoHandleAuthResult: true,
//       }
//
//       this.iQQOpenApi = QQOpenApiFactory.createApi(this.APP_ID, openApiOption);
//       DebugLog.d('QQLoginManager initialized successfully');
//     } catch (error) {
//       DebugLog.e('QQLoginManager init failed: ' + JSON.stringify(error));
//     }
//   }
//
//   // 检查QQ是否安装
//   public isQQAppInstalled(): boolean {
//     try {
//       return this.iQQOpenApi?.isQQInstalled() ?? false;
//     } catch (error) {
//       DebugLog.e('Check QQ installation failed: ' + JSON.stringify(error));
//       return false;
//     }
//   }
//
//   // 登录方法 - Promise方式 （not using）
//   public async login(callback: SnsOneLoginCallback): Promise<void> {
//     this.SnsOneLoginCallback = callback;
//
//     if (!this.iQQOpenApi) {
//       this.handleLoginError('QQOpenApi not initialized');
//       return;
//     }
//
//     try {
//       const result: AuthResult = await this.iQQOpenApi.login({
//         scope: "all",
//         useQrCode: false,
//         networkTimeout: 0,
//         forceWebLogin: false
//       });
//
//       this.handleAuthResult(result);
//     } catch (error) {
//       this.handleLoginError(error);
//     }
//   }
//
//   // 登录方法 - 回调方式
//   public loginWithCallback(callback: SnsOneLoginCallback): void {
//     this.SnsOneLoginCallback = callback;
//
//     if (!this.iQQOpenApi) {
//       this.handleLoginError('QQOpenApi not initialized');
//       return;
//     }
//
//     const loginApiCallback: ApiCallback<AuthResponse> = {
//       onComplete: (response: AuthResponse): void => {
//         DebugLog.d(`onComplete response: ${JSON.stringify(response)}`);
//         if (response.ret == 0) {
//           this.onAuthSuccess(response);
//         } else {
//           this.handleLoginError(`Auth failed with ret: ${response.ret}`);
//         }
//       },
//       onError: (msg: string | null): void => {
//         this.handleLoginError(`onError: ${msg}`);
//       },
//       onCancel: (msg: string | null): void => {
//         this.handleLoginError('Login canceled by user');
//       }
//     };
//
//     try {
//       this.iQQOpenApi.login({
//         scope: "all",
//         useQrCode: false,
//         networkTimeout: 0,
//         forceWebLogin: false
//       }, loginApiCallback);
//     } catch (error) {
//       this.handleLoginError(error);
//     }
//   }
//
//   // 处理授权结果
//   private handleAuthResult(result: AuthResult): void {
//     switch (result.type) {
//       case AuthResultType.Success:
//         if (result.authResponse) {
//           this.onAuthSuccess(result.authResponse);
//         } else {
//           this.handleLoginError( 'Auth response is null');
//         }
//         break;
//       case AuthResultType.Cancel:
//         this.handleLoginError('Login canceled by user');
//         break;
//       case AuthResultType.Error:
//         this.handleLoginError(result.message ?? 'Unknown error');
//         break;
//       default:
//         this.handleLoginError('Unknown auth result type');
//     }
//   }
//
//   // 授权成功处理
//   private async onAuthSuccess(authResponse: AuthResponse): Promise<void> {
//     try {
//
//       const authCode    = authResponse.authCode;
//       const expiresIn   = authResponse.expiresIn;
//
//       if (!authCode) {
//         this.handleLoginError('Missing required auth data');
//         return;
//       }
//
//       const accessToken = await this.getAccessToken(authCode)
//       const openId      = await this.getOpenId(accessToken)
//       const userInfo    = await this.getUserInfo(accessToken, openId)
//       this.resolveUserInfo(openId, accessToken, userInfo.nickname || '', userInfo.figureurl || '', expiresIn)
//
//     } catch (error) {
//       this.handleLoginError(error);
//     }
//   }
//
//
//   /**
//    * 通过 authorization_code 获取 access_token（并解析 query-string 响应）
//    * 参考文档：
//    * https://wiki.connect.qq.com/%e4%bd%bf%e7%94%a8authorization_code%e8%8e%b7%e5%8f%96access_token
//    *
//    * 注意：生产环境建议走服务端换取 access_token，以保护 client_secret
//    */
//   private getAccessToken(authCode: string): Promise<string> {
//     return new Promise<string>((resolve, reject) => {
//       try {
//         // 请根据实际从 AppSettings 获取或替换值（不要在客户端暴露 client_secret）
//         const clientId: string = String(AppSettings.CfgQQ.AppId);
//         const clientSecret: string = String(AppSettings.CfgQQ.AppKey); // 注意安全
//         const redirectUri: string = encodeURIComponent(String(AppSettings.CfgQQ.Url || ''));
//
//         const url = `https://graph.qq.com/oauth2.0/token?grant_type=authorization_code&client_id=${clientId}` +
//           `&client_secret=${clientSecret}&code=${encodeURIComponent(authCode)}&redirect_uri=${redirectUri}`;
//
//         // 使用 HarmonyOS Fetch.fetch
//         Fetch.fetch({
//           url,
//           method: "GET",
//           responseType: "text",
//           success: (resp: FetchResponse) => {
//             try {
//
//               const responseText: string = resp.data?.toString() ?? "";
//               console.log('QQ Token Response:', responseText);
//
//               // 使用修正后的解析方法
//               const tokenData = this.parseUrlEncodedResponse(responseText);
//
//               if (tokenData.access_token) {
//                 resolve(tokenData.access_token);
//               } else if (tokenData.error) {
//                 // 处理QQ API错误
//                 const errorMsg = tokenData.error_description || tokenData.error;
//                 reject(new Error(`QQ API Error: ${errorMsg}`));
//               } else {
//                 reject(new Error("Access token not found in response"));
//               }
//
//             } catch (err) {
//               reject(err as Error);
//             }
//           },
//           fail: (err: Error, code: number) => {
//             reject(new Error(`Fetch token failed: code=${code} err=${JSON.stringify(err)}`));
//           }
//         });
//       } catch (err) {
//         reject(err as Error);
//       }
//     });
//   }
//
//   /**
//    * 解析URL编码的响应数据 - 修正解构赋值问题
//    * 替代方案：使用数组索引访问
//    */
//   private parseUrlEncodedResponse(responseText: string): Record<string, string> {
//     const result: Record<string, string> = {};
//
//     // 检查是否是JSON格式
//     const trimmedText = responseText.trim();
//     if (trimmedText.startsWith('{') && trimmedText.endsWith('}')) {
//       try {
//         return JSON.parse(responseText);
//       } catch (error) {
//         // JSON解析失败，继续尝试URL编码解析
//         console.error('JSON parse failed, try URL encoded format');
//       }
//     }
//
//     // 解析URL编码格式：access_token=xxx&expires_in=7776000
//     // ArkTS不支持解构赋值，使用传统数组访问方式
//     const params = responseText.split('&');
//
//     for (let i = 0; i < params.length; i++) {
//       const param = params[i];
//       // 使用split分割键值对，然后通过索引访问
//       const keyValueArray = param.split('=');
//
//       // 确保分割后有足够的元素
//       if (keyValueArray.length >= 2) {
//         const key = keyValueArray[0];       // 第一个元素是key
//         const value = keyValueArray[1];      // 第二个元素是value
//
//         if (key && value !== undefined) {
//           // 使用decodeURIComponent解码URL编码的值
//           result[key] = decodeURIComponent(value);
//         }
//       }
//     }
//
//     return result;
//   }
//
//   ///获取OpenId
//   private getOpenId(accessToken: string): Promise<string> {
//     return new Promise<string>((resolve, reject) => {
//       try {
//         const url = `https://graph.qq.com/oauth2.0/me?access_token=${encodeURIComponent(accessToken)}`;
//
//         Fetch.fetch({
//           url,
//           method: "GET",
//           responseType: "text",
//           success: (resp: FetchResponse) => {
//             try {
//               const responseText: string = resp.data?.toString() ?? "";
//               console.log('QQ OpenId Response:', responseText);
//
//               const trimmed = responseText.trim();
//
//               // 官方返回格式：callback( {...} );
//               if (trimmed.startsWith("callback(")) {
//                 const start = trimmed.indexOf("callback(") + "callback(".length;
//                 const end = trimmed.lastIndexOf(")");
//                 if (end > start) {
//                   const inner = trimmed.substring(start, end).trim();
//
//                   let obj = json.parse(inner) as Record<string, string>;
//
//                   if (obj && typeof obj.openid === "string") {
//                     resolve(obj.openid);
//                   } else {
//                     reject(new Error("openid not found in JSONP response"));
//                   }
//                   return;
//                 } else {
//                   reject(new Error("malformed JSONP response"));
//                   return;
//                 }
//               }
//
//               reject(new Error("Unexpected response format"));
//             } catch (err) {
//               reject(err as Error);
//             }
//           },
//           fail: (err: Error, code: number) => {
//             reject(new Error(`Fetch openid failed: code=${code} err=${JSON.stringify(err)}`));
//           }
//         });
//       } catch (err) {
//         reject(err as Error);
//       }
//     });
//   }
//
//   /**
//    * 通过 access_token 与 openId 获取用户信息
//    * 参考文档：
//    * https://wiki.connect.qq.com/openapi%e8%b0%83%e7%94%a8%e8%af%b4%e6%98%8e_oauth2-0
//    *
//    * GET https://graph.qq.com/user/get_user_info?access_token=ACCESS_TOKEN&oauth_consumer_key=APPID&openid=OPENID
//    */
//   private getUserInfo(accessToken: string, openId: string): Promise<QQUserInfo> {
//     return new Promise<QQUserInfo>((resolve, reject) => {
//       try {
//         const clientId: string = String(AppSettings.CfgQQ.AppId);
//
//         const url = `https://graph.qq.com/user/get_user_info?access_token=${encodeURIComponent(accessToken)}` +
//           `&oauth_consumer_key=${encodeURIComponent(clientId)}&openid=${encodeURIComponent(openId)}&format=json`;
//
//         Fetch.fetch({
//           url,
//           method: "GET",
//           responseType: "json",
//           success: (resp: FetchResponse) => {
//             try {
//
//
//               // 返回的是jsson
//               const data      = resp.data as Record<string, string>;
//
//
//               const ret: number  = Number(data["ret"]) ?? 0;
//               const msg  = data["msg"] ?? "";
//
//               if (ret !== 0) {
//                 reject(new Error(`QQ API Error [${ret}]: ${msg}`));
//                 return;
//               }
//
//               const nickname  = data["nickname"] ?? "";
//               const figureurl = data["figureurl_qq_2"] ?? "";
//
//               if (nickname) {
//                 resolve({nickname: nickname, figureurl: figureurl});
//                 return;
//               } else {
//                 reject(new Error("access_token not found in JSON response"));
//                 return;
//               }
//
//             } catch (err) {
//               reject(err as Error);
//             }
//
//           },
//           fail: (err: Error, code: number) => {
//             reject(new Error(`Fetch user info failed: code=${code} err=${JSON.stringify(err)}`));
//           }
//         });
//       } catch (err) {
//         reject(err as Error);
//       }
//     });
//   }
//
//
//   // 获取用户信息
//   private async resolveUserInfo(openId: string, accessToken: string, userName: string, avatarAddr: string, expiresIn: number): Promise<void> {
//     try {
//
//       // 创建用户信息对象并填充数据
//       const snsUser         = new SnsOneUser();
//       snsUser.userId        = openId;
//       snsUser.userName      = userName ?? '';          // 使用空字符串作为默认值
//       snsUser.accessToken   = accessToken ?? '';
//       snsUser.expireIn      = this.getDateStrByAddSeconds(expiresIn ?? null)
//       snsUser.avatarAddress = avatarAddr ?? '';
//
//
//       this.handleLoginSuccess(snsUser);
//
//     } catch (error) {
//       this.handleLoginError(error);
//     }
//   }
//
//
//
//   // 处理登录成功
//   private handleLoginSuccess(user: SnsOneUser): void {
//     if (this.SnsOneLoginCallback) {
//       this.SnsOneLoginCallback(true, false, undefined, user);
//     }
//   }
//
//   // 处理登录错误
//   private handleLoginError(error: string): void {
//     DebugLog.e('Login failed: ' + JSON.stringify(error));
//     if (this.SnsOneLoginCallback) {
//       this.SnsOneLoginCallback(false, false, error, undefined);
//     }
//   }
//
//   // 处理回调数据（需要在Ability的onNewWant中调用）
//   public handleResult(want: Want): void {
//     try {
//       this.iQQOpenApi?.handleResult(want);
//     } catch (error) {
//       DebugLog.e('Handle result failed: ' + JSON.stringify(error));
//     }
//   }
//
//   // 将过期时长（秒）转换为过期时间字符串
//   private getDateStrByAddSeconds(seconds: number): string {
//     try {
//
//       const now        = new Date();
//       const expireDate = new Date(now.getTime() + seconds * 1000);
//
//       // 格式化为ISO字符串，与Java版本保持一致
//       return expireDate.toISOString();
//     } catch (error) {
//       DebugLog.e('Format date failed: ' + JSON.stringify(error));
//       return '';
//     }
//   }
// }
//
//
// interface QQUserInfo {
//   nickname?: string;
//   figureurl?: string
// }