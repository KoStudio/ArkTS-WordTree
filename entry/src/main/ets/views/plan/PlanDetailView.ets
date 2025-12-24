import { Plan } from '../../models/managers/plan/plancurve/Plan'
import { BoxType } from '../../models/managers/plan/plancurve/BoxType'
import { DateUtils } from '../../common/utils/DateUtils'
import { getString, getStringF } from '../../common/utils/ResourceUtils'
import { buildNavTitle } from '../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../app/constants/AppDefines'
import { SectionDatas } from '../../common/utils/array/SectionDatas'


export namespace PlanDetailViewConfig {

  ///导航key
  export const NavKey = "PlanDetailView_show"

  ///打开方式
  export function NavTo(navPath: NavPathStack | undefined, param: PlanDetailViewConfig.Param){
    if (!navPath) { return }

    if (param.plan ) {
      navPath.pushPathByName(PlanDetailViewConfig.NavKey, param, true)
    }
  }

  /// 参数类型
  export interface Param {
    plan      : Plan
  }

}


interface Item {
  name: ResourceStr    // 左侧标题
  value: string   // 右侧内容
}


@ComponentV2
export struct PlanDetailView {

  // ==================== 参数区 ====================
  @Param plan?: Plan | null = undefined   // 外部传入的计划对象

  // ==================== 本地状态 ====================
  @Local private sectionData: SectionDatas<string, Item> = new SectionDatas<string, Item>() // 分组数据（按区块显示）

  // ==================== 生命周期 ====================
  aboutToAppear(): void {
    this.loadData() // 组件显示前加载数据
  }

  // ==================== UI 构建函数 ====================
  build() {
    NavDestination(){
      this.buildList()
    }
    //.title(getStringF($r('app.string.plan_detail_nav_title'))) // 设置导航栏标题
    .title(buildNavTitle($r('app.string.plan_detail_nav_title')))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色
  }

  @Builder buildList(){
    List() {
      ForEach(this.sectionData.allSections(), (section: string) => {
        ListItemGroup({ space: 0, style: ListItemGroupStyle.NONE }) {
          ForEach(this.sectionData.allDatasOfSection(section), (item: Item) => {
            ListItem({ style: ListItemStyle.NONE }) {
              this.buildRow(item)
            }
            .backgroundColor(Color.White)
          })
        }
        .margin({ top: 10, bottom: 5 })
        .divider({ strokeWidth: 1 })
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_obscure'))
    .padding(0)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  // 构建列表行
  @Builder buildRow(item: Item){
    Row() {
      Text(item.name)
        .fontSize(16)
        .fontColor($r('app.color.color_text'))

      Blank().layoutWeight(1)

      Text(item.value)
        .fontSize(14)
        .fontColor($r('app.color.color_text2'))
    }
    .width('100%')
    .padding({left:10, right:10, top: 10, bottom: 10 })
    .margin(5)
  }

  // ==================== 数据加载逻辑 ====================
  private loadData(): void {
    let sectionData = new SectionDatas<string, Item>() // 清空旧数据

    if (!this.plan) return

    const plan = this.plan

    // ---------- (1) 复习间隔 ----------
    const distancesString: string[] = (plan.distances ?? [])
      .map((d: number) => {
        if (d === BoxType.New) {
          return null
        } else if (d === BoxType.Rev1) {
          return getStringF($r('app.string.plan_detail_review_day'), d)
        } else {
          return getStringF($r('app.string.plan_detail_review_days'), d)
        }
      })
      .filter((v) => v !== null)
      .map((v) => v as string)

    // ---------- (2) 标题分组 ----------
    const titleSection = 'title'
    sectionData.addSection(titleSection)
    sectionData.addSectionWithData(titleSection, { name: plan.planName ?? '', value: '' })

    // ---------- (3) 单词统计 ----------
    const wordsSection = 'words'
    sectionData.addSection(wordsSection)
    sectionData.addSectionWithData(wordsSection, {
      name: getString($r('app.string.plan_detail_txt_learned')),
      value: getStringF($r('app.string.plan_detail_words_cnt'), (plan.learnedWordIds ?? []).length)
    })
    sectionData.addSectionWithData(wordsSection, {
      name: getString($r('app.string.plan_detail_txt_wordsall')),
      value: getStringF($r('app.string.plan_detail_words_cnt'), (plan.wordIds ?? []).length)
    })

    // ---------- (4) 每日学习 / 复习规则 ----------
    const revSection = 'rev'
    sectionData.addSection(revSection)
    sectionData.addSectionWithData(revSection, {
      name: getString($r('app.string.plan_detail_txt_everydaystudy')),
      value: getStringF($r('app.string.plan_detail_words_cnt'), plan.getCountPerDay() ?? 0)
    })
    sectionData.addSectionWithData(revSection, {
      name: getStringF($r('app.string.plan_detail_txt_review')),
      value: distancesString.join(', ')
    })

    // ---------- (5) 当前天数 / 所需天数 ----------
    const daysSection = 'days'
    sectionData.addSection(daysSection)
    sectionData.addSectionWithData(daysSection, {
      name: getString($r('app.string.plan_detail_txt_cur')),
      value: getStringF($r('app.string.plan_detail_cur_day'), (plan.numOfToday ?? 0) + 1)
    })
    const needDays = plan.dayOfs ? plan.dayOfs.length : 0
    sectionData.addSectionWithData(daysSection, {
      name: getString($r('app.string.plan_detail_txt_needs')),
      value: this.getLocalizedDaysString(needDays)
    })

    // ---------- (6) 开始 / 结束日期 ----------
    const datesSection = 'dates'
    sectionData.addSection(datesSection)
    sectionData.addSectionWithData(datesSection, {
      name: getString($r('app.string.plan_detail_txt_startdate')),
      value: plan.startDate ? DateUtils.toDateString(plan.startDate) : ' -- '
    })
    sectionData.addSectionWithData(datesSection, {
      name: getString($r('app.string.plan_detail_txt_enddate')),
      value: plan.endDate ? DateUtils.toDateString(plan.endDate) : ' -- '
    })

    // 保存到本地状态
    this.sectionData = sectionData
  }

  // ==================== 工具方法 ====================
  /**
   * 根据天数返回本地化字符串（单/复数形式）
   * @param daysCnt 天数
   * @returns 本地化后的字符串
   */
  private getLocalizedDaysString(daysCnt: number): string {
    if (daysCnt === 1) {
      return getStringF($r('app.string.plan_detail_days_cnt'), daysCnt)
    } else {
      return getStringF($r('app.string.plan_detail_days_cnts'), daysCnt)
    }
  }
}