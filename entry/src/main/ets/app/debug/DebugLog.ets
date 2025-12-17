// DebugLog.ets
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DebugFlg } from './DebugFlg';

const DOMAIN = 0xFF00;
const DEFAULT_TAG = 'DEBUG_LOG';

export class DebugLog {
  private static isDebugMode(): boolean {
    return DebugFlg.isDebugMode()
  }

  static d(msg: string): void {
    if (DebugLog.isDebugMode()) {
      hilog.debug(DOMAIN, DEFAULT_TAG, '%{public}s', msg);
    }
  }

  static i(msg: string): void {
    if (DebugLog.isDebugMode()) {
      hilog.info(DOMAIN, DEFAULT_TAG, '%{public}s', msg);
    }
  }

  static w(msg: string): void {
    if (DebugLog.isDebugMode()) {
      hilog.warn(DOMAIN, DEFAULT_TAG, '%{public}s', msg);
    }
  }

  static e(msg: string): void {
    hilog.error(DOMAIN, DEFAULT_TAG, '%{public}s', msg);
  }

  static f(msg: string): void {
    hilog.fatal(DOMAIN, DEFAULT_TAG, '%{public}s', msg);
  }


}
