import { common, Want } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import  * as wxopensdk from '@tencent/wechat_open_sdk';
import { SnsOneUser } from '../../user/User';
import { AppSettings } from '../../../../app/constants/AppSettings';
import { getAppContext } from '../../../../app/constants/AppContext';
import { Toast } from '../../../../common/utils/Toast';
import { StringCrypto } from '../../../../common/utils/strings/StringCrypto';
import { DebugLog } from '../../../../app/debug/DebugLog';

///////////////////////////////////////////////////////////////////////////////////////////
/// 微信登录管理器 - 封装微信登录功能
///
/// 参考文档:
/// https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/ohos.html
/// https://developers.weixin.qq.com/doc/oplatform/Mobile_App/WeChat_Login/Development_Guide.html
//////////////////////////////////////////////////////////////////////////////////////////////

// 定义回调类型
export type SnsOneLoginCallback = (success: boolean, isCancelled: boolean, error?: string, user?: SnsOneUser) => void;


// 配置信息 (需要根据实际配置修改)
const APP_ID         = AppSettings.CfgWeixin.AppId       // 从微信开放平台获取
const APP_SECRET     = AppSettings.CfgWeixin.AppSecret   // 从微信开放平台获取
const UNIVERSAL_LINK = AppSettings.CfgWeixin.Url         // 配置的Universal Link

// 处理类型枚举
enum HandleType {
  GET_TOKEN,           // 通过code获取access_token
  CHECK_TOKEN,         // 检查token有效性
  REFRESH_TOKEN,       // 刷新token
  GET_INFO,            // 获取用户信息
  GET_TOKEN_FOR_TICKET,// 获取token用于ticket
  GET_TICKET           // 获取ticket
}


export class WXLoginManager {
  // 单例实例
  private static instance: WXLoginManager = new WXLoginManager();

  // 使用get shared属性方式 (类似Swift的static let shared)
  public static get shared(): WXLoginManager {
    return WXLoginManager.instance;
  }

  // 缓存数据
  private openId: string = '';
  private accessToken: string = '';
  private refreshToken: string = '';
  private scope: string = '';
  private expiresIn: number = 0;

  // 回调函数
  private snsLoginCallback?: SnsOneLoginCallback

  ///扫码登录 回调
  private onReceivedQrImage?: (base64JpegImageBuffer: string) => void;

  private wxApi?: wxopensdk.WXApi

  // 私有构造函数
  private constructor() {
    // 构造函数逻辑
  }

  // MARK: - 公共方法

  /**
   * [1/2]
   * 注册微信应用
   * 需要在应用启动时（或登录页面）调用，注册应用ID和Universal Link
   * 参考: https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/ohos.html
   */
  public registerApp(): void {
    if (this.wxApi) {
      return; // 避免重复初始化
    }

    ///注册微信api
    this.wxApi =  wxopensdk.WXAPIFactory.createWXAPI(APP_ID);
  }

  /**
   * 检查微信是否安装
   * @returns boolean 微信是否安装
   */
  public isWxAppInstalled(): boolean {
    return this.wxApi?.isWXAppInstalled() || false
  }

  /**
   * 微信APP登录
   * @param snsLoginCallback 登录回调函数
   * 参考: https://developers.weixin.qq.com/doc/oplatform/Mobile_App/WeChat_Login/Development_Guide.html
   */
  public async login(snsLoginCallback: SnsOneLoginCallback): Promise<void> {
    this.snsLoginCallback = snsLoginCallback;

    // 先检查微信是否安装
    if (!this.isWxAppInstalled()) {
      this.onFailed('微信未安装，请先安装微信');
      return;
    }

    // 构造认证请求
    let req   = new wxopensdk.SendAuthReq()
    req.scope = 'snsapi_userinfo'  // 只能填 snsapi_userinfo[1](@ref)
    req.state = 'harmony_login'    // 用于防止CSRF攻击的随机字符串


    // 发送认证请求
    await this.wxApi?.sendReq(getAppContext() as common.UIAbilityContext, req);

  }


  /**
   * 微信扫码登录 (ArkTS版本)
   * 启动二维码登录流程，首先请求access_token用于后续获取ticket
   * @param onReceivedQrImage 接收到二维码图像时的回调函数（可选）
   * @param snsLoginCallback 登录结果回调函数
   */
  public loginQr(onReceivedQrImage?: (base64JpegImageBuffer: string) => void, snsLoginCallback?: SnsOneLoginCallback): void {
    // 保存回调函数引用
    this.onReceivedQrImage = onReceivedQrImage;
    this.snsLoginCallback = snsLoginCallback

    // 构建请求access_token的URL
    const url = `https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=${APP_ID}&secret=${APP_SECRET}`;

    // 启动二维码获取流程，首先请求access_token用于获取ticket
    this.asyncRequestUrlWithType(url, HandleType.GET_TOKEN_FOR_TICKET)
  }
  ///扫码登录 收到Ticket后，用于签名，并请求登录二维码


  ///主动停止 扫码登录
   stopQrLogin(){
     wxopensdk.DiffDevOAuthFactory.getDiffDevOAuth()?.stopOAuth()
    this.onFailed("取消登录")
  }

  /**
   * 创建微信事件处理器
   */
  private createWXEventHandler(): wxopensdk.WXApiEventHandler {
    return {
      onReq: (req: wxopensdk.BaseReq): void => {
        console.log('收到微信请求:', JSON.stringify(req));

        // 处理微信发来的请求，如分享、支付等
        if (req instanceof wxopensdk.LaunchFromWXReq) {
          // //获取开放标签传递的extinfo数据逻辑
          let messageExt = req.message?.messageExt
          //Handle...
        }
      },

      onResp: (resp: wxopensdk.BaseResp): void => {
        console.log('收到微信响应:', JSON.stringify(resp));

        //Toast.showDebugMessage("收到微信响应:', JSON.stringify(resp)")
        //如果第三方程序向微信发送了 sendReq 的请求，那么 onResp 会被回调。sendReq 请求调用后，会切到微信终端程序界面。


        ///获得用户登录授权后，启动用户信息获取流程

        let code = (resp as wxopensdk.SendAuthResp).code
        if (code){
          this.getAccessTokenWithCode(code)
        }else{
          // 处理授权失败
          this.handleAuthError(resp.errCode);
        }
      }
    };
  }

  ///扫码登录回调
  private createOnAuthCallBackForQrAuth(): wxopensdk.OAuthCallback {
    return {
      ///得到二维码
      onGotQRCode: (base64JpegImageBuffer: string) =>  {
        ///显示二维码页面
        this.onReceivedQrImage?.(base64JpegImageBuffer)

      },
      ///用户扫描二维码之后，回调该接口
      onQRCodeScanned: () => {
        DebugLog.d("onQrcodeScanned")
      },

      ///用户点击授权后，回调该接口
      onAuthFinish: (authCode: string) => {
        ///用户点击 “同意”
        ///
        //异步 获取Access_token，然后获取用户信息
        // （和App登录时，跳转回来后一样的流程，进入到handler中，成功后会调用onCompletion,有Error时会调用onFail）
        this.getAccessTokenWithCode(authCode)
      },

      onAuthError: (errCode: wxopensdk.OAuthErrCode, errMsg: string) => {
        let failMsg = `failed on onAuthFinish >>> errcode: ${errCode}`
        if (errCode === wxopensdk.OAuthErrCode.WechatAuth_Err_Cancel) {
          failMsg = "用户取消登录"
        }else if (errCode === wxopensdk.OAuthErrCode.WechatAuth_Err_Timeout){
          failMsg = "登录超时"
        }else {
          failMsg = errMsg
        }

        DebugLog.e(`in onAuthError: ${errCode}.${failMsg}`)

        ///回调
        this.onFailed(`${errCode}.${failMsg}`)
      }

    }
  }

  /**
   * 处理授权错误
   * @param errCode 错误代码
   */
  private handleAuthError(errCode: number): void {
    let errorMessage = '授权失败';

    switch (errCode) {
      case -2: // 用户取消
        errorMessage = '用户取消登录';
        break;
      case -4: // 用户拒绝授权
        errorMessage = '用户拒绝授权';
        break;
      default:
        errorMessage = `授权失败，错误码: ${errCode}`;
    }

    this.onFailed(errorMessage);
  }

  /**
   * 通过code获取access_token
   * @param code 微信授权返回的code
   * 参考: https://api.weixin.qq.com/sns/oauth2/access_token
   */
  private getAccessTokenWithCode(code: string): void {
    const url = `https://api.weixin.qq.com/sns/oauth2/access_token?appid=${APP_ID}&secret=${APP_SECRET}&code=${code}&grant_type=authorization_code`;
    this.asyncRequestUrlWithType(url, HandleType.GET_TOKEN)

  }

  /**
   * 处理与微信通信回传的JSON数据
   * @param type 处理类型，标识不同的请求场景
   * @param data 响应数据（使用Record类型避免any）
   */
  private handleRequest(type: HandleType, data: Record<string, string | number> | undefined): void {
    // 如果数据为空，直接返回失败
    if (!data) {
      this.onFailed('响应数据为空');
      return;
    }

    switch (type) {
      case HandleType.GET_TOKEN: // 通过 code 获取 access_token
        //////////////////////////////////////////////////
        // https://developers.weixin.qq.com/doc/oplatform/Mobile_App/WeChat_Login/Authorized_API_call_UnionID.html
        // https://developers.weixin.qq.com/doc/oplatform/Mobile_App/WeChat_Login/Development_Guide.html
        //
        // 正确的返回：
        // {
        //     "access_token": "ACCESS_TOKEN",
        //     "expires_in": 7200,
        //     "refresh_token": "REFRESH_TOKEN",
        //     "openid": "OPENID",
        //     "scope": "SCOPE"
        // }
        //////////////////////////////////////////////////

        if (data.errcode !== undefined) {
          //////////////////////////////////////////////////
          //错误返回样例：
          //{
          //    "errcode": 40029,
          //     "errmsg": "invalid code"
          //}
          //////////////////////////////////////////////////
          const errCode: string =  data.errcode as string;
          const errMsg: string  = data.errmsg as string;
          this.onFailed(`failed on GET_TOKEN: errcode: ${errCode ?? ''}, ${errMsg ?? ''}`);
        } else {
          this.openId = data.openid as string;
          this.accessToken = data.access_token as string;
          this.refreshToken = data.refresh_token as string;
          this.scope = data.scope as string;
          this.expiresIn = data.expires_in as number; // 7200 秒，2小时

          if (this.openId && this.accessToken) {
            // Check Token
            const checkUrl = `https://api.weixin.qq.com/sns/auth?access_token=${this.accessToken}&openid=${this.openId}`;
            this.asyncRequestUrlWithType(checkUrl, HandleType.CHECK_TOKEN);
          } else {
            this.onFailed('failed on GET_TOKEN: 请先获取accessToken');
          }
        }
        break;

      case HandleType.CHECK_TOKEN:  // 检验授权凭证（access_token）是否有效
        if (data.errcode === 0) {
          //////////////////////////////////////////////////
          // 正确的 Json 返回结果：
          // {
          //     "errcode": 0,
          //     "errmsg": "ok"
          // }
          //////////////////////////////////////////////////
          if (this.accessToken && this.openId) {
            const userInfoUrl = `https://api.weixin.qq.com/sns/userinfo?access_token=${this.accessToken}&openid=${this.openId}`;
            this.asyncRequestUrlWithType(userInfoUrl, HandleType.GET_INFO);
          }
        } else {
          //////////////////////////////////////////////////
          // 错误的 Json 返回示例:
          // {
          //     "errcode": 40003,
          //     "errmsg": "invalid openid"
          // }
          //////////////////////////////////////////////////
          if (this.refreshToken) {
            const refreshUrl = `https://api.weixin.qq.com/sns/oauth2/refresh_token?appid=${APP_ID}&grant_type=refresh_token&refresh_token=${this.refreshToken}`;
            this.asyncRequestUrlWithType(refreshUrl, HandleType.REFRESH_TOKEN);
          }
        }
        break;

      case HandleType.REFRESH_TOKEN: // 刷新或续期 access_token 使用
        if (data.errcode !== undefined) {
          //////////////////////////////////////////////////
          // 错误返回样例：
          // {
          //     "errcode": 40030,
          //     "errmsg": "invalid refresh_token"
          // }
          //////////////////////////////////////////////////
          const errCode = data.errcode as string;
          const errMsg = data.errmsg as string;
          this.onFailed(`failed on REFRESH_TOKEN: errcode: ${errCode ?? ''}, ${errMsg ?? ''}`);
        } else {
          //////////////////////////////////////////////
          // 正确的返回：
          // {
          //     "access_token": "ACCESS_TOKEN",
          //     "expires_in": 7200,
          //     "refresh_token": "REFRESH_TOKEN",
          //     "openid": "OPENID",
          //     "scope": "SCOPE"
          // }
          //////////////////////////////////////////////////
          this.openId       = data.openid as string;
          this.accessToken  = data.access_token as string;
          this.refreshToken = data.refresh_token as string;
          this.scope        = data.scope as string;

          if (this.openId && this.accessToken) {
            // Check Token
            const userInfoUrl = `https://api.weixin.qq.com/sns/userinfo?access_token=${this.accessToken}&openid=${this.openId}`;
            this.asyncRequestUrlWithType(userInfoUrl, HandleType.CHECK_TOKEN);
          }
        }
        break;

      case HandleType.GET_INFO: // 获取用户个人信息（UnionID 机制）
        if (data.errcode !== undefined) {
          //////////////////////////////////////////////////
          // 错误返回样例：
          // {
          //     "errcode": 40003,
          //     "errmsg": "invalid openid"
          // }
          //////////////////////////////////////////////////
          const errCode = data.errcode as string;
          const errMsg = data.errmsg as string;
          this.onFailed(`failed on GET_INFO: errcode: ${errCode ?? ''}, ${errMsg ?? ''}`);
        } else {
          //////////////////////////////////////////////////
          // 正确的 Json 返回结果：
          // {
          //     "openid": "OPENID",
          //     "nickname": "NICKNAME",
          //     "sex": 1,
          //     "province": "PROVINCE",
          //     "city": "CITY",
          //     "country": "COUNTRY",
          //     "headimgurl": "https://thirdwx.qlogo.cn/mmopen/g3MonUZtNHkdmzicIlibx6iaFqAc56vxLSUfpb6n5WKSYVY0ChQKkiaJSgQ1dZuTOgvLLrhJbERQQ4eMsv84eavHiaiceqxibJxCfHe/0",
          //     "privilege": ["PRIVILEGE1", "PRIVILEGE2"],
          //     "unionid": " o6_bmasdasdsad6_2sgVt7hMZOPfL"
          // }
          //////////////////////////////////////////////////

          const nickname = data.nickname as string;
          const headimgurl = data.headimgurl as string;

          this.onCompletion(
            this.openId ?? '',
            nickname,
            this.accessToken,
            this.getDateStrByAddSeconds(this.expiresIn),
            headimgurl
          );
        }
        break;

      case HandleType.GET_TOKEN_FOR_TICKET: // 通过 code 获取 access_token
        //////////////////////////////////////////////////
        // https://developers.weixin.qq.com/doc/oplatform/Mobile_App/WeChat_Login/Authorized_API_call_UnionID.html
        // https://developers.weixin.qq.com/doc/oplatform/Mobile_App/WeChat_Login/Development_Guide.html
        //
        // 正确的返回：
        // {
        //     "access_token": "ACCESS_TOKEN",
        //     "expires_in": 7200,
        //     "refresh_token": "REFRESH_TOKEN",
        //     "openid": "OPENID",
        //     "scope": "SCOPE"
        // }
        //////////////////////////////////////////////////

        if (data.errcode !== undefined) {
          //////////////////////////////////////////////////
          // 错误返回样例：
          // {
          //     "errcode": 40029,
          //     "errmsg": "invalid code"
          // }
          //////////////////////////////////////////////////
          const errCode = data.errcode as string;
          const errMsg = data.errmsg as string;
          this.onFailed(`failed on GET_TOKEN: errcode: ${errCode ?? ''}, ${errMsg ?? ''}`);
        } else {
          //////////////////////////////////////////////////
          // https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Get_access_token.html
          // 正确的返回：
          // {
          //     "access_token": "ACCESS_TOKEN",
          //     "expires_in": 7200,
          // }
          //////////////////////////////////////////////////
          const accessToken = data.access_token as string;
          const expiresIn = data.expires_in as number; // 7200 秒，2小时

          if (accessToken) {
            // get ticket
            // https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=ACCESS_TOKEN&type=2
            const ticketUrl = `https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=${accessToken}&type=2`;
            this.asyncRequestUrlWithType(ticketUrl, HandleType.GET_TICKET);
          } else {
            this.onFailed('failed on GET_TOKEN: 请先获取accessToken');
          }
        }
        break;

      case HandleType.GET_TICKET: // 获取 Ticket
        // ///TODO: 用服务器获取TICKET
        // sdk_ticket 是用于生成签名的临时票据。正常情况下，sdk_ticket 的有效期为 7200 秒，通过 access_token 来获取。
        // 由于获取 sdk_ticket 的 api 调用次数非常有限，频繁刷新 sdk_ticket 会导致 api 调用受限，影响自身业务，
        // 开发者需在自己的服务存储与更新 sdk_ticket。
        //
        // 1.参考以下文档，使用 APP 的 Appid 和 AppSecret 获取 access_token 获取 access_token,：
        //    https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421140183
        //
        // 2.用第一步拿到的 access_token 采用 http GET 方式请求获得 sdk_ticket：
        //    https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=ACCESS_TOKEN&type=2

        //////////////////////////////////////////////////
        // 正确的 Json 返回结果：
        // {
        //     "errcode": 0,
        //     "errmsg": "ok",
        //     "ticket": "-p3A5zVP95IuafPhzA6lRR95_F9nZEBfJ_n4E9t8ZFWKJTDPOwccVQhHCwDBmvLkayF_jh-m9HOExhumOziDWA",
        //     "expires_in": 7200
        // }
        //////////////////////////////////////////////////
        const errCode = data.errcode as number;
        const errMsg = data.errmsg as string;
        const ticket = data.ticket as string;  // Ticket
        const expires_in = data.expires_in as number; // 过期时间：秒

        if (errCode !== 0) {
          this.onFailed(`failed on GET_TOKEN: errcode: ${errCode ?? 0}, ${errMsg ?? ''}`);
        } else {
          this.onLoginQRReceivedTicket(ticket ?? '', expires_in);
        }
        break;

      default:
        break;
    }
  }


  // MARK: - 工具方法

  /**
   * 异步网络请求封装函数 (ArkTS版本)
   * 使用async/await处理异步操作，避免回调地狱
   * @param url 请求的URL地址
   * @param handlerType 处理类型，用于标识不同的请求场景
   */
  asyncRequestUrlWithType(url: string, handlerType: HandleType) {
    this.asyncRequestUrl(url, (success: boolean, msg?: string, data?: Record<string, string | number>) => {
      if (success) {
        this.handleRequest(handlerType, data)
      }else{
        Toast.showMessage(msg || "")
        this.handleRequest(handlerType, data)
      }
    })
  }

  /**
   * 异步网络请求 (简化版)
   * 将 Swift 的 URLSession 代码转换为 ArkTS 版本
   * @param url 请求的URL地址
   * @param completionHandler 完成回调函数
   */
  asyncRequestUrl(
    url: string,
    completionHandler?: (success: boolean, errorMsg?: string, data?: Record<string, string | number>) => void
  ): void {
    const httpRequest = http.createHttp();

    httpRequest.request(
      url,
      {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000,
        expectDataType: http.HttpDataType.STRING
      },
      (err: BusinessError, response: http.HttpResponse) => {
        // 确保请求对象被销毁
        httpRequest.destroy();

        // 处理网络错误
        if (err) {
          completionHandler?.(false, err.message);
          return;
        }

        // 处理响应数据
        if (response.result) {
          try {
            const responseData: Record<string, string | number> = JSON.parse(response.result as string);
            completionHandler?.(true, undefined, responseData);  //成功回调
          } catch {
            completionHandler?.(false, 'JSON解析错误');
          }
        } else {
          completionHandler?.(false, '无响应数据');
        }
      }
    );
  }


  /**
   * 生成指定秒数后的日期字符串
   * @param seconds 秒数
   * @returns ISO格式的日期字符串
   */
  private getDateStrByAddSeconds(seconds: number): string {
    const date = new Date();
    date.setSeconds(date.getSeconds() + seconds);
    return date.toISOString();
  }

  /**
   * 微信登录授权成功回调 (ArkTS版本)
   * 当从微信API成功获取用户信息后调用此方法
   * @param openId 用户的微信开放ID
   * @param userName 用户昵称（可选）
   * @param accessToken 访问令牌（可选）
   * @param expireIn 令牌过期时间（可选）
   * @param avatarAddr 用户头像地址（可选）
   */
  private onCompletion(openId: string, userName: string | null, accessToken: string | null, expireIn: string | null, avatarAddr: string | null): void {
    // 创建用户信息对象并填充数据
    const snsUser         = new SnsOneUser();
    snsUser.userId        = openId;
    snsUser.userName      = userName ?? '';          // 使用空字符串作为默认值
    snsUser.accessToken   = accessToken ?? '';
    snsUser.expireIn      = expireIn ?? '';
    snsUser.avatarAddress = avatarAddr ?? '';

    // 执行登录成功回调
    // 使用可选链操作符(?.)安全调用可能为null的回调函数
    this.snsLoginCallback?.(true, false, undefined, snsUser);
  }

  /**
   * 微信登录授权失败回调 (ArkTS版本)
   * 当登录过程出现任何错误时调用此方法
   * @param error 错误对象，包含错误详情
   */
  private onFailedError(error: Error): void {
    // 执行登录失败回调，传递错误信息
    this.snsLoginCallback?.(false, false, error.message, undefined);
  }

  /**
   * 微信登录授权失败回调 (简化版)
   * 提供直接使用错误消息字符串的便捷方法
   * @param message 错误描述信息（可选）
   */
  private onFailed(message?: string): void {
    // 创建Error对象并调用完整的onFailed方法
    this.onFailedError(new Error(message ?? '微信登录失败'));
  }

  /**
   * 扫码登录时，获得ticket后的处理函数 (ArkTS版本)
   * 根据微信开放平台要求生成签名并调用认证接口
   * @param ticket 从微信服务器获取的临时票据
   * @param expireIn 票据过期时间（秒）
   */
  private async onLoginQRReceivedTicket(ticket: string, expireIn?: number): Promise<void> {
    // 签名生成所需参数
    const appid: string      = APP_ID;        // 微信应用ID
    const sdk_ticket: string = ticket;              // 从微信获取的ticket
    const noncestr: string   = this.generateRandomString(); // 生成随机字符串
    const timeStamp: string  = Math.floor(Date.now() / 1000).toString(); // 当前时间戳（秒级）
    const scope: string      = "snsapi_userinfo";         // 授权范围

    //////////////////////////////////////////////////
    // 签名生成步骤：
    // 1. 对所有待签名参数按照字段名（即key）的 ASCII 码从小到大排序（字典序）
    //    appid、noncestr、sdk_ticket、timestamp
    // 2. 使用 URL 键值对的格式拼接成字符串 string1：
    //    appid=wxappid&noncestr=noncestr&sdk_ticket=ticket_value&timestamp=timestamp_value
    // 3. 对 string1 进行 sha1 签名，得到 signature
    //////////////////////////////////////////////////

    // 构建待签名字符串
    const sign: string = `appid=${appid}&noncestr=${noncestr}&sdk_ticket=${sdk_ticket}&timestamp=${timeStamp}`;

    // 计算SHA1签名
    const signature: string = await StringCrypto.sha1(sign)//await this.sha1Hash(sign);


    // 需要在主线程执行UI操作
    // 使用setTimeout模拟DispatchQueue.main.async
    //startOAuth(appId: string, scope: string, noncestr: string, timestamp: string, signature: string, callback: OAuthCallback): void
    wxopensdk.DiffDevOAuthFactory.getDiffDevOAuth()?.startOAuth(
      appid,
      scope,
      noncestr,
      timeStamp,
      signature,
      this.createOnAuthCallBackForQrAuth()//回调
    )
  }

  /**
   * 生成随机字符串
   * @param length 字符串长度
   * @returns 随机字符串
   */
  private generateRandomString(length: number = 16): string {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';

    for (let i = 0; i < length; i++) {
      result += characters.charAt(Math.floor(Math.random() * characters.length));
    }

    return result;
  }

  ///[2/2]
  ///// 在EntryAbility中响应来自微信的回调
  //onCreate 和onNewWant中调用
  handleWeChatCallIfNeed(want: Want) {
    let eventHandler = this.createWXEventHandler()
    this.wxApi?.handleWant(want, eventHandler)
  }
}

