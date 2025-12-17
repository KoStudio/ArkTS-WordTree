import { statfs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

export class DiskStatus {

  // 同步检查内部存储空间（单位：字节）
  static getAvailableBytesForDataDirectorySync(context: common.Context): number {
    try {
      return statfs.getFreeSizeSync(context.filesDir);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`内部存储检查失败[code:${error.code}]: ${error.message}`);
      return 0
    }
  }


  // 快捷方法：检查空间是否足够（同步）
  static isDiskSpaceEnoughSync(context: common.Context, needMegas: number): boolean {
    const availableBytes = DiskStatus.getAvailableBytesForDataDirectorySync(context);
    const needBytes = needMegas * 1024 * 1024;
    console.info(`可用空间: ${availableBytes}字节，需要空间: ${needBytes}字节`);
    return availableBytes > needBytes;
  }
}
