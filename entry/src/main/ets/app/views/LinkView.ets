// 导入必要的模块
import webview from '@ohos.web.webview'; // Web组件
import { ShareUtils } from '../../common/utils/ShareUtils';
import { resourceManager } from '@kit.LocalizationKit';
import { getString, ResourceUtils } from '../../common/utils/ResourceUtils';
import { common, Want } from '@kit.AbilityKit';
import { getAppContext } from '../constants/AppContext';
import { dNavBackIcon } from '../constants/AppDefines';
import { buildStandardMenu, CustomNavigationMenuItem } from '../constants/AppFunctions';
import { ItemOption, Toast } from '../../common/utils/Toast';
import { buildNavTitle } from '../constants/AppBuilders';
import { NavPathManager } from '../../pages/NavPathManager';


export namespace LinkViewConfig {

  ///导航key
  export const NavKey = "LinkView_show"

  ///打开方式
  export function NavTo(navPath: NavPathStack | undefined, param: LinkViewConfig.Param, isOpenInBrowser: boolean = false){

    ///在浏览器中打开
    if (isOpenInBrowser){
      openInSystemBrowser(param.url)
      return
    }

    if (!navPath) { return }
    navPath.pushPathByName(LinkViewConfig.NavKey, param, true)
  }

  ///默认Nav撕开
  export function open(param: LinkViewConfig.Param, isOpenInBrowser: boolean = false){
     NavTo(NavPathManager.shared.navPath, param, isOpenInBrowser)
  }

  /// 参数类型
  export interface Param {
    title: ResourceStr
    url: string
  }

}

@ComponentV2
export struct LinkView {

  // 参数
  @Param @Require title: ResourceStr; // 标题（父组件传入）
  @Param @Require url: string;   // URL地址（字符串形式）

  // 内部状态（使用 @Local 替代 @State）
  @Local webController: webview.WebviewController = new webview.WebviewController();

  build() {
    NavDestination() {
      Column() {
        // WebView组件（全屏显示）
        Web({
          src: this.url,
          controller: this.webController
        })
          .width('100%')
          .height('100%')
      }
      .backgroundColor($r('app.color.color_obscure'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .width('100%')
      .height('100%')
    }

    // 设置导航栏标题（支持本地化）
    .title(buildNavTitle(this.title))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary'))
    .menus(buildStandardMenu(this.buildMenuItems()))
    // 添加工具栏按钮
    // .toolbarConfiguration([
    //   {
    //     value: 'share', // 功能标识（可选）
    //     icon: $r('app.media.share'), // 图标资源
    //     action: () => this.shareUrl() // 点击事件
    //   }
    // ])
  }

  //Nav Menu for Create
  buildMenuItems(): CustomNavigationMenuItem[] {
    return [
      {value: "more", icon: $r('app.media.moreh'), isSvg: true, action: () => {
        ///更多
        this.actionPopMenu()
      }
      }
    ]
  }


  private actionPopMenu(){
    let options: ItemOption[] = [];

    ///分享link
    options.push(
      {text: $r('app.string.link_url_cfm_btn_sharelink'),action: ()=>{
        this.shareUrl() // 点击事件
      }})
    // 显示
    Toast.showSelectOptions('', undefined, options)
  }

  // 分享URL功能
  private shareUrl() {
    ShareUtils.shareLink(this.url, getString(this.title))
  }
}


// 在系统浏览器中打开链接
export function openInSystemBrowser(url: string): void {
  try {
    let want: Want = {
      action: 'ohos.want.action.viewData',
      uri: url,
      parameters: {
        // 可选：传递额外参数
      }
    };
    let context = getContext(getAppContext()) as common.UIAbilityContext;
    context.startAbility(want).catch(()=> {
      console.error('打开浏览器失败:');

    });
  } catch (error) {
    console.error('打开浏览器异常:', error);
  }
}