// ==== 文件路径相关 ====
import { BundleUtils } from '../../common/utils/BundleUtils';
import { DisplayUtils } from '../../common/utils/DisplayUtils';
import { getString } from '../../common/utils/ResourceUtils';
import { DebugFlg } from '../debug/DebugFlg';
import { AppConstants } from './AppConstants';
import { getAppContext } from './AppContext';
import { AppSettings } from './AppSettings';

export class MyDatas  {
  static readonly FolderName = 'MyDatas'
  static readonly DBName     = 'learnDb.sqlite'
};


/** 本应用的 sqlite声音数据 根目录 ~/app_Database/CloudSoundDatas/ */
export const dAppSoundFolderPath = AppConstants.dataBasePath + 'SoundDatas/'

/** 用户sqlite数据目录 ~/app_Database/MyDatas/ */
export const dMyDataFolderPath = AppConstants.dataBasePath + MyDatas.FolderName + '/'

/** 用户sqlite数据 ~/app_Database/MyDatas/UserData.sqlite */
//应该使用基于BookManager下的方法获取
// Book的子目录下的DB，如:~/app_Database/MyDatas/1/learnDb.sqlite
// export const dMyDataFilePath = dMyDataFolderPath + MyDatas.DBName;

/** 云声音 缓存sqlite数据目录 ~/app_Database/CloudSoundDatas/ */
export const dAppCloudSoundFolderPath = AppConstants.dataBasePath + 'CloudSoundDatas/'

/** 本应用的 云BookDb数据sqlite 下载后的 根目录~/app_Database/CBookDatas/ */
export const dAppCBookDbFolderPath = AppConstants.dataBasePath + 'CBookDatas/'

/**
 * 本地 EBook（用户自建词汇本）textDb 根目录，与 Android `AppDefines.kt` 的 `dAppEBookFolderPath`、
 * iOS `dAppEBookFolderURL` 一致（~/app_Database/EBookDatas/）。
 */
export const dAppEBookFolderPath = AppConstants.dataBasePath + 'EBookDatas/'

/** 本应用的 云BookIcon image 下载后的 根目录~/app_Document/CBookIcons/ */
export const dAppCBookIconFolderPath = AppConstants.docBasePath + 'CBookIcons/'


/** 获取缓存路径 */
export const dAppCachefolder = getAppContext().cacheDir + '/';

/** 获取文件路径 */
export const dAppFilefolder = getAppContext().filesDir + '/';


// ==== 设备信息相关 ====
export const isTablet         = DisplayUtils.isTabletByLayout();

// 获取px尺寸
export const dScreenWidth     = DisplayUtils.getScreenWidthVp();
export const dScreenHeight    = DisplayUtils.getScreenHeightVp();
export const dIsLandscape     = DisplayUtils.isLandscapeByAspectRatio()

export const isDebugMode      = DebugFlg.isDebugMode()

export const dFontNameKaiti   = "STKaiti" //楷体
export const dFontNameDefault = "HarmonyOS Sans" // 默认字体

export const dAppVersion      = BundleUtils.getBundleInfoSync().versionName
export const dNavBackIcon     = $r('app.media.back') // null

// ==== 表情符号常量 ====
export const dMemberFlag      = "\uD83D\uDC51"; // 👑
export const dFlashFlag       = "\u26a1";       // ⚡
export const dStarFlag        = "\u2728";       // ✨
export const dCorrectFlag     = "\u2705";    // ✅
export const dWrongFlag       = "\u274c";      // ❌

export const dAppName         = AppSettings.App.appName //WordTree