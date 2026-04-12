
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { SettingManager } from '../../../models/managers/setting/SettingManager';
import { getAppContext } from '../../../app/constants/AppContext';


// 音效类型枚举
export enum SEType {
  Correct   = "correct",
  Wrong     = "wrong",
  Warning   = "warning",
  Fanfare   = "fanfare",
  Clicked   = "btn_click2"
}

// 音效服务类（单例模式）
export class SEService {
  private static instance: SEService;
  private soundPool: media.SoundPool | null = null;
  private soundMap: Map<SEType, number> = new Map(); // 存储soundId
  private context: common.Context | null = null;
  private isInitialized: boolean = false;

  // 私有构造函数
  private constructor() {}

  // 获取单例实例
  public static get shared(): SEService {
    if (!SEService.instance) {
      SEService.instance = new SEService();
    }
    return SEService.instance;
  }

  /**
   * 初始化音效服务
   * @param context 应用上下文
   */
  public async initialize(context: common.Context): Promise<boolean> {
    if (this.isInitialized) {
      console.info('SoundEffectService is already initialized');
      return true;
    }

    this.context = context;

    try {
      // 配置音频渲染参数（与华为 SoundPool 短音频开发指导一致）
      // 官方说明：usage 为 STREAM_USAGE_UNKNOWN / MUSIC / MOVIE / AUDIOBOOK 时，SoundPool 短音为混音策略，不易与其它媒体冲突；
      // 使用 STREAM_USAGE_NOTIFICATION 时走通知音策略，新系统上可能与「通知音量」「免打扰」等挂钩，易出现升级后无声。
      // 参考：使用 SoundPool 播放短音频 (ArkTS) — https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/using-soundpool-for-playback
      let audioRendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 1
      };

      // 创建SoundPool实例，参数5表示最大同时播放流数
      this.soundPool = await media.createSoundPool(5, audioRendererInfo);
      console.info('SoundPool initialized successfully');

      // 设置事件监听
      this.setupEventListeners();

      // 预加载所有音效
      const loadResult = await this.preloadAllSounds();

      if (!loadResult) {
        console.error('Some sounds failed to load');
        return false;
      }

      this.isInitialized = true;
      return true;
    } catch (error) {
      console.error(`Failed to initialize SoundPool: ${(error as BusinessError).message}`);
      return false;
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    if (!this.soundPool) return;

    // 监听资源加载完成
    this.soundPool.on('loadComplete', (soundId: number) => {
      console.info('loadComplete, soundId: ' + soundId);
    });

    // 监听播放完成（带streamId信息）
    // this.soundPool.on('playFinishedWithStreamId', (streamId: number) => {
    //   console.info(`play finished, streamId: ${streamId}`);
    // });

    // 监听错误事件
    this.soundPool.on('error', (error: BusinessError) => {
      console.error('error happened, message: ' + error.message);
    });
  }

  /**
   * 预加载所有音效
   */
  private async preloadAllSounds(): Promise<boolean> {
    const types =  Object.values(SEType);
    let allLoaded = true;

    for (let type of types) {
      const loaded = await this.loadSound(type);
      if (!loaded) {
        allLoaded = false;
        console.error(`Failed to load sound: ${type}`);
      }
    }

    return allLoaded;
  }

  /**
   * 加载单个音效
   * @param type 音效类型
   */
  private rawFilePathForType(type: SEType): string {
    // 资源目录 rawfile/mov/：correct/wrong/warning/fanfare 为 mp3；点击音 btn_click2 为 wav（与 iOS/Android 资源命名一致）。
    const ext: string = (type === SEType.Clicked) ? 'wav' : 'mp3';
    return `mov/${type}.${ext}`;
  }

  private async loadSound(type: SEType): Promise<boolean> {
    if (!this.soundPool || !this.context) {
      console.error('SoundPool or context not initialized');
      return false;
    }

    try {
      // 获取资源文件描述符
      let resourceManager = this.context.resourceManager;
      let rawFileValue = await resourceManager.getRawFd(this.rawFilePathForType(type));

      // 使用fd、offset和length加载音效
      let soundId = await this.soundPool.load(
        rawFileValue.fd,
        rawFileValue.offset,
        rawFileValue.length
      );

      // 存储soundId
      this.soundMap.set(type, soundId);
      console.info(`Sound ${type} loaded with soundId: ${soundId}`);
      return true;
    } catch (error) {
      console.error(`Failed to load sound ${type}: ${(error as BusinessError).message}`);
      return false;
    }
  }

  /**
   * 检查音效是否已加载
   * @param type 音效类型
   */
  public isSoundLoaded(type: SEType): boolean {
    return this.soundMap.has(type) && this.soundMap.get(type)! > 0;
  }

  /**
   * 播放音效
   * @param type 音效类型
   */
  public async playSound(type: SEType): Promise<boolean> {

    ///效果音 关闭
    if (!SettingManager.shared.soundEffect) {
      return false
    }

    // 与 EntryAbility 动态 import 竞态：首屏极快进入测验时 SoundPool 可能尚未就绪，此处懒加载一次（getAppContext 在 initAppContext 之后可用）。
    if (!this.isInitialized || !this.soundPool) {
      const ctx: common.Context = (this.context ?? getAppContext()) as common.Context;
      const ok: boolean = await this.initialize(ctx);
      if (!ok || !this.soundPool) {
        console.error('SEService.playSound: initialize failed or SoundPool missing');
        return false;
      }
    }

    const soundId = this.soundMap.get(type);
    if (soundId === undefined || soundId <= 0) {
      console.error(`Sound ${type} not loaded or load failed`);
      // 尝试重新加载
      const loaded = await this.loadSound(type);
      if (!loaded) return false;
    }

    try {
      // 配置播放参数
      let playParameters: media.PlayParameters = {
        loop: 0,          // 不循环
        rate: audio.AudioRendererRate.RENDER_RATE_NORMAL, // 使用枚举值
        leftVolume: 1.0,  // 左声道音量
        rightVolume: 1.0, // 右声道音量
        priority: 0       // 优先级
      };

      // 播放音效
      return new Promise<boolean>((resolve) => {
        this.soundPool!.play(this.soundMap.get(type)!, playParameters, (error: BusinessError, streamId: number) => {
          if (error) {
            console.error(`Play sound failed: ${error.message}`);
            resolve(false);
          } else {
            console.info(`Sound playing with streamId: ${streamId}`);
            resolve(true);
          }
        });
      });
    } catch (error) {
      console.error(`Play sound error: ${(error as BusinessError).message}`);
      return false;
    }
  }

  /**
   * 设置音量
   * @param type 音效类型
   * @param volume 音量范围(0.0-1.0)
   */
  public async setVolume(type: SEType, volume: number): Promise<void> {
    if (!this.soundPool) {
      console.error('SoundPool not initialized');
      return;
    }

    const soundId = this.soundMap.get(type);
    if (soundId === undefined || soundId <= 0) {
      console.error(`Sound ${type} not loaded`);
      return;
    }

    try {
      // 注意：当前HarmonyOS不支持左右声道分别设置，以leftVolume为准[1](@ref)
      await this.soundPool.setVolume(soundId, volume, volume);
      console.info(`Volume set to ${volume} for sound ${type}`);
    } catch (error) {
      console.error(`Set volume failed: ${(error as BusinessError).message}`);
    }
  }

  /**
   * 清空所有音效资源
   */
  public async clear(): Promise<void> {
    if (!this.soundPool) {
      return;
    }

    try {
      // 卸载所有音效
      for (let entry of this.soundMap.entries()) {
        let type = entry[0]; // 第一个元素是键
        let soundId = entry[1]; // 第二个元素是值
        if (soundId > 0) {
          await this.soundPool.unload(soundId);
          console.info(`Sound ${type} unloaded`);
        }
      }

      // 清空映射表
      this.soundMap.clear();
      console.info('All sound resources cleared');

    } catch (error) {
      console.error(`Clear failed: ${(error as BusinessError).message}`);
    }
  }

  /**
   * 释放资源
   */
  public async release(): Promise<void> {
    if (!this.soundPool) {
      return;
    }

    try {
      // 先清空所有音效
      await this.clear();

      // 移除事件监听
      this.removeEventListeners();

      // 释放SoundPool
      await this.soundPool.release();
      this.soundPool = null;
      this.isInitialized = false;
      console.info('SoundPool resources released');

    } catch (error) {
      console.error(`Release failed: ${(error as BusinessError).message}`);
    }
  }

  /**
   * 移除事件监听器
   */
  private removeEventListeners(): void {
    if (!this.soundPool) return;

    this.soundPool.off('loadComplete');
    // this.soundPool.off('playFinishedWithStreamId');
    this.soundPool.off('error');
  }

  /**
   * 检查是否已初始化
   */
  public getIsInitialized(): boolean {
    return this.isInitialized;
  }
}

// 全局播放函数（与业务处直接调用 SEService.shared.playSound 等价；未使用 await 时须 void 避免浮 Promise）
export function playSE(type: SEType): void {
  void SEService.shared.playSound(type);
}