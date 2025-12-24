import { dMemberFlag } from '../../app/constants/AppDefines'
import { GlobalKey } from '../../app/constants/GlobalKey'
import { DateUtils } from '../../common/utils/DateUtils'
import { MemberManager } from '../../models/managers/member/MemberManager'
import { DayOf } from '../../models/managers/plan/plancurve/DayOf'
import { Plan } from '../../models/managers/plan/plancurve/Plan'
import { DayOfWordsViewConfig } from './DayOfWordsView'


@ComponentV2
export struct DayOfRow {

  @Param @Require dayOf: DayOf
  @Param @Require plan: Plan

  @Local cntNew           : number = 0
  @Local cntNewLearned    : number = 0
  @Local cntReview        : number = 0
  @Local cntReviewLearned : number = 0

  @Consumer(GlobalKey.kNavPath) navPath?: NavPathStack


  aboutToAppear(): void {
    this.prepareLearnDatas()
  }

  @Monitor('plan', 'dayOf')
  onChangeOfPlan(){
    this.prepareLearnDatas()
  }
  ///判断 是否是今天
  get isToday() :boolean {
    if(this.plan.startDate){
      const num = DateUtils.daysTo(new Date(), this.plan.startDate)
      return this.dayOf.num === num
    }else{
      return false
    }

  }

  build() {
    Row() {
      //左边 名称
      this.buildLeft()

      //竖线
      Divider()
        .width(1) // 竖线宽度 1px
        .height(60) // 高度，可根据需要调整
        .backgroundColor($r('app.color.color_gray_light')) // 灰色

      //右边 进度圆环
      this.buildRight()

    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({left: 10, right: 10})
    .backgroundColor($r('app.color.color_white'))
    .borderRadius(5)
    .border({width: this.isToday ? 1 : 0, radius: 2, color: $r('app.color.colorAccent')})
    //.shadow({ radius: 5 })
    .onClick(() => {
      // 点击整行跳转
      DayOfWordsViewConfig.open({dayOf: this.dayOf, plan: this.plan})
    })
  }

  @Builder buildLeft() {
    Column(){
      Text(this.dayOf.numString + (MemberManager.shared.checkDayOfUsable(this.dayOf.num, false) ? "" : dMemberFlag))
        .fontColor($r('app.color.colorPrimaryDark'))
        .fontSize(22)

      Text(this.plan.dateStringOn(this.dayOf))
        .fontColor($r('app.color.color_detail'))
        .fontSize(16)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .width(120)
  }

  @Builder buildRight() {
    Row({space: 20}){

      //学习
      this.buildProgress($r('app.string.dayofs_cell_txt_study'), this.cntNewLearned, this.cntNew)

      //复习
      this.buildProgress($r('app.string.dayofs_cell_txt_review'), this.cntReviewLearned, this.cntReview)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.SpaceAround)
  }

  @Builder buildProgress(title: ResourceStr, curCnt: number, totalCnt: number){

    Stack(){

      // 圆形进度
      Progress({ value: curCnt, total: totalCnt, type: ProgressType.Ring })
        .color($r('app.color.colorAccent'))
        .width('100%')
        .height('100%')
        .style({ strokeWidth: 2 })

      Column(){
        Text(totalCnt.toString())
          .fontSize(12)
          .align(Alignment.Center)

        Text(title)
          .fontSize(12)
          .align(Alignment.Center)

      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .padding(2)
    .width(66)
    .height(66)
    .align(Alignment.Center)
    .visibility(totalCnt > 0 ? Visibility.Visible : Visibility.Hidden)
  }

  private prepareLearnDatas(){
    // 获取新学和复习的单词列表
    const wordIdsForNew: number[]    = this.plan.wordIdsWhenNew(this.dayOf)
    const wordIdsForReview: number[] = this.plan.wordIdsWhenReview(this.dayOf)

    // 转换成 Set，方便后续过滤
    const wordIdsForNewSet         = new Set(wordIdsForNew)
    const wordIdsForReviewSet      = new Set(wordIdsForReview)

    // 单词数量
    const wordsCntForNew           = wordIdsForNew.length
    const wordsCntForReview        = wordIdsForReview.length

    // 已学单词数量（过滤掉不属于当前 dayOf 的单词）
    const learnedWordsCntForNew    = (this.plan?.learnedWordIdsWhenNew(this.dayOf))
      .filter(id => wordIdsForNewSet.has(id)).length

    const learnedWordsCntForReview = (this.plan?.learnedWordIdsWhenReview(this.dayOf))
      .filter(id => wordIdsForReviewSet.has(id)).length

    this.cntNew                    = wordsCntForNew
    this.cntReview                 = wordsCntForReview
    this.cntNewLearned             = learnedWordsCntForNew
    this.cntReviewLearned          = learnedWordsCntForReview
  }

}