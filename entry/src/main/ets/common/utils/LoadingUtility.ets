
export class LoadingUtility {

  private static loadingDialog: CustomDialogController | null = null

  //===============================
  // 显示加载提示（菊花转圈 + 文字）
  //===============================
  static showLoading(msg: ResourceStr = 'loading..', percent: number| undefined = undefined) {
    // 如果已有 loading，则不重复创建
    if (LoadingUtility.loadingDialog) {
      return
    }

    const controller = new CustomDialogController({
      builder: (): LoadingView => LoadingView({ message: msg, percent: percent }),
      autoCancel: false,
      alignment: DialogAlignment.Center,
      customStyle: true,
      isModal: true
    })

    controller.open()
    LoadingUtility.loadingDialog = controller
  }

  //===============================
  // 隐藏加载提示
  //===============================
  static hideLoading() {
    if (LoadingUtility.loadingDialog) {
      LoadingUtility.loadingDialog.close()
      LoadingUtility.loadingDialog = null
    }
  }

  //===============================
  // 显示进度加载（带百分比）暂时未实现此方法..by ko 2025.10.16
  //===============================
  static showProgress(msg: ResourceStr, percent: number) {
    // 若超过100则直接关闭
    if (percent >= 100) {
      LoadingUtility.hideLoading()
      return
    }

    if (!LoadingUtility.loadingDialog) {
      LoadingUtility.showLoading(msg, percent)
    }


  }
}


//===============================
// 自定义加载对话框组件
//===============================
@ComponentV2
struct LoadingView {

  @Param message: ResourceStr = ''
  @Param percent?: number = undefined // 0..100

  build() {
    Column() {


      if (this.percent){

        // 圆形旋转动画
        Progress({ value: this.percent, total: 100, type: ProgressType.Ring })
          .color(Color.Grey)
          .width(100)
          .height(100)
          .style({ strokeWidth: 20 })

        // 百分比显示
        Text(`${this.percent.toFixed(0)}%`)
          .fontSize(14)
          .fontColor(Color.White)
          .opacity(0.8)
      }


      // 提示文字
      Text(this.message)
        .fontSize(16)
        .fontColor(Color.White)

    }
    .padding(24)
    .backgroundColor($r('app.color.color_translucent_dark'))
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}