import { AbilityConstant, bundleManager, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import {  initAppContext, initUIContext } from '../app/constants/AppContext';
import { SystemSizeManager as SystemSizeManager } from '../common/managers/SystemSizeManager';

import { BundleUtils } from '../common/utils/BundleUtils';
import { DebugFlg } from '../app/debug/DebugFlg';


const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 强制应用使用浅色模式，不跟随系统变化
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    ///初始化全局context
    initAppContext(this.context)


    ///初始化ShareUtils
    import('../common/utils/ShareUtils').then((it)=>{it.ShareUtils.init(this.context)})

    //保存语言
    import('../common/components/Language/LanguageManager').then((it)=>{it.LanguageManager.applySavedLanguage()})

    ///初始化SE
    import('../common/components/SoundEffect/SEManager').then((it)=> {it.SEService.shared.initialize(this.context)})

    ///这里没效果，改成在UI画面index.ets中设置
    ///设置状态栏背景色
    // StatusBarUtil.setStatusBarBackgroundColor(getColor($r('app.color.color_nav_bg')))
    // StatusBarUtil.setStatusBarContentColor(getColor($r('app.color.color_nav_text')))


    ///动态初始化
    ///初始化应用数据
    setTimeout(async ()=>{
      await this.initDatas()
    },100)



    //版本更新
    this.runVersionUpdate()

    ///配置微信 登录
    this.initWxLogin(want)


  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    ///配置微信登录回调
    // import('../models/managers/sns/wx/WxLoginManager').then((it)=>{it.WXLoginManager.shared.handleWeChatCallIfNeed(want)})

    //QQ登录配置

    // import('../models/managers/sns/qq/QQLoginManager').then((it)=> {it.QQLoginManager.shared.handleResult(want)})
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');


    ///初始化Size
    SystemSizeManager.shared.init(windowStage)


    windowStage.loadContent('pages/Index', async (err) => {


      // ✅ 从主窗口获取 UIContext，并全局保存
      const uiContext = windowStage.getMainWindowSync().getUIContext()
      initUIContext(uiContext)

      // uiContext.getFont().registerFont({
      //   familyName: "STKaiti",//'Kaiti',  // 自定义字体名称
      //   familySrc: $rawfile('Fonts/kaiti_gb2312.ttf')  // 字体路径
      // });

      //////可通过setKeyboardAvoidMode接口设置键盘避让模式为KeyboardAvoidMode.RESIZE，表示压缩模式
      ///let uiContext :UIContext = windowStage.getMainWindowSync().getUIContext();
      ///uiContext.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET);



      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }


      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    //HandWriting手写套件要用，
    // 文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/pen-suite#section151484318552
    //GlobalContext.setContext(this.context);
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }


  // 使用处代码
  async initDatas() {


    import('../models/datas/book/BookDbAccess')             .then((it) => { it.BookDbAccess.shared })

    // import('../models/datas/word/WordDbAccess')                   .then((it) => { it.WordDbAccess.shared })
    import('../models/datas/myData/WordUserDbAccess')             .then((it) => { it.WordUserDbAccess.shared })
    import('../models/datas/model/SearchManager')                 .then((it) => { it.SearchManager.shared })
    import('../models/datas/book/BookManager')                    .then((it) => { it.BookManager.shared })
    import('../models/datas/basedict/BaseWordDbAccess')           .then((it) => { it.BaseWordDbAccess.shared })
    import('../models/datas/cigen/CigenWordDbAccess')             .then((it) => { it.CigenWordDbAccess.shared })


  }


  initSettings(){
    // 1. 初始化时建立自动持久化关联


    // // 接受序列化失败的回调
    // PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
    //   console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
    // });

  }


  ///配置微信登录
  initWxLogin(want: Want){
    ///////////////////////////////////////////
    ///获取appIdentifier，微信登录和微信支付需要用，需要配置在微信开放平台的appIdentifier，不是AppID，
    ///
    // (注意：不能使用自动签名：同一应用申请的debug profile或release profile中，appIdentifier一致。
    // 注：如果debug启用IDE自动签名，那么appIdentifier为随机分配（此appIdentifier不可作为应用正式的身份标识），不同于应用正式profile中的appIdentifier。
    // 参考：https://developer.huawei.com/consumer/cn/forum/topic/0204192989131047958
    ///
    ///这是自动签名获取的：6918705225533654805，不对。
    ///需要使用自己申请的debug或release时的profile，(release签名不能调试，所以只能用申请debug类型的profile)
    ///6917579325076446931
    ///6917592474741463583 //WordTree
    ///
    ///QQ登录需要获取fingerPrint的md5
    //   fingerprint = "0e5ad763ce8811a91d7de1c38a4f1f200041d4bbb458102a537f6475662298ff"//单词树
    //   fingerprintMd5 = "f138c6c6c06a0dc45c1031345e34b5aa" //单词树
    //
    // if (DebugFlg.isDebugMode()) {
    //   BundleUtils.getBundleAppIdentifier()
    // }
    ////////////////////////////////////////////////////////////

    ///配置微信登录回调
    // import('../models/managers/sns/wx/WxLoginManager').then((it)=>{
    //   // 尽早初始化微信SDK
    //   it.WXLoginManager.shared.registerApp();
    //
    //   //处理回调
    //   it.WXLoginManager.shared.handleWeChatCallIfNeed(want)}
    // )
  }


  runVersionUpdate(){


    import('../common/components/VersionChecker/VersionChecker').then(async (it)=>{
      await it.VersionChecker.shared.runVersionUpdateIfNeeded(async (oldVer, newVer) => {

        //第一次安装时
        if (oldVer == "0.0.0") {
          // import('../models/datas/myData/UserLessonManager').then(async (it) => {
          //   // 插入样本 字卡集
          //   await it.UserLessonManager.shared.createSampleData()
          // })

        }

      })
    })

  }



}