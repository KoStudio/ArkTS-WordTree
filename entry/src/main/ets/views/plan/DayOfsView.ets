import { GlobalKey } from "../../app/constants/GlobalKey"
import { ArrayWords } from "../../common/utils/array/ArrayStringUtils"
import { ItemOption, Toast } from "../../common/utils/Toast"
import { DayOf } from "../../models/managers/plan/plancurve/DayOf"
import { Plan } from "../../models/managers/plan/plancurve/Plan"
import { PlanManager, PlanManagerNotification } from "../../models/managers/plan/plancurve/PlanManager"
import { SettingManager } from "../../models/managers/setting/SettingManager"
import { DayOfRow } from "./DayOfRow"
import { PieceCountSlideView } from "./piececountpicker/PieceCountView"
import { PlanDetailViewConfig } from "./PlanDetailView"
import json from "@ohos.util.json"
import { SimpleEventBus } from "../../common/components/eventbus/SimpleEventBus"
import { buildStandardMenu, CustomNavigationMenuItem } from "../../app/constants/AppFunctions"
import { CreatePlanViewConfig } from "./CreatePlanView"
import { buildNavTitle } from "../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../app/constants/AppDefines"
import { NavTo } from "../../pages/NavPathManager"
import { MemberManager } from "../../models/managers/member/MemberManager"
import { WordCardsViewConfig } from "../card/wordcard/WordCardsView"
import { DetailCardsViewConfig } from "../card/detail/DetailCardsView"
import { WordUser } from "../../models/datas/myData/WordUser"


export namespace DayOfsViewConfig {

  ///导航key
  export const NavKey = "DayOfsView_show"

  ///打开方式
  export function open(param: DayOfsViewConfig.Param){
    NavTo(NavKey, param, true)
  }

  /// 参数类型
  export interface Param {
    plan: Plan

  }

}

@ComponentV2
export struct DayOfsView {

  @Param @Require initPlan: Plan

  @Local private plan: Plan | null = null
  @Local private dayOfs: DayOf[] = []

  @Local isShowPieceCount: boolean = false
  @Local currentDayOf: DayOf | null = null

  private scroller: ListScroller = new ListScroller();

  @Consumer(GlobalKey.kNavPath) navPath?: NavPathStack

  private refreshKey : number = 0

  async aboutToAppear() {
    this.plan   = this.initPlan

    ///监听plan变化，有可能在DayOfWords页面修改过每日学习个数
    SimpleEventBus.on<number>(PlanManagerNotification.namePlanUpdated, async (planId)=>{
      /// plan的设置有变化，这里需要更新UI
      if (planId === ( this.plan?.planId ?? 0)) {
        this.plan = await PlanManager.getPlanByPlanId(planId)
        this.loadData()
      }
    })
  }

  aboutToDisappear(): void {
    ///取消监听
    SimpleEventBus.off(PlanManagerNotification.namePlanUpdated)
  }

  @Monitor('plan')
  private loadData() {
    // this.dayOfs = this.plan?.dayOfs || []
    this.dayOfs = [...(this.plan?.dayOfs || [])]
    this.refreshKey += 1
  }

  build() {
    NavDestination(){
      Stack(){

        //构建列表
        this.buildList()
      }
    }
    //.title($r('app.string.dayofs_nav_title')) // 设置导航栏标题
    // .title(this.plan?.planName)
    .title(buildNavTitle(this.plan?.planName))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色
    .bindSheet($$this.isShowPieceCount, this.buildPieceCountView(), {
      detents: [SheetSize.FIT_CONTENT],
      preferType: SheetType.CENTER,//使用center在Folder上展开时能正常居中显示
      //title: {title:$r('app.string.detail_item_sort_nav_title')} ,
      showClose: false
    })
    .menus(buildStandardMenu(this.buildMenuItems()))
    .onShown(()=>{
      this.loadData()
    })

  }

  @Builder buildList(){
    Column() {


      // 单元列表
      if (this.dayOfs) {
        List({ space: 10, scroller: this.scroller }) {
          ForEach(this.dayOfs, (dayOf: DayOf, index: number) => {
            ListItem() {
              // dayOf行
              DayOfRow({dayOf: dayOf, plan: this.plan!})
            }
            .margin({left: 10, right:10})
            .backgroundColor(Color.Transparent)
            .swipeAction({

              end: {
              builder: () => { this.buildSwipeButtons(index) },
              onAction: () => { this.gotoStudy(index)}
            }})

          }, (dayOf: DayOf, index: number) => json.stringify(dayOf) +"_"+index.toString() +"_"+ this.refreshKey)
        }
        .width('100%')
        .height('100%')
        // .onItemDelete((index: number) => {return this.deleteUnits([index])}) // 删除事件
        .divider({ strokeWidth: 0, color: Color.Transparent })
      }

    }
    .padding({ top: 10 })
    .backgroundColor($r('app.color.color_obscure'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
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

        ///更多
        this.actionPopMenu()
      }
      }
    ]
  }

  @Builder buildSwipeButtons(index: number){

    Row(){

      ///修改
      this.buildSwipeButton($r('app.string.dayofs_cell_btn_edit'), $r('app.color.colorAccent'), ()=>{
        this.currentDayOf     = this.dayOfs[index]//储存当前dayOf
        this.isShowPieceCount = true //显示PieceView
        this.scroller.closeAllSwipeActions()// 关闭滑动行
      })

      ///学习
      this.buildSwipeButton($r('app.string.dayofs_cell_btn_study'), $r('app.color.colorPrimary'), ()=>{
        ///去学习页面
        this.gotoStudy(index)
      })
    }
    .alignItems(VerticalAlign.Center)
    .height('100%')

  }


  @Builder buildSwipeButton(text: ResourceStr, bgColor: Resource = $r('app.color.colorPrimary'), onCallback:()=>void){
    Button() {
      Text(text)
        .fontSize(16)
        .fontColor(Color.White)
    }
    .borderRadius(0)
    .padding(6)
    .height('100%')
    .width('auto')  // 根据内部内容自适应宽度
    .constraintSize({ minWidth: 44 })  // 指定最小宽度为
    .type(ButtonType.Normal)
    .backgroundColor(bgColor)
    .onClick(onCallback)
  }

  @Builder buildPieceCountView() {
    if (this.plan && this.currentDayOf){
      PieceCountSlideView({title: this.currentDayOf.numString ?? '', initCount: this.plan.wordIdsWhenNew(this.currentDayOf).length, pickerHandler: (count: number, repeat: boolean)=>{

        this.resetPlan(count, repeat)
        ///关闭
        this.isShowPieceCount = false


      }})
    }
  }

  private resetPlan(newCount: number, isRepeat: boolean){
    ///重新制作plan
    if (this.plan && this.currentDayOf) {
      let newPlan = PlanManager.createPlanFromPlan(this.plan, {pieceNo: this.currentDayOf.num, count: newCount}, isRepeat)
      newPlan.save()


      ///更新内存数据，刷新UI
      if (PlanManager.shared.plan?.planId == newPlan.planId) {
        ///如果是当前plan也要一并更新，否则首页上plan不会更新
        PlanManager.shared.plan = newPlan
      }

      //刷新页面
      this.plan               = newPlan
      this.dayOfs = [...(newPlan.dayOfs || [])]  // ✅ 关键：新建数组引用
    }
  }

  private actionPopMenu(){
    let options: ItemOption[] = [];

    ///查看plan详细
    options.push(
      {text: $r('app.string.dayofs_alert_btn_detail'),action: ()=>{
        PlanDetailViewConfig.open({plan: this.plan!})
      }})

    /////编辑plan
    options.push(
      {text: $r('app.string.dayofs_alert_btn_edit'),action: ()=>{
        CreatePlanViewConfig.openWithPlan(this.plan!)
      }})

    /////删除plan
    options.push(
      {text: $r('app.string.dayofs_alert_btn_remove'),action: ()=>{
        //弹窗一：Alert
        this.actionConfirmRemovePlan()

      }})

    ///清空学习记录
    options.push(
      {text: $r('app.string.dayofs_alert_btn_clear'),action: async ()=>{

        await this.plan?.deleteLearn()
        this.loadData()
      }})

    // 显示
    Toast.showSelectOptions('', undefined, options)
  }

  ///确认删除Plan
  actionConfirmRemovePlan(){
    Toast.showConfirm({
      msg: $r('app.string.dayofs_alert_msg_delete_plan'),
      btnYes: $r('app.string.dayofs_alert_btn_delete'),
      yesAction: async ()=>{
        ///如果删除的是当前正在学习的plan，需要置为nil
        if (this.plan?.planId === PlanManager.shared.plan?.planId) {
          PlanManager.shared.plan = null
        }

        //删除plan
        await this.plan?.delete()

        //直接返回首页
        this.navPath?.pop(true)//?.popToIndex(0)
      }
    })

  }

  // 批量删除单元
  private gotoStudy(index: number){

    //关闭滑动行
    this.scroller.closeAllSwipeActions()

    if (!this.plan) return;

    const dayOf = this.dayOfs[index];
    if (!dayOf) return;

    ///会员检查， 当前Dayof是否可用
    if(!MemberManager.shared.checkDayOfUsable(dayOf.num ?? 0, true)) { return }

    let words: WordUser[] = []

    // 按 distance 排序，新字在前，复习在后
    for (const box of dayOf.boxes) {
      words.push(...this.plan.wordsFor(dayOf, [box.distance]))
    }

    // 缓存当前日份中已经学习过的wordIds
    const learnedIds = new Set(this.plan.learnedWordIdsFor(dayOf))

    // 默认第一个
    // 自动获取下一个未学习的
    let indexToShow = words.findIndex(w => !learnedIds.has(w.idx || 0));
    if (indexToShow < 0) indexToShow = 0;


    //打开详细
    this.gotoDetail(words, indexToShow)

  }

  gotoDetail(words: WordUser[], index: number = 0){
    if (!this.plan) return;

    const dayOf = this.dayOfs[index];
    if (!dayOf) return;

    if (SettingManager.shared.planQuickLearn) {
      WordCardsViewConfig.open({words: words, initIndex: index, plan: this.plan, dayOf: dayOf})
    }else{
      DetailCardsViewConfig.open({words: words, initIndex: index, plan: this.plan, dayOf: dayOf})
    }

  }

}

