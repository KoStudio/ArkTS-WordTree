import { buildNavTitle } from "../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../app/constants/AppDefines";
import { QuestionMode, QuizManager, QuizType } from "../../models/datas/model/QuizManager";
import { NavTo } from "../../pages/NavPathManager";
import { SubTestView } from "./SubTestView";

export namespace TestTopViewConfig {

  ///导航key
  export const NavKey = "TestTopView_show"

  ///打开方式
  export function open(){
    NavTo(NavKey, undefined, true)
  }

}

@ComponentV2
export struct TestTopView{


  aboutToAppear() {

    QuizManager.shared.questionMode = QuestionMode.Normal
  }


  // MARK: - 构建页面
  build() {
    NavDestination() {
      Column() {

        SubTestView()
      }
    }
    .title(buildNavTitle(this.getNavTitle()))
    .backButtonIcon(dNavBackIcon)
    .backgroundColor($r('app.color.colorPrimary'))
  }

  private getNavTitle(): ResourceStr {
    return $r('app.string.nav_title_test');
  }

}


