import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { getAppContext } from '../../app/constants/AppContext';
import { FileUtility } from './FileUtility';
import { common } from '@kit.AbilityKit';

/**
 * SavePhotoUtils
 * HarmonyOS 5.0 工具类：用于保存图片至系统相册
 * 支持 PixelMap、路径、屏幕截图、多张图片
 */
export class SavePhotoUtils {

  /**
   * 将 PixelMap 保存到系统相册
   * @param context 上下文对象
   * @param pixel PixelMap 对象
   * @param format 保存格式 (默认 'jpeg')
   */
  static async savePixelMapToAlbum(pixel: image.PixelMap | null | undefined, format: 'jpeg' | 'png' = 'png') {
    if (!pixel) return console.error('❌ pixelMap 为空');
    try {
      const context = getAppContext()
      const helper  = photoAccessHelper.getPhotoAccessHelper(context);
      const uri     = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, format);
      const file    = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      const packer  = image.createImagePacker();
      const packOpts: image.PackingOption = { format: `image/${format}`, quality: 98 };

      await new Promise<void>((resolve, reject) => {
        packer.packToFile(pixel, file.fd, packOpts, (err: BusinessError) => {
          if (err) reject(err);
          else resolve();
        });
      });

      packer.release(() => {});
      fileIo.close(file.fd);
      console.log('✅ 图片已保存到相册')
    } catch (err) {
      const error = err as BusinessError;
      console.error(`❌ 保存 PixelMap 出错: code=${error.code}, message=${error.message}`);
    }
  }

  /**
   * 保存指定路径的图片文件到系统相册
   * @param context 上下文对象
   * @param srcPath 图片源路径
   */
  static async saveFileToAlbum(srcPath: string) {
    try {
      const context = getAppContext()
      const helper  = photoAccessHelper.getPhotoAccessHelper(context);
      const uri     = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpeg');
      const src     = await fileIo.open(srcPath, fileIo.OpenMode.READ_ONLY);
      const dest    = await fileIo.open(uri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE);
      const buffer  = new ArrayBuffer(4096);

      let bytesRead = 0;
      do {
        bytesRead   = await fileIo.read(src.fd, buffer);
        if (bytesRead > 0) {
          await fileIo.write(dest.fd, buffer.slice(0, bytesRead));
        }
      } while (bytesRead > 0);

      fileIo.close(src.fd);
      fileIo.close(dest.fd);

      console.log('✅ 图片已保存到相册')
    } catch (err) {
      const error = err as BusinessError;
      console.error(`❌ 保存文件出错: code=${error.code}, message=${error.message}`);
    }
  }


  /**
   * 批量保存多张 PixelMap 到相册
   * @param context 上下文对象
   * @param pixelMaps PixelMap 数组
   */
  static async savePixelMapsToAlbum(pixelMaps: image.PixelMap[]) {
    if (!pixelMaps || pixelMaps.length === 0) {
      console.warn('⚠️ 没有可保存的图片');
      return;
    }
    for (let i = 0; i < pixelMaps.length; i++) {
      await SavePhotoUtils.savePixelMapToAlbum(pixelMaps[i]);
    }

  }

  ///保存图片到临时文件，并返回path
  static async savePixelMapToTempFile(
    pixelMap: image.PixelMap,
    prefix: string = 'snapshot',
    format: 'image/png' | 'image/jpeg' = 'image/png',
    quality: number = 100
  ): Promise<string> {
    const context = getContext() as common.UIAbilityContext;
    const dir = `${context.cacheDir}/snapshots`;

    // 确保目录存在
    FileUtility.createFolderIfNeeds(dir);

    // 打包 PixelMap 为图片二进制
    const packer = image.createImagePacker();
    const arrayBuffer: ArrayBuffer = await packer.packToData(pixelMap, { format, quality });

    // 构造文件路径
    const ext = format === 'image/png' ? 'png' : 'jpg';
    const filePath = `${dir}/${prefix}_${Date.now()}.${ext}`;

    // 打开文件
    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);

    try {
      // 直接写入 ArrayBuffer
      fileIo.writeSync(file.fd, arrayBuffer);
    } finally {
      fileIo.closeSync(file);
    }

    console.info('✅ PixelMap 已保存:', filePath);
    return filePath;
  }


}