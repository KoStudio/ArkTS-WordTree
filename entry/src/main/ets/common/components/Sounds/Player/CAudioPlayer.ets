import media from '@ohos.multimedia.media';
import { AudioTool } from './AudioTool'; // 导入您提供的AudioTool
import { VolumeChecker } from '../../../utils/VolumeChecker';
import { CSoundHelper } from '../Cloud/Manager/CSoundHelper';
import { CSoundManager } from '../Cloud/Manager/CSoundManager';
import { Toast } from '../../../utils/Toast';

// 定义音频数据结构
interface AudioData {
  idxx     : number;                 // 音频唯一标识
  text     : string;                 // 音频资源名称
  avPlayer : media.AVPlayer;         // AVPlayer实例
}

export class AudioPlayer {
  // 单例实例（静态属性）
  private static _instance              : AudioPlayer;

  // 组件内部状态
  isPlaying                              : boolean = false;
  private playingAudioData?              : AudioData;
  private queue                          : AudioData[] = [];

  // 回调函数
  allFinishedCallback?                   : () => void;

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

      // 1. 使用AudioTool创建播放器实例
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
   */
  private async generateAudioData(text: string): Promise<AudioData | null> {

    const csound = await CSoundHelper.startDownloadOrGenerateSound(text)
    if (!csound || csound.data === null || csound.idxx === null) {
      return null
    }

    const idxx = csound.idxx;

    // 使用AudioTool创建播放器
    const avPlayer = await AudioTool.createAudioPlayer(
      csound.data,
      csound.idxx,
      async (state: string) => {
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
      }
    );

    if (!avPlayer) {
      // 如果创建失败，删除损坏缓存
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
        if (playerData.avPlayer.state !== 'released') {
          try {
            playerData.avPlayer.release();
          } catch (e) {
            console.error(`清理队列失败: ${e}`);
          }
        }

        // 清理临时文件
        AudioTool.removeTmpMp3File(playerData.idxx)
      }
    }
  }

  /**
   * 尝试播放队列中的下一首
   * @param delaySecond 播放前延迟（秒）
   * @returns 是否成功播放
   */
  private tryPlay(delaySecond: number = 0): boolean {
    if (this.queue.length === 0) return false;

    const playerData = this.queue.shift();
    if (!playerData) return false;

    this.playingAudioData = playerData;
    this.isPlaying        = true;

    const startPlay = () => {
      try {
        if (playerData.avPlayer.state === 'prepared') {

          // 设置播放速度
          AudioTool.changePlaySpeed(playerData.avPlayer);

          playerData.avPlayer.play();
        }
      } catch (err) {
        console.error(`播放失败: ${JSON.stringify(err)}`);
      }
    };

    // 对应 Kotlin 的 dispatch_delay
    if (delaySecond > 0) {
      setTimeout(() => {
        startPlay();
      }, delaySecond * 1000);
    } else {
      startPlay();
    }

    return true;
  }

  /**
   * 如果需要则尝试播放（当前没有播放时）
   */
  private tryPlayIfNeeds(): boolean {
    if (!this.isPlaying) {
      return this.tryPlay();
    }
    return true;
  }

  /**
   * 音频播放完成处理
   * @param idxx 音频唯一标识
   */
  private async onAudioFinished(idxx: number) {

    if (this.playingAudioData) {
      await this.playingAudioData.avPlayer.release();
      this.playingAudioData = undefined;
    }

    this.isPlaying = false;

    // 删除临时文件
    AudioTool.removeTmpMp3File(idxx)

    // 尝试播放下一首（带间隔）
    const gapSecond = AudioTool.getPlayGap()

    if (!this.tryPlay(gapSecond)) {
      if (this.allFinishedCallback) {
        this.allFinishedCallback();
      }
    }
  }
}