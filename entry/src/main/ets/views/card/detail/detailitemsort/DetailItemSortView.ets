import { NavBarView } from "../../../../app/views/NavBarView"
import { DetailItemManager, ItemOrder } from "../../../../models/managers/detailitem/DetailItemManager"


@ComponentV2
export struct DetailItemSortView {

  @Param   @Require isShowing        : boolean
  @Event   $isShowing                : (val: boolean) => void    = (val: boolean) => {}
  @Event   onClose                   : (changed: boolean) => void

  // 当前页面显示的排序列表，从 DetailItemManager 获取初始顺序
  @Local   itemOrders                : ItemOrder[]               = DetailItemManager.shared.getItemOrders()

  // 标记是否有排序或可见性改变
  private  isSortChanged             : boolean                   = false


  // 页面即将显示
  aboutToAppear() {
    this.itemOrders = DetailItemManager.shared.getItemOrders()
  }

  // 页面即将消失
  aboutToDisappear() {
    // 拖拽完成后保存最终顺序到 DetailItemManager
    if (this.isSortChanged) {
      DetailItemManager.shared.updateOrders(this.itemOrders)
    }
    this.onClose(this.isSortChanged)
  }

  build() {
    Column({ space: 12 }) {

      // 自定义导航栏
      this.buildNavBar()

      // 拖拽提示
      Row(){
        Text($r('app.string.detail_item_sort_drag_tip'))
          .fontSize(14)
          .fontColor(Color.Gray)
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')

      // 列表，可拖动排序
      List({ space: 1 }) {
        ForEach(this.itemOrders, (itemOrder: ItemOrder, index: number) => {
          ListItem() {
            this.buildRow(itemOrder, index)
          }
          .key(itemOrder.item)
        })
          ///拖动排序 (直接使用ForEach的onMove)
          .onMove((fromIndex: number, toIndex: number) =>{
            this.move(fromIndex, toIndex)
          })
      }
      .width('100%')
      .height('100%')

    }
    .backgroundColor($r('app.color.color_obscure'))
  }

  // 构建导航栏
  @Builder buildNavBar(){
    NavBarView({
      title: $r('app.string.detail_item_sort_nav_title'),

      // 左侧按钮数组（只有一个图标按钮）
      leftButtons: [
        {
          icon: $r('app.media.back'),
          onClick: () => { this.$isShowing(false) }
        }
      ],

      // 右侧按钮数组（只有一个文本按钮）
      rightButtons: [
        {
          text: $r('app.string.detail_item_sort_btn_done'),
          onClick: () => { this.$isShowing(false) }
        }
      ]
    })
  }

  // 构建列表行
  @Builder buildRow(itemOrder: ItemOrder, index: number){
    Row() {
      Toggle({ type: ToggleType.Switch, isOn: itemOrder.isVisible })
        .onChange((isOn: boolean) => this.changeVisible(index, isOn))
        .selectedColor($r('app.color.color_switch_tint'))

      Text(DetailItemManager.shared.getLocalizedName(itemOrder.item))
        .fontSize(18)
        .fontColor(itemOrder.isVisible ? $r('app.color.colorPrimaryDark') : $r('app.color.color_obscure'))
        .layoutWeight(1)
        .margin({left: 5})

      Image($r('app.media.dragsort'))
        .width(24)
        .height(24)
        .hitTestBehavior(HitTestMode.None)///不要响应任何事件
    }
    .backgroundColor(Color.White)
    .padding({left:5, right:5, top: 10, bottom: 10 })
    .margin(5)
  }


  // 拖拽移动方法：把元素从 from 移动到 to
  private move(from: number, to: number): void {
    if (to === -1 || from === to) return

    // 取出拖拽元素
    const movingItem = this.itemOrders.splice(from, 1)[0]

    // 插入到新位置
    this.itemOrders.splice(to, 0, movingItem)

    // ⚡ 强制触发 UI 更新，保证动画生效
    this.itemOrders = [...this.itemOrders]

    DetailItemManager.shared.updateOrders(this.itemOrders)

    this.isSortChanged = true
  }

  // 改变可见性
  private changeVisible(index: number, isOn: boolean) {

    const item = this.itemOrders[index].item
    DetailItemManager.shared.changeVisible(item, isOn)
    //this.itemOrders[index].isVisible = isOn
    this.itemOrders = DetailItemManager.shared.getItemOrders()

    this.isSortChanged = true
  }

}