import { NavTitleView } from "../views/NavTitleView";


@Builder
export function buildNavTitle(title: ResourceStr | null | undefined){
  // Row() {
  //   Text(title)
  //     .fontColor(Color.White) // 在这里设置你想要的标题颜色
  //     .fontSize(26)
  //     .fontWeight(FontWeight.Bold)
  //     .margin({left: 10})
  // }
  // .width('100%')
  // .height(56)
  // .backgroundColor(Color.Transparent)

  NavTitleView({title: title})

}

