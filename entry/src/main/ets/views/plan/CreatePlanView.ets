import { GlobalKey } from "../../app/constants/GlobalKey"
import { IconTintButton } from "../../app/views/buttons/IconTintButton"
import { TextButton } from "../../app/views/buttons/TextButton"
import { TextCheckBox } from "../../app/views/buttons/TextCheckBox"
import { TextStyleButton, TextStyleButtonStyle } from "../../app/views/buttons/TextStyleButton"
import { LinkViewConfig } from "../../app/views/LinkView"
import { NumberPickerView } from "../../app/views/NumberPickerView"
import { DateUtils } from "../../common/utils/DateUtils"
import { getString } from "../../common/utils/ResourceUtils"
import { Toast } from "../../common/utils/Toast"
import { BoxType, DistanceFromBase, DistanceHelper } from "../../models/managers/plan/plancurve/BoxType"
import { Plan } from "../../models/managers/plan/plancurve/Plan"
import { PlanManager } from "../../models/managers/plan/plancurve/PlanManager"
import { SettingManager } from "../../models/managers/setting/SettingManager"
import { util } from "@kit.ArkTS"
import { DayOfsViewConfig } from "./DayOfsView"
import { logEvent } from "../../common/components/Logger/Logger"
import { buildNavTitle } from "../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../app/constants/AppDefines"
import { LoadingUtility } from "../../common/utils/LoadingUtility"
import { NavTo } from "../../pages/NavPathManager"

export namespace CreatePlanViewConfig {

  ///导航key
  export const NavKey = "CreatePlanView_show"

  ///编辑plan
  export function openWithPlan(plan: Plan){
    open({plan: plan})
  }

  ///新建plan的快速方法
  export function openWithNew(wordIds: number[], name: string, bookId: number){
    open({initWordIds: wordIds, initName: name, bookId: bookId})
  }

  ///打开方式
  function open(param: CreatePlanViewConfig.Param){
    NavTo(NavKey, param, true)
  }

  /// 参数类型
  export interface Param {
    initWordIds  ?: number[] | null
    initName     ?: string   | null
    bookId       ?: number   | null

    plan         ?: Plan     | null
  }

}

@ComponentV2
export struct CreatePlanView {
  /// 入口参数
  @Param initWordIds  ?: number[]  | null    = undefined      // 单词ID数组
  @Param initName     ?: string    | null   = undefined      // 计划名称
  @Param bookId       ?: number    | null    = undefined      // 书本 ID
  @Param plan         ?: Plan      | null   = undefined      // 已存在的计划（可选）

  @Local wordIds       : number[]           = []       // 单词ID数组
  @Local planName      : string             = ''        // 计划名称
  @Local countPerDay   : number             = 5         // 每天学习数量
  @Local days          : number             = 0

  @Local startDate        : ResourceStr        = ''        // 开始于：2025-10-16
  @Local reviewDays       : BoxType[]          = DistanceHelper.allBoxTypes() // 复习间隔天数
  @Local selectedReviews  : Set<number>        = new Set([1, 2, 4, 7, 15, 30]) // 选中状态

  @Local private chkRev1  : boolean            = true
  @Local private chkRev2  : boolean            = true
  @Local private chkRev4  : boolean            = true
  @Local private chkRev7  : boolean            = true
  @Local private chkRev15 : boolean            = true
  @Local private chkRev30 : boolean            = true

  private oldPlan         : Plan | null        = null
  private tempPlan        : Plan | null        = null

  private readonly dayMax  : number             = 500       // 总数大于500时才有效

  /// 导航路径
  @Consumer(GlobalKey.kNavPath) private navPath?: NavPathStack         // 导航路径状态

  get chkReviews(): boolean[] {
    return [
      this.chkRev1,
      this.chkRev2,
      this.chkRev4,
      this.chkRev7,
      this.chkRev15,
      this.chkRev30
    ]
  }

  aboutToAppear(): void {
    this.refreshUI()
  }

  @Monitor('countPerDay','chkRev1', 'chkRev2', 'chkRev4', 'chkRev7', 'chkRev15', 'chkRev30')
  private onChangeOfCreateConditions(){
    this.createTempPlan()
  }

  // MARK: - 渲染主视图
  build() {
    NavDestination(){
      Column({ space: 12 }) {
        this.buildPanel()
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_obscure'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    // .title($r('app.string.plan_create_nav_title'))
    .title(buildNavTitle($r('app.string.plan_create_nav_title')))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色
  }

  @Builder buildPanel(){
    // 主体内容区域
    Column({ space: 16 }) {

      // --- 计划名称输入框 ---
      this.buildPlanName()

      // --- 每天学习数量设置 ---
      this.buildEveryDaySection()

      // --- 学习所需天数按钮 ---
      this.buildNeedSection()

      // --- 开始日期 ---
      Text(this.startDate)
        .fontSize(14)
        .fontColor('#666')
        .margin({ top: 10 })

      // --- 复习区块 ---
      this.buildReviewSection()

      // --- 保存按钮 ---
      TextButton({text: $r(this.oldPlan?.planId ? 'app.string.plan_create_btn_update' : 'app.string.plan_create_btn_save'), minWidth: 166, isEnabled: this.wordIds.length > 0, onClickCallBack: ()=>{ this.actionOk()}})

    }
    .width('95%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#33000000' })
  }

  @Builder buildPlanName(){
    Column(){
      // --- 计划名称输入框 ---
      TextInput({
        placeholder: $r('app.string.plan_create_txt_name'),
        text: this.planName,
      })
        .width('100%')
        .height(50)
        .backgroundColor(Color.White)
        .border({width: {bottom: 1}, color: Color.Gray,radius: 0})
        .margin({ top: 12 })
        .onChange(value => this.planName = value)

      Row(){
        // --- 单词总数 ---
        Text(this.getLocalizedTotalWordsString(this.wordIds.length))//`共 ${this.totalWords} 个单词`
          .fontSize(12)
          .fontColor($r('app.color.color_text2'))
          .align(Alignment.End)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')

  }

  // MARK: - 每天学习数量
  @Builder buildEveryDaySection() {
    Row({ space: 8}) {
      // 标签
      Text($r('app.string.plan_create_txt_everyday'))
        .fontSize(14)
        .fontColor($r('app.color.color_text'))

      Blank().layoutWeight(0.5)

      // 使用 NumberPickerView
      NumberPickerView({
        minValue: 1,
        maxValue: Math.min(this.wordIds.length, this.dayMax),
        selectedValue: this.countPerDay,
        onSelected: (val: number) => {
          this.countPerDay = val
        }
      })
        .width('60%')
        .height(50)

      Blank().layoutWeight(0.5)

      // 单位
      Text($r('app.string.plan_create_txt_everydayunit'))
        .fontSize(14)
        .fontColor($r('app.color.color_text'))
    }
  }

  // MARK: - 所需天数
  @Builder buildNeedSection() {
    Stack() {
      Row(){
        Text($r('app.string.plan_create_txt_need'))
          .fontSize(14)
          .fontColor('#333')

      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Row(){
        //88天
        TextStyleButton({
          text: this.getLocalizedDaysString(this.days),
          style: TextStyleButtonStyle.DEFAULT,
          isEnabled: this.wordIds.length > 0,
          onClickCallBack: ()=>{
            this.actionViewPlan()
          }})
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
  }

  // MARK: - 复习部分
  @Builder buildReviewSection() {
    Column({ space: 8 }) {
      Row({ space: 6}) {
        Text($r('app.string.plan_create_txt_review'))
          .fontSize(14)
          .fontColor($r('app.color.color_text'))

        ///?按钮
        IconTintButton({icon: ($r('app.media.shelp')), onClickCallBack: ()=>{
          this.actionHelp()
        }})
      }

      // 上排按钮（+1、+2、+4）
      Row({ space: 20}) {
        //+1天
        TextCheckBox({text: this.getRevDayStr(BoxType.Rev1), checked: this.chkRev1!!})

        //+2天
        TextCheckBox({text: this.getRevDayStr(BoxType.Rev2) + "  ", checked: this.chkRev2!!})

        //+4天
        TextCheckBox({text: this.getRevDayStr(BoxType.Rev3), checked: this.chkRev4!!})
      }
      .margin({left: 10})
      .justifyContent(FlexAlign.Start)

      // 下排按钮（+7、+15、+30）
      Row({ space: 20}) {
        //+7天
        TextCheckBox({text: this.getRevDayStr(BoxType.Rev4), checked: this.chkRev7!!})

        //+15天
        TextCheckBox({text: this.getRevDayStr(BoxType.Rev5), checked: this.chkRev15!!})

        //+30天
        TextCheckBox({text: this.getRevDayStr(BoxType.Rev6), checked: this.chkRev30!!})
      }
      .margin({left: 10})
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private getRevDayStr(revDays: DistanceFromBase): string {
    let format = getString($r('app.string.plan_create_chk_reviewdays'))
    if (revDays === BoxType.Rev1) {
      format = getString($r('app.string.plan_create_chk_reviewday'))
    }
    return util.format(format, revDays)
  }

  private refreshUI() {
    // 清空单词数组
    let wordIds: number[] = []

    // plan 已经存在时
    if (this.plan) {
      wordIds.push(...this.plan.wordIds)

      // 已经存在的 plan
      this.oldPlan       = this.plan
      this.tempPlan      = this.plan

      this.wordIds       = this.plan.wordIds
      this.planName      = this.plan.planName ||''
      this.countPerDay   = this.plan.getCountPerDay()

      //this.btnDays.setTitle(this.getLocalizedDaysString(this.plan.dayOfs.length))
      this.days = this.plan.dayOfs.length

      if (this.plan.startDate) {
        const startDateStr = DateUtils.toDateString(this.plan.startDate)
        this.startDate    = $r('app.string.plan_create_txt_start_date', startDateStr) // "开始于:  \(startDateStr)"
      }

      // 显示复习勾选框状态
      this.chkRev1  = false
      this.chkRev2  = false
      this.chkRev4  = false
      this.chkRev7  = false
      this.chkRev15 = false
      this.chkRev30 = false

      this.plan.distances.forEach((distance: number, idx: number)=>{
        switch (distance){
          case BoxType.Rev1 : this.chkRev1  = true; break;
          case BoxType.Rev2 : this.chkRev2  = true; break;
          case BoxType.Rev3 : this.chkRev4  = true; break;
          case BoxType.Rev4 : this.chkRev7  = true; break;
          case BoxType.Rev5 : this.chkRev15 = true; break;
          case BoxType.Rev6 : this.chkRev30 = true; break;
        }
      })

    } else if (this.initWordIds) {
      this.wordIds = this.initWordIds || []

      // 新建时
      wordIds.push(...this.wordIds)

      this.planName  = this.initName ?? ''
      this.startDate = ''

      // 新建 plan
      this.createTempPlan()
    }

    //更新单词ID
    this.wordIds = wordIds

  }

  // MARK: - 点击帮助
  private actionHelp() {
    //baidu wiki
    let addr = "https://baike.baidu.com/item/%E9%81%97%E5%BF%98%E6%9B%B2%E7%BA%BF/7278665?fromtitle=%E8%89%BE%E5%AE%BE%E6%B5%A9%E6%96%AF%E8%AE%B0%E5%BF%86%E6%9B%B2%E7%BA%BF&fromid=6214463&fr=aladdin"
    LinkViewConfig.NavTo(this.navPath, {title: getString($r('app.string.plan_create_txt_review')), url: addr})
  }

  ///点击复习+Days

  private actionChkReview(){
    //do nothing
    //在onChangeOfCreateCondition中刷新
  }


  // MARK: - 保存计划
  private async actionOk() {
    if (this.planName.trim().length === 0) {
      ///请输入计划名称
      Toast.showMessage($r('app.string.plan_create_msg_need_name'))
      return
    }

    

    //确定保存
    //创建重新新plan时，如果存在旧的plan，需要提示学习用户，会删除学习记录

    if (this.oldPlan?.planId) {
      this.confirmUpdatePlan(this.oldPlan.planId)
    }else {
      //非会员，检查已经创建的计划个数
      // if(!MemberManager.shared.checkPlanCount()){ return}

      //制作plan，同时传入nil的planId
      await this.createTempPlan()

      //保存
      this.savePlan()

      logEvent("CreatePlan_Save") //日志
    }
  }


  // MARK: - 点击选择天数
  private actionViewPlan() {
    if (this.tempPlan) {
      DayOfsViewConfig.open({plan: this.tempPlan})
    }

  }

  private confirmUpdatePlan(planId: number){
    Toast.showAlert({
      title: $r('app.string.plan_create_alert_update_title'),
      message: $r('app.string.plan_create_alert_update_msg'),
      secondaryButton: {value: $r('app.string.plan_create_alert_btn_cancel'), fontColor: Color.Gray, action: () => {}},
      primaryButton: {value: $r('app.string.plan_create_alert_update_btn_yes'), action: async () => {

        //制作plan，同时传入把之前存在的planId
        await this.createTempPlan(planId)

        //保存
        await this.savePlan()

      }}
    })
  }

  private async createTempPlan(planId: number | null = null){
    // 1️⃣ 参数检查
    if (!this.wordIds || this.wordIds.length === 0) {
      console.warn('[warn] wordIds 为空，无法创建计划')
      return
    }
    if (!this.planName || this.planName.trim().length === 0) {
      console.warn('[warn] planName 为空，无法创建计划')
      return
    }

    const planName: string = this.planName.trim()

    // 2️⃣ 计算复习间隔数组 distances
    // [BoxType.new.rawValue] 相当于一个固定的起始值 0（新学习）
    const distances: number[] = [BoxType.New]
    if (this.chkRev1) distances.push(BoxType.Rev1)
    if (this.chkRev2) distances.push(BoxType.Rev2)
    if (this.chkRev4) distances.push(BoxType.Rev3)
    if (this.chkRev7) distances.push(BoxType.Rev4)
    if (this.chkRev15) distances.push(BoxType.Rev5)
    if (this.chkRev30) distances.push(BoxType.Rev6)
    // this.chkReviews.forEach((chk, idx) => {
    //   if (chk) {
    //     const day = this.reviewDays[idx]
    //     if (day) {
    //       distances.push(day)
    //     }
    //   }
    // })

    // 3️⃣ 创建临时计划
    this.tempPlan = await PlanManager.createPlan(
      planId,
      planName,
      this.wordIds,
      this.bookId,
      this.countPerDay,
      distances
    )

    // 4️⃣ 更新按钮标题（使用本地化字符串）
    this.days = this.tempPlan?.dayOfs?.length ?? 0
    //const localizedStr: string = this.getLocalizedDaysString(dayCount)

  }

  // 保存计划
  private savePlan() {
    // 显示加载提示
    LoadingUtility.showLoading($r('app.string.plan_create_alert_msg_making'))

    // 异步执行保存操作
    setTimeout(async () => {
      // 保存临时计划
      await this.tempPlan?.save()
      this.oldPlan = this.tempPlan

      // 切换正在学习的计划与书本信息
      PlanManager.shared.plan                      = this.oldPlan
      // SettingManager.shared.currentBookId          = this.oldPlan?.getTempBookId() ?? 0
      // SettingManager.shared.currentBookLastLessonId = -1 // 重置当前学习课ID

      // 记录日志
      //LogEvent.log(LogEvent.Id.savePlan, 'wordCount', `${this.words.length}`)

      // 主线程回调：隐藏加载并显示完成提示
      LoadingUtility.hideLoading()
      Toast.showMessage($r('app.string.plan_create_alert_msg_make_done'))

      // 返回根视图
      this.navPath?.popToIndex(-1, true)
    }, 0)
  }

  // 根据天数获取本地化字符串（自动判断单复数）
  private getLocalizedDaysString(daysCnt?: number): ResourceStr {
    const cnt: number = daysCnt ?? 0
    if (cnt === 1) {
      // 单数
      return $r('app.string.plan_create_btn_days_cnt', cnt)
    } else {
      // 复数
      return $r('app.string.plan_create_btn_days_cnts',cnt)
    }
  }

  // 根据单词数量获取本地化字符串（自动判断单复数）
  private getLocalizedTotalWordsString(wordsCnt: number): ResourceStr {
    if (wordsCnt === 1) {
      // 单数
      return $r('app.string.plan_create_words_cnt' ,wordsCnt)
    } else {
      // 复数
      return $r('app.string.plan_create_words_cnts', wordsCnt)
    }
  }
}