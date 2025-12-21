import { GlobalKey } from '../app/constants/GlobalKey';
import { PrivacyManager } from '../common/components/Privacy/PrivacyManager';
import { ResourceUtils } from '../common/utils/ResourceUtils';
import { PrivacyPopup } from '../common/components/Privacy/PrivacyPopup';
import { logEvent, Logger } from '../common/components/Logger/Logger';
import { getAppContext } from '../app/constants/AppContext';
import { NavTitleView } from '../app/views/NavTitleView';
import { navigationTo } from './NavigationTo';
import { NavPathManager } from './NavPathManager';
import { SubLearnView } from '../views/main/sub/SubLearnView';
import { SubReportView } from '../views/main/sub/report/SubReportView';
import { SubReviewView } from '../views/main/sub/SubReviewView';
import { SubTestView } from '../views/main/sub/SubTestView';
import { SubListView } from '../views/main/sub/list/SubListView';
import { TintImage } from '../app/views/TintImage';
import { NavBarView } from '../app/views/NavBarView';
import { SetViewConfig } from '../views/main/under/SetView';
import { MemberView } from '../views/setting/member/MemberView';


@Entry
@ComponentV2
struct Index {

  @Local selectedIndex           : number        = 0;

  @Provider(GlobalKey.kNavPath) navPath          : NavPathStack = NavPathManager.shared.navPath;

  @Local isPrivacyAgreed         : boolean       = false; // 隐私弹窗 是否已同意
  @Local private isShowMemberView: boolean       = false;

  @Local refreshSearch           : boolean       = false;

  async aboutToAppear(): Promise<void> {

    //隐私弹窗 是否已经同意
    this.isPrivacyAgreed = PrivacyManager.shared.checkAgreement()

    /// 隐私弹窗 已同意时
    this.onChangeOfIsPrivacyAgreed()


  }

  @Monitor('isPrivacyAgreed')
  onChangeOfIsPrivacyAgreed(){
    //隐私弹窗 已同意
    if (this.isPrivacyAgreed) {
      //初始化 日志记录
      Logger.preInit(getAppContext())
      Logger.initilaze()

      logEvent("index_showed") //日志
    }
  }

  build() {

    ///已同意
    if (this.isPrivacyAgreed){

      ///正常显示
      this.buildMain()
    }else{

      //隐私政策
      this.buildPrivacyPopup()
    }

  }

  @Builder
  buildMain(){
    Navigation(this.navPath) {

      Stack() {

        //首页 背景图片
        // this.buildBg()

        Column(){
          this.buildNavBar()
          this.customTab()
        }
        .layoutWeight(1)
        .bindSheet($$this.isShowMemberView, this.buildMemberView(), {
          detents: [SheetSize.FIT_CONTENT],
          preferType: SheetType.CENTER,
          showClose: false
        })

      }
      .height('100%')

    }
    .width('100%')
    .padding({bottom: 0})
    .margin(0)
    // .backgroundColor($r('app.color.color_nav_bg'))
    .mode(NavigationMode.Stack)
    .title(this.buildNavTitle())
    .titleMode(NavigationTitleMode.Mini)
    .hideTitleBar(true)
    //.hideTitleBar(this.selectedIndex === 0 ? true : false)
    .hideBackButton(true)
    // .navBarWidth('100%') // 导航栏宽度
    // .menus(this.createNavMenuItems())
    // .key(`nav_menus_${this.menuRefreshKey}`)
    .navDestination(this.navigationTo)
    .navBarPosition(NavBarPosition.Start)

    .onNavBarStateChange((isVisible: boolean) => {
      ///监听Navigation的onNavBarStateChange事件。
      ///在回调函数中，如果变量isVisible为true，表明首页正在显示。
      //https://developer.huawei.com/consumer/cn/doc/architecture-guides/shaking_to_dialog_1-ts_11-0000002340361193
      if (isVisible) {
        ///相当于popBack到首页时，执行刷新（nav上的FavIcon有可能改变了）
        this.refreshSearch = !this.refreshSearch // 执行刷新
      }
    })
  }

  @Builder buildBg(){
    Image($r('app.media.main_bg'))
      .width('100%')
      .height('100%')
      .objectFit(ImageFit.Fill)
      .position({ x: 0, y: 0 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // 构建导航栏
  @Builder buildNavBar(){
    NavBarView({
      title: this.navTitle(),

      navBarBgColor:  $r('app.color.colorPrimary'),
      navBarTitleColor: $r('app.color.color_white'),

      // 左侧按钮数组（只有一个图标按钮）
      leftButtons: [
        {
          icon: $r('app.media.ic_menu'), //set
          onClick: () => {
            SetViewConfig.open()
          }
        }
      ],

      // 右侧按钮数组
      rightButtons: [
        {
          icon: $r('app.media.search'),
          onClick: () => {  }
        },
        {
          icon: $r('app.media.ic_more'),
          onClick: () => {  }
        },
      ]
    })
      .height(50)
  }

  @Builder buildNavTitle(){
    NavTitleView({title: this.navTitle()})
  }
  navTitle(): ResourceStr {
    switch (this.selectedIndex){
      case 0: return $r('app.string.nav_title_main_learn')
      case 1: return $r('app.string.nav_title_main_list')
      case 2: return $r('app.string.nav_title_main_review')
      case 3: return $r('app.string.nav_title_main_report')
      default : return $r('app.string.nav_title_main_learn')
    }
  }

  @Builder
  customTab(){
    Tabs({barPosition: BarPosition.End}) {

      // learn
      TabContent() {
        SubLearnView()
      }
      .tabBar(this.tabBuilder(0, $r('app.string.tab_title_learn'), $r("app.media.tab_f_0_1")))

      // list
      TabContent() {
        SubListView({isShowing: this.selectedIndex === 1, refreshSearch: this.refreshSearch})
      }
      .tabBar(this.tabBuilder(1, $r('app.string.tab_title_list'), $r("app.media.tab_f_1_1")))

      //review
      TabContent() {
        SubReviewView({isShowing: this.selectedIndex === 2})
      }
      .tabBar(this.tabBuilder(2, $r('app.string.tab_title_review'), $r("app.media.tab_f_3_1")))

      //report
      TabContent() {
        SubReportView({isShowing: this.selectedIndex === 3})
      }
      .tabBar(this.tabBuilder(3, $r('app.string.tab_title_report'), $r("app.media.tab_f_4_1")))


    }
    .width('100%')
    .layoutWeight(1)
    //.barHeight(52)
    .scrollable(false) //禁止滚动切换
    .barMode(BarMode.Fixed) //tabBar固定or滚动
    .animationDuration(0) //禁止切换内容时的动画
    .backgroundColor($r('app.color.color_main_tab_bg'))
    .onContentWillChange((currentIndex: number, commingIndex: number) => {
      this.selectedIndex = commingIndex
      return true
    })

  }

  @Builder
  tabBuilder(index: number, title: string | Resource, icon: Resource) {
    Column({space: 8}) {
      TintImage({
        src: icon,
        colorStr: this.selectedIndex === index ? '#80CA56' : '#9E9E9E',
        iconSize: 20
      })
      // Image(icon)
      //   .size({ width: 25, height: 25 })
      //   .fillColor(this.selectedIndex === index ? $r('app.color.color_main_tab_selected') : $r('app.color.color_main_tab_tint'))


      Text(title)
        .fontSize('12')
        .fontColor($r('app.color.color_main_tab_tint'))
        .fontColor(this.selectedIndex === index ? '#80CA56': '#9E9E9E')
    }
    .justifyContent(FlexAlign.SpaceAround)

  }

  @Builder
  navigationTo<T>(name: string, param: T){
    navigationTo(name, param)
  }

  @Builder
  buildPrivacyPopup() {

    //隐私页面
    PrivacyPopup({
      htmlContent: ResourceUtils.resourceToString(
        $r('app.string.privacy_pop_content')
      ),
      onAgree: ()=> {
        //同意
        this.isPrivacyAgreed = true

        if (this.isPrivacyAgreed) {
          Logger.preInit(getAppContext())
          Logger.initilaze()
        }
      }

    })

  }

  @Builder buildMemberView() {
    MemberView({isShowing: this.isShowMemberView, $isShowing:(val: boolean)=>{
      //关闭会员页面
      this.isShowMemberView = val

    }})
  }
}

