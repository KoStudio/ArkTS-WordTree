import abilityAccessCtrl from '@ohos.abilityAccessCtrl'; // 导入权限管理模块
import type { Permissions } from '@ohos.abilityAccessCtrl'; // 导入权限类型定义
import bundleManager from '@ohos.bundle.bundleManager'; // 导入应用包管理模块
import common from '@ohos.app.ability.common'; // 导入Ability通用模块
import { BusinessError } from '@ohos.base'; // 导入错误类型
import promptAction from '@ohos.promptAction'; // 导入弹窗提示模块
import Want from '@ohos.app.ability.Want';
import { DebugLog } from '../../../app/debug/DebugLog';

/**
 * 权限组类型定义（类似Swift中的struct）
 * 定义不同功能所需的权限集合
 */
interface PermissionGroup {
  readonly RECORD: readonly Permissions[]; // 录音权限组
  readonly STORAGE: readonly Permissions[]; // 存储权限组
  readonly CAMERA: readonly Permissions[]; // 相机权限组
  readonly VIBRATOR: readonly Permissions[]; // 震动权限组
  readonly IMAGES: readonly Permissions[]; // 媒体读取权限组
  readonly NOTIFICATION: readonly Permissions[]; // 通知权限组
  readonly CAMERA_AND_IMAGES: readonly Permissions[]; // 相机+媒体组合权限
}

/**
 * 权限管理工具类（类似Swift中的static class）
 * 封装权限申请、检查等操作
 */
export default class PermissionManager {
  /**
   * 权限组常量声明（类似Kotlin中的companion object）
   * 包含各功能对应的权限列表
   */
  static readonly PERMISSION_GROUP: PermissionGroup = {
    RECORD: ['ohos.permission.MICROPHONE'], // 麦克风权限
    STORAGE: ['ohos.permission.STORE_PERSISTENT_DATA'], // 持久化存储权限
    CAMERA: ['ohos.permission.CAMERA'], // 相机权限
    VIBRATOR: ['ohos.permission.VIBRATE'], // 震动权限
    IMAGES: ['ohos.permission.READ_MEDIA'], // 媒体读取权限
    NOTIFICATION: ['ohos.permission.PUBLISH_AGENT_REMINDER'], // 代理提醒权限
    CAMERA_AND_IMAGES: ['ohos.permission.CAMERA', 'ohos.permission.READ_MEDIA'], // 相机+媒体组合
  };

  /**
   * 创建权限管理器实例（类似SwiftUI中的EnvironmentObject）
   * @returns 权限管理器对象
   */
  private static getAtManager(): abilityAccessCtrl.AtManager {
    return abilityAccessCtrl.createAtManager(); // 创建权限管理实例
  }

  /**
   * 同步获取应用的访问令牌ID（类似Kotlin中的同步方法）
   * @returns 应用的唯一令牌ID
   * @throws 获取失败时抛出错误
   */
  private static getAccessTokenIdSync(): number {
    try {
      // 组合标志位获取完整包信息
      const flags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_METADATA;
      // 同步获取当前应用包信息
      const info = bundleManager.getBundleInfoForSelfSync(flags);
      return info.appInfo.accessTokenId; // 返回访问令牌ID
    } catch (err) {
      throw new Error(`TokenID 获取失败: ${(err as BusinessError).code}`);
    }
  }

  /**
   * 检查单个权限授权状态（异步方法）
   * @param permission 要检查的权限名
   * @returns Promise对象，解析为是否已授权
   */
  static async checkPermission(permission: Permissions): Promise<boolean> {
    try {
      const tokenId = PermissionManager.getAccessTokenIdSync(); // 获取令牌ID
      const atMgr = PermissionManager.getAtManager(); // 获取管理器
      // 检查权限状态（类似Swift的AVAuthorizationStatus）
      const status = await atMgr.checkAccessToken(tokenId, permission);
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED; // 返回授权状态
    } catch (err) {
      console.error(`权限检查失败: ${(err as BusinessError).message}`);
      return false;
    }
  }

  /**
   * 请求权限授权（首次申请）
   * @param context UIAbility上下文（类似SwiftUI的ViewContext）
   * @param permissions 权限列表
   * @param rationale 权限说明文案（可选）
   * @returns Promise对象，解析为是否全部授权
   */
  static async requestPermissions(
    context: common.UIAbilityContext,
    permissions: Permissions[],
    rationale?: string | Resource
  ): Promise<boolean> {

    ///检查是是否已经有授权？
    const allGranted = await Promise.all(
      permissions.map(permission => PermissionManager.checkPermission(permission))
    );

    if (allGranted.every(granted => granted)) {
      return true;
    }

    // 如果有说明文案则先显示（类似SwiftUI的alert）
    if (rationale) {
      const isGo = await PermissionManager.showRationale(rationale)
     if(!isGo) {
       //用户点击取消
       return false
     }

    }
    const atMgr = PermissionManager.getAtManager();
    try {
      // 弹出系统权限申请对话框（类似Android的requestPermissions）
      const result = await atMgr.requestPermissionsFromUser(context, permissions);

      // 检查所有权限是否都被授予
      return result.authResults.every(status => status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
    } catch (err) {
      console.error(`权限请求失败: ${(err as BusinessError).code}`);
      return false;
    }
  }

  /**
   * 跳转设置页进行二次授权（类似Android的shouldShowRequestPermissionRationale）
   * @param context UIAbility上下文
   * @param permissions 权限列表
   * @returns Promise对象，解析为是否全部授权
   */
  static async requestPermissionOnSetting(
    context: common.UIAbilityContext,
    permissions: Permissions[]
  ): Promise<boolean> {
    const atMgr = PermissionManager.getAtManager();
    try {
      // 跳转到应用设置页面
      const results = await atMgr.requestPermissionOnSetting(context, permissions);
      return results.every(status =>
      status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      );
    } catch (err) {
      console.error(`二次授权失败: ${(err as BusinessError).code}`);

      // 方案3：终极回退方案（跳转应用详情页）[8](@ref)
      const want: Want = {
        action: 'action.settings.app.info',
        uri: `package:${context.abilityInfo.bundleName}`
      };
      await context.startAbility(want);

      return false;
    }
  }


  /**
   * 显示权限说明弹窗（私有方法）
   * @param message 说明文案
   * @returns Promise对象，用户点击"继续"后resolve
   */
  private static async showRationale(message: string | Resource): Promise<boolean> {
    return new Promise((resolve) => {
      // 创建系统弹窗（类似SwiftUI的Alert）
      promptAction.showDialog({
        title: '权限说明',
        message,
        buttons: [
          { text: '取消', color: '#999999' },
          { text: '继续', color: '#0A59F7' },
        ]
      }).then(res => {
        if (res.index === 1) { // 用户点击"继续"
          resolve(true);
        }else{
          resolve(false);
        }
      });
    });
  }

  /**
   * 确保权限授权（完整流程：先申请→失败则跳设置页）
   * @param context UIAbility上下文
   * @param permissions 权限列表
   * @param rationale 说明文案（可选）
   * @returns Promise对象，解析为最终是否全部授权
   */
  static async ensurePermission(
    context: common.UIAbilityContext,
    permissions: Permissions[],
    rationale?: string | Resource
  ): Promise<boolean> {
    // 先尝试常规申请
    const grantedAll = await PermissionManager.requestPermissions(context, permissions, rationale);
    if (grantedAll) return true;
    // 失败后跳转设置页
    return await PermissionManager.requestPermissionOnSetting(context, permissions);
  }

  // 新增方法：带二次申请流程的权限确保
  static async ensurePermissionWithRetry(
    context: common.UIAbilityContext,
    permissions: Permissions[],
    rationale?: string | Resource,
    retryMessage?: string | Resource // 二次授权提示文案[1](@ref)
  ): Promise<boolean> {
    // 1. 首次申请
    const firstGranted = await PermissionManager.requestPermissions(context, permissions, rationale);
    if (firstGranted) return true;

    // 2. 显示二次授权提示（类似Android的shouldShowRequestPermissionRationale[4,7](@ref)）
    return new Promise<boolean>(async (resolve) => {
      promptAction.showDialog({
        title: '权限说明',
        message: retryMessage || '该功能需要权限才能使用，请前往设置开启',
        buttons: [
          { text: '取消', color: '#999999' },
          { text: '去设置', color: '#0A59F7' }
        ]
      }).then(async (res) => {
        if (res.index === 1) {
          // 3. 跳转系统设置页进行二次授权[2,5](@ref)
          const settingGranted = await PermissionManager.requestPermissionOnSetting(context, permissions);
          resolve(settingGranted);
        } else {
          resolve(false);
        }
      });
    });
  }

  // ================= 具体权限封装方法 =================

  /** 请求录音权限（封装方法） */
  static async requestRecordPermission(
    context: common.UIAbilityContext,
    rationale?: string | Resource
  ): Promise<boolean> {
    return await PermissionManager.requestPermissions(
      context,
      [...PermissionManager.PERMISSION_GROUP.RECORD],
      rationale
    );
  }

  /** 请求存储权限（封装方法） */
  static async requestStoragePermission(
    context: common.UIAbilityContext,
    rationale?: string | Resource
  ): Promise<boolean> {
    return await PermissionManager.requestPermissions(
      context,
      [...PermissionManager.PERMISSION_GROUP.STORAGE],
      rationale
    );
  }

  /** 请求相机+媒体权限（封装方法） */
  static async requestCameraAndImagesPermission(
    context: common.UIAbilityContext,
    rationale?: string | Resource
  ): Promise<boolean> {
    return await PermissionManager.requestPermissions(
      context,
      [...PermissionManager.PERMISSION_GROUP.CAMERA_AND_IMAGES],
      rationale
    );
  }

  /** 请求通知权限（封装方法） */
  static async requestNotificationPermission(
    context: common.UIAbilityContext,
    rationale?: string | Resource
  ): Promise<boolean> {
    return await PermissionManager.requestPermissions(
      context,
      [...PermissionManager.PERMISSION_GROUP.NOTIFICATION],
      rationale
    );
  }
}