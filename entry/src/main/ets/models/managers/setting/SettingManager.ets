import preferences from '@ohos.data.preferences';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import { getAppContext } from '../../../app/constants/AppContext';

class Pref {
  // MARK: - 设置键常量
  static readonly PREF_NAME                    : string = "PrefSettingManager";               // 设置的名称
  static readonly KEY_SETTING_AUTOPRONOUNCE    : string = "PreKey_wordCardautoPronounce";     // 自动发音
  static readonly KEY_SETTING_AUTOPRONOUNCEEX  : string = "PreKey_wordCardautoPronounceEx";   // 扩展的自动发音
  static readonly KEY_SETTING_AUTOPLAYINTERVAL : string = "PreKey_wordCardPlayInterval";      // 自动播放间隔
  static readonly KEY_SETTING_ROLLREPEAT       : string = "PreKey_wordCardRollRepeat";        // 是否循环播放
  static readonly KEY_SETTING_HIDETRANSLATION  : string = "PreKey_wordCardHideTranslation";   // 是否隐藏翻译
  static readonly KEY_SETTING_SOUNDEFFECT      : string = "PreKey_soundEffect";               // 声音效果
  static readonly KEY_SETTING_FONTSIZE         : string = "PreKey_fontSize";                  // 字体大小
  static readonly KEY_SETTING_PUZZELSPEED      : string = "PreKey_puzzelSpeed";               // 拼图速度
}

// MARK: - SettingManager - 设置管理器（单例模式）
@ObservedV2
export class SettingManager {

  // MARK: - 单例实例
  private static instance                         : SettingManager;

  // MARK: - 获取单例实例
  public static get shared(): SettingManager {
    if (!SettingManager.instance) {
      SettingManager.instance = new SettingManager();       // 创建单例
    }
    return SettingManager.instance;
  }

  // MARK: - 私有构造函数
  private constructor() {
    this.initPreferences(getAppContext());                 // 初始化 Preferences
  }

  // MARK: - 公共成员变量
  public preferences                              : preferences.Preferences | null = null;

  // MARK: - 设置变量（公开直接访问）
  @Trace public autoPlaySound                            : boolean = false;
  @Trace public autoPlaySoundEx                          : boolean = false;
  @Trace public autoPlayInterval                         : number  = 5000;
  @Trace public rollRepeat                               : boolean = false;
  @Trace public hideTranslation                          : boolean = false;
  @Trace public soundEffect                              : boolean = true;
  @Trace public fontSize                                 : number  = 18;
  @Trace public puzzleSpeed                              : number  = 0;

  public save(){
    this.savePreference()
  }

  // MARK: - 初始化Preferences
  private initPreferences(context: common.Context): void {
    try {
      this.preferences = preferences.getPreferencesSync(context, { name: Pref.PREF_NAME });
      this.loadPreference();                                 // 加载已有设置
    } catch (err) {
      console.error('初始化Preferences失败:', (err as BusinessError).message);
    }
  }

  // MARK: - 从Preferences加载设置
  private loadPreference(): void {
    if (!this.preferences) return;

    try {
      this.autoPlaySound    = this.preferences.getSync(Pref.KEY_SETTING_AUTOPRONOUNCE,    false) as boolean;
      this.autoPlaySoundEx  = this.preferences.getSync(Pref.KEY_SETTING_AUTOPRONOUNCEEX,  false) as boolean;
      this.autoPlayInterval = this.preferences.getSync(Pref.KEY_SETTING_AUTOPLAYINTERVAL, 5000) as number;
      this.rollRepeat       = this.preferences.getSync(Pref.KEY_SETTING_ROLLREPEAT,       false) as boolean;
      this.hideTranslation  = this.preferences.getSync(Pref.KEY_SETTING_HIDETRANSLATION,  false) as boolean;
      this.soundEffect      = this.preferences.getSync(Pref.KEY_SETTING_SOUNDEFFECT,      true) as boolean;
      this.fontSize         = this.preferences.getSync(Pref.KEY_SETTING_FONTSIZE,         18) as number;
      this.puzzleSpeed      = this.preferences.getSync(Pref.KEY_SETTING_PUZZELSPEED,      0) as number;

      console.log('设置已加载');
    } catch (err) {
      console.error('加载设置失败:', (err as BusinessError).message);
    }
  }

  // MARK: - 保存设置到Preferences
  private async savePreference(): Promise<void> {
    if (!this.preferences) return;

    try {
      await this.preferences.put(Pref.KEY_SETTING_AUTOPRONOUNCE,    this.autoPlaySound);
      await this.preferences.put(Pref.KEY_SETTING_AUTOPRONOUNCEEX,  this.autoPlaySoundEx);
      await this.preferences.put(Pref.KEY_SETTING_AUTOPLAYINTERVAL, this.autoPlayInterval);
      await this.preferences.put(Pref.KEY_SETTING_ROLLREPEAT,       this.rollRepeat);
      await this.preferences.put(Pref.KEY_SETTING_HIDETRANSLATION,  this.hideTranslation);
      await this.preferences.put(Pref.KEY_SETTING_SOUNDEFFECT,      this.soundEffect);
      await this.preferences.put(Pref.KEY_SETTING_FONTSIZE,         this.fontSize);
      await this.preferences.put(Pref.KEY_SETTING_PUZZELSPEED,      this.puzzleSpeed);

      await this.preferences.flush();                              // 刷新保存的设置
      console.log('设置已保存');
    } catch (err) {
      console.error('保存设置失败:', (err as BusinessError).message);
    }
  }

  // MARK: - 恢复默认设置
  async restoreDefaultSettings(): Promise<void> {
    this.autoPlaySound    = false;
    this.autoPlaySoundEx  = false;
    this.autoPlayInterval = 5000;
    this.rollRepeat       = false;
    this.hideTranslation  = false;
    this.soundEffect      = true;
    this.fontSize         = 18;
    this.puzzleSpeed      = 0;

    // 保存默认设置
    await this.savePreference();
  }

  // MARK: -  会员 -> 非会员 恢复默认设置
  async restoreSettingsForNonMember(): Promise<void> {
    this.autoPlaySound    = false;
    this.autoPlaySoundEx  = false;
    this.hideTranslation  = false;

    // 保存默认设置
    await this.savePreference();
  }
}