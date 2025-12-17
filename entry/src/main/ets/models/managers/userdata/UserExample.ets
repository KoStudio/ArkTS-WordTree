/// 用于服务器上备份和恢复用户数据
export interface UserExampleJson {
  serial_no?        : number | null;
  last_result_type? : number | null;
  num_of_succeeded? : number | null;
  num_of_failed?    : number | null;
  check_level?      : number | null;
  failed_year?      : number | null;
  failed_month?     : number | null;
  failed_day?       : number | null;
  learn_times?      : number | null;
  memo?             : string | null;
  share_memos?      : Array<Record<string, string>> | null;
  deleted?          : boolean | null;
}

/// CodingKeys（保持 Kotlin 的结构）
export class UserExampleKeys {
  static readonly SerialNo       = "serial_no";
  static readonly LastResultType = "last_result_type";
  static readonly NumOfSucceeded = "num_of_succeeded";
  static readonly NumOfFailed    = "num_of_failed";
  static readonly CheckLevel     = "check_level";
  static readonly FailedYear     = "failed_year";
  static readonly FailedMonth    = "failed_month";
  static readonly FailedDay      = "failed_day";
  static readonly LearnTimes     = "learn_times";
  static readonly Memo           = "memo";
  static readonly ShareMemos     = "share_memos";
  static readonly Deleted        = "deleted";
}

/// 以 iOS 为准：0:none, 1:succeed, 2:failed
export enum iOS_LastResultType {
  None    = 0,
  Succeed = 1,
  Failed  = 2
}

/// 用户示例模型（用于上传/恢复用户单词相关数据）
export class UserExample {
  serialNo       : number | null                         = null;
  lastResultType : number | null                         = null;
  numOfSucceeded : number | null                         = null;
  numOfFailed    : number | null                         = null;
  checkLevel     : number | null                         = null;
  failedYear     : number | null                         = null;
  failedMonth    : number | null                         = null;
  failedDay      : number | null                         = null;
  learnTimes     : number | null                         = null;
  memo           : string | null                         = null;
  shareMemos     : Array<Record<string, string>> | null   = null;
  deleted        : boolean | null                        = null;

  constructor(init?: Partial<UserExample>) {
    if (!init) return;
    this.serialNo       = init.serialNo       ?? null;
    this.lastResultType = init.lastResultType ?? null;
    this.numOfSucceeded = init.numOfSucceeded ?? null;
    this.numOfFailed    = init.numOfFailed    ?? null;
    this.checkLevel     = init.checkLevel     ?? null;
    this.failedYear     = init.failedYear     ?? null;
    this.failedMonth    = init.failedMonth    ?? null;
    this.failedDay      = init.failedDay      ?? null;
    this.learnTimes     = init.learnTimes     ?? null;
    this.memo           = init.memo           ?? null;
    this.shareMemos     = init.shareMemos     ?? null;
    this.deleted        = init.deleted        ?? null;
  }

  static from(json: UserExampleJson): UserExample {
    const obj = new UserExample();

    obj.serialNo       = json.serial_no        ?? null;
    obj.lastResultType = json.last_result_type ?? null;
    obj.numOfSucceeded = json.num_of_succeeded ?? null;
    obj.numOfFailed    = json.num_of_failed    ?? null;
    obj.checkLevel     = json.check_level      ?? null;
    obj.failedYear     = json.failed_year      ?? null;
    obj.failedMonth    = json.failed_month     ?? null;
    obj.failedDay      = json.failed_day       ?? null;
    obj.learnTimes     = json.learn_times      ?? null;
    obj.memo           = json.memo             ?? null;
    obj.shareMemos     = json.share_memos      ?? null;
    obj.deleted        = json.deleted          ?? null;

    return obj;
  }

  /**
   * 批量解析 JSON 数组
   * @param jsonArray - JSON 数组对象
   */
  static fromJsonArray(jsonArray: UserExampleJson[] | null | undefined): UserExample[] {
    if (!jsonArray || !Array.isArray(jsonArray)) return [];
    return jsonArray.map(item => UserExample.from(item));
  }

  /// 以 iOS 为准：0:none, 1:succeed,2:failed
  static readonly iOS_LastResultType = iOS_LastResultType;

  /// equals：根据 serialNo 判定相等（与 Kotlin 的 equals 行为一致）
  equals(other: UserExample): boolean {
    if (!other) return false;
    const otherSerial = (other as UserExample).serialNo ?? null;
    return otherSerial === this.serialNo;
  }

  /// hashCode：简单返回 serialNo 的数值哈希（Kotlin 用 serialNo.hashCode()）
  hashCode(): number {
    // 若 serialNo 为 null，则返回 0
    return (this.serialNo ?? 0);
  }

  /// 获取最后一次测验失败的日期（若无可靠日期则返回 null）
  getLastFailedDate(): Date | null {
    const y = this.failedYear;
    const m = this.failedMonth;
    const d = this.failedDay;

    if (y == null || m == null || d == null) return null;
    if (y === 0 || m === 0 || d === 0) return null;

    // JS Date 的 month 是 0..11，因此需要减一
    try {
      return new Date(y, m - 1, d);
    } catch (e) {
      return null;
    }
  }
}