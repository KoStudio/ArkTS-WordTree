// 登录类型枚举
export enum LoginType {
  email     = 'email',
  wechat    = 'wechat',
  wechat_qr = 'wechat_qr',
  huawei    = 'huawei'
}

export class LoginTypeHelper {

  // 静态转换方法：将原始字符串转换为枚举值
  static fromRaw(str?: string | null): LoginType | null {
    if (str === undefined || str === null) {
      return null;
    }

    const normalizedInput = str.toLowerCase();

    switch (normalizedInput) {
      case 'email'     : return LoginType.email;
      case 'wechat'    : return LoginType.wechat;
      case 'wechat_qr' : return LoginType.wechat_qr;
      case 'huawei'    : return LoginType.huawei;
      default          : return null;
    }
  }
}

///用于Http提交时的Param
export class UserCodingKeys {
  static readonly userId          = "user_id";
  static readonly userName        = "user_name";
  static readonly email           = "email";
  static readonly password        = "password";
  static readonly loginType       = "login_type";
  static readonly loginIdentifier = "login_identifier";
  static readonly loginTime       = "login_time";
  static readonly createTime      = "create_time";
  static readonly imageAddr       = "image_addr";

  static readonly safeCode        = "safe_code";
  static readonly deviceType      = "device_type";
  static readonly appName         = "app_name";
}

///用于Http表示后收到的json转换对象
export interface UserJson {
  user_id?: number | null
  user_name?: string | null
  login_identifier?: string | null
  login_type?: string | null
}

// 用户信息模型
export class User {
  userId: number | null = null;
  userName: string | null = null;
  loginIdentifier: string | null = null;
  loginType: LoginType | null = null;

  static from(json: UserJson): User {
    const user           = new User();
    user.userId          = json.user_id ?? null
    user.userName        = json.user_name ?? null
    user.loginIdentifier = json.login_identifier ?? null
    user.loginType       = LoginTypeHelper.fromRaw(json.login_type)

    return user
  }
}




// SNS登录类型
export enum SnsOneType {
  WECHAT = "wechat"
}

// SNS用户信息模型
export class SnsOneUser {
  userId: string | null = null;
  userName: string | null = null;
  avatarAddress: string | null = null;
  accessToken: string | null = null;
  expireIn: string | null = null;
}

