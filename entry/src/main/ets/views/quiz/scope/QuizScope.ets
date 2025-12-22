import { TintImage } from "../../../app/views/TintImage"

@ComponentV2
export struct QuizScopeFooter {

  @Param isSelected: boolean = false
  @Event onSelect:(selected: boolean)=>void
  @Event onNext:()=>void

  build() {
    this.buildFooter()
  }

  @Builder buildFooter(){
    Row({space: 6}) {
      // 勾选图标
      Row(){
        TintImage({src: this.isSelected ? $r('app.media.quiz_check_yes') : $r('app.media.quiz_check_no'), colorStr: '#ff787878'})

        ///全部选择
        Text($r('app.string.test_scope_btn_selectall'))
          .fontColor($r('app.color.color_footTint'))
          .margin({left: 5})
      }
      .onClick(()=>{
        this.onSelect(!this.isSelected)
      })


      Blank().layoutWeight(1)


      Row() {
        //下一步
        Text($r('app.string.test_scope_btn_next'))
          .fontColor($r('app.color.color_footTint'))
        TintImage({src:$r('app.media.arrow_right_circle'), colorStr: '#ff787878'})
          .margin({left: 5})
      }
      .backgroundColor(Color.Transparent)
      .onClick(()=>{
        this.onNext()
      })
    }
    .padding(16)
    .width('100%')
    //.height(44)
    .backgroundColor($r('app.color.color_foot'))
    .justifyContent(FlexAlign.SpaceBetween)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

  }
}