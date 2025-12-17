import { BgImage } from "../../../../app/views/BgImage";
import { TextButton } from "../../../../app/views/buttons/TextButton";
import { GraphPart } from "../../../../app/views/CircleView";
import { getString } from "../../../../common/utils/ResourceUtils";
import { Mistake, MistakeHelper } from "../../../../models/datas/model/Mistake";
import { SearchManager } from "../../../../models/datas/model/SearchManager";
import { GraphInfoPanel } from "./GraphInfoPanel";
import { ChartPart, RandarChartV2 } from "./RadarView";


// ======================= Color =======================
export class ColorTestInfo {
  static readonly Correct : string = "#F6687C";
  static readonly Wrong   : string = "#629DEC";
  static readonly Still   : string = "#41C5EE";
}

export class ColorMistake {
  static readonly WrangsOnly1   : string = "#F6687C";
  static readonly Wrangs1_3     : string = "#629DEC";
  static readonly Wrangs3_5     : string = "#41C5EE";
  static readonly Wrangs5_10    : string = "#9FD468";
  static readonly Wrangs10_Over : string = "#F78F5D";
}

@ComponentV2
export struct SubReportView {

  @Param isShowing    : boolean                        = false;

  @Local private cntAll       : number = 0;
  @Local private cntLearned   : number = 0;

  @Local private cntCorrected : number = 0;
  @Local private cntWrang     : number = 0;
  @Local private cntStill     : number = 0;
  @Local private cntMistakes  : [number, [Mistake, number][]] = [0, []];

  @Local private testParts: GraphPart[] = []
  @Local private mistakeParts: GraphPart[] = []

  @Local chartData: ChartPart[] = [
    // new ChartPart('数学', 100, 75, '#FF6B6B'),
    // new ChartPart('语文', 100, 85, '#4ECDC4'),
    // new ChartPart('英语', 100, 60, '#45B7D1'),
    // new ChartPart('物理', 100, 90, '#96CEB4'),
    // new ChartPart('化学', 100, 70, '#FECA57'),
    // new ChartPart('生物', 100, 80, '#FF9FF3')
  ];

  @Monitor('isShowing')
  onChangeOfShowing(){
    if (this.isShowing){
      this.loadData()
    }
  }


  aboutToAppear(): void {
    this.loadData()
  }

  build() {
    Stack() {
      //通用 背景
      BgImage()


      Scroll() {
        Column({ space: 10 }) {
          this.buildLearnInfoPanel()
          this.buildTestInfoPanel()
          this.buildMistakeInfoPanel()
          this.buildCategoryChartView()

          Blank().layoutWeight(1)
        }
        .justifyContent(FlexAlign.Start)

      }
      .width('100%')
      .height('100%')
    }
  }


  @Builder buildLearnInfoPanel(){

    Column({ space: 10 }) {

      // up "学习状况"
      Text($r('app.string.report_title_learn'))
        .fontSize(18)
        .fontColor('#76A7F1')
        .margin({top: 10, left: 10})


      // mid 主面板
      Column() {

        ///已学习单词数
        Text($r('app.string.report_txt_learn_wordscount'))
          .fontSize(15)
          .fontColor($r('app.color.color_text'))
          .margin({top: 10, left: 20})



        Row() {
          //进度条
          Progress({ value: this.cntLearned, total: this.cntAll, type: ProgressType.Linear })
            .foregroundColor('#76A7F1')
            .backgroundColor($r('app.color.color_obscure'))
            .height(30)
            .layoutWeight(1)

          Text(`${this.cntLearned}/${this.cntAll}`)
            .fontColor($r('app.color.color_detail'))
            .fontSize(13)
            .margin({ left: 5 })
        }
        .width('100%')
        .padding(10)
        .justifyContent(FlexAlign.End)

      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})

  }

  @Builder buildTestInfoPanel(){

    Column(){
      GraphInfoPanel({
        title: $r('app.string.report_title_test'),
        titleColor: '#EC9C7A',
        parts: this.testParts,
        allCount: this.cntAll,
        precision: 1 //小数点后1位
      })
    }
    .borderRadius(5)
  }

  @Builder buildMistakeInfoPanel(){
    Column(){
      GraphInfoPanel({
        title: $r('app.string.report_title_mistake'),
        titleColor: '#F55775',
        parts: this.mistakeParts,
        allCount: this.cntMistakes[0],
        precision: 0 //小数点后0位
      })

    }
    .borderRadius(5)
    // .backgroundColor(Color.White)
  }


  @Builder buildCategoryChartView(){
   Column(){
    Row(){
      // 正确率 （分类别）
      Text($r('app.string.report_title_category_radar'))
        .fontSize(18)
        .fontColor('#ff21a9be')
        .margin({top: 10, left: 10})
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)


     // 使用雷达图组件
     RandarChartV2({
       parts: this.chartData,
       chartWidth: 320,
       chartHeight: 320
     })

       .width('100%')
       .height(320)
   }
   .margin({left: 10, right: 10, top: 10, bottom: 30})
   .width('100%')
   .justifyContent(FlexAlign.Center)
   .alignItems(HorizontalAlign.Center)

  }

  private async loadData() {
    // 模拟获取数据
    this.cntAll     = SearchManager.shared.getAliveWords().length
    this.cntLearned = SearchManager.shared.getLearnedWords().length

    //テスト状況
    this.cntCorrected = SearchManager.shared.getCorrectedWords().length
    this.cntWrang     = SearchManager.shared.getWrongWords().length
    this.cntStill     = this.cntAll - this.cntCorrected - this.cntWrang;

    ///Test 圆环图
    this.testParts = [
      { partName: getString($r('app.string.report_txt_test_correct')), count: this.cntCorrected, color: ColorTestInfo.Correct },
      { partName: getString($r('app.string.report_txt_test_wrang')), count: this.cntWrang, color: ColorTestInfo.Wrong },
      { partName: getString($r('app.string.report_txt_test_still')), count: this.cntStill, color: ColorTestInfo.Still }
    ]

    ///Mistake 圆环图
    this.cntMistakes             = SearchManager.shared.getMistakesWithCount()
    let cntAllMistakes: number   = this.cntMistakes[0]
    this.mistakeParts            = []
    let mistakeColors : string[] = [ColorMistake.WrangsOnly1, ColorMistake.Wrangs1_3, ColorMistake.Wrangs3_5, ColorMistake.Wrangs5_10, ColorMistake.Wrangs10_Over]
    // 遍历第二项数组
    for (let i = 0; i < this.cntMistakes[1].length; i++) {
      const item    = this.cntMistakes[1][i];
      const mistake = item[0];   // Mistake
      const cnt     = item[1];   // number

      this.mistakeParts.push({ partName: MistakeHelper.localizedName(mistake), count: cnt, color: mistakeColors[i] },)
    }

    ///分类 ChartView
    let categories = SearchManager.shared.getAllCategories()
    this.chartData = []
    this.chartData.push(new ChartPart(getString($r('app.string.report_txt_chart_all')), this.cntAll, this.cntCorrected))
    for (let i = 0; i < categories.length; i++) {
      const category = categories[i];
      const allCount = category.aliveWords.length;
      const curCount = category.correctedWords.length;
      this.chartData.push(new ChartPart(category.categoryName, allCount, curCount))
    }

  }

}