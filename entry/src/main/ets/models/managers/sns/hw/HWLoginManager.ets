import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import storage from '@ohos.data.storage';
import { common } from '@kit.AbilityKit';
import { authentication } from '@kit.AccountKit';
import { SnsOneUser } from '../../user/User';
import { getAppContext } from '../../../../app/constants/AppContext';

export class HwLoginManager {
  private static instance: HwLoginManager;
  private readonly STORAGE_KEY = 'HwAuthData';
  private TAG = "HwLoginManager";

  static get shared(): HwLoginManager {
    if (!HwLoginManager.instance) {
      HwLoginManager.instance = new HwLoginManager();
    }
    return HwLoginManager.instance;
  }

  // 核心登录方法（完全使用 async/await 模式）
  async login(): Promise<SnsOneUser> {
    try {
      // 先尝试静默登录
      return await this.silentLogin();
    } catch (silentError) {
      hilog.warn(0x0000, this.TAG, `静默登录失败，拉起显式界面: ${JSON.stringify(silentError)}`);
      return await this.explicitLogin(); // 尝试显式登录
    }
  }

  // 静默登录实现
  private async silentLogin(): Promise<SnsOneUser> {
    const request: authentication.LoginWithHuaweiIDRequest =
      new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();

    request.forceLogin = false; // 关键参数：false 表示静默登录
    request.state = util.generateRandomUUID(); // 生成防伪标识

    const controller = new authentication.AuthenticationController();
    const response = await controller.executeRequest(request) as authentication.LoginWithHuaweiIDResponse;

    // 安全校验（防CSRF）
    if (response.state && request.state !== response.state) {
      throw new Error(`State校验失败: 请求=${request.state}, 响应=${response.state}`);
    }

    return this.handleAuthSuccess(response);
  }

  // 显式登录实现
  private async explicitLogin(): Promise<SnsOneUser> {
    const request: authentication.LoginWithHuaweiIDRequest =
      new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();

    request.forceLogin = true; // true 表示显式登录
    request.state = util.generateRandomUUID(); // 生成防伪标识

    const controller = new authentication.AuthenticationController();
    const response = await controller.executeRequest(request) as authentication.LoginWithHuaweiIDResponse;

    // 安全校验
    if (response.state && request.state !== response.state) {
      throw new Error(`State校验失败: 请求=${request.state}, 响应=${response.state}`);
    }

    return this.handleAuthSuccess(response);
  }
  private async requestUserProfile(): Promise<SnsOneUser> {
    try {
      // 创建授权请求获取用户信息
      const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();

      // 设置请求权限范围，profile用于获取头像和昵称
      authRequest.scopes = ['profile'];

      // 用于防跨站点请求伪造
      authRequest.state = util.generateRandomUUID();

      // 设置为true会在未授权时拉起授权页面
      authRequest.forceAuthorization = true;

      const controller = new authentication.AuthenticationController(getAppContext());
      const response = await controller.executeRequest(authRequest) as authentication.AuthorizationWithHuaweiIDResponse;

      // 安全校验
      if (response.state && authRequest.state !== response.state) {
        throw new Error(`State校验失败: 请求=${authRequest.state}, 响应=${response.state}`);
      }

      const credential = response.data!;
      const user = new SnsOneUser();

      // 获取用户昵称和头像URL
      // 注意：未设置昵称默认返回华为账号绑定的匿名手机号/邮箱
      user.userName = credential.nickName || '华为用户';
      // 使用 avatarUri 获取头像地址
      user.avatarAddress = credential.avatarUri || '';

      hilog.info(0x0000, this.TAG, `获取用户信息成功: 昵称=${user.userName}, 头像=${user.avatarAddress}`);

      return user; // 直接返回SnsOneUser实例
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0000, this.TAG, `获取用户信息失败: code=${err.code}, message=${err.message}`);

      // 处理常见错误
      const errorMap: Record<number, string> = {
        1001502001: "用户未登录华为账号", // ERROR_CODE_LOGIN_OUT
        1001502012: "用户取消授权",       // ERROR_CODE_USER_CANCEL
        1001502005: "网络异常，请检查网络设置", // ERROR_CODE_NETWORK_ERROR
        12300001: "系统服务异常，请稍后重试",  // ERROR_CODE_SYSTEM_SERVICE
        1001500002: "重复请求，应用无需处理"   // ERROR_CODE_REQUEST_REFUSE
      };

      throw new Error(errorMap[err.code] || `获取用户信息失败: ${err.code}`);
    }
  }

  // 统一处理登录成功
  // 统一处理登录成功
  private async handleAuthSuccess(response: authentication.LoginWithHuaweiIDResponse): Promise<SnsOneUser> {
    const credential = response.data!;
    const user = new SnsOneUser();

    // 获取关键凭证
    user.userId      = credential.unionID || credential.openID; // unionID这样可以也android上的huawei登录id共享用户数据
    user.accessToken = credential.authorizationCode!; // 授权码

    // 登录成功后立即获取用户详细信息（昵称和头像）
    try {
      const userProfile = await this.requestUserProfile();
      user.userName = userProfile.userName;
      user.avatarAddress = userProfile.avatarAddress;
    } catch (error) {
      hilog.warn(0x0000, this.TAG, `获取用户详细信息失败，但登录成功: ${error.message}`);
      // 即使获取详细信息失败，仍然返回基本登录信息
    }

    hilog.info(0x0000, this.TAG, "登录成功，用户ID:" + user.userId);
    return user;
  }

  // 错误处理映射
  getErrorMessage(error: BusinessError): string {
    const errorMap: Record<number, string> = {
      1001502001: "未登录华为账号",
      1001502012: "用户取消授权",
      1001502005: "网络错误，请重试",
      1001500001: "证书指纹不匹配，检查AGC配置"
    };
    return errorMap[error.code] || `未知错误: ${error.code}`;
  }
}

// 使用示例（在Page中）
@Entry
@Component
struct LoginPage {
  private loginMgr = HwLoginManager.shared;
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  build() {
    Column() {
      Button('华为一键登录')
        .width('80%')
        .height(50)
        .onClick(async () => {
          this.isLoading = true;
          this.errorMessage = '';
          try {
            const user = await this.loginMgr.login();
            hilog.info(0x0000, "LoginPage",
              `登录成功！用户: ${user.userName}, ID: ${user.userId}, 头像: ${user.avatarAddress}`);

            // 登录成功，跳转首页
            // router.pushUrl({ url: 'pages/Home' });
          } catch (error) {
            this.errorMessage = error.message || '登录失败';
            hilog.error(0x0000, "LoginPage", `登录错误: ${this.errorMessage}`);
          } finally {
            this.isLoading = false;
          }
        })

      if (this.isLoading) {
        LoadingProgress()
          .width(50).height(50)
      }

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontColor(Color.Red)
          .margin({ top: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}