import { bundleManager, common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import prompt from '@ohos.promptAction';
import web from '@ohos.web.webview';
import router from '@ohos.router';
import { DebugLog } from '../../app/debug/DebugLog';
import { getAppContext } from '../../app/constants/AppContext';

/**
 * 应用市场工具类
 * 提供拉起应用市场写评论页面的功能
 */
export class ReviewUtils {
  private static readonly TAG: string = 'ReviewUtils';



  static reviewThisApp(){
    ReviewUtils.openReviewPageByAppLink(getAppContext() as common.UIAbilityContext , ReviewUtils.getCurrentBundleName())
  }


  /**
   * 通过Deep Linking方式拉起应用市场写评论页
   * @param context - UIAbility上下文
   * @param bundleName - 应用包名
   */
  static openReviewPageByDeepLink(context: common.UIAbilityContext, bundleName: string): void {
    const deepLink: string = `store://appgallery.huawei.com/app/detail?id=${bundleName}&action=write-review`;
    const want: Want = {
      action: 'ohos.want.action.appdetail',
      uri: deepLink
    };

    context.startAbility(want)
      .then(() => {
        hilog.info(0x0000, ReviewUtils.TAG, 'DeepLink跳转应用市场写评论页成功');
      })
      .catch((err: BusinessError) => {
        hilog.error(0x0000, ReviewUtils.TAG, `DeepLink跳转失败: ${JSON.stringify(err)}`);
        ReviewUtils.handleFallback(context, bundleName, err);
      });
  }

  /**
   * 通过App Linking方式拉起应用市场写评论页
   * @param context - UIAbility上下文
   * @param bundleName - 应用包名
   */
  static openReviewPageByAppLink(context: common.UIAbilityContext, bundleName: string): void {
    const appLink: string = `https://appgallery.huawei.com/app/detail?id=${bundleName}&action=write-review`;

    context.openLink(appLink, { appLinkingOnly: false })
      .then(() => {
        hilog.info(0x0000, ReviewUtils.TAG, 'AppLink跳转应用市场写评论页成功');
      })
      .catch((err: BusinessError) => {
        hilog.error(0x0000, ReviewUtils.TAG, `AppLink跳转失败: ${JSON.stringify(err)}`);
        ReviewUtils.handleFallback(context, bundleName, err);
      });
  }

  /**
   * 处理跳转失败的备用方案
   * @param context - UIAbility上下文
   * @param bundleName - 应用包名
   * @param error - 错误对象
   */
  private static handleFallback(context: common.UIAbilityContext, bundleName: string, error: BusinessError): void {
    // 1. 显示错误提示
    prompt.showToast({
      message: '无法直接跳转应用市场',
      duration: 3000
    });

    // 2. 尝试使用WebView打开应用市场网页版
    ReviewUtils.openWebAppMarket(context, bundleName);
  }

  /**
   * 使用WebView打开应用市场网页版
   * @param context - UIAbility上下文
   * @param bundleName - 应用包名
   */
  private static openWebAppMarket(context: common.UIAbilityContext, bundleName: string): void {
    const webUrl: string = `https://appgallery.huawei.com/app/${bundleName}`;

    // 假设有一个WebViewPage页面用于展示网页
    router.pushUrl({
      url: 'pages/WebViewPage',
      params: { urlToLoad: webUrl }
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, ReviewUtils.TAG, `WebView跳转失败: ${JSON.stringify(err)}`);
      prompt.showToast({
        message: '无法打开应用市场',
        duration: 3000
      });
    });
  }

  /**
   * 获取当前应用的包名
   * @returns 当前应用的包名
   */
  static  getCurrentBundleName(): string {
    const bundleInfo =  bundleManager.getBundleInfoForSelfSync(0);
    return bundleInfo.name;
  }

  /**
   * 通过系统浏览器打开华为应用市场的Web页面
   * @param packageName 目标应用的包名
   */
  static openInWebBrowser(context: common.UIAbilityContext, packageName: string): void {
    const webUrl = `https://appgallery.huawei.com/app/detail?id=${packageName}`;

    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: webUrl
    };

    context.startAbility(want)
      .then(() => {
        hilog.info(0x0000, ReviewUtils.TAG, '通过系统浏览器打开应用市场成功');
      })
      .catch((err: BusinessError) => {
        hilog.error(0x0000, ReviewUtils.TAG, `通过系统浏览器打开失败: ${JSON.stringify(err)}`);
        DebugLog.e(`通过系统浏览器打开失败: ${JSON.stringify(err)}`);

        // 降级方案：使用应用内WebView打开
        ReviewUtils.openWebAppMarket(context, packageName);
      });
  }

}