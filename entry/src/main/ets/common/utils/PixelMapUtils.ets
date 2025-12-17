import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import { Size } from '@kit.ArkUI';


/**
 * PixelMap工具类
 * 提供从文件、资源、内存等多种源创建和管理PixelMap的功能
 * @author HarmonyOS Developer
 * @since 2024
 */
export class PixelMapUtil {
  private constructor() {}

  /**
   * 从文件路径创建PixelMap
   */
  static createPixelMapFromFileSync(
    filePath: string,
    options?: image.DecodingOptions
  ): image.PixelMap | null {
    try {
      const imageSource : image.ImageSource = image.createImageSource(filePath);
      const decodingOptions: image.DecodingOptions = options || {
        desiredSize        : { width: 0, height: 0 },
        desiredPixelFormat : image.PixelMapFormat.RGBA_8888
      };
      return imageSource.createPixelMapSync(decodingOptions);
    } catch (error) {
      console.error('从文件创建PixelMap失败:', error);
      return null;
    }
  }


  /**
   * 从内存数据创建PixelMap
   */
  static async createPixelMapFromBuffer(
    buffer: ArrayBuffer,
    options?: image.DecodingOptions
  ): Promise<image.PixelMap | null> {
    try {
      const imageSource = image.createImageSource(buffer);
      return await imageSource.createPixelMap(options);
    } catch (error) {
      console.error('从内存创建PixelMap失败:', error);
      return null;
    }
  }

  /**
   * 从 Uint8Array 创建 PixelMap（create 系列命名）
   * @param data Uint8Array 数据
   * @param options 解码选项
   */
  static async createPixelMapFromUint8Array(
    data: Uint8Array,
    options?: image.DecodingOptions
  ): Promise<image.PixelMap | null> {
    return await PixelMapUtil.uint8ArrayToPixelMap(data, options);
  }

  /**
   * 使用packToFile直接保存PixelMap（高效，无内存中转）
   */
  static async savePixelMapDirect(
    pixelMap: image.PixelMap,
    filePath: string,
    format: string = 'image/jpeg',
    quality: number = 90
  ): Promise<string> {
    if (!pixelMap) {
      throw new Error('PixelMap不能为空');
    }

    let file: fs.File | null = null; // 文件对象

    try {
      // 确保目录存在
      const dirPath = filePath.substring(0, filePath.lastIndexOf('/'));
      try {
        fs.accessSync(dirPath);
      } catch {
        fs.mkdirSync(dirPath, true);
      }

      // 打开文件
      file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);

      const imagePacker: image.ImagePacker = image.createImagePacker();
      const packingOptions: image.PackingOption = { format, quality };

      // 使用 file.fd 作为文件描述符保存
      await imagePacker.packToFile(pixelMap, file.fd, packingOptions);

      console.log(`PixelMap直接保存成功: ${filePath}`);
      return filePath;

    } catch (error) {
      console.error('直接保存PixelMap失败:', error);

      // 清理工作
      if (file !== null) {
        try {
          fs.closeSync(file.fd);
          if (fs.accessSync(filePath)) {
            fs.unlinkSync(filePath);
          }
        } catch (cleanupError) {
          console.warn('清理失败文件时发生错误:', cleanupError);
        }
      }

      throw new Error(typeof error === 'string' ? error : JSON.stringify(error));

    } finally {
      if (file !== null) {
        try {
          fs.closeSync(file.fd);
        } catch (closeError) {
          console.warn('关闭文件描述符时发生错误:', closeError);
        }
      }
    }
  }

  /**
   * 压缩PixelMap
   */
  static async compressPixelMap(
    pixelMap: image.PixelMap,
    maxSize: number,
    quality: number = 80
  ): Promise<image.PixelMap | null> {
    try {
      const info   = await pixelMap.getImageInfo();
      const width  = info.size.width;
      const height = info.size.height;

      // 计算缩放比例
      const scale     = Math.min(maxSize / width, maxSize / height, 1);
      const newWidth  = Math.floor(width * scale);
      const newHeight = Math.floor(height * scale);

      const arrayBuffer = await PixelMapUtil.pixelMapToArrayBuffer(pixelMap, 'image/jpeg', quality);

      return await PixelMapUtil.createPixelMapFromBuffer(arrayBuffer, {
        desiredSize        : { width: newWidth, height: newHeight },
        desiredPixelFormat : image.PixelMapFormat.RGBA_8888
      });

    } catch (error) {
      console.error('压缩PixelMap失败:', error);
      return null;
    }
  }

  /**
   * 释放PixelMap资源
   */
  static releasePixelMap(pixelMap: image.PixelMap): void {
    if (pixelMap) {
      try {
        pixelMap.release();
      } catch (error) {
        console.error('释放PixelMap资源失败:', error);
      }
    }
  }

  /**
   * 获取PixelMap信息
   */
  static async getPixelMapInfo(pixelMap: image.PixelMap): Promise<image.ImageInfo> {
    return await pixelMap.getImageInfo();
  }

  /**
   * 将PixelMap转换为ArrayBuffer
   */
  private static async pixelMapToArrayBuffer(
    pixelMap: image.PixelMap,
    format: string = 'image/png',
    quality: number = 90
  ): Promise<ArrayBuffer> {
    const imagePacker: image.ImagePacker = image.createImagePacker();
    return await imagePacker.packing(pixelMap, { format, quality });
  }

  /**
   * 根据指定 text，创建 PixelMap（类似 UIImage）
   * @param text        文本内容
   * @param width       图片宽度
   * @param height      图片高度
   * @param inCenter    是否在正中间
   * @param fontSize    字体大小
   * @param textColor   字体颜色
   * @param bgColor     背景颜色
   */
  static createImageFromTextSync(
    text: string,
    width: number,
    height: number,
    inCenter: boolean = true, // 是否在正中间
    fontSize: number = 16,
    textColor: string = '#000000',
    bgColor: string = '#D3D3D3' // lightGray
  ): image.PixelMap | null {
    try {
      // 1️⃣ 获取屏幕 scale
      // const disp = display.getDefaultDisplaySync();
      // const scale = disp.densityPixels ?? 1;

      // 2️⃣ 创建空白 PixelMap
      const pixelMap = image.createPixelMapSync({
        size: { width, height },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        editable: true,
        alphaType: 1
      });

      // 3️⃣ 创建 CanvasRenderingContext2D 绑定 PixelMap
      const settings = new RenderingContextSettings(true);
      const ctx = new CanvasRenderingContext2D(settings);
      ctx.setPixelMap(pixelMap); // ⚠️ 关键：绑定 PixelMap

      // 4️⃣ 填充背景色
      ctx.fillStyle = bgColor;
      ctx.fillRect(0, 0, width, height);

      // 5️⃣ 设置文字属性
      ctx.fillStyle = textColor;
      ctx.font = `${fontSize}px sans-serif`;
      ctx.textAlign = inCenter ? 'center' : 'start';
      ctx.textBaseline = 'middle';

      // 6️⃣ 计算绘制位置
      const x = inCenter ? width / 2 : 0;
      const y = inCenter ? height / 2 : fontSize;

      // 7️⃣ 绘制文字
      ctx.fillText(text, x, y);

      // 8️⃣ 返回 PixelMap
      return pixelMap;
    } catch (error) {
      console.error('根据文字创建PixelMap失败:', error);
      return null;
    }
  }

  /**
   * 重设PixelMap大小（拉伸/缩放到指定尺寸）
   * @param pixelMap 原始PixelMap
   * @param newSize 新的宽高
   */
  static reSizedPixelMap(src: image.PixelMap, newSize: Size): image.PixelMap | null {
    try {
      const srcW = src.getImageInfoSync().size.width;
      const srcH = src.getImageInfoSync().size.height;
      const dstW = newSize.width;
      const dstH = newSize.height;

      // 读取源像素
      const srcBuffer = new ArrayBuffer(srcW * srcH * 4);
      src.readPixelsToBufferSync(srcBuffer);
      const srcPixels = new Uint8ClampedArray(srcBuffer);

      // 创建目标 PixelMap
      const dstPixelMap = image.createPixelMapSync({
        size: { width: dstW, height: dstH },
        pixelFormat: image.PixelMapFormat.ARGB_8888,
        editable: true
      });
      const dstBuffer = new ArrayBuffer(dstW * dstH * 4);
      const dstPixels = new Uint8ClampedArray(dstBuffer);

      // 最近邻缩放算法
      for (let y = 0; y < dstH; y++) {
        for (let x = 0; x < dstW; x++) {
          const srcX = Math.floor(x * srcW / dstW);
          const srcY = Math.floor(y * srcH / dstH);

          const srcIndex = (srcY * srcW + srcX) * 4;
          const dstIndex = (y * dstW + x) * 4;

          dstPixels[dstIndex] = srcPixels[srcIndex];       // A
          dstPixels[dstIndex + 1] = srcPixels[srcIndex + 1]; // R
          dstPixels[dstIndex + 2] = srcPixels[srcIndex + 2]; // G
          dstPixels[dstIndex + 3] = srcPixels[srcIndex + 3]; // B
        }
      }

      // 写入目标 PixelMap
      dstPixelMap.writeBufferToPixelsSync(dstBuffer);

      return dstPixelMap;
    } catch (e) {
      console.error("reSizedPixelMap error:", e);
      return null;
    }
  }

  /**
   * 等比缩放PixelMap，保证在targetSize内
   * @param pixelMap 原始PixelMap
   * @param targetSize 最大尺寸
   */
  static reSizedPixelMapWithin(pixelMap: image.PixelMap, targetSize: Size): image.PixelMap | null {
    try {
      const info = pixelMap.getImageInfoSync();
      const width  = info.size.width;
      const height = info.size.height;

      const scaleWidth  = targetSize.width / width;
      const scaleHeight = targetSize.height / height;
      const scale       = Math.min(scaleWidth, scaleHeight, 1); // 保证不放大

      return PixelMapUtil.scaledPixelMap(pixelMap, scale);
    } catch (error) {
      console.error('等比缩放PixelMap失败:', error);
      return null;
    }
  }

  /**
   * 裁剪PixelMap为正方形（以最小边为准）
   * @param pixelMap 原始PixelMap
   */
  static squaredPixelMap(pixelMap: image.PixelMap): image.PixelMap | null {
    try {
      const info = pixelMap.getImageInfoSync();
      const width  = info.size.width;
      const height = info.size.height;

      const size = Math.min(width, height);
      const x    = Math.floor((width - size) / 2);
      const y    = Math.floor((height - size) / 2);

      const targetPixelMap = image.createPixelMapSync({
        size: { width: size, height: size },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        editable: true,
        alphaType: 1
      });

      const settings = new RenderingContextSettings(true);
      const ctx = new CanvasRenderingContext2D(settings);
      ctx.setPixelMap(targetPixelMap);

      // 绘制原始PixelMap到目标PixelMap，偏移裁剪
      ctx.drawImage(pixelMap, -x, -y, width, height);

      return targetPixelMap;
    } catch (error) {
      console.error('裁剪PixelMap为正方形失败:', error);
      return null;
    }
  }

  /**
   * 等比缩放PixelMap
   * @param pixelMap 原始PixelMap
   * @param scale 缩放比例
   */
  static scaledPixelMap(pixelMap: image.PixelMap, scale: number): image.PixelMap | null {
    try {
      const info = pixelMap.getImageInfoSync();
      const newWidth  = Math.floor(info.size.width * scale);
      const newHeight = Math.floor(info.size.height * scale);
      return PixelMapUtil.reSizedPixelMap(pixelMap, { width: newWidth, height: newHeight });
    } catch (error) {
      console.error('等比缩放PixelMap失败:', error);
      return null;
    }
  }

  /**
   * 将 PixelMap 转换为 Uint8Array
   * 可用于存储到 SQLite 的 BLOB 字段
   * @param pixelMap 待转换的 PixelMap 对象
   * @param format  输出格式，默认 'image/png'
   * @param quality 压缩质量（0-100），默认 90
   * @returns Uint8Array 或 null
   */
  static async pixelMapToUint8Array(
    pixelMap: image.PixelMap,
    format: string = 'image/png',
    quality: number = 90
  ): Promise<Uint8Array | null> {
    try {
      // 调用已有的 pixelMapToArrayBuffer 方法
      const arrayBuffer = await PixelMapUtil.pixelMapToArrayBuffer(pixelMap, format, quality);
      return new Uint8Array(arrayBuffer);
    } catch (error) {
      console.error('PixelMap 转 Uint8Array 失败:', error);
      return null;
    }
  }

  /**
   * 将 Uint8Array 转换为 PixelMap
   * @param data  Uint8Array 数据
   * @param options 可选解码参数
   * @returns PixelMap 或 null
   */
  static async uint8ArrayToPixelMap(
    data: Uint8Array,
    options?: image.DecodingOptions
  ): Promise<image.PixelMap | null> {
    if (!data || data.length === 0) return null;

    try {
      // 显式创建新的 ArrayBuffer 并拷贝数据，避免结构化类型错误
      const buffer = new ArrayBuffer(data.length);
      new Uint8Array(buffer).set(data);

      // 调用已有方法从 buffer 创建 PixelMap
      return await PixelMapUtil.createPixelMapFromBuffer(buffer, options);

    } catch (error) {
      console.error('Uint8Array 转 PixelMap 失败:', error);
      return null;
    }
  }
}