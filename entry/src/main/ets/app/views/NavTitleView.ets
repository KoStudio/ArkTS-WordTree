@ComponentV2
export struct NavTitleView{

  @Param @Require title: ResourceStr | null
  @Param fontFamily: string                = '' // 默认为空字符串，表示使用系统默认字体

  build() {
    Row() {
      Text(this.title)
        .fontColor(Color.White)
        .maxFontSize(26)  // 最大字号
        .minFontSize(14)  // 最小字号（根据需要调整）
        //.maxLines(1)      // 限制单行显示[6](@ref)
        .textOverflow({ overflow: TextOverflow.Ellipsis }) // 超出显示省略号[6](@ref)
        .fontWeight(FontWeight.Bold)
        .fontFamily(this.fontFamily || 'HarmonyOS Sans')
        .margin({ left: 10 })
        .constraintSize({ maxWidth: '100%' }) // 限制最大宽度[6](@ref)
        .layoutWeight(1)  // 允许文本容器伸缩
    }
    .justifyContent(FlexAlign.Start)
    .width('70%')
    .height(56)
    .backgroundColor(Color.Transparent)
  }
}

