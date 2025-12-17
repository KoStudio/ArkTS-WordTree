import { buildStandardMenu } from "../constants/AppFunctions"


@ComponentV2
export struct MenuView{

  // @Param items: NavigationMenuItem[] = []
  @Event onCreatedMenu:() => NavigationMenuItem[]

  build() {
    buildStandardMenu(this.onCreatedMenu())
  }


  // @Builder
  // buildStandardMenu(items: NavigationMenuItem[]) {
  //   Row({space: 2}){
  //     ForEach(items, (item: NavigationMenuItem) => {
  //       if (item.icon) {//优先 使用icon
  //         Image(item.icon)
  //           .width(26)
  //           .height(26)
  //           .backgroundColor(Color.Transparent)
  //           .fillColor(Color.White) //按钮 着色
  //           .onClick(() => item.action?.())
  //           .margin(10)
  //       }else { //使用文本
  //         Button() {
  //           Text(item.value)
  //             .fontSize(18)
  //             .fontColor(Color.White) //文本按钮 颜色
  //         }
  //         .backgroundColor(Color.Transparent)
  //         .onClick(() => item.action?.())
  //         .margin(10)
  //       }
  //     }, (item: NavigationMenuItem) => item.value.toString())
  //   }
  //   .padding(5)
  //
  // }
}