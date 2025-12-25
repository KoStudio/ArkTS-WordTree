import { GlobalKey } from "../../app/constants/GlobalKey"
import { TextButton } from "../../app/views/buttons/TextButton"
import { ArrayWords, StringWords } from "../../common/utils/array/ArrayStringUtils"
import { getString, getStringF } from "../../common/utils/ResourceUtils"
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
import { SectionDatas } from "../../common/utils/array/SectionDatas"
import { WordUser } from "../../models/datas/myData/WordUser"
import { WordCardsViewConfig } from "../card/wordcard/WordCardsView"
import { TEUtility } from "../../common/utils/TEUtility"
import { Box } from "../../models/managers/plan/plancurve/Box"
import { DetailCardsViewConfig } from "../card/detail/DetailCardsView"
import { TextCheckBox } from "../../app/views/buttons/TextCheckBox"


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


  @Local  sectionWords  : SectionDatas<string, WordUser> = new SectionDatas()

  @Local scroller                   : Scroller = new Scroller();

  @Local isShowPieceCount: boolean = false


  @Local isQucklearn: boolean = SettingManager.shared.planQuickLearn

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
      .backgroundColor($r('app.color.color_background'))
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
    Column() {
      List({ space: 0,scroller: this.scroller}) {
        // 内层unit列表
        ForEach(this.sectionWords.allSections(), (section: string, sectionIndex: number) => {
          ListItemGroup({ header: this.buildGroupHeader(section, sectionIndex), style: ListItemGroupStyle.NONE }) {

            ForEach(this.sectionWords.allDatasOfSectionIndex(sectionIndex), (word: WordUser, rowIndex: number) => {
              ListItem() {
                this.buildRowContent(word, rowIndex)
              }
              .onClick(()=>{
                this.handleRowClick(sectionIndex, rowIndex)
              })
              .margin({ bottom: 1 })
            },(word: WordUser, rowIndex: number)=>`${word.titleEn}_${rowIndex}`)

          }
        }, (section: string, sectionIndex: number) => `${section}_${sectionIndex}`)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .sticky(StickyStyle.Header)


    }
    .padding({ top: 0 })
    .backgroundColor($r('app.color.color_transparent'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Start)
  }


  @Builder
  buildGroupHeader(section: string, index: number) {
    Row() {
      Text(`${section}`)
        .margin({ top: 5, bottom: 5, left: 10, right: 10 })
        // .fontColor(TEUtility.getSectionTextColor(index))
        .fontColor($r('app.color.color_list_section'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
      Blank().layoutWeight(1)
    }
    .justifyContent(FlexAlign.Start)
    .width('100%')
    .backgroundColor($r('app.color.color_list_section_bg'))
  }

  @Builder
  buildRowContent(word: WordUser, rowIndex: number) {
    Row(){

      ///left
      Column(){

        Text(`${word.titleEn}`)
          .fontSize(18)
          .fontColor($r('app.color.color_text'))


        Text(word.wordJpClippedString)
          .fontSize(15)
          .fontColor($r('app.color.color_detail'))
          .margin({left: 15, top: 5})


      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)

      //right
      Row({space: 10}){
        if (word.memo){
          //memo icon
          //TintImage({src: $r('app.media.learn_icon_memo'), iconSize: 20, colorStr:"#888888"})
          Image($r('app.media.learn_icon_memo'))
            .width(14)
            .height(17)
        }

        //录音icon
        //TintImage({src: $r('app.media.learn_icon_voice')})

      }

    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding({left: 10, top: 5, bottom: 5})
    .layoutWeight(1)
    .backgroundColor($r('app.color.color_clear'))
    .border({width: {bottom: 1}, style: BorderStyle.Dashed, color: $r('app.color.color_obscure')})
  }


  handleRowClick(sectionIndex: number, rowIndex: number){

    let words = this.sectionWords.allDatas()
    // WordCardsViewConfig.open({words: words, initIndex: this.sectionWords.indexOfAllFromIndex(rowIndex, sectionIndex)})
    let initIndex = this.sectionWords.indexOfAllFromIndex(rowIndex, sectionIndex)


    ///会员检查， 当前Dayof是否可用
    if(!MemberManager.shared.checkDayOfUsable(this.dayOf?.num ?? 0, true)) { return }

    //打开详细
    this.gotoDetail(words, initIndex)
  }

  @Builder buildFooterView(){
    Stack(){
      Row({space: 5}){

        ///学习按钮
        TextButton({text: $r('app.string.dayof_btn_study'), minWidth: 160, onClickCallBack: ()=>{this.actionStudy()}})

        ///快速学习
        TextCheckBox({text: $r('app.string.dayof_btn_chk_quicklearn'), checked: this.isQucklearn, $checked:(isChecked)=>{
          this.isQucklearn = isChecked
          SettingManager.shared.planQuickLearn = this.isQucklearn
        }})

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
    // // 如果有planId时，说明是已经保存到Db中的plan
    // // 这里需要重新读取 plan的learn数据
    // if (this.plan?.planId != null) {
    //   // 重新从db加载 plan
    //   if (this.plan.bookId != null) {
    //     this.plan = await PlanManager.getPlanByBookId(this.plan.bookId)
    //   }
    // }


    let sectionData: SectionDatas<string, WordUser> = new SectionDatas()
    let learnedWordIds: Set<number> = new Set()

    const dayOf = this.dayOf
    if (!dayOf || !this.plan) {
      return
    }

    // 遍历dayOf的boxes
    dayOf.boxes.forEach((box: Box) => {
      const words = this.plan?.wordsFor(dayOf, [box.distance])
      if (words && words.length > 0) {
        if (box.distance === 0) {
          // 学习(新字)
          const str = getStringF($r('app.string.dayof_section_words_new'), this.getStringForCommonCount(words.length))
          sectionData.addSectionWithDatas(str, words)
        } else {
          // 复习(+n天)
          const str = getStringF($r('app.string.dayof_section_words_review'), DistanceHelper.distanceString(box.distance), this.getStringForCommonCount(words.length))
          sectionData.addSectionWithDatas(str, words)
        }
      }
    })

    // 缓存当前日份中已经学习过的wordIds
    const learnedWords = this.plan?.learnedWordsFor(dayOf)
    if (learnedWords) {
      learnedWords.forEach((word: WordUser) => {
        if (word.idx != null) {
          learnedWordIds.add(word.idx)
        }
      })
    }

    // 更新UI数据
    this.sectionWords = sectionData
    // 这里需要将learnedWordIds传递给适配器，但当前DayOfWordsView没有适配器属性
    // 可能需要根据实际需求调整
  }

  /// 获取通用计数字符串
  private getStringForCommonCount(count: number): string {
    return `${count}个`
  }

  actionStudy(){
    this.startStudy()

  }


  /**
   * 开始学习全部单词
   * @param random 是否乱序
   */
  startStudy() {
    const dayOf = this.dayOf
    const plan = this.plan
    if (!plan || !dayOf) {
      return
    }

    ///会员检查， 当前Dayof是否可用
    if(!MemberManager.shared.checkDayOfUsable(dayOf.num ?? 0, true)) { return }


    let words: WordUser[] = []

    // 按 distance 排序，新字在前，复习在后
    for (const box of dayOf.boxes) {
      words.push(...plan.wordsFor(dayOf, [box.distance]))
    }

    //打开详细
    this.gotoDetail(words, 0)


    logEvent("DayOfWordsView_study") //日志
  }

  gotoDetail(words: WordUser[], index: number = 0){
    if (this.isQucklearn) {
      WordCardsViewConfig.open({words: words, initIndex: index, plan: this.plan, dayOf: this.dayOf})
    }else{
      DetailCardsViewConfig.open({words: words, initIndex: index, plan: this.plan, dayOf: this.dayOf})
    }

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