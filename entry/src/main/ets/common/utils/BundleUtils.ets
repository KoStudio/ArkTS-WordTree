import { bundleManager, common } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { StringCrypto } from "./strings/StringCrypto";

export class BundleUtils {

  // 获取Bundle信息的封装方法
  static getBundleInfoSync(): bundleManager.BundleInfo {
    // 1. 组合标志位（关键修正）
    const bundleFlags =
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_METADATA
      | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_HAP_MODULE
      | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_ABILITY
      | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION

    // 2. 调用API获取信息
    const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags);

    // 3. 返回有效数据
    return bundleInfo;
  }

  /**
   * 获取appIdentifier
   */
  static getBundleAppIdentifier() {
    // 根据给定的bundle名称获取BundleInfo。
    // 使用此方法需要申请 ohos.permission.GET_BUNDLE_INFO权限。
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO;
    try {
      bundleManager.getBundleInfoForSelf(bundleFlags).then(async (data) => {
        //获取appIdentifier
        let appIdentifier = data.signatureInfo.appIdentifier;

        let fingerprint = data.signatureInfo.fingerprint.toLowerCase() // 获取 fingerprint

        let fingerprintMd5 = await StringCrypto.md5(fingerprint)

        console.info('getBundleAppIdentifier successfully. Data: ' + appIdentifier + ', fingerprint:' + fingerprint + ', md5(fingerprint):'+ fingerprintMd5);
      }).catch((err: BusinessError) => {
        console.error('getBundleAppIdentifier failed. Cause: ' + err.message);
      });
    } catch (error) {
      console.error('getBundleAppIdentifier failed:' + error.message);
    }
  }
}

