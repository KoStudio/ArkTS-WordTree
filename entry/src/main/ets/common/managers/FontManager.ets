// FontManager.ts - 字体管理类（支持双注册、可覆盖复制）
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { UIContext } from '@kit.ArkUI';

// 字体缓存映射（独立于类）
const arkuiFontCache: Set<string> = new Set();
const pdfFontCache: Map<string, string> = new Map();

export class FontManager {
  /**
   * 注册字体到 ArkUI 渲染系统（用于 UI 组件显示）
   * @param uiContext UIContext 对象（当前页面上下文）
   * @param fontName 注册使用的字体名称
   * @param rawFilePath 字体资源路径（如 $rawfile(...)）
   */
  static registerForArkUI(
    uiContext: UIContext,
    fontName: string,
    rawFilePath: ResourceStr
  ): void {
    if (arkuiFontCache.has(fontName)) {
      // 已注册则跳过
      return;
    }
    uiContext.getFont().registerFont({
      familyName: fontName,
      familySrc: rawFilePath
    });
    arkuiFontCache.add(fontName);
    console.info(`ArkUI 字体注册成功: ${fontName}`);
  }

  /**
   * 注册字体到 PDF 生成系统，复制字体文件并返回物理路径
   * @param context Ability 上下文（可访问 filesDir）
   * @param fontName 字体名称（唯一 key）
   * @param rawFilePath 原始字体资源路径
   * @param force 若为 true，则即使已存在同名文件也会重新复制
   * @returns Promise<string> 返回字体在沙箱中的绝对路径
   */
  static async registerForPDF(
    context: common.Context,
    fontName: string,
    rawFilePath: string,
    force: boolean = false
  ): Promise<string> {
    // 如果已缓存且不强制复制，直接返回已缓存路径
    if (!force && pdfFontCache.has(fontName)) {
      return pdfFontCache.get(fontName)!;
    }

    // 应用私有目录中的 fonts 子目录
    const fontDir = `${context.filesDir}/fonts/`;

    try {
      const exists = await fs.access(fontDir);
      if (!exists) {
        await fs.mkdir(fontDir);
      }
    } catch {
      // 如果访问失败，尝试创建目录
      await fs.mkdir(fontDir);
    }

    const targetPath = `${fontDir}${fontName}.ttf`;

    // 判断目标文件是否存在
    try {
      const existsFile = await fs.access(targetPath);
      if (existsFile) {
        if (!force) {
          pdfFontCache.set(fontName, targetPath);
          return targetPath;
        } else {
          await fs.unlink(targetPath);
        }
      }
    } catch {
      // 文件不存在也没关系，继续写入
    }

    try {
      // 获取 raw 字体文件内容
      const rawFont: Uint8Array = await context.resourceManager.getRawFileContent(rawFilePath);

      if (!rawFont || rawFont.length === 0) {
        throw new Error("字体内容为空");
      }

      // 写入字体文件
      await new Promise<void>((resolve, reject) => {
        try {
          const fd = fs.openSync(targetPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
          fs.write(fd.fd, rawFont.buffer, (err) => {
            fs.closeSync(fd);
            if (err) {
              console.error(`字体写入失败: ${err.message}`);
              reject(err);
            } else {
              resolve();
            }
          });
        } catch (error) {
          console.error(`字体文件打开失败: ${error.message}`);
          reject(error);
        }
      });

      // 检查写入是否成功
      const stat = await fs.stat(targetPath);
      console.info(`PDF 字体写入成功: ${targetPath}, size = ${stat.size}`);

      pdfFontCache.set(fontName, targetPath);
      return targetPath;
    } catch (err) {
      console.error(`PDF 字体复制失败: ${JSON.stringify(err)}`);
      throw new Error("FONT_COPY_FAILED");
    }
  }

  /**
   * 获取 PDF 字体路径（如果已注册）
   * @param fontName 字体名称常量
   * @returns 已缓存路径或 undefined
   */
  static getPdfFontPath(fontName: string): string | undefined {
    return pdfFontCache.get(fontName);
  }
}