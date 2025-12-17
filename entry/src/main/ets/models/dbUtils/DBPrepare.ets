// ==== 数据库准备工具模块 ====
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { DbFileUtility } from '../../common/utils/DbFileUtility';
import { ResPath } from '../../app/constants/ResPath';
import { getAppContext } from '../../app/constants/AppContext';
import { checkDiskSpace } from '../../app/constants/AppFunctions';
import { fileUriService } from '@kit.ScenarioFusionKit';
import { FileUtility } from '../../common/utils/FileUtility';

/**
 * 数据库准备协议接口
 */
export interface DBPrepareProtocol {
  /**
   * 检查数据库是否可打开
   * @param dbPath 数据库文件路径
   * @returns 返回是否可打开
   */
  isDbOpenable(dbPath: string): Promise<boolean>;
}



export class DbPrepareUtils {
  // ==================== 公有方法 ====================

  /**
   * 准备数据库文件（根据资源路径）
   * @param protocol 数据库协议实现
   * @param context Ability上下文
   * @param resPath 资源路径对象
   * @param async 是否异步操作
   */
  static async prepareDbIfNeeds(protocol: DBPrepareProtocol, resPath: ResPath) {
    await DbPrepareUtils.prepareDbIfNeedsByPath(protocol, resPath.assetPath, resPath.filePath);
  }

  /**
   * 准备数据库文件（根据具体路径）
   * @param protocol 数据库协议实现
   * @param context Ability上下文
   * @param fromAssetsPath assets路径
   * @param toTargetPath 目标路径
   * @param async 是否异步操作
   */
  static async prepareDbIfNeedsByPath(protocol: DBPrepareProtocol, fromAssetsPath: string, toTargetPath: string) {
    // 检查磁盘空间
    checkDiskSpace();

    const exists = FileUtility.isFileExistAt(toTargetPath);

    if (!exists) {
      // 不存在就拷贝
      await DbFileUtility.copyDatabaseFromAssetsIfNeeds(getAppContext(), fromAssetsPath, toTargetPath);
      return;
    }

    const isOpenable = await protocol.isDbOpenable(toTargetPath)
    if (!isOpenable) {

      FileUtility.deleteFileAt(toTargetPath);

      await DbFileUtility.copyDatabaseFromAssetsIfNeeds(getAppContext(), fromAssetsPath, toTargetPath);
    }


    // 文件已存在，检查是否可打开
    // protocol.isDbOpenable(toTargetPath)
    //   .then((openable) => {
    //     if (!openable) {
    //       FileUtility.deleteFileAt(toTargetPath);
    //       DbFileUtility.copyDatabaseFromAssetsIfNeedsAsync(getAppContext(), fromAssetsPath, toTargetPath, true);
    //     } // openable 为 true 就不需要任何处理
    //   })
    //   .catch(() => {
    //     // 出现异常也认为不可打开，删除并拷贝
    //     FileUtility.deleteFileAt(toTargetPath);
    //     DbFileUtility.copyDatabaseFromAssetsIfNeedsAsync(getAppContext(), fromAssetsPath, toTargetPath, true);
    //   });
  }
}
