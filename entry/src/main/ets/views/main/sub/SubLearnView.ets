import { IconTintButton } from "../../../app/views/buttons/IconTintButton"
import { TextButton } from "../../../app/views/buttons/TextButton"
import { getStringF } from "../../../common/utils/ResourceUtils"
import { Book } from "../../../models/datas/book/Book"
import { BookManager } from "../../../models/datas/book/BookManager"
import { SearchManager } from "../../../models/datas/model/SearchManager"
import { UnitsViewConfig } from "../../learn/UnitsView"
import { QuickLearnViewConfig } from "../../quicklearn/QuickLearnView"
import { QuizChallengeView, QuizChallengeViewConfig } from "../../quiz/running/QuizChallengeView"
import { ChallengeTopViewConfig } from "../../test/ChallengeTopView"
import { TestTopViewConfig } from "../../test/TestTopView"

@ComponentV2
export struct SubLearnView {

  @Local bookManager: BookManager = BookManager.shared
  @Local book: Book | null = this.bookManager.currentBook

  @Local unitsCount    : number = 0
  @Local wordsCount    : number = 0

  @Local cntLearned: number     = 0
  @Local cntCorrected: number   = 0
  @Local cntWrang: number       = 0


  @Monitor('bookManager.currentBook')
  onChangeOfBook(){
    this.book         = this.bookManager.currentBook

    this.unitsCount   = this.book?.unitsCount ?? 0
    this.wordsCount   = this.book?.wordsCount ?? 0

    this.cntLearned   = SearchManager.shared.getLearnedWords().length
    this.cntCorrected = SearchManager.shared.getCorrectedWords().length
    this.cntWrang     = SearchManager.shared.getWrongWords().length

  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 12 }) {
          this.InfoPanel()
          this.ButtonPanel()
          this.TodayPanel()
          this.CurvePanel()
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
      this.LearnTestItem($r('app.media.ic_yixuexi'), $r('app.string.main_study_txt_info_learned'), `${this.cntLearned}`, '#66CD40')// '已学习'
      Blank().width(20)
      this.LearnTestItem($r('app.media.ic_yiceyan'), $r('app.string.main_study_txt_info_tested'), `${this.cntCorrected + this.cntWrang}`, '#26C9FF') //'已测验'
    }
    .margin({top: 10})

  }

  @Builder
  LearnTestItem(icon: Resource, title: ResourceStr, value: ResourceStr, valueColor: string) {
    Row({ space: 4 }) {
      Image(icon)
        .width(15)
        .height(11)
        .objectFit(ImageFit.Contain)

      Text(title)
        .fontSize(14)
        .fontColor($r('app.color.color_text2'))

      Text(value).fontSize(26).fontColor(valueColor)
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
          IconTintButton({icon: $r('app.media.list'), iconSize: 22, iconColor: $r('app.color.color_gray'), onClickCallBack: () => {}})
        }
        .width('100%')

        Column({ space: 6 }) {
          //Button('').width(180).height(32)
          //创建计划
          TextButton({text: $r('app.string.main_curve_btn_create_plam'), minWidth: 200})


          ///创建学习计划，开始记忆曲线
          Text($r('app.string.main_curve_txt_info_create'))
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


}



