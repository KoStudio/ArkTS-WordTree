import audio from '@ohos.multimedia.audio';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@ohos.base';

export class VolumeChecker {
  /**
   * 检查设备音量是否低于阈值（修正版本）
   * @param threshold 音量阈值 (默认 0.12)
   * @param message 提示信息 (默认提示文本)
   *
   * 关键修正：正确处理 getVolumeGroupManager() 返回的 Promise 对象
   * Swift 类比：类似处理 Swift 的 async/await 异步操作
   * Kotlin 类比：类似 Kotlin 协程中的挂起函数
   */
  static async checkVolume(
    threshold: number = 0.12,
    message: ResourceStr = $r('app.string.sys_msg_volume_small')
  ) {
    try {
      // 1. 获取音频管理器实例
      const audioManager: audio.AudioManager = audio.getAudioManager();

      // 2. 获取音量管理器 [2,7](@ref)
      const audioVolumeManager = audioManager.getVolumeManager();

      // 3. 异步获取音量组管理器（正确等待Promise解析）[1,6](@ref)
      const groupManager = await audioVolumeManager.getVolumeGroupManager(audio.DEFAULT_VOLUME_GROUP_ID);

      // 4. 使用回调方式获取当前媒体音量 [3,4](@ref)
      groupManager.getVolume(audio.AudioVolumeType.MEDIA, (err: BusinessError, value: number) => {
        if (err) {
          console.error(`获取音量失败: ${err.code}, ${err.message}`);
          return;
        }

        const currentVolume: number = value; // 当前音量值 (0.00-1.00)

        // 5. 检查音量是否低于阈值
        if (currentVolume < threshold) {
          // 显示Toast提示
          promptAction.showToast({
            message: message,
            duration: 3000,
            bottom: '50%'
          });
        }
      });
    } catch (err) {
      console.error(`音量检查失败: ${err.code}, ${err.message}`);
    }
  }
}

// 使用示例
async function exampleUsage() {
  await VolumeChecker.checkVolume();
}