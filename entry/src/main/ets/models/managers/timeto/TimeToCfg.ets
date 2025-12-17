import { DebugFlg } from "../../../app/debug/DebugFlg";

// MARK: - TimeTo Config
export class TimeTo { // 单位: 小时
  public static UpdateServerConfigs: number = DebugFlg.isDebugMode() ? 1.0 / 3600.0 : 24 * 5; // 5天检查一次 ServerConfigs中的配置，Debug：1秒
  public static AutoRefreshSubscriptionInfo: number = DebugFlg.isDebugMode() ? 1.0 / 3600.0 :  6; // 5小时检查一次 订阅时间变化，Debug：1秒
}