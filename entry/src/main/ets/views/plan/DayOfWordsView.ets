import { GlobalKey } from "../../app/constants/GlobalKey"
import { TextButton } from "../../app/views/buttons/TextButton"
import { ArrayWords, StringWords } from "../../common/utils/array/ArrayStringUtils"
import { getString } from "../../common/utils/ResourceUtils"
import { StringUtils } from "../../common/utils/strings/StringUtils"
import { ItemOption, Toast } from "../../common/utils/Toast"
import { DayOf } from "../../models/managers/plan/plancurve/DayOf"
import { Plan } from "../../models/managers/plan/plancurve/Plan"
import { util } from "@kit.ArkTS"
import { DistanceHelper } from "../../models/managers/plan/plancurve/BoxType"
import { SettingManager } from "../../models/managers/setting/SettingManager"
import { ArrayUtils } from "../../common/utils/array/ArrayUtils"
import { IconTintButton } from "../../app/views/buttons/IconTintButton"
import { PieceCountSlideView } from "./piececountpicker/PieceCountView"
import { PlanManager } from "../../models/managers/plan/plancurve/PlanManager"
import { buildStandardMenu, CustomNavigationMenuItem } from "../../app/constants/AppFunctions"
import { logEvent } from "../../common/components/Logger/Logger"
import { buildNavTitle } from "../../app/constants/AppBuilders"
import { dMemberFlag, dNavBackIcon } from "../../app/constants/AppDefines"
import { MemberManager } from "../../models/managers/member/MemberManager"
import { NavTo } from "../../pages/NavPathManager"


export namespace DayOfWordsViewConfig {

  ///导航key
  export const NavKey = "DayOfWordsView_show"

  ///打开方式
  export function open(param: DayOfWordsViewConfig.Param){


    if (param.dayOf && param.plan) {
      NavTo(NavKey, param, true)
    }
  }

  /// 参数类型
  export interface Param {
     dayOf: DayOf
     plan: Plan

  }

}


@ComponentV2
export struct DayOfWordsView {

  @Param @Require initDayOf: DayOf
  @Param @Require initPlan: Plan

  @Local private dayOf: DayOf | null = null
  @Local private plan: Plan | null = null

  // @Local lessons: Lesson[] = []

  @Local learnedTexts: Set<string> = new Set<string>()

  @Local isShowPieceCount: boolean = false

  @Consumer(GlobalKey.kNavPath) private navPath?: NavPathStack

  aboutToAppear(): void {
    this.dayOf = this.initDayOf
    this.plan  = this.initPlan

    this.loadDatas()
  }



  build() {
    NavDestination(){
      Column() {
        this.buildList()
        //Blank().layoutWeight(1)
        this.buildFooterView()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_obscure'))
      //.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

    }
    .bindSheet($$this.isShowPieceCount, this.buildPieceCountView(), {
      detents: [SheetSize.FIT_CONTENT],
      preferType: SheetType.CENTER,//使用center在Folder上展开时能正常居中显示
      //title: {title:$r('app.string.detail_item_sort_nav_title')} ,
      showClose: false
    })
    // .title(this.dayOf?.numString) // 设置导航栏标题
    .title(buildNavTitle(this.getNavTitle()))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色
    .menus(buildStandardMenu(this.buildMenuItems()))
    .onShown(()=>{
      ///加载数据
      //this.loadDatas()

      logEvent("DayOfWordsView_onShown") //日志
    })


  }

  getNavTitle(): string {
    if (!MemberManager.shared.checkDayOfUsable(this.dayOf?.num ?? 0, false)) {
       return this.dayOf?.numString + dMemberFlag

    }else{
      return this.dayOf?.numString || ''
    }

  }

  //
  //
  // @Builder
  // buildStandardMenu(items: NavigationMenuItem[]) {
  //   Row({space: 2}){
  //     ForEach(items, (item: NavigationMenuItem) => {
  //       if (item.icon && typeof item.icon === 'object') {//优先 使用icon
  //         Image(item.icon)
  //           .width(26)
  //           .height(26)
  //           .backgroundColor(Color.Transparent)
  //           .fillColor(Color.White) //按钮 着色
  //           .onClick(() => item.action?.())
  //           .margin(10)
  //       }else { //使用文本
  //         Button() {
  //           Text(item.value)
  //             .fontSize(18)
  //             .fontColor(Color.White) //文本按钮 颜色
  //         }
  //         .backgroundColor(Color.Transparent)
  //         .onClick(() => item.action?.())
  //         .margin(10)
  //       }
  //     })
  //   }
  //   .padding(5)
  //
  // }


  //Nav Menu for Create
  buildMenuItems(): CustomNavigationMenuItem[] {
    return [
      {value: "more", icon: $r('app.media.moreh'), isSvg: true, action: () => {
        this.actionPopmenu()
      }
      }
    ]
  }


  @Builder buildList(){
    Column({ space: 0 }) {
      Row(){
        ///共10个
        // Text($r('app.string.dayof_txt_total', this.getTotalCnt()))
        //   .fontColor($r('app.color.color_text2'))
        //   .fontSize(12)
      }
      .padding(5)
      .width('100%')
      .justifyContent(FlexAlign.Start)

      // 表格视图
      List({ space: 0 }) {
        // 卡片模式
        // ForEach(this.lessons, (lesson: Lesson, index: number) => {
        //   ListItem() {
        //     this.buildLessonRow(lesson, index)
        //   }
        // })
      }
      .width('100%')
      .layoutWeight(1)
      //.height('100%')

      .backgroundColor($r('app.color.color_obscure'))
    }
    .width('100%')
    //.height('100%')
    .layoutWeight(1)
    .backgroundColor($r('app.color.color_obscure'))
    // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  // @Builder buildList(){
  //   Scroll() {
  //     Column() {
  //       ///列表
  //       Row(){
  //         ///左边 共0个
  //         Text($r('app.string.dayof_txt_total', this.getTotalCnt()))
  //           .fontColor($r('app.color.color_text2'))
  //           .fontSize(12)
  //       }
  //       .padding(5)
  //       .width('100%')
  //       .justifyContent(FlexAlign.Start)
  //
  //       ForEach(this.lessons, (lesson: Lesson, lessonIndex: number) => {
  //         this.buildLessonRow(lesson, lessonIndex)
  //       })
  //
  //       Blank().layoutWeight(1)
  //     }
  //     //.width('100%')
  //
  //   }
  //   .width('100%')
  //   .height('100%') // 设置Scroll高度
  //   .scrollBar(BarState.Auto)
  // }
  // @Builder buildLessonRow(lesson: Lesson, index: number){
  //
  //   ListRowCells({
  //     title: lesson.lessonName,
  //     textStr: lesson.texts,
  //     isShowMore: false,
  //     plan: this.plan,
  //     dayOf: this.dayOf
  //   })
  //     .margin({ bottom: 10 })
  // }


  @Builder buildFooterView(){
    Stack(){
      Row({space: 5}){

        ///学习按钮
        TextButton({text: $r('app.string.dayof_btn_study'), minWidth: 160, onClickCallBack: ()=>{this.actionStudy()}})

        //随机按钮
        IconTintButton({icon: $r('app.media.random_1'), onClickCallBack: () => { this.actionRandom()}})

      }
      .width('100%')
      .height(44)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.color_obscure'))
    .border({width: {top: 0.5}, color: Color.Gray})
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }


  @Builder buildPieceCountView() {
    if (this.plan && this.dayOf){
      PieceCountSlideView({title: this.dayOf.numString ?? '', initCount: this.plan.wordIdsWhenNew(this.dayOf).length, pickerHandler: (count: number, repeat: boolean)=>{

        this.resetPlan(count, repeat)

        // 延迟关闭 Sheet
        setTimeout(() => {

          ///关闭
          this.isShowPieceCount = false

          ///并清空存储的当前行
          this.loadDatas()
        }, 200) // 200ms 让动画先执行完再关闭

      }})
    }
  }

  private resetPlan(newCount: number, isRepeat: boolean){
    ///重新制作plan
    if (this.plan && this.dayOf) {
      let newPlan = PlanManager.createPlanFromPlan(this.plan, {pieceNo: this.dayOf.num, count: newCount}, isRepeat)
      newPlan.save()


      ///更新内存数据，刷新UI
      if (PlanManager.shared.plan?.planId == newPlan.planId) {
        ///如果是当前plan也要一并更新，否则首页上plan不会更新
        PlanManager.shared.plan = newPlan
      }

      //刷新页面
      this.plan               = newPlan
      this.dayOf              = newPlan.dayOfs.find(day => day.num === this.dayOf?.num) || null;
      this.loadDatas()
    }
  }


  /// 重新刷新数据
  private async loadDatas() {
    // 使用异步任务模拟后台线程执行
    // let lessons: Lesson[] = []
    //
    // const dayOf = this.dayOf
    // if (!dayOf || !this.plan) {
    //   return
    // }
    //
    // const unit    = new Unit()
    // unit.unitId   = dayOf.num
    // unit.unitName = getString(dayOf.numString)
    //
    // // 遍历 boxes
    // for (const box of dayOf.boxes) {
    //   const wordIds = this.plan.wordIdsFor(dayOf, [box.distance])
    //
    //   if (wordIds && wordIds.length > 0) {
    //     const lesson    = new Lesson()
    //     lesson.unitId   = dayOf.num
    //     lesson.unitName = getString(dayOf.numString)
    //     lesson.lessonId = box.distance
    //     lesson.texts    = ArrayWords.joinedWordsString(wordIds)// 词语:空格连接, 单字: 直接连接
    //
    //     if (box.distance === 0) {
    //       // 学习(新字)
    //       const formatNew    = getString($r('app.string.dayof_section_words_new'))
    //       lesson.lessonName  = util.format(formatNew, '')
    //     } else {
    //       // 复习(+N天)
    //       const formatReview = getString($r('app.string.dayof_section_words_review'))
    //       lesson.lessonName  = util.format(formatReview, DistanceHelper.distanceString(box.distance), '')
    //
    //     }
    //
    //     // 检查是否已存在相同 lessonId
    //     const existed = lessons.find(les => les.lessonId === lesson.lessonId)
    //     if (existed) {
    //       existed.texts = (existed.texts ?? '') + ' ' + ArrayWords.joinedWordsString(wordIds)
    //       existed.texts = StringUtils.trimedString(existed.texts)
    //     } else {
    //       lessons.push(lesson)
    //     }
    //   }
    // }
    //
    // // 缓存当前日期已学习过的单词
    // let learnedWordIds = this.plan.learnedWordIdsFor(dayOf)
    // // if (learnedWordIds && learnedWordIds.length > 0) {
    // //   learnedWordIds.forEach(id => this.learnedTexts.add(id))
    // // }
    //
    // this.lessons      = lessons
    // this.learnedTexts = new Set(learnedWordIds)

    // 回到主线程（UI更新）
    // postTask(() => {
    //   if (this.tableView && typeof this.tableView.reloadData === 'function') {
    //     this.tableView.reloadData()
    //   }
    //
    //   if (this.footerView) {
    //     const enabled = this.lessons.length > 0
    //     this.footerView.btn.isEnabled = enabled
    //     this.footerView.btnRandom.isEnabled = enabled
    //   }
    // })
  }
  // private getTotalCnt(): number {
  //   const totalCount = this.lessons.reduce((sum, lesson) => sum + lesson.textCount, 0);
  //   return totalCount
  // }

  actionStudy(){
    this.startStudy()

  }

  actionRandom(){
    this.startStudy(true)
  }

  /**
   * 开始学习全部单词
   * @param random 是否乱序
   */
  startStudy(random: boolean = false) {
    const dayOf = this.dayOf
    const plan = this.plan
    if (!plan || !dayOf) {
      return
    }

    ///会员检查， 当前Dayof是否可用
    if(!MemberManager.shared.checkDayOfUsable(dayOf.num ?? 0, true)) { return }


    let wordIdsOfDayOf: number[] = []

    // 按 distance 排序，新字在前，复习在后
    for (const box of dayOf.boxes) {
      const wordIds = plan.wordIdsFor(dayOf, [box.distance])
      if (wordIds && wordIds.length > 0) {
        wordIdsOfDayOf.push(...wordIds)
      }
    }

    // 有词语时，强制使用词语卡
    // if (ArrayWords.containsWords(wordIdsOfDayOf)) {
    //   SettingManager.shared.currentCardStyleType = CardStyleType.STYLE4
    // }

    // 随机乱序
    // if (random) {
    //   wordIdsOfDayOf =  ArrayUtils.shuffled(wordIdsOfDayOf)
    // }
    //
    // // 拼接文字（词语:空格连接，单字:直接连接）
    // const text = ArrayWords.joinedWordsString(wordIdsOfDayOf)
    //
    // // 跳转到学习卡片页
    // MakeViewConfig.NavTo(this.navPath, {initTexts: text, initIndex: 0, plan: plan, dayOf: dayOf})

    logEvent("DayOfWordsView_study") //日志
  }

  ///显示转到测验或挑战页面的弹出选项
  private actionPopmenu(){
    let options: ItemOption[] = []


    ///修改学习单字个数..
    options.push(
      {text: getString($r('app.string.dayof_alert_btn_edit')),action: ()=>{
        this.isShowPieceCount = true
      }})

    Toast.showActionMenu('', options)
  }
}