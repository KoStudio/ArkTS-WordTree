import { DateUtils } from "../../../common/utils/DateUtils";

export class UserDataCodingKeys {

  static readonly userId       = "user_id";
  static readonly userDataAddr = "user_data_addr";
  static readonly createDate   = "create_date";
  static readonly updateDate   = "update_date";

}

/// 用于服务器上备份和恢复用户数据
export class UserDataJson {
  user_id?: number | null = null;
  user_data_addr?: string | null = null;
  create_date?: string | null = null;
  update_date?: string | null = null;
}

/// 用于服务器上备份和恢复用户数据
export class UserData {
  userId: number | null = null;
  userDataAddr: string | null = null;
  createDate: Date | null = null;
  updateDate: Date | null = null;

  constructor() {}

  // 从JSON对象解析的静态方法
  static fromJson(json: UserDataJson): UserData {
    const data = new UserData();

    // 直接属性赋值
    data.userId = json.user_id ?? null;
    data.userDataAddr = json.user_data_addr ?? null;

    // 日期转换
    if (json.create_date) {
      data.createDate = DateUtils.toDateFromUTC(json.create_date)
    }

    if (json.update_date) {
      data.updateDate = DateUtils.toDateFromUTC(json.update_date);
    }

    return data;
  }
}