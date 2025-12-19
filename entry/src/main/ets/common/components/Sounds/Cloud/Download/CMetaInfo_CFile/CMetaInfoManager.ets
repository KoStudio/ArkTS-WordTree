import preferences from '@ohos.data.preferences';
import { isDebugMode } from '../../../../../../app/constants/AppDefines';
import { TimeToManager } from '../../../../../../models/managers/timeto/TimeToManager';
import { DateUtils } from '../../../../../utils/DateUtils';
import { CMetaInfo } from './CMetaInfo';


// MARK: - CMetaInfo 管理器
export class CMetaInfoManager {
  /// 偏好存储的名字
  private prefName: string;

  /// 初始化时传入 PrefName
  constructor(prefName: string) {
    this.prefName = prefName;
  }

  /// 获取当前 name 的 Book 的 TimeToKey
  /// 用于记录是否到时间可以 Check 一次了
  public getTimeToKeyFor(name: string): string {
    return `TimeTo_Check__${name}`;
  }

  /// 比较本地保存的更新时间和服务器上的更新时间，判断是否需要更新
  public async isNeedUpdateForMeta(info: CMetaInfo): Promise<boolean> {
    const savedStr    = await this.getUpdateDateFromSavedMeta(info);
    const updateDateStr = info.updateDate;

    if (savedStr && updateDateStr) {
      const savedDate   = DateUtils.toDateFromUTC(savedStr);
      const updateDate  = DateUtils.toDateFromUTC(updateDateStr);

      if (savedDate && updateDate) {
        // 腾讯服务器很奇怪，通过 Get 获取到的日期是 GMT+0000，这里需要 +8 小时才能和 Download 时的时间一样，应该是 Bug. by ko 20.12.20
        const fixedUpdateDate = updateDate;
        // 目前，Get 获取的日期与 Download 时的时间一样，都是 GMT+0000, 所以这里可以不用 +8:00 小时了 (Cos 上需要重新上传一次) by ko 2024.09.

        /// 各个 CDN 下载服务器的时间可能会有延迟，这将已经保存的日期往后 +60 分钟，这样确保下载保存的时间不会比列表获取的时间还要新
        /// 如果 getMeta 时用的 CDN 服务器与 download 时用的 CDN 服务器不同，可能导致，同一个文件被多次重复下载
        const fixedSavedDate  = DateUtils.addMinutes(savedDate, isDebugMode ? 0 : 60) //savedDate.addMinutes(isDebug() ? 0 : 60);
        return DateUtils.isGreater(fixedUpdateDate, fixedSavedDate)
        //return fixedUpdateDate.isGreaterThanDate(fixedSavedDate);
      }
    }

    return true; // 如果本地不存在，则需要更新
  }

  /// 保存 Meta 信息
  public async saveMetaInfo(info: CMetaInfo): Promise<void> {
    if (!info.fileName || !info.updateDate) return;

    const context = getContext(this);
    const prefs   = await preferences.getPreferences(context, this.prefName);

    // 直接以 fileName 为 key 存储 updateDate
    await prefs.put(info.fileName, info.updateDate);
    await prefs.flush();
  }

  /// 删除 Meta 信息
  public async removeMetaInfo(info: CMetaInfo): Promise<void> {
    if (!info.fileName) return;

    const context = getContext(this);
    const prefs   = await preferences.getPreferences(context, this.prefName);

    // 直接将该 key 对应的值置为 null
    await prefs.put(info.fileName, null);
    await prefs.flush();
  }

  /// 获取 Meta 信息中的更新时间
  public async getUpdateDateFromSavedMeta(info: CMetaInfo): Promise<string | null> {
    if (!info.fileName) return null;

    const context = getContext(this);
    const prefs   = await preferences.getPreferences(context, this.prefName);
    const value   = await prefs.get(info.fileName, null);

    if (typeof value === 'string') {
      return value
    }

    return null
  }

  /// 清除所有 CMeta，重新刷新
  public async clearAll(callback: (fileName: string) => void): Promise<void> {
    const context = getContext(this);
    const prefs   = await preferences.getPreferences(context, this.prefName);

    // 获取所有 key
    const keys: string[] = Object.keys(await prefs.getAll());

    for (const fileName of keys) {
      /// 先清空 回调
      callback(fileName);

      // 同时也清空刷新时间，这样可以立即刷新一次
      TimeToManager.clearSavedTimeByName(this.getTimeToKeyFor(fileName));

      // 删除该 key
      await prefs.put(fileName, null);
    }

    await prefs.flush();
  }
}