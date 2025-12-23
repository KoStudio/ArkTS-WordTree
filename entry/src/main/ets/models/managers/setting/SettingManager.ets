import preferences from '@ohos.data.preferences';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import { getAppContext } from '../../../app/constants/AppContext';

// ============================================================
// MARK: - Pref - 设置键常量
// ============================================================
class Pref {

  static readonly PREF_NAME                    : string = "PrefSettingManager";               // 设置名称

  static readonly KEY_SETTING_AUTOPRONOUNCE    : string = "PreKey_wordCardautoPronounce";     // 自动发音
  static readonly KEY_SETTING_AUTOPRONOUNCEEX  : string = "PreKey_wordCardautoPronounceEx";   // 扩展自动发音
  static readonly KEY_SETTING_AUTOPLAYINTERVAL : string = "PreKey_wordCardPlayInterval";      // 自动播放间隔
  static readonly KEY_SETTING_ROLLREPEAT       : string = "PreKey_wordCardRollRepeat";        // 是否循环
  static readonly KEY_SETTING_HIDETRANSLATION  : string = "PreKey_wordCardHideTranslation";   // 隐藏翻译

  static readonly KEY_SETTING_PRONSPEED        : string = "PreKey_wordCardPronSpeed";         // 发音速度
  static readonly KEY_SETTING_PRONTIMES        : string = "PreKey_wordCardPronTimes";         // 发音次数
  static readonly KEY_SETTING_PRONGAP          : string = "PreKey_wordCardPronGap";           // 发音间隔

  static readonly KEY_SETTING_DETAILSTYLE      : string = "PreKey_DetailStyle";               // 详情样式
  static readonly KEY_SETTING_PLANQUICKLEARN   : string = "PreKey_PlanQuickLearn";            // 快速学习
  static readonly KEY_SETTING_ENABLECURVE      : string = "PreKey_EnableCurve";               // 遗忘曲线

  static readonly KEY_SETTING_SOUNDEFFECT      : string = "PreKey_soundEffect";               // 声音效果
  static readonly KEY_SETTING_FONTSIZE         : string = "PreKey_fontSize";                  // 字体大小
  static readonly KEY_SETTING_PUZZELSPEED      : string = "PreKey_puzzelSpeed";               // 拼图速度
  static readonly KEY_SETTING_AUTOUPDATE       : string = "PreKey_autoUpdate";                // 自动更新
}

// ============================================================
// MARK: - SettingManager - 设置管理器（单例）
// ============================================================
@ObservedV2
export class SettingManager {

  // MARK: - 单例
  private static instance                      : SettingManager;

  public static get shared(): SettingManager {
    if (!SettingManager.instance) {
      SettingManager.instance = new SettingManager();
    }
    return SettingManager.instance;
  }

  // MARK: - Preferences
  public preferences                           : preferences.Preferences | null = null;

  // MARK: - 基础设置
  @Trace public hideTranslation                : boolean = false;
  @Trace public autoPlaySound                  : boolean = false;
  @Trace public autoPlaySoundEx                : boolean = false;
  @Trace public autoPlayInterval               : number  = 5000;
  @Trace public rollRepeat                     : boolean = false;

  // MARK: - 发音相关
  @Trace public pronSpeed                      : number  = 1;      // NORMAL
  @Trace public pronTimes                      : number  = 1;
  @Trace public pronGap                        : number  = 0;      // SHORT

  // MARK: - 学习策略
  @Trace public detailStyle                    : number  = 0;
  @Trace public planQuickLearn                 : boolean = false;
  @Trace public enableCurve                    : boolean = true;

  // MARK: - 显示 & 其他
  @Trace public soundEffect                    : boolean = true;
  // @Trace public fontSize                       : number  = 18;
  @Trace public puzzleSpeed                    : number  = 0;
  @Trace public autoUpdate                     : boolean = true;

  // MARK: - 构造
  private constructor() {
    this.initPreferences(getAppContext());
  }

  // MARK: - 初始化 Preferences
  private initPreferences(context: common.Context): void {
    try {
      this.preferences = preferences.getPreferencesSync(context, { name: Pref.PREF_NAME });
      this.loadPreference();
    } catch (err) {
      console.error('初始化 Preferences 失败:', (err as BusinessError).message);
    }
  }

  // MARK: - 加载设置
  private loadPreference(): void {
    if (!this.preferences) return;

    try {
      this.hideTranslation  = this.preferences.getSync(Pref.KEY_SETTING_HIDETRANSLATION , false) as boolean;
      this.autoPlaySound    = this.preferences.getSync(Pref.KEY_SETTING_AUTOPRONOUNCE   , false) as boolean;
      this.autoPlaySoundEx  = this.preferences.getSync(Pref.KEY_SETTING_AUTOPRONOUNCEEX , false) as boolean;
      this.autoPlayInterval = this.preferences.getSync(Pref.KEY_SETTING_AUTOPLAYINTERVAL, 5000 ) as number;
      this.rollRepeat       = this.preferences.getSync(Pref.KEY_SETTING_ROLLREPEAT      , false) as boolean;

      this.pronSpeed        = this.preferences.getSync(Pref.KEY_SETTING_PRONSPEED       , 1     ) as number;
      this.pronTimes        = this.preferences.getSync(Pref.KEY_SETTING_PRONTIMES       , 1     ) as number;
      this.pronGap          = this.preferences.getSync(Pref.KEY_SETTING_PRONGAP         , 0     ) as number;

      this.detailStyle      = this.preferences.getSync(Pref.KEY_SETTING_DETAILSTYLE     , 0     ) as number;
      this.planQuickLearn   = this.preferences.getSync(Pref.KEY_SETTING_PLANQUICKLEARN  , false ) as boolean;
      this.enableCurve      = this.preferences.getSync(Pref.KEY_SETTING_ENABLECURVE     , true  ) as boolean;

      this.soundEffect      = this.preferences.getSync(Pref.KEY_SETTING_SOUNDEFFECT     , true  ) as boolean;
      // this.fontSize         = this.preferences.getSync(Pref.KEY_SETTING_FONTSIZE        , 18    ) as number;
      this.puzzleSpeed      = this.preferences.getSync(Pref.KEY_SETTING_PUZZELSPEED     , 0     ) as number;
      this.autoUpdate       = this.preferences.getSync(Pref.KEY_SETTING_AUTOUPDATE      , true  ) as boolean;

    } catch (err) {
      console.error('加载设置失败:', (err as BusinessError).message);
    }
  }

  // MARK: - 保存设置
  public async save(): Promise<void> {
    if (!this.preferences) return;

    try {
      await this.preferences.put(Pref.KEY_SETTING_HIDETRANSLATION , this.hideTranslation);
      await this.preferences.put(Pref.KEY_SETTING_AUTOPRONOUNCE  , this.autoPlaySound);
      await this.preferences.put(Pref.KEY_SETTING_AUTOPRONOUNCEEX, this.autoPlaySoundEx);
      await this.preferences.put(Pref.KEY_SETTING_AUTOPLAYINTERVAL, this.autoPlayInterval);
      await this.preferences.put(Pref.KEY_SETTING_ROLLREPEAT     , this.rollRepeat);

      await this.preferences.put(Pref.KEY_SETTING_PRONSPEED      , this.pronSpeed);
      await this.preferences.put(Pref.KEY_SETTING_PRONTIMES      , this.pronTimes);
      await this.preferences.put(Pref.KEY_SETTING_PRONGAP        , this.pronGap);

      await this.preferences.put(Pref.KEY_SETTING_DETAILSTYLE    , this.detailStyle);
      await this.preferences.put(Pref.KEY_SETTING_PLANQUICKLEARN , this.planQuickLearn);
      await this.preferences.put(Pref.KEY_SETTING_ENABLECURVE    , this.enableCurve);

      await this.preferences.put(Pref.KEY_SETTING_SOUNDEFFECT    , this.soundEffect);
      // await this.preferences.put(Pref.KEY_SETTING_FONTSIZE       , this.fontSize);
      await this.preferences.put(Pref.KEY_SETTING_PUZZELSPEED    , this.puzzleSpeed);
      await this.preferences.put(Pref.KEY_SETTING_AUTOUPDATE     , this.autoUpdate);

      await this.preferences.flush();
    } catch (err) {
      console.error('保存设置失败:', (err as BusinessError).message);
    }
  }

  // MARK: - 恢复默认设置
  async restoreDefaultSettings(): Promise<void> {
    this.hideTranslation  = false;
    this.autoPlaySound    = false;
    this.autoPlaySoundEx  = false;
    this.autoPlayInterval = 5000;
    this.rollRepeat       = false;

    this.pronSpeed        = 1;
    this.pronTimes        = 1;
    this.pronGap          = 0;

    this.detailStyle      = 0;
    this.planQuickLearn   = false;
    this.enableCurve      = true;

    this.soundEffect      = true;
    // this.fontSize         = 18;
    this.puzzleSpeed      = 0;
    this.autoUpdate       = true;

    await this.save();
  }

  // MARK: - 会员 -> 非会员
  async restoreSettingsForNonMember(): Promise<void> {
    this.autoPlaySound    = false;
    this.autoPlaySoundEx  = false;
    this.hideTranslation  = false;

    await this.save();
  }
}