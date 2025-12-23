import media from '@ohos.multimedia.media';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { createFolderIfNeeds } from '../../../../app/constants/AppFunctions';
import { BusinessError } from '@kit.BasicServicesKit';
import { DebugLog } from '../../../../app/debug/DebugLog';
import { Toast } from '../../../utils/Toast';
import { getAppContext } from '../../../../app/constants/AppContext';
import { SettingManager } from '../../../../models/managers/setting/SettingManager';
import json from '@ohos.util.json';


// 定义配置项接口（解决对象字面量类型问题）
interface AudioToolConfig {
  IsNotPlayingIndex: number;
  TmpFmt: (idxx: number) => string;
}

/**
 * 音频工具类 - 处理音频数据转换和播放
 * 功能：将 Uint8Array 格式的音频数据转换为可播放格式
 */
export class AudioTool {
  // 1. 显式声明配置类型
  static readonly Configs: AudioToolConfig = {
    IsNotPlayingIndex: -1,
    TmpFmt: (idxx: number) => `${idxx}_01.mp3`
  };



  /**
   * 创建播放器并播放 Uint8Array 音频数据
   * @param data Uint8Array 格式的音频数据
   * @param idxx 音频唯一标识符
   * @returns 播放器实例
   */
  static async createAudioPlayer(data: Uint8Array, idxx: number, onStateChange: (state: string) =>void): Promise<media.AVPlayer | null> {
    try {

      const tempDir     = AudioTool.getTmpSoundDir()
      createFolderIfNeeds(tempDir)

      const tmpName     = AudioTool.Configs.TmpFmt(idxx);
      const filePath    = `${tempDir}/${tmpName}`;

      const arrayBuffer = data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
      const file        = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      const fd          = file.fd;
      await fs.write(fd, arrayBuffer);

      const avPlayer    = await media.createAVPlayer();

      const fileSize    = (await fs.stat(filePath)).size;
      const fdSource: media.AVFileDescriptor = { fd: fd, offset: 0, length: fileSize };
      avPlayer.fdSrc    = fdSource;

      // ✅ 延迟释放资源（直到播放器销毁）
      avPlayer.on('stateChange', async (state: string) => {

        // 仅当播放器销毁时关闭 fd
        if (state === 'released') {
          await fs.close(fd);
        }

        ///回调外部
        onStateChange(state)

      });

      // 延迟确保AVPlayer初始化完成，避免prepare时状态错误
      await new Promise<void>((resolve, reject) => setTimeout(resolve, 100));

      // ✅ 异步 prepare() 并等待状态转换
      await new Promise<void>((resolve, reject) => {
        avPlayer.prepare((err) => {
          err ? reject(err) : resolve();
        });
      });

      return avPlayer;

    } catch (err) {
      console.error(`创建播放器失败: ${err.code}, ${err.message} `);
      Toast.showDebugMessage(`创建播放器失败: ${err.code}, ${err.message} `)
      return null;
    }
  }

  /**
   * 删除指定文件
   * @param filePath 文件完整路径
   */
  static async removeFile(filePath: string): Promise<void> {
    try {
      const fileInfo = await fs.stat(filePath);
      // 10. 正确调用异步方法[8](@ref)
      if (fileInfo.isFile()) {
        await fs.unlink(filePath);
        console.info(`已删除临时文件: ${filePath}`);
      }
    } catch (err) {
      console.error(`删除文件失败: ${err}`);
    }
  }

  /**
   * 获取临时音频目录路径
   * @returns 临时目录路径
   */
  private static getTmpSoundDir(): string {
    const context = getAppContext()
    return `${context.cacheDir}/WC_Audio_Tmp_Files`;
  }

  /**
   * 删除指定ID的临时文件
   * @param idxx 音频唯一标识符
   */
  static async removeTmpMp3File(idxx: number): Promise<void> {
    const tempDir = AudioTool.getTmpSoundDir();
    const tmpName = AudioTool.Configs.TmpFmt(idxx);
    const filePath = `${tempDir}/${tmpName}`;
    await AudioTool.removeFile(filePath);
  }

  /**
   * 删除所有临时音频文件
   */
  static async removeTempAudioFiles(): Promise<void> {
    const tempDir = AudioTool.getTmpSoundDir();
    try {
      const files = await fs.listFile(tempDir);
      for (const file of files) {
        await AudioTool.removeFile(`${tempDir}/${file}`);
      }
      await fs.rmdir(tempDir);
      console.info(`已删除临时目录: ${tempDir}`);
    } catch (err) {
      console.error(`删除临时文件失败: ${err}`);
    }
  }

  /**
   * 根据用户设置调整播放速度
   * SDK 17：使用 setSpeed（PlaybackSpeed）
   */
  static changePlaySpeed(avPlayer: media.AVPlayer): void {
    if (!avPlayer) {
      return;
    }

    const index: number = SettingManager.shared.pronSpeed;

    // 默认 1.0x
    let speed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;

    switch (index) {
      case 0:
        // 约等于 0.8x（SDK 不支持精确值，只能取最近档位）
        speed = media.PlaybackSpeed.SPEED_FORWARD_0_75_X;
        break;

      case 1:
        speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
        break;

      case 2:
        // 约等于 1.2x
        speed = media.PlaybackSpeed.SPEED_FORWARD_1_25_X;
        break;

      default:
        speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
        break;
    }

    try {
      avPlayer.setSpeed(speed);
    } catch (e) {
      DebugLog.e('changePlaySpeed failed: ' + JSON.stringify(e));
    }
  }

  static getPlayGap(): number {
    const index: number = SettingManager.shared.pronGap

    let gap: number = 0.0;
    switch (index) {
      case 1:
        gap = 1.0;
        break;
      case 2:
        gap = 2.0;
        break;
      default:
        gap = 0.0;
        break;
    }

    return gap;
  }
}