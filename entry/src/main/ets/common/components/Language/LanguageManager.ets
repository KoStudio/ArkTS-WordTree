// LanguageManager.ets
import i18n from '@ohos.i18n';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { AppLanguage } from './AppLanguage';
import { Want } from '@kit.AbilityKit';
import { BundleUtils } from '../../utils/BundleUtils';
import { getAppContext } from '../../../app/constants/AppContext';
import { SearchManager } from '../../../models/datas/model/SearchManager';
import { WordDbAccess } from '../../../models/datas/word/WordDbAccess';
import { BaseWordDbAccess } from '../../../models/datas/basedict/BaseWordDbAccess';
import { CigenData } from '../../../models/datas/book/Book';
import { CigenWordDbAccess } from '../../../models/datas/cigen/CigenWordDbAccess';
import { BookDbAccess } from '../../../models/datas/book/BookDbAccess';
import { SimpleEventBus } from '../eventbus/SimpleEventBus';

const PREF_NAME: string = "app_lang_pref";
const KEY_LANG: string = "lang";

export class LanguageManagerNotification {
    static readonly languageChanged = 'LanguageManager.Notification.language.changed'
}
export class LanguageManager {

  // 返回默认语言（简体）
  static getDefault(): AppLanguage {
    return AppLanguage.Simplified;
  }


  /**
   * 获取当前实际使用的语言
   */
  static getCurrentLanguage(): AppLanguage {
    try {
      // 1️⃣ 优先读取应用设置的首选语言
      const appLang = i18n.System.getAppPreferredLanguage();
      if (appLang) {
        if (appLang.startsWith("zh-Hant")) return AppLanguage.Traditional;
        return AppLanguage.Simplified; // 默认简体
      }

      // 2️⃣ 如果没有设置应用首选语言，则使用系统语言
      const systemLang = i18n.System.getSystemLanguage();
      if (systemLang.startsWith("zh-Hant")) return AppLanguage.Traditional;
      return AppLanguage.Simplified;

    } catch (err) {
      console.error("LanguageManager.getCurrentLanguage failed: " + (err instanceof Error ? err.message : err));
      // 异常情况下返回默认语言
      return LanguageManager.getDefault();
    }
  }


  /**
   * 在 App 启动时调用，应用用户保存的语言（若存在）
   */
  static async applySavedLanguage(): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(getAppContext(), PREF_NAME);
      const savedLang = (await prefs.get(KEY_LANG, "")) as string;
      if (savedLang === "" ) {
        // 未保存，使用默认（不强制设置，保持系统/资源默认）
        return;
      }
      // savedLang 是形如 "zh-Hans" 或 "zh-Hant"
      i18n.System.setAppPreferredLanguage(savedLang);
    } catch (err) {
      console.error("LanguageManager.applySavedLanguage failed: " + err.message);
    }
  }

  /**
   * 切换语言：保存偏好 -> 设置首选语言 -> 重启 EntryAbility（使资源生效）
   */
  static async switchLanguage(lang: AppLanguage): Promise<void> {
    try {
      let context = getAppContext()

      // 保存偏好
      await LanguageManager.saveLanguage(lang);

      // 设置应用首选语言
      i18n.System.setAppPreferredLanguage(lang);

      //重置数据
      LanguageManager.resetDatas()

      // 重启 EntryAbility 使新语言生效
      // await LanguageManager.restartEntryAbility(context);

      SimpleEventBus.emit(LanguageManagerNotification.languageChanged)
    } catch (err) {
      console.error("LanguageManager.switchLanguage failed: " + err.message);
    }
  }

  // 保存语言到 preferences
  private static async saveLanguage(lang: AppLanguage): Promise<void> {
    try {
      let context = getAppContext()
      const prefs = await preferences.getPreferences(context, PREF_NAME);
      await prefs.put(KEY_LANG, lang);
      await prefs.flush();
    } catch (err) {
      console.error("LanguageManager.saveLanguage failed: " + err.message);
    }
  }

  private static async resetDatas(){

    // await WordDbAccess.shared.init()
    await BaseWordDbAccess.shared.init()
    await CigenWordDbAccess.shared.init()

    SearchManager.shared.refreshData()
  }
  // // 重新启动当前 Ability（EntryAbility），以便语言资源生效
  // private static async restartEntryAbility(context: common.UIAbilityContext): Promise<void> {
  //   try {
  //     // 使用静态的bundle名称和ability名称
  //
  //     const want = {
  //       bundleName: BundleUtils.getBundleInfoSync().name,//"com.or.toeic.hm.vocabulary",
  //       abilityName: "EntryAbility"
  //     } as Want;
  //
  //     // 先启动新Ability，再终止当前Ability
  //     //await context.startAbility(want);
  //
  //     // 等待一段时间确保新Ability启动完成后再终止当前Ability
  //     await new Promise<void>((resolve) => {
  //       //setTimeout(resolve, 200);
  //     });
  //
  //    // await context.terminateSelf();
  //
  //   } catch (err) {
  //     console.error("LanguageManager.restartEntryAbility failed: " + err.message);
  //
  //   }
  // }
}

