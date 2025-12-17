import { CustomNavigationMenuItem } from "../constants/AppFunctions"
import { NavBarView, NavButtonItem } from "./NavBarView"
import { dNavBackIcon} from "../constants/AppDefines"
import { NavPop, NavPopTop } from "../../pages/NavPathManager"

@ComponentV2
export struct NavBarCommonView {

  // 中间标题
  @Param title?: ResourceStr | null = null
  @Param rightItems: CustomNavigationMenuItem[] = []

  get rightBtns(): NavButtonItem[]{
    return this.rightItems.map((item, i) => ({ text: item.value, icon: item.icon, isSvg: item.isSvg, onClick: item.action }) as NavButtonItem)
  }

  build() {


    NavBarView({
      title: this.title,

      // 左侧按钮数组
      leftButtons: [
        {
          icon: dNavBackIcon,
          onClick: () => {
            NavPop()
          }
        },
        {
          icon: $r('app.media.btn_top_1'),
          onClick: () => {
            NavPopTop()
          }
        }
      ],

      // 右侧按钮数组
      rightButtons: this.rightBtns,
    })
  }
}