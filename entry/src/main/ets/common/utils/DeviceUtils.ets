import { deviceInfo } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { preferences } from '@kit.ArkData';
import { AppSettings } from '../../app/constants/AppSettings';


const PREF_FILE = 'app_device_prefs';

// 配置键名常量类
class Pref {
  static readonly Name            : string = "app_device_prefs"; // 偏好存储名称
  static readonly KEY_DEVICE_UUID : string = 'device_uuid';
}

/**
 * HarmonyOS 设备信息工具类 (Stage模型)
 * 功能等效于原Android的DeviceUtility
 */
export class DeviceUtil {
  // 设备类型常量
  private static readonly DEVICE_TYPE = AppSettings.App.deviceType;



  static getStableUUID(): string {
    // 打开或创建 Preferences 存储（持久化）
    let pref =  preferences.getPreferencesSync(getContext(), {name: Pref.Name});

    // 尝试读取已保存的 UUID
    let uuid = pref.getSync(Pref.KEY_DEVICE_UUID, '') as string;
    if (uuid && uuid.length > 0) {
      return uuid; // 已存在，直接返回
    }

    // 否则生成新的 UUID
    uuid = util.generateRandomUUID(); // HarmonyOS 提供的安全随机 UUID 方法

    // 保存到本地持久化
    pref.putSync(Pref.KEY_DEVICE_UUID, uuid);
    pref.flush(); // ⚠️ 必须调用 flush() 才会真正写入磁盘

    return uuid;
  }

  /**
   * 获取设备类型
   */
  static getDeviceType(): string {
    return DeviceUtil.DEVICE_TYPE;
  }

  static getUUID(): string {
    const uuid = DeviceUtil.getStableUUID()//util.generateRandomUUID(true);
    return uuid
  }

  /**
   * 获取设备品牌 (等效Android的getPhoneBrand)
   */
  static getPhoneBrand(): string {
    return deviceInfo.brand.toLowerCase() || 'unknown';
  }

  /**
   * 判断是否为华为设备 (精确匹配)
   */
  static isHuaweiDevice(): boolean {
    return DeviceUtil.getPhoneBrand() === 'huawei';
  }

  /**
   * 判断是否为荣耀设备
   */
  static isHonorDevice(): boolean {
    return DeviceUtil.getPhoneBrand() === 'honor';
  }

  /**
   * 判断是否为小米设备
   */
  static isXiaomiDevice(): boolean {
    return DeviceUtil.getPhoneBrand() === 'xiaomi';
  }

  /**
   * 判断是否为vivo设备
   */
  static isVivoDevice(): boolean {
    return DeviceUtil.getPhoneBrand() === 'vivo';
  }

  /**
   * 判断是否为OPPO设备
   */
  static isOppoDevice(): boolean {
    return DeviceUtil.getPhoneBrand() === 'oppo';
  }

  static getSdkApiVersion(): number {
    return deviceInfo.sdkApiVersion
  }

  // static getDeviceTypeHard(): string {
  //   return deviceInfo.deviceType //phone, 2in1,tablet,car,wearable
  // }

}