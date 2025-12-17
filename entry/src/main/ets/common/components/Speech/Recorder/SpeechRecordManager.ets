import media from '@ohos.multimedia.media';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { RecordSound, SpeechRecordDbAccessor } from './SpeechRecordDbAccessor';
import { getAppContext } from '../../../../app/constants/AppContext';
import { BusinessError } from '@kit.BasicServicesKit';
import { Permissions } from '@kit.AbilityKit';
import bundleManager from '@ohos.bundle.bundleManager'; // 导入应用包管理模块
import { promptAction } from '@kit.ArkUI';
import { awaitDelay, createFolderIfNeeds } from '../../../../app/constants/AppFunctions';
import { Toast } from '../../../utils/Toast';

const RECORD_FILE_EXT = '.aac';  // 录音文件扩展名

/**
 * 录音管理类（非单例实现）
 * 使用@ObservedV2和@Trace实现响应式状态管理
 */
@ObservedV2
export class SpeechRecordManager {
  // ===================== 状态变量 =====================
  @Trace isRecording: boolean = false;   // 是否正在录音
  @Trace isPlaying: boolean = false;     // 是否正在播放
  @Trace isTalking: boolean = false;     // 是否检测到说话

  // ===================== 音频对象 =====================
  private avRecorder?: media.AVRecorder;  // 录音器
  private avPlayer?: media.AVPlayer;    // 播放器
  private timerId?: number;               // 定时器ID
  private soundName?: string;              // 当前录音文件名
  private soundPath: string;              // 录音文件存储路径
  private context: common.UIAbilityContext;

  private recordFile: fs.File | null = null; // 新增：保存文件句柄

  // ===================== 构造函数 =====================
  constructor() {
    this.context = getAppContext() as common.UIAbilityContext
    // 初始化录音路径（Swift FileManager → ArkTS fs）
    this.soundPath = this.context.cacheDir + '/recording_files/';

    // 创建存储文件夹（Swift createDirectory → ArkTS mkdirSync）
    createFolderIfNeeds(this.soundPath)
  }

  // ===================== 公开方法 =====================

  /**
   * 开始录音
   * @param text - 录音关联的文本
   */
  async startRecord(text?: string): Promise<void> {
    if (!text) return;
    this.soundName = text;

    // 请求录音权限（Swift AVAudioSession → ArkTS abilityAccessCtrl）
    const granted = await this.requestRecordAuthorization();
    if (!granted) return;

    await this.startRecording();
  }

  /**
   * 停止录音
   */
  async stopRecord(): Promise<void> {
    await this.stopRecording();
  }

  /**
   * 开始播放录音
   * @param text - 要播放的录音关联文本
   */
  async startPlay(text?: string): Promise<void> {
    if (!text) return;
    this.soundName = text;
    await this.startPlaying();
  }

  /**
   * 停止播放
   */
  async stopPlay(): Promise<void> {
    await this.stopPlaying();
  }

  // ===================== 录音核心方法 =====================

  private async startRecording(): Promise<void> {
    await this.stopRecording()
    if (this.isRecording) return;

    try {
      // 1. 创建录音文件并获取文件描述符 ✅
      const filePath = this.getRecordedFilePath();
      this.recordFile = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);

      // 2. 创建录音器
      this.avRecorder = await media.createAVRecorder();

      // 3. 配置录音参数（关键修正：使用 fd 格式）
      const avConfig: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        profile: {
          audioBitrate: 100000,
          audioChannels: 1,
          audioCodec: media.CodecMimeType.AUDIO_AAC,
          audioSampleRate: 11025,
          fileFormat: media.ContainerFormatType.CFT_MPEG_4A // 容器格式需为 m4a
        },
        url: `fd://${this.recordFile.fd}` // ✅ 关键修正：文件描述符格式
      };

      await awaitDelay(500)

      // 4. 准备并开始录音
      await this.avRecorder.prepare(avConfig);
      await this.avRecorder.start();
      this.isRecording = true;

      // 5. 启动说话检测
      this.startTalkingDetection();
    } catch (err) {
      console.error(`录音启动失败: ${JSON.stringify(err)}`);
      // 异常时关闭文件
      if (this.recordFile?.fd) await fs.close(this.recordFile.fd);
    }
  }

  // 停止录音时释放资源 ✅
  private async stopRecording(): Promise<void> {
    if (!this.isRecording) return;

    try {
      await this.avRecorder?.stop();
      await this.avRecorder?.release();
    } catch (err) {
      console.error(`停止录音失败: ${JSON.stringify(err)}`);
    } finally {
      // 关闭文件描述符
      if (this.recordFile?.fd) {
        await fs.close(this.recordFile.fd);
        this.recordFile = null;
      }
      this.isRecording = false;

      // ✅ 新增：停止说话检测
      this.stopTalkingDetection(); // 确保清理定时器

      ///保存录音到数据库
      await this.saveRecordingToDB(); // 确保录音数据持久化
    }
  }

  // ===================== 播放核心方法 =====================
  private async startPlaying(): Promise<void> {

    await this.stopPlaying()

    if (this.isPlaying || !this.soundName) return;

    try {
      // 1. 从数据库获取音频数据
      const recordSound = await SpeechRecordDbAccessor.shared.getRecordSound(this.soundName);
      if (!recordSound?.pronData) return;

      // 2. 创建临时文件路径
      const tempFilePath = `${this.soundPath}temp_${Date.now()}${RECORD_FILE_EXT}`;

      // 3. 使用文件描述符写入数据（替代已废弃的 writeFile）
      const arrayBuffer  = recordSound.pronData.buffer.slice(recordSound.pronData.byteOffset, recordSound.pronData.byteOffset + recordSound.pronData.byteLength);
      const file         = await fs.open(tempFilePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      await fs.write(file.fd, arrayBuffer);

      // 4. 创建 AVPlayer 并配置 fdSrc
      this.avPlayer       = await media.createAVPlayer();
      const fileSize      = (await fs.stat(tempFilePath)).size;
      this.avPlayer.fdSrc = { fd: file.fd, offset: 0, length: fileSize };

      // 5. 状态监听（包含资源清理）
      this.avPlayer.on('stateChange', async (state: string) => {
        // 播放完成时停止并清理
        if (state === 'completed') {
          this.stopPlaying();
        }
        // 播放器释放时关闭文件描述符
        if (state === 'released') {
          await fs.close(file.fd);
          await fs.unlink(tempFilePath);
        }
      });

      // 延迟确保AVPlayer初始化完成，避免prepare时状态错误
      await awaitDelay(500)

      // 6. 异步准备播放器（必须等待 prepared 状态）
      await new Promise<void>((resolve, reject) => {
        this.avPlayer?.prepare((err: BusinessError) => {
          err ? reject(err) : resolve();
        });
      });

      // 7. 开始播放
      await this.avPlayer.play();
      this.isPlaying = true;

    } catch (err) {
      console.error(`播放启动失败: ${JSON.stringify(err)}`);
    }
  }

  private async stopPlaying(): Promise<void> {
    if (!this.avPlayer) return;

    try {
      await this.avPlayer.stop();
      await this.avPlayer.release();
    } catch (err) {
      console.error(`停止播放失败: ${JSON.stringify(err)}`);
    } finally {
      this.isPlaying = false;
      this.avPlayer = undefined;
    }
  }


  private async requestRecordAuthorization(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const permissions: Permissions[] = ['ohos.permission.MICROPHONE'];

      // 1. 获取应用标识
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const tokenId: number = bundleInfo.appInfo.accessTokenId;

      // 2. 检查现有权限状态
      const currentStatus = await atManager.checkAccessToken(
        tokenId,
        permissions[0]
      );

      if (currentStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true;
      }

      // 3. 动态请求权限
      const result = await atManager.requestPermissionsFromUser(
        getContext(this) as common.UIAbilityContext,
        permissions
      );

      // 4. 验证结果
      const allGranted = result.authResults.every(status =>
      status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      );

      if (!allGranted) {
        promptAction.showToast({ message: '需要麦克风权限才能录音', duration: 3000 });
      }
      return allGranted;
    } catch (err) {
      console.error(`权限请求失败: ${JSON.stringify(err)}`);
      return false;
    }
  }

  private startTalkingDetection(): void {
    this.timerId = setInterval(async () => {
      if (!this.avRecorder) return;
      try {
        // 振幅检测（Swift updateMeters → ArkTS getAudioCapturerMaxAmplitude）
        const amplitude = await this.avRecorder.getAudioCapturerMaxAmplitude();

        this.isTalking = amplitude > 1000;
        Toast.showDebugMessage(`amplitude:${amplitude}, isTalking:${this.isTalking}`)
      } catch (err) {
        console.error(`振幅检测失败: ${JSON.stringify(err)}`);
      }
    }, 1000) as number;
  }

  private stopTalkingDetection(): void {
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = undefined;
    }
    this.isTalking = false;
  }

  private getRecordedFilePath(): string {
    return this.soundName ?
      `${this.soundPath}${this.soundName}${RECORD_FILE_EXT}` : '';
  }

  private async saveRecordingToDB(): Promise<void> {
    if (!this.soundName) return;

    const filePath = this.getRecordedFilePath();
    let file: fs.File | null = null;

    try {
      // 1. 打开文件（显式指定文件操作类型）
      file = await fs.open(filePath, fs.OpenMode.READ_ONLY);

      // 2. 获取文件大小（用于创建正确大小的缓冲区）
      const fileStat = await fs.stat(filePath);
      const fileSize = fileStat.size;

      // 3. 创建ArrayBuffer（显式指定Uint8Array类型）
      const arrayBuffer = new ArrayBuffer(fileSize);

      // 4. 读取文件内容（使用显式类型声明）
      const readResult: number = await new Promise((resolve, reject) => {
        fs.read(file!.fd, arrayBuffer, (err: BusinessError, bytesRead: number) => {
          err ? reject(err) : resolve(bytesRead);
        });
      });

      // 5. 转换为Uint8Array（显式类型转换）
      const fileData: Uint8Array = new Uint8Array(arrayBuffer, 0, readResult);

      //等待100秒
      awaitDelay(200)

      Toast.showDebugMessage(this.soundName +", filedata.length:" + fileData.length)
      // 6. 保存到数据库
      await SpeechRecordDbAccessor.shared.insertOrUpdateRecord(this.soundName, fileData);

    } catch (err) {
      console.error(`保存录音失败: ${JSON.stringify(err)}`);
    } finally {
      // 7. 确保关闭文件描述符
      if (file?.fd !== undefined) {
        await fs.close(file.fd);
      }
      // 8. 删除临时文件
      await fs.unlink(filePath);
    }
  }

  // ===================== 数据库操作 =====================
  async isExistsSound(soundName: string): Promise<boolean> {
    const sound = await SpeechRecordDbAccessor.shared.getRecordSound(soundName)
    return (sound?.pronData) != null;
  }

  async getSound(text: string): Promise<RecordSound | null> {
    return await SpeechRecordDbAccessor.shared.getRecordSound(text);
  }

  async getAllSounds(): Promise<RecordSound[] | null> {
    return await SpeechRecordDbAccessor.shared.getAllRecordSounds();
  }

  async removeSound(soundName: string): Promise<void> {
    await SpeechRecordDbAccessor.shared.removeRecordSound(soundName);
  }

  async removeAllSounds(): Promise<void> {
    await SpeechRecordDbAccessor.shared.removeAllRecordSounds();
  }
}