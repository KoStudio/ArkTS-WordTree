// AppCfgManager.ets
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { ServerCfg, ServerCfgManager } from './ServerCfgManager';
import { Toast } from '../../../common/utils/Toast';
import { NetWorkTool } from '../../../common/utils/NetworkUtils';
import { TimeToManager, TimeToType } from '../timeto/TimeToManager';

// 配置键名常量类
class Pref {
  static readonly Name: string = "DailyCount_Setting"; // 偏好存储名称
}

// 通知相关常量类
export class AppCfgNotification {
  static readonly AppCfgUpdated: string = "app_cfg_updated_from_server"; // 配置更新通知名称
}

// 应用配置枚举 - 所有配置项定义
export enum AppCfg {
  // 通用配置
  Dictation_Detect_Merged_Api_GeneralOrHandwriting = "Dictation_Detect_Merged_Api_GeneralOrHandwriting", // [通用] 听写合并检测Api使用通用还是手写

  InAppBooks_Show_In_SaveToBooks                    = "InAppBooks_Show_In_SaveToBooks",                   // [通用] 内置课本 在SaveToBooks（CopyTo，ImportCsv）时是否显示
  InAppBooks_Can_ShareOnline                        = "InAppBooks_Can_ShareOnline",                       // [通用] 内置课本 可否分享到 在线课本
  CreatedUserCards_Can_ShareOnline                  = "CreatedUserCards_Can_ShareOnline",                 // [通用] 用户卡片 可否分享到 在线课本
  BookOnline_Download_is_ON                         = "BookOnline_Download_is_ON",                        // [通用] 在线课本是否可查看或下载
  BookOnline_Publish_is_ON                          = "BookOnline_Publish_is_ON",                         // [通用] 在线课本是否可以发布
  Android_HowTo_CreateCSV_idx_in_Instruction        = "Android_HowTo_CreateCSV_idx_in_Instruction",       // [通用] 如何制作csv并发布到手机 在Instruction中对应的idx
  Android_HowTo_Imort_SharedData_idx_in_Instruction = "Android_HowTo_Imort_SharedData_idx_in_Instruction",// [通用] 如何导入他人分享的数据? 在Instruction中对应的idx
  Android_ShareAppLink_idx_in_Instruction           = "Android_ShareAppLink_idx_in_Instruction",          // [通用] 分享应用link 在Instruction中对应的idx

  Android_Home_Notice_idx_in_Instruction           = "Android_Home_Notice_idx_in_Instruction",          // [通用] 首页滚动公告在Instruction中对应的idx

  AutoRefreshSubscriptionInfo_is_ON                = "AutoRefreshSubscriptionInfo_is_ON",               // [通用] 是否启用 自动刷新会员订阅时间
  AutoRefreshSubscriptionInfo_Interval_Minutes     = "AutoRefreshSubscriptionInfo_Interval_Minutes",    // [通用] 自动刷新 服务器上的会员订阅的 时间间隔

  CosAuditCheckForSignup_is_ON                     = "CosAuditCheckForSignup_is_ON",                    // [通用] 是否启用 注册审核
  CosAuditCheckForLogin_is_ON                      = "CosAuditCheckForLogin_is_ON",                     // [通用] 是否启用 登录审核

  CBook_Useable_is_ON                              = "CBook_Useable_is_ON",                             // [通用] 是否启用 CBook[总开关]
  CBook_AutoUpdateCheck_is_ON                      = "CBook_AutoUpdateCheck_is_ON",                     // [通用] 是否启用 CBook自动更新检查
  CBook_AutoUpdateCheck_Interval_Minutes           = "CBook_AutoUpdateCheck_Interval_Minutes",          // [通用] CBook自动更新检查 时间间隔
  CBookList_AutoUpdateCheck_is_ON                  = "CBookList_AutoUpdateCheck_is_ON",                 // [通用] 是否启用 CBookList自动更新检查
  CBookIcon_AutoUpdateCheck_is_ON                  = "CBookIcon_AutoUpdateCheck_is_ON",                 // [通用] 是否启用 CBookIcon自动更新检查

  // 会员配置
  M_Dictation_Detect_OneByOne_Total_Cnt           = "M_Dictation_Detect_OneByOne_Total_Cnt",          // [会员]听写检测使用oneByone的总行数

  // 非会员配置
  N_Dictation_ScanTimes_Total_Cnt                 = "N_Dictation_ScanTimes_Total_Cnt",                 // [非会员]可以执行文字识别的次数(总共)

  // 非会员(订阅描述)配置
  N_P_maxBookCount            = "N_P_maxBookCount",           // 非会员(订阅) 最大学习集个数
  N_P_maxGroupCountPerBook    = "N_P_maxGroupCountPerBook",   // 非会员(订阅) 每个学习集中的最大组数
  N_P_maxUnitCountInAppBook   = "N_P_maxUnitCountInAppBook",  // 非会员(订阅) 内置课本中可使用的最大单元数
  N_P_maxWordPronCountDaily   = "N_P_maxWordPronCountDaily",  // 非会员(订阅) 每日 查看汉字发音 个数
  N_P_maxWordStrokeCountDaily = "N_P_maxWordStrokeCountDaily",// 非会员(订阅) 每日 查看汉字笔画 个数
  N_P_maxPhrasePronCountDaily = "N_P_maxPhrasePronCountDaily",// 非会员(订阅) 每日 查看词语/成语发音 个数
  N_P_maxDictationTimesDaily  = "N_P_maxDictationTimesDaily", // 非会员(订阅) 每日 可以使用听写 次数
  N_P_maxPlanCount            = "N_P_maxPlanCount",           // 非会员(订阅) 可以创建的计划个数
  N_P_maxPlanDayOfsCount      = "N_P_maxPlanDayOfsCount",     // 非会员(订阅) 可以使用的DayOf数

  N_P_maxEBookCount          = "N_P_maxEBookCount",          // 非会员(订阅) 可以创建的"我的课本"最大个数
  N_P_maxEPartCountPerBook   = "N_P_maxEPartCountPerBook",   // 非会员(订阅) 每个课本中可以新增的"字表"最大个数
  N_P_maxELessonCountPerPart = "N_P_maxELessonCountPerPart", // 非会员(订阅) 每个字表中可以添加的"汉字组"最大个数
}

// 应用配置管理器类
export class AppCfgManager {
  // 配置字典
  private dict: Map<string, number> = new Map<string, number>();

  // 单例实例
  private static instance: AppCfgManager | null = null;

  // 私有构造函数
  private constructor() {
    // 从本地加载配置
    this.loadPreference();

    // 从服务器加载配置（如果需要）
    // this.loadConfigsIfNeeds();
  }

  // 获取单例实例
  static get shared(): AppCfgManager {
    if (!AppCfgManager.instance) {
      AppCfgManager.instance = new AppCfgManager();
    }
    return AppCfgManager.instance;
  }

  // 获取配置项的默认值
  private static getDefaultValue(cfg: AppCfg): number {
    let defaultValue: number = 0;
    switch (cfg) {
      // 通用配置默认值
      case AppCfg.Dictation_Detect_Merged_Api_GeneralOrHandwriting:        defaultValue = 1;      break; // [通用]听写合并检测Api使用(0:通用[正确率低], 1:手写)
      case AppCfg.InAppBooks_Show_In_SaveToBooks:                          defaultValue = 0;      break; // [通用] 内置课本 在SaveToBooks时是否显示(0：不显示，1：显示）
      case AppCfg.InAppBooks_Can_ShareOnline:                              defaultValue = 0;      break; // [通用] 内置课本 在分享到在线课本中 是否显示 (0：不显示，1：显示）
      case AppCfg.CreatedUserCards_Can_ShareOnline:                        defaultValue = 0;      break; // [通用] 用户卡片 可否分享到 在线课本 (0：不可以，1：可以）
      case AppCfg.BookOnline_Download_is_ON:                               defaultValue = 0;      break; // [通用] 在线课本是否可查看或下载(0: 不能查看或下载, 1: 可以下载)
      case AppCfg.BookOnline_Publish_is_ON:                                defaultValue = 0;      break; // [通用] 在线课本是否可以发布(0: 不能发布, 1: ON 可以发布)
      case AppCfg.Android_HowTo_CreateCSV_idx_in_Instruction:              defaultValue = 13;     break; // [通用] 如何制作csv并发布到手机 在Instruction中对应的idx
      case AppCfg.Android_HowTo_Imort_SharedData_idx_in_Instruction:       defaultValue = 14;     break; // [通用] 如何导入他人分享的数据? 在Instruction中对应的idx
      case AppCfg.Android_ShareAppLink_idx_in_Instruction:                 defaultValue = 15;     break; // [通用] 分享应用link 在Instruction中对应的idx
      case AppCfg.Android_Home_Notice_idx_in_Instruction:                  defaultValue = 1;      break; // [通用] 首页滚动公告在Instruction中对应的idx。只有idx > 0时，才会查询Server端的Instruction
      case AppCfg.AutoRefreshSubscriptionInfo_is_ON:                       defaultValue = 1;      break; // [通用] 是否启用 自动刷新会员订阅时间(0：未启用，1：已启用）
      case AppCfg.AutoRefreshSubscriptionInfo_Interval_Minutes:            defaultValue = 60*12;  break; // [通用] 自动刷新 服务器上的会员订阅的 时间间隔（只读） 单位：分钟
      case AppCfg.CosAuditCheckForSignup_is_ON:                            defaultValue = 1;      break; // [通用] 是否启用 注册审核(0：未启用，1：已启用）
      case AppCfg.CosAuditCheckForLogin_is_ON:                             defaultValue = 1;      break; // [通用] 是否启用 登录审核(0：未启用，1：已启用）
      case AppCfg.CBook_Useable_is_ON:                                     defaultValue = 1;      break; // [通用] 是否启用 CBook[总开关]（Cos下载的Book）(0：未启用〈使用App bundle内的Book〉，1：已启用）
      case AppCfg.CBook_AutoUpdateCheck_is_ON:                             defaultValue = 1;      break; // [通用] 是否启用 CBook自动更新检查
      case AppCfg.CBook_AutoUpdateCheck_Interval_Minutes:                  defaultValue = 60*48;  break; // [通用] CBook自动更新检查 时间间隔 单位：分钟
      case AppCfg.CBookList_AutoUpdateCheck_is_ON:                         defaultValue = 1;      break; // [通用] 是否启用 CBookList自动更新检查
      case AppCfg.CBookIcon_AutoUpdateCheck_is_ON:                         defaultValue = 1;      break; // [通用] 是否启用 CBookIcon自动更新检查

    // 会员配置默认值
      case AppCfg.M_Dictation_Detect_OneByOne_Total_Cnt:                   defaultValue = 100;    break; // [会员]听写检测使用oneByone的总行数

    // 非会员配置默认值
      case AppCfg.N_Dictation_ScanTimes_Total_Cnt:                         defaultValue = 2;      break; // [非会员]可以执行文字识别的次数(总共)

    // 非会员(订阅描述)配置默认值
      case AppCfg.N_P_maxBookCount:                                        defaultValue = 3;      break; // 非会员(订阅) 最大学习集个数
      case AppCfg.N_P_maxGroupCountPerBook:                                defaultValue = 3;      break; // 非会员(订阅) 每个学习集中的最大组数
      case AppCfg.N_P_maxUnitCountInAppBook:                               defaultValue = 10;     break; // 非会员(订阅) 内置课本中可使用的最大单元数
      case AppCfg.N_P_maxWordPronCountDaily:                               defaultValue = 10;     break; // 非会员(订阅) 每日 查看汉字发音 个数
      case AppCfg.N_P_maxWordStrokeCountDaily:                             defaultValue = 5;      break; // 非会员(订阅) 每日 查看汉字笔画 个数
      case AppCfg.N_P_maxPhrasePronCountDaily:                             defaultValue = 5;      break; // 非会员(订阅) 每日 查看词语/成语发音 个数
      case AppCfg.N_P_maxDictationTimesDaily:                              defaultValue = 1;      break; // 非会员(订阅) 每日 可以使用听写 次数
      case AppCfg.N_P_maxPlanCount:                                        defaultValue = 1;      break; // 非会员(订阅) 可以创建的计划个数
      case AppCfg.N_P_maxPlanDayOfsCount:                                  defaultValue = 7;      break; // 非会员(订阅) 可以使用的DayOf数
      case AppCfg.N_P_maxEBookCount:                                       defaultValue = 1;      break; // 非会员(订阅) 可以创建的"我的课本"最大个数
      case AppCfg.N_P_maxEPartCountPerBook:                                defaultValue = 1;      break; // 非会员(订阅) 每个课本中可以新增的"字表"最大个数
      case AppCfg.N_P_maxELessonCountPerPart:                              defaultValue = 10;     break; // 非会员(订阅) 每个字表中可以添加的"汉字组"最大个数
    }
    return defaultValue;
  }

  // 保存偏好设置到本地
  // 保存偏好设置到本地
  private async savePreference(): Promise<void> {
    try {
      // 获取 preferences 实例
      let context: common.Context = getContext(this) as common.Context;
      let prefs = await preferences.getPreferences(context, Pref.Name);

      // 将配置字典保存到 preferences
      for (let key of this.dict.keys()) {
        let value = this.dict.get(key);
        await prefs.put(key, value);
      }

      // 刷新到磁盘
      await prefs.flush();
    } catch (err) {
      console.error(`保存偏好设置失败: ${err.message}`);
    }
  }

  // 从本地加载偏好设置
  private async loadPreference(): Promise<void> {
    try {
      // 先设置本地默认值
      for (let cfgValue of Object.values(AppCfg)) {
        this.dict.set(cfgValue, AppCfgManager.getDefaultValue(cfgValue));
      }

      // 获取 preferences 实例
      let context: common.Context = getContext(this) as common.Context;
      let prefs = await preferences.getPreferences(context, Pref.Name);

      // 更新已经保存的值
      for (let cfgValue of Object.values(AppCfg)) {
        let savedValue = await prefs.get(cfgValue, AppCfgManager.getDefaultValue(cfgValue));
        this.dict.set(cfgValue, savedValue as number);
      }
    } catch (err) {
      console.error(`加载偏好设置失败: ${err.message}`);
    }
  }

  // 判断时间间隔，一次获取所有ServerConfigs
  loadConfigsIfNeeds(): void {
    // 检查网络连接
    if (!NetWorkTool.checkInternetConnection(false)) {
      return;
    }

    ///7天检查是否到时间需要，从服务器更新Configs
    if (TimeToManager.isTimeTo(TimeToType.updateServerConfigs)) {
      this.refreshServerCfgs();
      TimeToManager.saveTime(TimeToType.updateServerConfigs, true);
    }

    // 在 ArkTS 中，网络检查和定时器功能需要根据具体API实现
    console.log("loadConfigsIfNeeds - 需要实现网络检查和定时逻辑");
  }

  // 立即执行一次ServerCfg查询
  public refreshServerCfgs(): void {
    // 从服务器或缓存中加载 configs
    ServerCfgManager.loadServerCfgs( (success: boolean, msg: string | null, serverCfgs: ServerCfg[] | null) => {

      if (success) {
        if (serverCfgs) {

          // 遍历所有 AppCfg 枚举
          Object.keys(AppCfg).forEach((appCfg) => {

            // 找到 server 返回的对应 key
            const serverCfg = serverCfgs.find(sc => sc.key === appCfg.valueOf());

            if (serverCfg) {
              // 如果 server 上有 key，但无 value 返回，则默认为 0
              // ［这是 server 上的 bug，暂时未改 by ko 2022.09.10］
              //this.dict[appCfg.valueOf()] = serverCfg.value ?? 0; // 更新 server 上的值
              this.dict.set(appCfg.valueOf(), serverCfg.value ?? 0);// 更新 server 上的值
            }
          });
        }

        // 保存到本地 Preferences
        this.savePreference();

        /// 发送配置更新通知，有需要的地方（如：Marquee Notice）可以即时获得通知
        //NotificationCenter.post(AppCfgManager.Notification.Name.AppCfgUpdated, this);

        Toast.showDebugMessage("刷新ServerCfg成功");
        //LogEvent.log(LogEvent.Id.appCfgResfeshSucceed);

      } else {
        if (msg) {
          Toast.showDebugMessage(msg);
        }

        //LogEvent.log(LogEvent.Id.appCfgResfeshFailed);
      }
    });

    // 在 ArkTS 中，网络请求需要使用 @ohos.net.http 模块
    console.log("refreshServerCfgs - 需要实现服务器配置获取逻辑");
  }

  // MARK: - 获取函数

  /// 获取 [通用]听写Merged检测Api是否使用Handwriting
  isDictationDetectMergedApiUseHandwriting(): boolean {
    let value = this.dict.get(AppCfg.Dictation_Detect_Merged_Api_GeneralOrHandwriting) ??
    AppCfgManager.getDefaultValue(AppCfg.Dictation_Detect_Merged_Api_GeneralOrHandwriting);
    return value === 1;
  }

  /// 获取 [通用] 内置课本 在SaveToBooks（CopyTo，ImportCsv）时是否显示
  isInAppBooks_Show_In_SaveToBooks(): boolean {
    let value = this.dict.get(AppCfg.InAppBooks_Show_In_SaveToBooks) ??
    AppCfgManager.getDefaultValue(AppCfg.InAppBooks_Show_In_SaveToBooks);
    return value === 1;
  }

  /// 获取 [通用] 内置课本 可否分享到 在线课本
  isInAppBooks_Can_ShareOnline(): boolean {
    let value = this.dict.get(AppCfg.InAppBooks_Can_ShareOnline) ??
    AppCfgManager.getDefaultValue(AppCfg.InAppBooks_Can_ShareOnline);
    return value === 1;
  }

  /// 获取 [通用] 用户卡片 可否分享到 在线课本
  isCreatedUserCard_Can_ShareOnline(): boolean {
    let value = this.dict.get(AppCfg.CreatedUserCards_Can_ShareOnline) ??
    AppCfgManager.getDefaultValue(AppCfg.CreatedUserCards_Can_ShareOnline);
    return value === 1;
  }

  /// 获取 [通用] 在线课本是否可查看或下载
  isBookOnline_Download_ON(): boolean {
    let value = this.dict.get(AppCfg.BookOnline_Download_is_ON) ??
    AppCfgManager.getDefaultValue(AppCfg.BookOnline_Download_is_ON);
    return value === 1;
  }

  /// 获取 [通用]在线课本是否可以发布
  isBookOnline_Publish_ON(): boolean {
    let value = this.dict.get(AppCfg.BookOnline_Publish_is_ON) ??
    AppCfgManager.getDefaultValue(AppCfg.BookOnline_Publish_is_ON);
    return value === 1;
  }

  /// 获取 [通用]如何制作csv并发布到手机 在Instruction中对应的idx
  getHowTo_CreateCSV_idx_in_Instruction(): number {
    return this.dict.get(AppCfg.Android_HowTo_CreateCSV_idx_in_Instruction) ??
    AppCfgManager.getDefaultValue(AppCfg.Android_HowTo_CreateCSV_idx_in_Instruction);
  }

  /// 获取 [通用]如何导入他人分享的数据? 在Instruction中对应的idx
  getHowTo_Imort_SharedData_idx_in_Instruction(): number {
    return this.dict.get(AppCfg.Android_HowTo_Imort_SharedData_idx_in_Instruction) ??
    AppCfgManager.getDefaultValue(AppCfg.Android_HowTo_Imort_SharedData_idx_in_Instruction);
  }

  /// 获取 [通用] 分享应用link 在Instruction中对应的idx
  getAndroid_ShareAppLink_idx_in_Instruction(): number {
    return this.dict.get(AppCfg.Android_ShareAppLink_idx_in_Instruction) ??
    AppCfgManager.getDefaultValue(AppCfg.Android_ShareAppLink_idx_in_Instruction);
  }

  /// 获取 [通用]Android首页滚动公告idx(Instruction表)
  getHomeNoticeIdx_In_Instruction(): number {
    return this.dict.get(AppCfg.Android_Home_Notice_idx_in_Instruction) ??
    AppCfgManager.getDefaultValue(AppCfg.Android_Home_Notice_idx_in_Instruction);
  }

  /// 获取 [通用] 是否启用 自动刷新会员订阅时间
  isAutoRefreshSubscriptionInfo_is_ON(): boolean {
    let value = this.dict.get(AppCfg.AutoRefreshSubscriptionInfo_is_ON) ??
    AppCfgManager.getDefaultValue(AppCfg.AutoRefreshSubscriptionInfo_is_ON);
    return value === 1;
  }

  /// 获取 [通用]自动刷新 服务器上的会员订阅的 时间间隔（只读） 单位：分钟
  getAutoRefreshSubscriptionInfo_Interval_Minutes(): number {
    return this.dict.get(AppCfg.AutoRefreshSubscriptionInfo_Interval_Minutes) ??
    AppCfgManager.getDefaultValue(AppCfg.AutoRefreshSubscriptionInfo_Interval_Minutes);
  }

  /// 获取 [通用] 是否启用 审核检查for注册 (用户名)
  isCosAuditCheckForSignup_is_ON(): boolean {
    let value = this.dict.get(AppCfg.CosAuditCheckForSignup_is_ON) ??
    AppCfgManager.getDefaultValue(AppCfg.CosAuditCheckForSignup_is_ON);
    return value === 1;
  }

  /// 获取 [通用] 是否启用 审核检查for登录 (用户名和头像)
  isCosAuditCheckForLogin_is_ON(): boolean {
    let value = this.dict.get(AppCfg.CosAuditCheckForLogin_is_ON) ??
    AppCfgManager.getDefaultValue(AppCfg.CosAuditCheckForLogin_is_ON);
    return value === 1;
  }

  /// [通用] 是否启用 CBook[总开关]（Cos下载的Book）
  isCBook_Useable_is_ON(): boolean {
    let value = this.dict.get(AppCfg.CBook_Useable_is_ON) ??
    AppCfgManager.getDefaultValue(AppCfg.CBook_Useable_is_ON);
    return value === 1;
  }

  /// [通用] 是否启用 CBook自动更新检查
  isCBook_AutoUpdateCheck_is_ON(): boolean {
    let value = this.dict.get(AppCfg.CBook_AutoUpdateCheck_is_ON) ??
    AppCfgManager.getDefaultValue(AppCfg.CBook_AutoUpdateCheck_is_ON);
    return value === 1;
  }

  /// [通用] CBook自动更新检查 时间间隔 单位：分钟
  getCBook_AutoUpdateCheck_Interval_Minutes(): number {
    return this.dict.get(AppCfg.CBook_AutoUpdateCheck_Interval_Minutes) ??
    AppCfgManager.getDefaultValue(AppCfg.CBook_AutoUpdateCheck_Interval_Minutes);
  }

  /// [通用] 是否启用 CBookList自动更新检查
  isCBookList_AutoUpdateCheck_is_ON(): boolean {
    let value = this.dict.get(AppCfg.CBookList_AutoUpdateCheck_is_ON) ??
    AppCfgManager.getDefaultValue(AppCfg.CBookList_AutoUpdateCheck_is_ON);
    return value === 1;
  }

  /// [通用] 是否启用 CBookIcon自动更新检查
  isCBookIcon_AutoUpdateCheck_is_ON(): boolean {
    let value = this.dict.get(AppCfg.CBookIcon_AutoUpdateCheck_is_ON) ??
    AppCfgManager.getDefaultValue(AppCfg.CBookIcon_AutoUpdateCheck_is_ON);
    return value === 1;
  }

  // MARK: - 获取函数 - 会员相关

  /// 获取 会员 可使用的听写OneByOne检测总次数
  getMember_DictationDetectOneByOne_TotalCnt(): number {
    return this.dict.get(AppCfg.M_Dictation_Detect_OneByOne_Total_Cnt) ??
    AppCfgManager.getDefaultValue(AppCfg.M_Dictation_Detect_OneByOne_Total_Cnt);
  }

  // MARK: - 获取函数 - 非会员相关

  /// 获取 非会员 总共可执行的听写识别 检测总次数
  getNonMember_DictationScanTimes_TotalCnt(): number {
    return this.dict.get(AppCfg.N_Dictation_ScanTimes_Total_Cnt) ??
    AppCfgManager.getDefaultValue(AppCfg.N_Dictation_ScanTimes_Total_Cnt);
  }

  // MARK: - 获取函数 - 非会员购买相关

  /// 获取 非会员(订阅) 总最大学习集个数
  getNonMember_Purchase_MaxBookCount(): number {
    return this.dict.get(AppCfg.N_P_maxBookCount) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxBookCount);
  }

  /// 获取 非会员(订阅) 每个学习集中的最大组数
  getNonMember_Purchase_MaxGroupCountPerBook(): number {
    return this.dict.get(AppCfg.N_P_maxGroupCountPerBook) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxGroupCountPerBook);
  }

  /// 获取 非会员(订阅) 内置课本中可使用的最大单元数
  getNonMember_Purchase_MaxUnitCountInAppBook(): number {
    return this.dict.get(AppCfg.N_P_maxUnitCountInAppBook) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxUnitCountInAppBook);
  }

  /// 非会员(订阅) 每日 查看汉字发音 个数
  getNonMember_Purchase_MaxWordPronCountDaily(): number {
    return this.dict.get(AppCfg.N_P_maxWordPronCountDaily) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxWordPronCountDaily);
  }

  /// 非会员(订阅) 每日 查看汉字笔画 个数
  getNonMember_Purchase_MaxWordStrokeCountDaily(): number {
    return this.dict.get(AppCfg.N_P_maxWordStrokeCountDaily) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxWordStrokeCountDaily);
  }

  /// 非会员(订阅) 每日 查看词语/成语发音 个数
  getNonMember_Purchase_MaxPhrasePronCountDaily(): number {
    return this.dict.get(AppCfg.N_P_maxPhrasePronCountDaily) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxPhrasePronCountDaily);
  }

  /// 非会员(订阅) 每日 可使用的听写次数
  getNonMember_Purchase_MaxDictationTimesDaily(): number {
    return this.dict.get(AppCfg.N_P_maxDictationTimesDaily) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxDictationTimesDaily);
  }

  /// 非会员(订阅) 可以创建的计划个数
  getNonMember_Purchase_MaxPlanCount(): number {
    return this.dict.get(AppCfg.N_P_maxPlanCount) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxPlanCount);
  }

  /// 非会员(订阅) 可以使用的DayOf数
  getNonMember_Purchase_MaxPlanDayOfsCount(): number {
    return this.dict.get(AppCfg.N_P_maxPlanDayOfsCount) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxPlanDayOfsCount);
  }

  /// 非会员(订阅) 可以创建的"我的课本"最大个数
  getNonMember_Purchase_MaxEBookCount(): number {
    return this.dict.get(AppCfg.N_P_maxEBookCount) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxEBookCount);
  }

  /// 非会员(订阅) 每个课本中可以新增的"字表"最大个数
  getNonMember_Purchase_MaxEPartCountPerBook(): number {
    return this.dict.get(AppCfg.N_P_maxEPartCountPerBook) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxEPartCountPerBook);
  }

  /// 非会员(订阅) 每个字表中可以添加的"汉字组"最大个数
  getNonMember_Purchase_MaxELessonCountPerPart(): number {
    return this.dict.get(AppCfg.N_P_maxELessonCountPerPart) ??
    AppCfgManager.getDefaultValue(AppCfg.N_P_maxELessonCountPerPart);
  }
}

