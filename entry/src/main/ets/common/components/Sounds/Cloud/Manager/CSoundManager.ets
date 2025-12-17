import { DebugLog } from '../../../../../app/debug/DebugLog';
import { SimpleEventBus } from '../../../eventbus/SimpleEventBus';
import { CosDownloader } from '../Download/Downloader/CosDownloader';
import { CSoundDbAccessor } from '../CSoundDbAccessor/CSoundDbAccessor';
import { CDBSound, lang_en_us } from '../CSoundDbAccessor/CDBSound';

// 定义通知相关的常量
export class CSoundNotification {

  static readonly NAME_SOUND_LOADED = "Wc.SoundModel.SoundDownloader.soundLoaded"

  static readonly UKEY_K_SOUND     = "SoundKey"

}

// 主模型类

export class CSoundManager {
  // 单例实例
  private static instance: CSoundManager | null = null;

  // 下载器和生成器
  private downloader: CosDownloader = CosDownloader.shared
  // private generator: IDownloader = new AmazonDownloader();

  ///用于缓存已经查询过的且存在的声音
  private existedSoundCacheSet: Set<string> = new Set<string>() // 如: [字 : true]

  // 私有构造函数
  private constructor() {}

  // 获取单例
  static get shared(): CSoundManager {
    if (!CSoundManager.instance) {
      CSoundManager.instance = new CSoundManager();
    }
    return CSoundManager.instance;
  }

  // 检查是否有发音缓存
  async isCSoundExistsInCache(text: string): Promise<boolean> {
    if (!text) {
      return false;
    }
    if (this.existedSoundCacheSet.has(text)) {
      return true
    }

    let rtn = await CSoundDbAccessor.shared.getByLangAndText(lang_en_us, text) !== null
    if (rtn) {
      //缓存结果true
      this.existedSoundCacheSet.add(text)
    }

    return rtn
  }

  /**
   * 获取声音，如果不存在会自动启动下载流程
   * @param text 文本内容
   * @param downloadIfNotExists 如果不存在是否下载
   * @param alsoGenerate 如果下载失败是否生成
   * @returns 返回声音数据或null
   */
  async getSound(text: string, downloadIfNotExists: boolean = true, alsoGenerate: boolean = true): Promise<CDBSound | null> {
    // 先从数据库查询
    const sound = await CSoundDbAccessor.shared.getByLangAndText(lang_en_us, text)
    if (sound) {
      DebugLog.d(`getSound: ${text} from db`);
      return sound;
    }

    if (downloadIfNotExists) {
      // 启动下载
      await this.downloader.startDownloadIfNeeds(text, async (data, msg) => {
        if (data && data.length > 0) {
          // 下载成功处理数据
          await this.processReceivedData(text, data, msg);
        } else if (alsoGenerate) {
          // 启动合成
          await this.generateSound(text);
        }
      });
    }

    return null;
  }

  // 生成声音
  private async  generateSound(text: string) {
    // this.generator.startDownloadIfNeeded(text, (data, msg) => {
    //   this.processReceivedData(text, data, msg);
    // });
  }

  // 处理接收到的数据
  private async processReceivedData(text: string, data: Uint8Array | null, msg: string | null) {
    if (data && data.length > 0) {

      const dbSound      = new CDBSound()
      dbSound.lang       = lang_en_us
      dbSound.text       = text
      dbSound.data       = data

      //插入db
      await CSoundDbAccessor.shared.insertSound(dbSound)

      // 发送通知
      SimpleEventBus.emit(CSoundNotification.NAME_SOUND_LOADED, dbSound)
      DebugLog.i(`new downloaded sound for text:${text}, data.length:${data.length} bytes`);

    } else {
      DebugLog.w(msg || 'data is null');
    }
  }

  // 删除声音
  async removeSound(sound: CDBSound) {
    if (sound.idxx) {
      await CSoundDbAccessor.shared.deleteById(sound.idxx)
    }
  }

  // 删除所有缓存
  async removeAllCachedSounds() {
    await CSoundDbAccessor.shared.deleteAll()
  }
}
