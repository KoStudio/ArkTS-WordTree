import media from '@ohos.multimedia.media';
import { AudioTool } from './AudioTool'; // 导入您提供的AudioTool
import { VolumeChecker } from '../../../utils/VolumeChecker';
import { CSoundHelper } from '../Cloud/Manager/CSoundHelper';
import { CSoundManager } from '../Cloud/Manager/CSoundManager';
import { Toast } from '../../../utils/Toast';

// 定义音频数据结构
interface AudioData {
  idxx: number;         // 音频唯一标识
  text: string;          // 音频资源名称
  avPlayer: media.AVPlayer; // AVPlayer实例
}

export class AudioPlayer {
  // 单例实例（静态属性）
  private static _instance: AudioPlayer;

  // 组件内部状态
  isPlaying: boolean = false;
  private playingAudioData?: AudioData;
  private queue: AudioData[] = [];

  // 回调函数
  allFinishedCallback?: () => void;

  // 私有构造函数（单例模式）
  private constructor() {}

  // 获取单例实例（静态方法）
  public static get shared(): AudioPlayer {
    if (!AudioPlayer._instance) {
      AudioPlayer._instance = new AudioPlayer();
    }
    return AudioPlayer._instance;
  }

  // MARK: - 公共方法

  /**
   * [停止并清空后]直接播放
   * @param text 音频资源URI（支持网络路径或本地文件路径）
   */
  public async play(text: string | null | undefined): Promise<void> {
    if (!text) { return }

    await VolumeChecker.checkVolume()
    this.stopAndClear();
    await this.loadSound(text);
  }

  /**
   * 排队播放,不清空正在播放的声音
   * @param text 音频资源URI
   */
  public async prepareToPlay(text: string | null | undefined): Promise<void> {
    if (!text) { return }

    await this.loadSound(text);
  }

  public async prepareSound(text: string | null | undefined){
    if (!text) { return }
    await CSoundHelper.startDownloadOrGenerateSound(text)
  }
  // 停止并清空队列
  public stopAndClear(): void {
    this.stop();
    this.clear();
  }

  // MARK: - 私有方法


  /**
   * 加载音频资源
   * @param text 音频资源URI
   */
  private async loadSound(text: string): Promise<void> {
    try {

      // 1. 使用AudioTool创建播放器实例[5](@ref)
      const audioData = await this.generateAudioData(text);

      if (audioData !== null) {

        // 加入队列
        this.queue.push(audioData);

        // 尝试播放
        this.tryPlayIfNeeds();
      }


    } catch (err) {
      console.error(`加载音频失败: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 生成音频数据（核心方法）
   * @param text 音频资源URI
   * @param idxx 音频唯一标识
   */
  private async generateAudioData(text: string): Promise<AudioData | null> {
    // 2. 模拟获取音频数据（实际项目替换为真实下载）
    const csound = await CSoundHelper.startDownloadOrGenerateSound(text)
    if (!csound || csound.data === null || csound.idxx === null) {
      return null
    }

    const idxx = csound.idxx;

    // 使用AudioTool创建播放器
    const avPlayer = await AudioTool.createAudioPlayer(csound.data, csound.idxx, async (state: string) => {
      switch (state) {
        case 'playing':
          this.isPlaying = true;
          break;
        case 'completed':
          await this.onAudioFinished(idxx);
          break;
        case 'error':
          console.error('播放器错误');
          this.stopAndClear();
          break;
      }
    });

    if (!avPlayer) {
      //2.如果有问题，打不开，则删除缓存数据，以待下载次重新下载
      Toast.showDebugMessage("创建avPlayer失败: null")
      await CSoundManager.shared.removeSound(csound)
      return null
    }

    return { idxx, text, avPlayer };

  }

  // 停止当前播放
  private stop(): void {
    if (this.playingAudioData) {
      const currentPlayer = this.playingAudioData.avPlayer;
      try {
        // 先停止播放再释放资源
        if (currentPlayer.state === 'playing' || currentPlayer.state === 'paused') {
          currentPlayer.stop();
        }
        if (currentPlayer.state !== 'released') {
          currentPlayer.release();
        }
      } catch (e) {
        console.error(`释放资源失败: ${e}`);
      }
      this.playingAudioData = undefined;
    }
    this.isPlaying = false;
  }

  // 清空播放队列
  private clear(): void {
    while (this.queue.length > 0) {
      const playerData = this.queue.shift();
      if (playerData) {
        // 6. 清理播放器资源
        if (playerData.avPlayer.state !== 'released') {
          try {
            playerData.avPlayer.release();
          } catch (e) {
            console.error(`清理队列失败: ${e}`);
          }
        }

        // 7. 清理临时文件[5](@ref)
        AudioTool.removeTmpMp3File(playerData.idxx)
      }
    }
  }

  /**
   * 尝试播放队列中的下一首
   * @returns 是否成功播放
   */
  private tryPlay(): boolean {
    if (this.queue.length === 0) return false;
    const playerData = this.queue.shift();
    if (!playerData) return false;

    this.playingAudioData = playerData;

    try {
      // Toast.showDebugMessage(`tryPlay.state= ${playerData.avPlayer.state}}`)
      if (playerData.avPlayer.state === 'prepared') {
        playerData.avPlayer.play();
        return true;
      }
      return false;
    } catch (err) {
      console.error(`播放失败: ${JSON.stringify(err)}`);
      return false;
    }
  }


  /**
   * 如果需要则尝试播放（当前没有播放时）
   * @returns 是否成功播放
   */
  private tryPlayIfNeeds(): boolean {
    if (!this.isPlaying) {
      return this.tryPlay();
    }
    return false;
  }

  /**
   * 音频播放完成处理
   * @param idxx 音频唯一标识
   */
  private async onAudioFinished(idxx: number) {
    // 9. 清理当前播放资源[5](@ref)
    if (this.playingAudioData) {
      // 只释放播放器，不关fd（由released状态回调处理）
      await this.playingAudioData.avPlayer.release(); // 触发released状态
      this.playingAudioData = undefined;
    }
    this.isPlaying = false;

    // 10. 删除临时文件
    AudioTool.removeTmpMp3File(idxx)

    // 尝试播放下一首
    if (!this.tryPlay()) {
      // 全部播放完成
      if (this.allFinishedCallback) {
        this.allFinishedCallback();
      }
    }
  }
}