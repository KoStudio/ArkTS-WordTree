import { SubscriptionInfo, SubscriptionInfoCodingKeys } from "./SubscriptionInfo";
import { preferences } from "@kit.ArkData";
import { getAppContext } from "../../../app/constants/AppContext";
import { DebugLog } from "../../../app/debug/DebugLog";
import { NetWorkTool } from "../../../common/utils/NetworkUtils";
import { Toast } from "../../../common/utils/Toast";
import { TimeToManager, TimeToType } from "../timeto/TimeToManager";
import { UserManager } from "../user/UserManager";
import { HttpUtils } from "../../networks/HttpUtils";
import { Servers, Route } from "../../networks/Server_Routes";
import { DeviceUtil } from "../../../common/utils/DeviceUtils";
import { Http } from "../../networks/Http";
import { SubscribeItem, SubscribeManager } from "../../../common/iab/SubscribeManager";

/** SubscriptionInfoManager Pref Key 常量 */
class SubscriptionInfoPrefKeys {
  public static readonly PrefName       : string = "Sub_scription_Info_Manager";
  public static readonly kWaitingRefresh: string = "is_need_a_refresh";

  /** 内部同步获取 Preferences */
  public static _getPrefs(): preferences.Preferences {
    return preferences.getPreferencesSync(getAppContext(), { name: SubscriptionInfoPrefKeys.PrefName });
  }
}

/** SubscriptionInfoManager */
export class SubscriptionInfoManager {

  /** 单例共享对象 */
  static shared: SubscriptionInfoManager = new SubscriptionInfoManager();

  /** 是否等待刷新到服务器 */
  private _isWaitingRefreshToServer: boolean = false;

  constructor() {
    this.loadPreference();  // 初始化时加载本地配置
  }

  // -------------------------
  // Getter / Setter
  // -------------------------
  get isWaitingRefreshToServer(): boolean {
    return this._isWaitingRefreshToServer;
  }

  set isWaitingRefreshToServer(value: boolean) {
    this._isWaitingRefreshToServer = value;
    this.savePreference();  // 设置时保存 Pref
  }

  // -------------------------
  // 本地 Preference 保存与加载
  // -------------------------

  /** 保存本地配置 */
  private savePreference(): void {
    try {
      const prefs = SubscriptionInfoPrefKeys._getPrefs();
      prefs.putSync(SubscriptionInfoPrefKeys.kWaitingRefresh, this._isWaitingRefreshToServer);
      prefs.flushSync();
    } catch (err) {
      DebugLog.d(`SubscriptionInfoManager.savePreference error: ${err}`);
    }
  }

  /** 加载本地配置 */
  private loadPreference(): void {
    try {
      const prefs = SubscriptionInfoPrefKeys._getPrefs();
      this._isWaitingRefreshToServer = prefs.getSync(SubscriptionInfoPrefKeys.kWaitingRefresh, false) as boolean;
    } catch (err) {
      DebugLog.d(`SubscriptionInfoManager.loadPreference error: ${err}`);
      this._isWaitingRefreshToServer = false;
    }
  }

  // -------------------------
  // 自动刷新订阅信息
  // -------------------------

  /** 自动刷新订阅信息（判断时间间隔） */
  autoRefreshSubscriptionInfoIfNeeds(): void {

    // 检查网络
    if (!NetWorkTool.checkInternetConnection(false)) return;

    // // 检查自动刷新开关
    // if (!AppCfgManager.shared.isAutoRefreshSubscriptionInfo_is_ON()) {
    //   Toast.showDebugMessage("自动刷新订阅时间..未启用");
    //   return;
    // }

    // 判断时间间隔是否到达
    if (TimeToManager.isTimeTo(TimeToType.autoRefreshSubsciptionInfo)) {
      Toast.showDebugMessage("自动刷新订阅时间..start..");
      this.refreshSubscriptionInfo(true);  // 只读
      TimeToManager.saveTime(TimeToType.autoRefreshSubsciptionInfo, true);
    }
  }

  /// 异步 自动刷新 订阅时间，
  asyncRefreshSubscriptionInfo(isReadServerOnly: boolean = false){
    this.refreshSubscriptionInfo(isReadServerOnly);  // 只读
  }

  // -------------------------
  // 刷新订阅信息
  // -------------------------

  /**
   * 刷新订阅信息
   * @param isReadServerOnly 是否只读取服务器数据
   */
  /**
   * 刷新订阅信息
   * @param isReadServerOnly 是否只读取服务器数据（不写回服务器）
   */
  private refreshSubscriptionInfo(isReadServerOnly: boolean = false): void {
    // 是否需要写回服务器
    let isWriteToServer                     : boolean = !isReadServerOnly;

    // 如果当前等待刷新并且已经有用户ID，则可以写回服务器
    if (isWriteToServer) {
      this._isWaitingRefreshToServer      = !UserManager.shared.isLogin();
    } else if (this._isWaitingRefreshToServer && UserManager.shared.isLogin()) {
      isWriteToServer                     = true;
      this._isWaitingRefreshToServer      = false;
    }

    const userId                          = UserManager.shared.userId;
    if (!UserManager.shared.isLogin())  return; // 没有用户ID，直接返回

    const currentItem                     = SubscribeManager.shared.currentItem;

    // 构建请求参数
    const sku                             = SubscribeManager.shared.currentItem?.sku;
    const endDate                         = SubscribeManager.shared.currentItem?.expiresDateMs;
    const purchasedPlatform               = SubscribeManager.shared.currentItem?.purchasedPlatform;

    // 构建请求参数
    const params: HttpUtils.HttpParams    = {};
    params[SubscriptionInfoCodingKeys.userId]                                     = userId ?? 0;
    if (sku)                 params[SubscriptionInfoCodingKeys.sku]               = sku;
    if (endDate)             params[SubscriptionInfoCodingKeys.endDate]           = Number(endDate).toFixed(0);
    if (purchasedPlatform)   params[SubscriptionInfoCodingKeys.purchasedPlatform] = purchasedPlatform;
    params[SubscriptionInfoCodingKeys.flavor]           = Servers.flavor;
    params[SubscriptionInfoCodingKeys.deviceIDFV]       = DeviceUtil.getStableUUID();
    params[SubscriptionInfoCodingKeys.deviceType]       = DeviceUtil.getDeviceType();
    params[SubscriptionInfoCodingKeys.isWriteable]      = isWriteToServer;

    const url                              : string = `${Servers.getRouteUrl(Route.subscription)}/refresh`;

    // 使用 Http.request 获取服务器返回数据
    Http.request(
      url,
      HttpUtils.Method.POST,
      params,
      (succeed: boolean, msg: string | null, data?: Object[] | null) => {
        if (!succeed || !data || data.length === 0) {
          DebugLog.d(`refreshSubscriptionInfo failed: ${msg}`);
          return;
        }

        // 将返回数据转换为 SubscriptionInfo 对象列表
        const list: SubscriptionInfo[]              = SubscriptionInfo.fromArray(data);
        const subscriptionInfo : SubscriptionInfo   = list[0];
        const newItem : SubscribeItem               = new SubscribeItem(subscriptionInfo.sku, subscriptionInfo.endDateMs);

        // 条件保存到本地
        SubscribeManager.shared.saveNewItemIfNeeds(newItem);
      }
    );
  }

  // -------------------------
  // 获取订阅信息
  // -------------------------

  getSubscriptionInfo(completion: (succeed: boolean, msg: string | null, list: SubscriptionInfo[] | null) => void): void {
    const userId = UserManager.shared.userId;
    if (!UserManager.shared.isLogin()) return;

    const params: HttpUtils.HttpParams = {};
    params["user_id"] = userId ?? "";

    const url = Servers.getRouteUrl(Route.subscription);
    Http.send(url, HttpUtils.Method.GET, params, (succeed: boolean, msg: string | null, data?: Object[]) => {
      const list = SubscriptionInfo.fromArray(data ?? null);
      completion(succeed, msg, list);
    });
  }

  // -------------------------
  // 更新订阅信息
  // -------------------------

  updateSubscriptionInfo(endDate: number, purchasedPlatform: string | null, completion: (succeed: boolean, msg: string | null) => void): void {
    const userId = UserManager.shared.userId;
    if (!UserManager.shared.isLogin()) return;

    const sku = SubscribeManager.shared.currentItem?.sku;

    const params: HttpUtils.HttpParams = {};
    params["user_id"]          = userId ?? "";
    if (sku) params["sku"]     = sku;
    params["end_date"]         = endDate;
    if (purchasedPlatform) params["purchased_platform"] = purchasedPlatform;
    params["flavor"]           = Servers.flavor;
    params["device_idfv"]      = DeviceUtil.getStableUUID();
    params["device_type"]      = DeviceUtil.getDeviceType();

    const url = Servers.getRouteUrl(Route.subscription);
    Http.send(url, HttpUtils.Method.POST, params, completion);
  }
}