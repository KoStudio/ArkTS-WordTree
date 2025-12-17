/**
 * 振动控制器（单例模式）
 * @version 2.1 (2025-06-04)
 * @description 提供标准化的振动效果调用接口
 */
import vibrator from '@ohos.vibrator';
import { BusinessError } from '@ohos.base';

export class Vibrator {
  // 单例实例
  private static sharedInstance: Vibrator;

  /**
   * 获取单例对象
   * @returns AppVibrator实例
   */
  public static get shared(): Vibrator {
    if (!Vibrator.sharedInstance) {
      Vibrator.sharedInstance = new Vibrator();
    }
    return Vibrator.sharedInstance;
  }

  /**
   * 基础振动（时间模式）
   * @param duration 振动时长(ms)，默认25ms
   * @param usage 使用场景，默认'touch'（触觉反馈）
   */
  vibrate(duration: number = 25, usage: vibrator.Usage = 'touch'): void {
    try {
      vibrator.startVibration(
        { type: 'time', duration },
        { id: 0, usage },
        (error: BusinessError) => {
          if (error) {
            console.error(`振动失败 code:${error.code}`);
          }
        }
      );
    } catch (err) {
      console.error(`异常捕获 code:${(err as BusinessError).code}`);
    }
  }

  /**
   * 预设效果振动
   * @param effectId 系统预设效果ID，默认'haptic.click'
   */
  vibratePreset(effectId: string = 'haptic.click'): void {
    vibrator.isSupportEffect(effectId, (err: BusinessError, state: boolean) => {
      if (!err && state) {
        vibrator.startVibration(
          { type: 'preset', effectId },
          { usage: 'touch' }
        );
      }
    });
  }

  /** 停止所有振动 */
  stop(): void {
    vibrator.stopVibration();
  }
}

// // 使用示例：
// // 1. 短振动（默认100ms）
// AppVibrator.shared.vibrate();
//
// // 2. 长振动（1000ms）
// AppVibrator.shared.vibrate(1000);
//
// // 3. 使用系统预设效果
// AppVibrator.shared.vibratePreset();

///震动
export function vibrate(){
  Vibrator.shared.vibrate()
}