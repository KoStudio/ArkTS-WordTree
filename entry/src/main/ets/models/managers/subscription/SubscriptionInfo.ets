export class SubscriptionInfoCodingKeys {
  static readonly userId           = "user_id";
  static readonly sku              = "sku";
  static readonly endDate          = "end_date";
  static readonly purchasedPlatform= "purchased_platform";
  static readonly flavor           = "flavor";
  static readonly deviceIDFV       = "device_idfv";
  static readonly deviceType       = "device_type";
  static readonly isWriteable      = "is_writeable";
}

export class SubscriptionInfo {
  userId:    number | null = null;  // 用户ID
  sku:       string | null = null;  // 订阅SKU
  endDateMs: number | null = null;  // 订阅结束时间戳（毫秒）

  constructor(json?: Record<string, Object>) {
    if (json) {
      this.userId    = (json['user_id']    as number) ?? null;
      this.sku       = (json['sku']        as string) ?? null;
      this.endDateMs = (json['end_date']   as number) ?? null;
    }
  }

  /**
   * 从数组构建 SubscriptionInfo 列表
   * @param arr JSON数组
   * @returns SubscriptionInfo 列表
   */
  static fromArray(arr: Object[] | null): SubscriptionInfo[] {
    if (!arr) return [];
    return arr.map(o => new SubscriptionInfo(o as Record<string, Object>));
  }

  /**
   * 转换为服务器可用参数字典
   * @returns 参数字典
   */
  asParamsDict(): Record<string, Object> {
    const params: Record<string, Object> = {};

    if (this.userId    !== null) params['user_id']     = this.userId;
    if (this.sku       !== null) params['sku']         = this.sku;
    if (this.endDateMs !== null) params['end_date']    = this.endDateMs;

    return params;
  }
}