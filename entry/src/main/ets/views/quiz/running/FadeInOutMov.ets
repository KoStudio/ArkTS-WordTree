

@ComponentV2
export struct FadeInOutMov {

  // @Param triggerShowRight: boolean = false
  // @Param triggerShowWrong: boolean = false

  @Param duration: number = 250;      // 动画时长
  @Param imageWidth: number = 320;    // 宽度
  @Param imageHeight: number = 126;   // 高度

  @Event onAppearing: ((ref: FadeInOutMov) => void) | null = null;  //外部调用时，可通过此方法获得当前对象的引用

  @Local isVisible: boolean = false;  // 控制显示隐藏
  @Local opacityValue: number = 0;    // 控制透明度
  @Local currentImage: Resource = $r('app.media.mov_right_1'); // 当前显示图片

  aboutToAppear(): void {
    this.onAppearing?.(this)
  }

  // @Monitor('triggerShowRight')
  // onChangeOfShowRight(){
  //   this.showRight()
  // }
  //
  // @Monitor('triggerShowWrong')
  // onChangeOfShow(){
  //   this.showWrong()
  // }


  build() {
    Image(this.currentImage)
      .width(this.imageWidth)
      .height(this.imageHeight)
      .opacity(this.opacityValue)
      .animation({ duration: this.duration, curve: Curve.EaseInOut })
      .visibility(this.isVisible ? Visibility.Visible : Visibility.Hidden);
  }

  // 内部动画方法
  private startAnimation(image: Resource) {
    this.currentImage = image;
    this.isVisible = true;
    this.opacityValue = 0;

    // 立即刷新状态
    animateToImmediately({ duration: 0 }, () => {});

    // 渐变出现
    animateTo({
      duration: this.duration,
      curve: Curve.EaseInOut,
      onFinish: () => this.startFadeOutAnimation()
    }, () => { this.opacityValue = 1; });
  }

  private startFadeOutAnimation() {
    animateTo({
      duration: this.duration,
      curve: Curve.EaseInOut,
      onFinish: () => { this.isVisible = false; }
    }, () => { this.opacityValue = 0; });
  }

  // 对外调用接口
  showRight() { this.startAnimation($r('app.media.mov_right_1')); }
  showWrong() { this.startAnimation($r('app.media.mov_mistake_1')); }
}