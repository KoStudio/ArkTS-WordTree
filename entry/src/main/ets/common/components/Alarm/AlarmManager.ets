import common from '@ohos.app.ability.common';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import preferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';
import PermissionManager from './PermissionManager';
import { getAppContext } from '../../../app/constants/AppContext';
import { DebugLog } from '../../../app/debug/DebugLog';

export default class AlarmManager {
  private static instance: AlarmManager | null = null; // 单例实例
  private context: common.UIAbilityContext; // 应用上下文
  private prefs: preferences.Preferences | null = null; // 轻量存储实例

  // 私有构造方法
  private constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.prefs   = preferences.getPreferencesSync(context, {name: 'alarm_prefs'})
      // .then(prefs => this.prefs = prefs)
      // .catch((err: BusinessError) => DebugLog.e(`Preferences初始化失败: ${err.code}`));
  }

  // 获取单例
  static get shared(): AlarmManager {
    if (!AlarmManager.instance) {
      AlarmManager.instance = new AlarmManager(getAppContext() as common.UIAbilityContext);
    }
    return AlarmManager.instance;
  }

  // 保存闹钟时间
  private async saveAlarmTime(date: Date): Promise<void> {
    if (!this.prefs) throw new Error('Preferences未初始化');
    await this.prefs.put('hour', date.getHours());
    await this.prefs.put('minute', date.getMinutes());
    await this.prefs.flush();
  }

  // 获取保存的闹钟时间
  public getSavedAlarmTime(): Date {
    if (!this.prefs) throw new Error('Preferences未初始化');
    const hour = Number(this.prefs.getSync('hour', 18)); // 默认18点
    const minute = Number(this.prefs.getSync('minute', 0)); // 默认0分
    const now = new Date();
    now.setHours(hour);
    now.setMinutes(minute);
    now.setSeconds(0);
    now.setMilliseconds(0);
    return now;
  }

  // 保存提醒ID
  private async saveReminderId(reminderId: number): Promise<void> {
    if (!this.prefs) throw new Error('Preferences未初始化');
    await this.prefs.put('reminderId', reminderId);
    await this.prefs.flush();
  }

  // 获取保存的提醒ID
  private async getSavedReminderId(): Promise<number | null> {
    if (!this.prefs) throw new Error('Preferences未初始化');
    const id = await this.prefs.get('reminderId', null);
    return typeof id === 'number' ? id : null;
  }

  // 设置系统提醒（核心方法）
  async setReminder(date: Date): Promise<void> {
    try {
      if (!this.isReminderEnabled()) {
        DebugLog.i('提醒开关为关闭状态，跳过设置');
        return;
      }

      // === 恢复权限检查 ===
      const granted = this.isGrantedNotificationPermission();
      if (!granted) {
        DebugLog.e('通知权限未授权，跳过设置提醒');
        return;
      }

      // 配置提醒参数[1,6](@ref)
      const reminder: reminderAgentManager.ReminderRequestAlarm = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
        hour: date.getHours(),
        minute: date.getMinutes(),
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // 每天重复
        title: '每日提醒',
        content: '学习时间到！',
        notificationId: 1001,
        wantAgent: { // 点击通知跳转目标
          pkgName: this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name
        }
      };

      await this.saveAlarmTime(date);

      const reminderId = await reminderAgentManager.publishReminder(reminder); // 发布提醒[1](@ref)
      await this.saveReminderId(reminderId);

      DebugLog.i(`提醒设置成功，ID: ${reminderId}`);
    } catch (err) {
      DebugLog.e(`设置失败: ${(err as BusinessError).message}`);
    }
  }

  private async isGrantedNotificationPermission(): Promise<boolean> {
    return await PermissionManager.checkPermission('ohos.permission.PUBLISH_AGENT_REMINDER')
  }
  // 请求通知权限
  private async requestNotificationPermission(): Promise<boolean> {
    return await PermissionManager.requestNotificationPermission(this.context, $r('app.string.set_msg_permission_notification'));
  }

  // 取消当前提醒
  public async cancelReminderById(): Promise<void> {
    if (!this.prefs) throw new Error('Preferences未初始化');
    const reminderId = await this.getSavedReminderId();
    if (reminderId != null) {
      try {
        await reminderAgentManager.cancelReminder(reminderId); // 取消指定提醒[1](@ref)
        await this.prefs.put('reminderId', null);
        await this.prefs.flush();
        DebugLog.i(`取消提醒成功，ID: ${reminderId}`);
      } catch (e) {
        DebugLog.e(`取消提醒失败: ${(e as Error).message}`);
      }
    }
  }

  // 设置提醒开关
  public async setReminderEnabled(enabled: boolean): Promise<boolean> {
    if (!this.prefs) throw new Error('Preferences未初始化');

    if (enabled) {
      const granted = await this.requestNotificationPermission(); // 检查权限
      if (!granted) return false;
    }

    await this.prefs.put('reminderOn', enabled);
    await this.prefs.flush();

    if (!enabled){
      await this.cancelReminderById(); // 关闭时取消提醒
      return false
    }
    return true
  }

  // 检查提醒开关状态
  public isReminderEnabled(): boolean {
    if (!this.prefs) throw new Error('Preferences未初始化');
    return Boolean(this.prefs.getSync('reminderOn', true)); // 默认开启
  }
}