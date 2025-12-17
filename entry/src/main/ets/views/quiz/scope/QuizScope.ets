
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
      Image(this.isSelected ? $r('app.media.quiz_btn_selectall_2') : $r('app.media.quiz_btn_selectall_1'))
        .width(98)
        .height(25)
        .onClick(()=>{
          this.onSelect(!this.isSelected)
        })


      Blank().layoutWeight(1)

      Button() {
        Image($r('app.media.quiz_btn_next_1'))
          .objectFit(ImageFit.Fill)
          .width(57)
          .height(18)
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