import { buildNavTitle } from "../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../app/constants/AppDefines";
import { NavTo } from "../../pages/NavPathManager";
import { WordCardsViewConfig } from "../card/wordcard/WordCardsView";
import { WordUser } from "../../models/datas/myData/WordUser";
import { getStringF } from "../../common/utils/ResourceUtils";
import { UnitWordListView } from "./sub/UnitWordListView";
import { DetailCardsViewConfig } from "../card/detail/DetailCardsView";


export namespace UnitWordsViewConfig {

  ///导航key
  export const NavKey = "UnitWordsView_show"

  ///打开方式
  export function open(param: Param){
    NavTo(UnitWordsViewConfig.NavKey, param, true)
  }

  export interface Param {
    unitId: number
  }

}

@ComponentV2
export struct UnitWordsView {

   @Param @Require unitId: number

  build() {
    NavDestination(){
      Stack(){


        UnitWordListView({
          unitId: this.unitId,
          onClickedRow: (rowIndex: number, words: WordUser[]) => { DetailCardsViewConfig.open({words: words, initIndex: rowIndex}) }
        })
      }
      .backgroundColor($r('app.color.color_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

    }
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色

  }

  getNavTitle(): ResourceStr {
    return getStringF($r('app.string.str_unit_no'), this.unitId)//`Lesson${this.unitId}`
  }

}

