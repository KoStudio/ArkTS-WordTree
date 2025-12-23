import { buildNavTitle } from "../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../app/constants/AppDefines";
import {  NavTo } from "../../pages/NavPathManager";
import { DetailCardsViewConfig } from "../card/detail/DetailCardsView";
import { WordCardsViewConfig } from "../card/wordcard/WordCardsView";
import { UnitListView } from "./sub/UnitListView";
import { UnitWordsViewConfig } from "./UnitWordsView";


export namespace UnitsViewConfig {

  ///导航key
  export const NavKey = "UnitsView_show"

  ///打开方式
  export function open(){
    NavTo(UnitsViewConfig.NavKey, undefined, true)
  }

}

@ComponentV2
export struct UnitsView {



  build() {
    NavDestination(){
      Stack(){
        UnitListView({
          onClickedRow:(sectionIndex, rowIndex, unit)     => { DetailCardsViewConfig.open({words: unit.aliveWords, initIndex: unit.indexOfNextLearnWord})},
          onClickedBtnList:(sectionIndex, rowIndex, unit) => { UnitWordsViewConfig.open({unitId: unit.unitId}) },
        })
      }
    }
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色

  }

  getNavTitle(): ResourceStr {
    return $r('app.string.nav_title_learn_unitlist')
  }

}

