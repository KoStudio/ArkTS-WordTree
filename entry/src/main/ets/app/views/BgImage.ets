
// 背景图片组件
@Component
export struct BgImage {
  build() {
    // Image($r('app.media.common_bg')) // 使用资源引用
    //   .width('100%')          // 等同于 .resizable() + .frame
    //   .height('100%')
    //   .objectFit(ImageFit.Cover) // 等同于 .aspectRatio(contentMode: .fill)
    //   .position({ x: 0, y: 0 })  // 确保从左上角开始布局
    //   .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])      // 关键配置：扩展到顶部和底部非安全区
    //
    Rect()
      .width('100%')
      .height('100%')
      .fill($r('app.color.color_background'))
      // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

  }
}
