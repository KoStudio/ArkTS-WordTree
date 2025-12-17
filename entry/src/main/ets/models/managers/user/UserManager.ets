// 引入 Stage 模型核心模块
import UIAbility from '@ohos.app.ability.UIAbility';
import preferences from '@ohos.data.preferences';
import http from '@ohos.net.http';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { getAppContext } from '../../../app/constants/AppContext';
import { Context } from '@kit.AbilityKit';
import { User, UserCodingKeys, UserJson, SnsOneUser, LoginType, LoginTypeHelper } from './User';
import { Http } from '../../networks/Http';
import { Route, Servers } from '../../networks/Server_Routes';
import { StringEncoder } from '../../../common/utils/strings/StringEncrypt';
import { HttpUtils } from '../../networks/HttpUtils';
import call from '@ohos.telephony.call';
import { HwLoginManager } from '../sns/hw/HWLoginManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppSettings } from '../../../app/constants/AppSettings';
import { DeviceUtil } from '../../../common/utils/DeviceUtils';
import { dAppFilefolder } from '../../../app/constants/AppDefines';
import { createFolderIfNeeds } from '../../../app/constants/AppFunctions';
import { SimpleDownloader } from '../../../common/components/SimpleDownloader/SimpleDownloader';
import { FileUtility } from '../../../common/utils/FileUtility';
import { SnsOneLoginCallback, WXLoginManager } from '../sns/wx/WxLoginManager';
import { DebugLog } from '../../../app/debug/DebugLog';
import { getString } from '../../../common/utils/ResourceUtils';

class Prefs {
  static readonly Name              = "UserInfos";         // 存储用户信息的Key
  static readonly kUserId           = "UseInfo_UserId";    // 用户ID
  static readonly kUserName         = "UseInfo_UserName";  // 用户名
  static readonly kLoginIdentifier  = "UseInfo_LoginIdentifier"; // 登录标识
  static readonly kLoginType        = "UseInfo_LoginType"; // 登录类型
  static readonly kAvatarPath       = "UseInfo_AvatarPath"; // 用户头像路径
}


@ObservedV2
export class UserManager {
  // === 2.1 单例模式（Stage 模型安全）===
  private static _instance: UserManager;
  static get shared(): UserManager {
    if (!UserManager._instance) {
      UserManager._instance = new UserManager();
    }
    return UserManager._instance;
  }


  // === 2.2 可观察属性（Swift @Published → ArkTS @Trace）===
  @Trace userId: number | null = null;
  @Trace userName: string | null = null;
  @Trace loginIdentifier: string | null = null;
  @Trace loginType: LoginType | null = null;
  @Trace avatarPath: string | null = null; // 存储头像文件路径

  // === 2.3 私有属性 ===
  private context: Context;
  private prefs: preferences.Preferences | null = null;
  // private emitter: Emitter = new Emitter();

  // === 2.4 事件通知（Swift Notification → ArkTS Emitter）===
  static readonly AVATAR_DOWNLOADED = "avatarDownloaded";
  static readonly USER_LOGOFF_FINISHED = "userLogoffFinished";

  private constructor() {
    this.context = getAppContext()
    this.initPreferences();
  }

  // === 3. 数据持久化（Swift UserDefaults → ArkTS Preferences）===
  private initPreferences() {
    this.prefs = preferences.getPreferencesSync(this.context, {name: Prefs.Name});
    this.loadPreference();
  }
  // 4. 加载偏好设置（严格匹配原始键名）
  private loadPreference() {
    if (!this.prefs) return;

    this.userId           = this.prefs.getSync(Prefs.kUserId, null) as number;
    this.userName         = this.prefs.getSync(Prefs.kUserName, "") as string;
    this.loginIdentifier  = this.prefs.getSync(Prefs.kLoginIdentifier, "") as string;
    this.loginType        = LoginTypeHelper.fromRaw(this.prefs.getSync(Prefs.kLoginType, "") as string) ?? null;
    this.avatarPath       = this.prefs.getSync(Prefs.kAvatarPath, "") as string;
  }

  // 5. 保存偏好设置（键名完全不变）
  private savePreference() {
    if (!this.prefs) return;

    this.prefs.putSync(Prefs.kUserId, this.userId ?? "");
    this.prefs.putSync(Prefs.kUserName, this.userName ?? "");
    this.prefs.putSync(Prefs.kLoginIdentifier, this.loginIdentifier ?? "");
    this.prefs.putSync(Prefs.kLoginType, this.loginType?.valueOf() ?? "");
    this.prefs.putSync(Prefs.kAvatarPath, this.avatarPath ?? "");

    this.prefs.flushSync();
  }

  // === 4. 核心功能实现 ===
  // 4.1 用户注册
  // async signUp(email: string, userName: string, password: string): Promise<HttpUtils.HttpResponse<Object>> {
  signUp(email: string, userName: string, password: string, completion: (succeed: boolean, msg: string | null) => void){
    const url                          = `${Servers.getRouteUrl(Route.login)}/signup`
    const params: HttpUtils.HttpParams = {};
    params[UserCodingKeys.email]       = email
    params[UserCodingKeys.userName]    = userName
    params[UserCodingKeys.password]    = StringEncoder.encodedToBase64(password) ?? ''
    params[UserCodingKeys.deviceType]  = DeviceUtil.getDeviceType()
    params[UserCodingKeys.appName]     = AppSettings.App.appName

    Http.send(url, HttpUtils.Method.GET, params, completion)
  }

  /// email用户登录
  login(email: string, password: string, completion: (succeed: boolean, msg: string | null) => void) {

    const params: HttpUtils.HttpParams  = {};
    params[UserCodingKeys.email]      = email
    params[UserCodingKeys.loginType]  = LoginType.email.valueOf()
    params[UserCodingKeys.password]   = StringEncoder.encodedToBase64(password) ?? ''
    params[UserCodingKeys.deviceType] = DeviceUtil.getDeviceType()
    params[UserCodingKeys.appName]    = AppSettings.App.appName

    ///执行登录
    this.doLogin(params, completion);
  }

  ///sns登录
  loginByIdentifier(identifier: string, userName: string, loginType: LoginType, completion: (succeed: boolean, msg: string | null) => void) {
    const params: HttpUtils.HttpParams        = {};
    params[UserCodingKeys.loginIdentifier]    = identifier
    params[UserCodingKeys.loginType]          = loginType.valueOf()
    params[UserCodingKeys.userName]           = userName
    params[UserCodingKeys.deviceType]         = DeviceUtil.getDeviceType()
    params[UserCodingKeys.appName]            = AppSettings.App.appName

    ///执行登录
    this.doLogin(params, completion);
  }
  /// 忘记密码：发送验证码
  /// - Parameters:
  ///   - email: 用户邮箱
  ///   - completion: 回调，返回是否成功及错误信息
  sendSafeCode(email: string, completion: (succeed: boolean, msg: string | null) => void) {
    const url                          = `${Servers.getRouteUrl(Route.login)}/safe_code`
    const params: HttpUtils.HttpParams = {};
    params[UserCodingKeys.email]       = email
    params[UserCodingKeys.appName]     = AppSettings.App.appName
    params['app_name_display']         = AppSettings.App.appDisplayName

    Http.send(url, HttpUtils.Method.GET, params, completion)

  }
  /// 重置密码
  /// - Parameters:
  ///   - email: 用户邮箱
  ///   - safeCode: 验证码
  ///   - password: 新密码
  ///   - completion: 回调，返回是否成功及错误信息
   resetPassword(email: string, safeCode: string, password: string, completion:  (succeed: boolean, msg: string | null) => void) {
     const url                          = `${Servers.getRouteUrl(Route.login)}/reset`
     const params: HttpUtils.HttpParams = {};
     params[UserCodingKeys.email]       = email
     params[UserCodingKeys.safeCode]    = safeCode
     params[UserCodingKeys.password]    = StringEncoder.encodedToBase64(password) ?? ''
     params[UserCodingKeys.appName]     = AppSettings.App.appName

     Http.send(url, HttpUtils.Method.GET, params, completion)
   }

  /// 注销用户账号
  /// - Parameter completion: 回调，返回是否成功及错误信息
   loginOff(completion:  (succeed: boolean, msg: string | null) => void) {
     if (!(this.userId !== null && this.loginIdentifier !== null && this.loginType !== null)) {
       return
     }
     const url                                  = `${Servers.getRouteUrl(Route.login)}/remove`
     const params: HttpUtils.HttpParams         = {};
     params[UserCodingKeys.userId]              = this.userId
     params[UserCodingKeys.loginIdentifier]     = this.loginIdentifier
     params[UserCodingKeys.loginType]           = this.loginType
     params[UserCodingKeys.appName]             = AppSettings.App.appName

     Http.send(url, HttpUtils.Method.GET, params, completion)
   }

  //  退出登录
  logout() {
    this.userId = null;
    this.userName = null;
    this.loginIdentifier = null;

    ///删除头像
    FileUtility.deleteFileAt(this.avatarPath)
    this.avatarPath = null;

    this.savePreference();
  }

  ///判断是否已经登录
  isLogin(): boolean {
    return (this.userId ?? 0) > 0
  }



  /// 通用登录方法
  /// - Parameters:
  ///   - params: 登录参数
  ///   - completion: 回调，返回是否成功及错误信息
  private doLogin(params: HttpUtils.HttpParams, completion: (succeed: boolean, msg: string | null) => void) {

    const url = Servers.getRouteUrl(Route.login)

    Http.request(url, HttpUtils.Method.GET, params, (succeed: boolean, msg: string | null, oneUserJsons: UserJson[] | null) => {

      if (oneUserJsons !== null && oneUserJsons.length > 0) {

        const user           = User.from(oneUserJsons[0])

        this.userId          = user.userId;
        this.userName        = user.userName;
        this.loginIdentifier = user.loginIdentifier;
        this.loginType       = user.loginType;

        ///异步保存
        this.savePreference();
      }

      ///回调
      completion(succeed, msg)
    })
  }

  loginBySns(type: LoginType, onReceivedQrImage: ((base64ImageString: string) => void) | undefined = undefined, completion: (succeed: boolean, msg: string | null) => void){

    if (type === LoginType.huawei) {

      HwLoginManager.shared.login().then((user: SnsOneUser) => {

        ///登录成功，向服务器写入信息
        this.createServerUserForSnsLogin(type, true, null, user, completion)

        // 登录成功，处理用户信息
        DebugLog.i(`登录成功，用户ID: ${user.userId}`);


      }).catch((error: BusinessError) => {
        // 登录失败，处理错误
        completion(false, `登录失败: ${error.code}, ${error.message}`)
      });
    }else if (type === LoginType.wechat){
      WXLoginManager.shared.login((success: boolean, isCancelled: boolean, error?: string, user?: SnsOneUser) => {

        if (user) {
          ///登录成功，向服务器写入信息
          this.createServerUserForSnsLogin(type, true, null, user, completion)

          // 登录成功，处理用户信息
          DebugLog.i(`登录成功，用户ID: ${user.userId}`);
        }else{
          // 登录失败，处理错误
          completion(false, `${error}`)
        }

      })
    }else if (type === LoginType.wechat_qr){
      WXLoginManager.shared.loginQr(onReceivedQrImage,(success: boolean, isCancelled: boolean, error?: string, user?: SnsOneUser) => {

        if (user) {
          ///登录成功，向服务器写入信息
          this.createServerUserForSnsLogin(type, true, null, user, completion)

          // 登录成功，处理用户信息
          DebugLog.i(`登录成功，用户ID: ${user.userId}`);
        }else{
          // 登录失败，处理错误
          completion(false, `${error}`)
        }

      })
    }
  }
  // 处理Server登录的异步函数
  private  createServerUserForSnsLogin(type: LoginType, succeeded: boolean, ex: Error | null, snsUser: SnsOneUser | null, completion: (success: boolean, msg: string | null) => void) {
    try {
      // 成功情况处理
      if (succeeded && snsUser !== null && snsUser?.userId !== null) {


        this.loginByIdentifier(snsUser.userId!, snsUser.userName || '华为用户', type, (success: boolean, msg: string | null)=> {
          // 回调
          completion(success, success ? null : '登录失败');

          if (success && snsUser.avatarAddress) {

            // 下载头像 - 异步操作但不阻塞主流程
            this.loadAvatarWithUrl(snsUser.avatarAddress)
              .then(() => {
                hilog.info(0x0000, 'Avatar', '头像下载成功');
              })
              .catch((error: Error) => {
                hilog.error(0x0000, 'Avatar', `头像下载失败: ${error.message}`);
              });
          }
        })


        return;
      }

      // 异常情况处理
      if (ex !== null) {
        completion(false, ex.message);
        return;
      }

      // 默认失败情况
      completion(false, 'login canceled');
    } catch (error) {
      // 统一错误处理
      const err = error as Error;
      completion(false, err.message);
    }
  }


  // 下载头像的异步函数
  private async loadAvatarWithUrl(avatarUrl: string): Promise<void> {
    try {

      createFolderIfNeeds(this.getAvatarFolder())

      const filePath = this.getAvatarPath()

      // 实现头像下载逻辑
      const downloader = new SimpleDownloader()
      const result = await downloader.downloadToPath(avatarUrl, filePath)

      this.avatarPath = result.filePath
      this.savePreference()

      // 这里可以处理下载的头像数据，比如保存到本地存储
      hilog.info(0x0000, 'Avatar', `头像下载成功: ${avatarUrl}`);
    } catch (error) {
      throw new Error(`头像下载失败: ${error.message}`);
    }
  }

  private getAvatarFolder(): string{
    return dAppFilefolder + "avatars/"
  }

  private getAvatarPath(): string {
    return this.getAvatarFolder() + "avatar.jpg"
  }
}
