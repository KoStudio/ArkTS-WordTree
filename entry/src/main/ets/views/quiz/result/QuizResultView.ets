import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { BgImage } from '../../../app/views/BgImage'
import { TextStyleButton, TextStyleButtonStyle } from '../../../app/views/buttons/TextStyleButton'
import { getStringF } from '../../../common/utils/ResourceUtils'
import { QuizManager, QuizType } from '../../../models/datas/model/QuizManager'
import { SearchConstants } from '../../../models/datas/model/SearchManager'
import { WordUser } from '../../../models/datas/myData/WordUser'
import { MemberManager } from '../../../models/managers/member/MemberManager'
import { NavPathManager, NavPop, NavPopToIndex, NavPopTop, NavTo } from '../../../pages/NavPathManager'
import { WordCardsViewConfig } from '../../card/wordcard/WordCardsView'
import { dMemberFlag } from '../../../app/constants/AppDefines';
import { MemberView } from '../../setting/member/MemberView'

export namespace QuizResultViewConfig {

  ///导航key
  export const NavKey = "QuizResultView_show"

  ///打开方式
  export function open(){
    NavTo(NavKey, undefined, true)
  }

}

@ComponentV2
export struct QuizResultView {

  @Local score:          number         = 0
  @Local comment:        ResourceStr    = ""
  @Local commentColor:   ResourceColor  = $r('app.color.colorAccent')
  @Local isAllCorrect:   boolean        = false
  @Local correctWords:   WordUser[]     = []
  @Local wrongWords:     WordUser[]     = []
  @Local questionWords:  WordUser[]     = []

  @Local imgResult:      Resource | ''   = ''

  @Local private isShowMemberView      : boolean       = false

  aboutToAppear(): void {

    this.loadData()
  }

  loadData(){
    this.score         = QuizManager.shared.score
    this.imgResult     = QuizManager.shared.getCommentImage(this.score)
    this.comment       = QuizManager.shared.getCommentText(this.score)
    this.commentColor  = QuizManager.shared.getCommentColorResource(this.score)
    this.correctWords  = QuizManager.shared.correctWords
    this.wrongWords    = QuizManager.shared.wrongWords
    this.questionWords = QuizManager.shared.questionWords
    this.isAllCorrect  = this.correctWords.length === this.questionWords.length
  }

  build() {

    NavDestination(){
      Stack(){

        //通用 背景
        BgImage()

        Column(){

          // 主要内容区域 - 使用权重布局填满剩余空间
          this.buildResultPanel()

          // 列表区域
          this.buildListView()

          // 底部操作栏
          this.buildFooter()
        }

      }

    }
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色
    .onBackPressed(()=>{
      //返回上上一页
      this.actionBack()
      return true
    })

  }
  getNavTitle(): ResourceStr {
    return $r('app.string.nav_title_quiz_result')

  }

  @Builder
  buildResultPanel() {
    Column() {

      Row() {
        ///正确率
        Text($r('app.string.quiz_result_score_rate'))
          .fontSize(16)
          .fontColor($r('app.color.color_detail'))
          .margin({ left: 10 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      // 结果图标和分数
      Row() {
        Image(this.imgResult)
          .width(38)
          .height(38)

        ///100%
        Text(`${this.score}%`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.colorAccent'))
          .margin({ left: 10 })
      }
      .padding(10)
      .justifyContent(FlexAlign.Center)

      // 评论和计数
      Row() {
        Text(this.comment)
          .fontSize(18)
          .fontColor(this.commentColor)


       Row(){
          //全10问
         Text(getStringF($r('app.string.quiz_result_score_count_all'), this.questionWords.length))
           .fontSize(14)
           .fontColor($r('app.color.color_detail'))
           .textAlign(TextAlign.End)

         ///正确 9问
         Text(getStringF($r('app.string.quiz_result_score_count_correct'), this.correctWords.length))
           .fontSize(14)
           .fontColor($r('app.color.color_detail'))
           .textAlign(TextAlign.End)
           .margin({left: 10})
       }

      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(10)
      .margin({ top: 10 })
    }
    .width('100%')
    .height(120)
    .margin({ top: 5, bottom: 5 })
  }



  // 构建列表区域
  @Builder
  buildListView() {
    Column() {
      // 分隔线
      Image($r('app.media.quiz_result_seperator'))
        .width('100%')
        .height(1)

      List({ space: 5 }) {
        ForEach(this.questionWords, (word: WordUser, index: number) => {
          ListItem() {
           this.buildRowContent(index, word)
          }
          .onClick(()=>{
            this.handleRowClick(index)
          })
        }, (item: string, index?: number) => `${index}-${item}`)
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 3 })
    }
    .width('100%')
    .layoutWeight(1)

  }

  @Builder
  buildRowContent(rowIndex: number, word: WordUser) {
    Row(){

      ///left
      Column(){

        Text(`${rowIndex + 1}`)
          .fontSize(28)
          .fontColor($r('app.color.color_link'))
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)

      ///mid
      Column(){

        Text(`${word.titleEn}`)
          .fontSize(18)
          .fontColor($r('app.color.color_text'))
          .margin({left: 15})


        Text(word.titleCn1ClippedShort)
          .fontSize(15)
          .fontColor($r('app.color.color_detail'))
          .margin({left: 15, top: 5})
      }
      .margin({left:5})
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)


      Blank().layoutWeight(1)

      //right
      Row({space: 10}){
        Image(word.lastResultType === SearchConstants.TEST_RESULT_CORRECT ? $r('app.media.list_right2') : $r('app.media.list_wrong'))
          .width(37)
          .height(37)
      }

    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding(10)
    .layoutWeight(1)
    .backgroundColor($r('app.color.color_clear'))
    .border({width: {bottom: 1}, style: BorderStyle.Dashed, color: $r('app.color.color_obscure')})
  }

  handleRowClick(rowIndex: number){
    //   goto card
    WordCardsViewConfig.open({words: this.questionWords, initIndex: rowIndex})
  }

  // 构建底部操作栏
  @Builder
  buildFooter() {
    Row() {
      TextStyleButton({
        style:           TextStyleButtonStyle.SOLID,
        text:            $r('app.string.quiz_result_btn_txt_retry'),
        onClickCallBack: () => {this.actionRetry()}
      })

      TextStyleButton({
        style:           TextStyleButtonStyle.SOLID,
        text:            dMemberFlag + getStringF($r('app.string.quiz_result_btn_txt_mistake')),
        onClickCallBack: () => {this.actionMistake()}
      })
        .visibility(this.isAllCorrect ? Visibility.Hidden : Visibility.Visible)
        .bindSheet($$this.isShowMemberView, this.buildMemberView(), {
          detents: [SheetSize.FIT_CONTENT],
          preferType: SheetType.CENTER,
          showClose: false
        })

      TextStyleButton({
        style:           TextStyleButtonStyle.SOLID,
        text:            $r('app.string.quiz_result_btn_txt_next'),
        onClickCallBack: () => {this.actionNext()}
      })

    }
    .padding(5)
    .width('100%')
    .backgroundColor($r('app.color.color_foot'))
    .justifyContent(FlexAlign.SpaceAround)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }



  @Builder buildMemberView() {
    MemberView({isShowing: this.isShowMemberView, $isShowing:(val: boolean)=>{
      //关闭会员页面
      this.isShowMemberView = val

    }})
  }

  actionBack(){

    const stackSize = NavPathManager.shared.navPath.size();       // 栈大小
    const targetIndex = stackSize - 3;           // 上上一页的索引（栈顶是当前页）
    if (targetIndex >= 0) {
      NavPopToIndex(targetIndex)
    } else {
      NavPopTop()             // 栈中页数不足，回到根页
    }
  }

 actionRetry(){
    NavPop()
 }

 actionMistake(){

   ///会员检查
   if(!MemberManager.shared.checkRetestMistakeUsable(true)) {
     this.isShowMemberView = true
     return
   }

    let words = QuizManager.shared.wrongWords
   QuizManager.shared.createNewQuizWithWords(words)
   NavPop()
   
 }

 actionNext(){

   ///下一单元
   if (QuizManager.shared.quizType === QuizType.Unit && QuizManager.shared.nextUnit() !== null) {
     QuizManager.shared.loadScopeWords()
     QuizManager.shared.createNewQuiz()
     NavPop()
   }else{

     ///返回首页
     NavPopTop()
   }
 }


}