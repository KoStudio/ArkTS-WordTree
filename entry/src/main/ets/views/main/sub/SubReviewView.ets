import { BgImage } from "../../../app/views/BgImage";
import { SectionDatas } from "../../../common/utils/array/SectionDatas";
import { TEUtility } from "../../../common/utils/TEUtility";
import { QuestionMode, QuizManager, QuizType } from "../../../models/datas/model/QuizManager";
import { WordUser } from "../../../models/datas/myData/WordUser";
import { WordCardsViewConfig } from "../../units/wordcard/WordCardsView";
import { SearchModifier } from "@kit.ArkUI";
import { SearchManager } from "../../../models/datas/model/SearchManager";
import { TextStyleButton, TextStyleButtonStyle } from "../../../app/views/buttons/TextStyleButton";
import { DateUtils } from "../../../common/utils/DateUtils";
import { QuizStartViewConfig } from "../../quiz/start/QuizStartView";

@ComponentV2
export struct SubReviewView {

  @Param isShowing    : boolean                        = false;

  @Local sectionWords : SectionDatas<string, WordUser> = new SectionDatas()
  @Local scroller     : Scroller                       = new Scroller();



  @Monitor('isShowing')
  onChangeOfShowing(){
    if (this.isShowing){
      this.loadData()
    }
  }

  aboutToAppear(): void {
    this.loadData()
  }

  loadData(){

    this.sectionWords = SearchManager.shared.getReviewSectionedWords()

  }

  build() {
    Stack(){
      //通用 背景
      BgImage()

     Row(){
       Image($r('app.media.review_timezone'))
         .width(2)
         .height('100%')
         .objectFit(ImageFit.Cover)
         .margin({left: 15})
     }
     .width('100%')
     .backgroundColor(Color.Transparent)
     .justifyContent(FlexAlign.Start)

      Column(){
        this.buildList()
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .height('100%')

    }
    .border({width: {bottom: 1}, color: $r('app.color.color_gray_light')})

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
  buildGroupHeader(section: string, sectionIndex: number) {
    Row() {
      Image(TEUtility.getSectionReviewIcon(sectionIndex))
        .width(22)
        .height(22)
        // .margin({left: 5, right: 10})

      Text(` ${section}`)
        .margin({ top: 5, bottom: 5, left: 10, right: 10 })
        .fontColor(TEUtility.getSectionTextColor(sectionIndex))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)

      Blank().layoutWeight(1)

      TextStyleButton({
        style:           TextStyleButtonStyle.ACCENT,
        text:            $r('app.string.review_btn_retest'),
        minWidth:        66,
        textPadding:     3,
        radius:          5,
        fontSize:        15,
        onClickCallBack: () => {this.actionReTest(sectionIndex, section)}
      })
    }
    .padding({ left: 5, right: 20, top: 2, bottom: 2})
    .justifyContent(FlexAlign.Start)
    .width('100%')
    .backgroundColor('#33999999')
  }

  @Builder
  buildRowContent(word: WordUser, rowIndex: number) {
    Row(){

      ///left
      Column(){

        Text(`${word.titleEn}`)
          .fontSize(18)
          .fontColor($r('app.color.color_text'))


        Text(word.titleCn1)
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
    .padding({left: 30, top: 5, bottom: 5})
    .layoutWeight(1)
    .backgroundColor($r('app.color.color_clear'))
    .border({width: {bottom: 1}, style: BorderStyle.Dashed, color: $r('app.color.color_obscure')})
  }


  handleRowClick(sectionIndex: number, rowIndex: number){

    let words = this.sectionWords.allDatasOfSectionIndex(sectionIndex)
    WordCardsViewConfig.open({words: words, initIndex: rowIndex})

  }

  actionReTest(sectionIndex: number, section: string){

    let date                        = DateUtils.toDate(section, 'yyyy/MM/dd')
    QuizManager.shared.wrangDate    = date
    QuizManager.shared.quizType     = QuizType.Review
    QuizManager.shared.questionMode = QuestionMode.Normal
    QuizStartViewConfig.open()

  }
}