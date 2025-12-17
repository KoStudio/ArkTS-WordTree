import { bundleManager } from "@kit.AbilityKit";

// DebugFlg.ets
export class DebugFlg {
  //private static readonly isDebug: boolean = true; // 编译时配置


  static isDebugMode(): boolean {
    // return DebugFlg.isDebug;

    // 获取应用是否为Release环境
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
    let mBundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags);
    let isRelease   = !mBundleInfo.appInfo.debug; // debug为false时即Release环境

    return !isRelease

  }
}