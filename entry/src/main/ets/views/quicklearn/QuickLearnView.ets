import { buildNavTitle } from "../../app/constants/AppBuilders";
import { dNavBackIcon } from "../../app/constants/AppDefines";
import { SectionDatas } from "../../common/utils/array/SectionDatas";
import { Part, Unit } from "../../models/datas/model/Part_Unit";
import { SearchConstants, SearchManager } from "../../models/datas/model/SearchManager";
import {  NavTo } from "../../pages/NavPathManager";
import json from "@ohos.util.json";
import { IconTintButton } from "../../app/views/buttons/IconTintButton";
import { getString, getStringF } from "../../common/utils/ResourceUtils";
import { TintImage } from "../../app/views/TintImage";
import { QuickLearnWordsViewConfig } from "./QuickLearnWordsView";
import { WordCardsViewConfig } from "../card/wordcard/WordCardsView";
import { TEUtility } from "../../common/utils/TEUtility";
import { BgImage } from "../../app/views/BgImage";
import { UnitListView } from "../learn/sub/UnitListView";


export namespace QuickLearnViewConfig {

  ///导航key
  export const NavKey = "QuickLearnView_show"

  ///打开方式
  export function open(){
    NavTo(QuickLearnViewConfig.NavKey, undefined, true)
  }


}

@ComponentV2
export struct QuickLearnView {




  build() {
    NavDestination(){
      Stack(){

        UnitListView({
          onClickedRow:(sectionIndex, rowIndex, unit)     => { WordCardsViewConfig.open({words: unit.aliveWords, initIndex: unit.indexOfNextLearnWord})},
          onClickedBtnList:(sectionIndex, rowIndex, unit) => { QuickLearnWordsViewConfig.open({unitId: unit.unitId}) },
        })
      }

    }
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色

  }

  getNavTitle(): ResourceStr {
    return  $r('app.string.nav_title_learn_unitlist')

  }
}

