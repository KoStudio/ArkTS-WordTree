import { BgImage } from "../../app/views/BgImage"
import { TEUtility } from "../../common/utils/TEUtility"
import { QuestionMode, QuizManager, QuizType } from "../../models/datas/model/QuizManager"
import { SearchManager } from "../../models/datas/model/SearchManager"
import { QuizScopeAllViewConfig } from "../quiz/scope/QuizScopeAllView"
import { QuizScopeCategoryViewConfig } from "../quiz/scope/QuizScopeCategoryView"
import { QuizScopeFavoriteViewConfig } from "../quiz/scope/QuizScopeFavoriteView"
import { QuizScopeMistakeViewConfig } from "../quiz/scope/QuizScopeMistakeView"
import { QuizScopeUnitViewConfig } from "../quiz/scope/QuizScopeUnitView"

@ComponentV2
export struct SubTestView {

  // @Param isShowing    : boolean                                       = false;

  @Local items: ItemOption[] = []
  @Local hasMistakes: boolean = false
  @Local hasFavorites: boolean = false

  private mistakeRowIndex = 3
  private favoriteRowIndex = 4

  // @Monitor('isShowing')
  // onChangeOfShowing(){
  //   // if (this.isShowing && !this.hasMistakes) {
  //   //   this.loadData()
  //   // }
  // }

  aboutToAppear(): void {
    this.items   = []
    const icons  = TEUtility.getQuizTopIconResIds()
    const titles = TEUtility.getQuizTopTextStrings()
    for (let index = 0; index < icons.length; index++) {
      const icon  = icons[index]
      const title = titles[index]
      this.items.push({icon, title})
    }


    this.loadData()
  }

  loadData(){
    this.hasMistakes = SearchManager.shared.getAllMistakes().length > 0
    this.hasFavorites = SearchManager.shared.getAllFavorites().length > 0
  }

  build() {
    Stack(){
      //通用 背景
      BgImage()

      Column(){
        this.buildList()
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .height('100%')

    }

  }


  @Builder buildList(){

    List() {

      ForEach(this.items, (item: ItemOption, index: number)=>{
        ListItem(){
          this.buildRow(index, this.items[index])
        }
        .onClick(()=> {
          if (this.isEnableForRow(index) ) {
            this.handleRowClick(index)
          }

        })
      })

    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.color_background'))
    .width('100%')
    .height('100%')
    .padding(0)
  }



  @Builder
  buildRow(index: number, item: ItemOption){

    Row(){
      Row(){
        //图标
        Image(item.icon)
          .width(44)
          .height(44)
          .margin({left: 10, right: 20})

        //文字
        Text(item.title)
          .fontWeight(FontWeight.Regular)
          .fontColor(this.isEnableForRow(index) ? Color.Black: Color.Gray)
      }
      .alignItems(VerticalAlign.Center)



      Blank().layoutWeight(1)

      if (this.isEnableForRow(index)){
        Image($r('app.media.chevron_right'))
          .width(11)
          .height(16)
      }

    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding({left: 20, right: 20, top: 16, bottom: 16})
    .border({width: {bottom: 1}, color: $r('app.color.color_obscure')})
    .justifyContent(FlexAlign.SpaceBetween)
  }

  handleRowClick(index: number){

    //QuizManager.shared.questionMode = QuestionMode.Normal
    switch (index){
      case 0: QuizManager.shared.quizType = QuizType.Unit;       QuizScopeUnitViewConfig.open();     break;
      case 1: QuizManager.shared.quizType = QuizType.All;        QuizScopeAllViewConfig.open();      break;
      case 2: QuizManager.shared.quizType = QuizType.Category;   QuizScopeCategoryViewConfig.open(); break;
      case 3: QuizManager.shared.quizType = QuizType.Mistake;    QuizScopeMistakeViewConfig.open();  break;
      case 4: QuizManager.shared.quizType = QuizType.Favorite;   QuizScopeFavoriteViewConfig.open(); break;
    }
  }

  isEnableForRow(index: number): boolean {
    if(index === this.mistakeRowIndex && !this.hasMistakes){
      return false
    }
    if(index === this.favoriteRowIndex && !this.hasFavorites){
      return false
    }
    return true
  }
}

interface ItemOption {
  icon: Resource
  title: ResourceStr
}
