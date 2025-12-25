import { IconTintButton } from "../../../app/views/buttons/IconTintButton"
import { TextButton } from "../../../app/views/buttons/TextButton"
import { SimpleEventBus } from "../../../common/components/eventbus/SimpleEventBus"
import { DateUtils } from "../../../common/utils/DateUtils"
import { getStringF } from "../../../common/utils/ResourceUtils"
import { Book } from "../../../models/datas/book/Book"
import { BookManager } from "../../../models/datas/book/BookManager"
import { SearchManager } from "../../../models/datas/model/SearchManager"
import { DayOf } from "../../../models/managers/plan/plancurve/DayOf"
import { Plan } from "../../../models/managers/plan/plancurve/Plan"
import { PlanManager, PlanManagerNotification } from "../../../models/managers/plan/plancurve/PlanManager"
import { SettingManager } from "../../../models/managers/setting/SettingManager"
import { BookListViewConfig } from "../../books/BookListView"
import { UnitsViewConfig } from "../../learn/UnitsView"
import { CreatePlanViewConfig } from "../../plan/CreatePlanView"
import { DayOfsViewConfig } from "../../plan/DayOfsView"
import { DayOfWordsViewConfig } from "../../plan/DayOfWordsView"
import { QuickLearnViewConfig } from "../../quicklearn/QuickLearnView"
import { QuizChallengeView, QuizChallengeViewConfig } from "../../quiz/running/QuizChallengeView"
import { ChallengeTopViewConfig } from "../../test/ChallengeTopView"
import { TestTopViewConfig } from "../../test/TestTopView"

@ComponentV2
export struct SubLearnView {

  @Param isShowing        : boolean                    = false;
  @Param refreshData      : boolean                    = false;

  @Local bookManager: BookManager = BookManager.shared
  @Local book: Book | null = this.bookManager.currentBook

  @Local unitsCount    : number = 0
  @Local wordsCount    : number = 0

  @Local cntLearned: number     = 0
  @Local cntCorrected: number   = 0
  @Local cntWrang: number       = 0

  @Local plan  : Plan | null = null
  @Local dayOf : DayOf | null = null

  @Local planBtnText : ResourceStr  = $r('app.string.main_curve_btn_create_plam')
  @Local planInfoText : ResourceStr = $r('app.string.main_curve_txt_info_create')

  aboutToAppear(): void {
    if (!BookManager.shared.currentBook) {
      BookListViewConfig.open({ isShowAllOnly: true }) //首次进入，需要下载单词本
    }else{
      this.loadData()
    }

    ///监听plan变化，有可能在DayOfWords页面修改过每日学习个数
    SimpleEventBus.on<number>(PlanManagerNotification.namePlanUpdated, async (planId)=>{
      /// plan的设置有变化，这里需要更新UI
      await this.loadPlanData()
    })

  }

  aboutToDisappear(): void {
    ///取消监听
    SimpleEventBus.off(PlanManagerNotification.namePlanUpdated)
  }

  @Monitor('isShowing')
  onChangeOfShowing(){
    if (this.isShowing){
      this.loadData()
    }
  }

  @Monitor('refreshData')
  onChangeOfRefresh(){
    ///返回时也要刷新
    if (this.isShowing) {
      //收藏，常错，未测，有可能变化，需要刷新
      this.loadData()
    }
  }


  @Monitor('bookManager.currentBook')
  async onChangeOfBook(){
    this.book         = this.bookManager.currentBook
    await SearchManager.shared.refreshData()

    this.loadData()
  }

  async loadData(){

    this.unitsCount   = this.book?.unitsCount ?? 0
    this.wordsCount   = this.book?.wordsCount ?? 0

    if (SearchManager.shared.getAllWords().length === 0) {
      await SearchManager.shared.refreshData()
    }

    this.cntLearned   = SearchManager.shared.getLearnedWords().length
    this.cntCorrected = SearchManager.shared.getCorrectedWords().length
    this.cntWrang     = SearchManager.shared.getWrongWords().length

   await this.loadPlanData()

  }

  async  loadPlanData(){
    this.plan   = await this.getPlan()
    this.dayOf  = await this.getDayOf()

    if (this.plan) {
      this.planBtnText = $r('app.string.main_curve_btn_study_start')
      if (this.dayOf) {
        this.planInfoText = getStringF($r('app.string.main_curve_txt_info_days'), this.dayOf.num + 1, this.plan.wordIdsWhenNew(this.dayOf)?.length ?? 0)
      }else{
        this.planInfoText = getStringF($r('app.string.main_curve_txt_info_days2'), this.plan.dayOfs.length, this.plan.wordIdsAll?.length ?? 0)

      }
      PlanManager.shared.plan = this.plan
    }else{
      this.planBtnText  = $r('app.string.main_curve_btn_create_plam')
      this.planInfoText = $r('app.string.main_curve_txt_info_create')
    }
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 12 }) {
          this.InfoPanel()
          this.ButtonPanel()
          if (SettingManager.shared.enableCurve){
            this.CurvePanel()
          }else{
            this.TodayPanel()
          }


        }
        .padding(10)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_background'))
    .border({width: {bottom: 1}, color: $r('app.color.color_gray_light')})
  }


  @Builder InfoPanel() {
    Column({ space: 10 }) {
      this.InfoTitleRow()
      this.InfoCountRow()
      this.InfoLearnTestRow()
    }
    .padding(10)
  }

  @Builder InfoTitleRow() {
    Text(this.book?.bookName || $r('app.string.main_study_txt_no_books'))
      .fontSize(28)
      .fontWeight(FontWeight.Bold)
      .textAlign(TextAlign.Center)
  }

  @Builder InfoCountRow() {
    Row({ space: 20 }) {
      // this.InfoBox(getStringF($r('app.string.main_study_txt_info_units'), this.unitsCount ), '#66CD40')
      // this.InfoBox(getStringF($r('app.string.main_study_txt_info_words'), this.wordsCount), '#26C9FF')

      Text(getStringF($r('app.string.main_study_txt_info_units'), this.unitsCount ))
        .width('45%')
        .padding(5)
        .textAlign(TextAlign.Center)
        .fontSize(16)
        .fontColor('#66CD40')
        .backgroundColor(Color.Transparent)
        .border({width: 1, color: '#66CD40', radius: 16})


      Text(getStringF($r('app.string.main_study_txt_info_words'), this.wordsCount))
        .width('45%')
        .padding(5)
        .textAlign(TextAlign.Center)
        .fontSize(16)
        .fontColor('#26C9FF')
        .backgroundColor(Color.Transparent)
        .border({width: 1, color: '#26C9FF', radius: 16})

    }
    .margin({top: 20})
  }

  @Builder InfoBox(text: string, color: string) {
    Text(text)
      .width('45%')
      .padding(5)
      .textAlign(TextAlign.Center)
      .fontSize(16)
      .fontColor(color)
      .backgroundColor(Color.Transparent)
      .border({width: 1, color: color, radius: 16})
  }

  @Builder InfoLearnTestRow() {
    Row({ space: 8 }) {
      this.LearnTestItem($r('app.media.ic_yixuexi'), $r('app.string.main_study_txt_info_learned'), ()=> `${this.cntLearned}`, '#66CD40')// '已学习'
      Blank().width(20)
      this.LearnTestItem($r('app.media.ic_yiceyan'), $r('app.string.main_study_txt_info_tested'), ()=> `${this.cntCorrected + this.cntWrang}`, '#26C9FF') //'已测验'
    }
    .margin({top: 10})

  }

  @Builder
  LearnTestItem(icon: Resource, title: ResourceStr, value: () => ResourceStr, valueColor: string) {
    Row({ space: 4 }) {
      Image(icon)
        .width(15)
        .height(11)
        .objectFit(ImageFit.Contain)

      Text(title)
        .fontSize(14)
        .fontColor($r('app.color.color_text2'))

      Text(value()).fontSize(26).fontColor(valueColor)
    }
    .alignItems(VerticalAlign.Bottom)
  }

  @Builder
  ButtonPanel() {
    Column({ space: 10 }) {

      Row({ space: 10 }) {
        this.MainButton($r('app.string.main_study_btn_quickremember'), $r('app.media.ic_kuaisujiyi'), '#8ACD2C', ()=>{ QuickLearnViewConfig.open() })
        this.MainButton($r('app.string.main_study_btn_study'), $r('app.media.ic_xuexi'), '#26C9FF', ()=>{ UnitsViewConfig.open() })
      }

      Row({ space: 10 }) {
        this.MainButton($r('app.string.main_study_btn_test'), $r('app.media.ic_ceyan'), '#A15DFD', ()=>{ TestTopViewConfig.open() })
        this.MainButton($r('app.string.main_study_btn_challenge'), $r('app.media.ic_tiaozhan'), '#FD56A1', ()=>{ ChallengeTopViewConfig.open() })
      }
    }
  }




  @Builder
  MainButton(title: ResourceStr, icon: Resource, bgColor: ResourceColor, onClick:()=>void) {
    Button() {
      Column({ space: 6 }) {
        Image(icon)
          .width(48)
          .height(48)

        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Normal)
          .fontColor(Color.White)
      }
    }
    .layoutWeight(1)
    .height(100)
    .type(ButtonType.ROUNDED_RECTANGLE)
    .backgroundColor(bgColor)
    .borderRadius(4)
    .onClick(onClick)
  }

  @Builder
  TodayPanel() {
    Stack() {
      Image($r('app.media.bg_banner'))
        .width('100%')
        .height(140)
        .objectFit(ImageFit.Cover)

      Row(){
        Text('Excellent\n   English').fontSize(32).fontColor(Color.White).margin({ left: 10, top: 10 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
    }

  }



  @Builder
  CurvePanel() {
    Column() {
      Column({ space: 8 }) {
        Row() {
          Text($r('app.string.main_curve_txt_curve'))
            .fontSize(13)
            .fontWeight(FontWeight.Normal)
            .fontColor($r('app.color.color_text2'))


          Blank()
          IconTintButton({icon: $r('app.media.list'), iconSize: 22, iconColor: $r('app.color.color_gray'), onClickCallBack: () => {
            ///DayOfs
            this.actionCurveList()
          }})
        }
        .width('100%')

        Column({ space: 6 }) {
          //Button('').width(180).height(32)
          //创建计划
          TextButton({text: this.planBtnText, minWidth: 200, onClickCallBack: ()=>{

            /// +创建计划/开始学习
            this.actionCurveStudy()
          }})


          ///创建学习计划，开始记忆曲线
          Text(this.planInfoText)
            .fontSize(14)
            .fontColor($r('app.color.color_text2'))
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({left: 10,right:10, top: 10, bottom: 30})
      .backgroundColor(Color.White)
      .borderRadius(4)
    }
    .padding(10)
    .backgroundColor('#EEEEEE')

  }


  actionCurveStudy(){

    if (!this.book) {
      return
    }


    if (this.plan) {
      //CreatePlanViewConfig.openWithPlan(this.plan)
      if (this.dayOf) {
        DayOfWordsViewConfig.open({plan: this.plan, dayOf: this.dayOf})
      }else{
        DayOfsViewConfig.open({plan: this.plan})
      }
    }else{
      const wordIds = SearchManager.shared.getAliveWordIds()
      CreatePlanViewConfig.openWithNew(wordIds, this.book.bookName ?? '', this.book.bookId ?? 0)
    }


  }
  actionCurveList(){

    if (this.plan) {
      DayOfsViewConfig.open({plan: this.plan})
    }else{
      this.actionCurveStudy()
    }


  }

  async getPlan(): Promise<Plan | null> {

    const bookId = BookManager.shared.currentBook?.bookId
    if (!bookId) {
      return null
    }

    return await PlanManager.getPlanByBookId(bookId)
  }

  /// 当前正在学习的 dayOf
  async getDayOf(): Promise<DayOf | null> {
    let plan = await this.getPlan()
    const startDate = plan?.startDate;
    if (startDate) {

      // 当前第几天，start from 0
      const dayNumIndex = DateUtils.daysTo(startDate, new Date());

      // 获取当前(今天)的 DayOf
      return plan?.dayOfs?.find(d => d.num === dayNumIndex) ?? null;

    } else {
      return null;
    }
  }
}



