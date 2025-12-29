// 登录类型枚举
export enum LoginType {
  email     = 'email',
  wechat    = 'wechat',
  wechat_qr = 'wechat_qr',
  huawei    = 'huawei',
  qq        = 'qq',
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
      case 'qq'        : return LoginType.qq;
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

  //static readonly userCode        = "user_code";
}

///用于Http表示后收到的json转换对象
export interface UserJson {
  user_id?: number | null
  user_name?: string | null
  email?: string | null
  password?: string | null
  login_type?: string | null
  login_identifier?: string | null
  login_time?: string | null        // Date 用 string 表示
  create_time?: string | null
  image_addr?: string | null
  device_type?: string | null
  user_code?: string | null
}

// 用户信息模型
export class User {
  userId: number | null = null;
  userName: string | null = null;
  email: string | null = null;
  password: string | null = null;
  loginType: LoginType | null = null;
  loginIdentifier: string | null = null;
  loginTime: Date | null = null;
  createTime: Date | null = null;
  imageAddr: string | null = null;
  deviceType: string | null = null;
  userCode: string | null = null;


  // 通过 JSON 生成 User（类似 Kotlin 的 from(json) 或 Swift 的 init(from decoder)）
  static from(json: UserJson): User {
    const user = new User();

    user.userId          = json.user_id          ?? null;
    user.userName        = json.user_name        ?? null;
    user.email           = json.email            ?? null;
    user.password        = json.password         ?? null;
    user.loginIdentifier = json.login_identifier ?? null;
    user.loginType       = LoginTypeHelper.fromRaw(json.login_type);

    user.loginTime       = json.login_time  ? new Date(json.login_time)  : null;
    user.createTime      = json.create_time ? new Date(json.create_time) : null;

    user.imageAddr       = json.image_addr ?? null;
    user.deviceType      = json.device_type ?? null;
    user.userCode        = json.user_code ?? null;

    return user;
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

