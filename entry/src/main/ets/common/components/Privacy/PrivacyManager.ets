import preferences from '@ohos.data.preferences';
import { getAppContext } from '../../../app/constants/AppContext';
import { common } from '@kit.AbilityKit';


const kPrefPrivacyName  = "privacy_settings"
const kPrefKey_isAgreed = "privacy_agreed21"

export class PrivacyManager {
  private static instance: PrivacyManager;
  private prefs: preferences.Preferences | null = null;

  // 单例模式实现
  static get shared(): PrivacyManager {
    if (!PrivacyManager.instance) {
      PrivacyManager.instance = new PrivacyManager();
    }
    return PrivacyManager.instance;
  }

  private constructor() {
    const context = getAppContext()
    this.prefs = preferences.getPreferencesSync(context, {name: kPrefPrivacyName});
  }

  checkAgreement(): boolean {
    if (!this.prefs) return false;

    try {
      const result = this.prefs.getSync(kPrefKey_isAgreed, false);
      return !!result; // !!值转换为布尔类型
    } catch (err) {
      console.error(`读取隐私状态失败: ${err.code}`);
      return false;
    }
  }


   handleAgree(agree: boolean){
    if (this.prefs) {
      if (agree) {
        this.prefs.putSync(kPrefKey_isAgreed, true);
        this.prefs.flushSync();
        console.info('隐私协议已同意');
      }else{
        console.info('隐私协议不同意，退出应用');

        const context = getAppContext() as common.UIAbilityContext;
        if (context) {
          context.terminateSelf();
          ///退出应用
        }

      }

    }
  }

}