import { IconButton } from '../../../../app/views/buttons/IconButton';
import { WaveView }             from '../Wave/WaveView';        // 波纹动画组件

@ComponentV2
export struct RecordingView {

  // ===================== 父组件传入参数 =====================
  @Param isTalking     : boolean = true;   // 是否检测到用户说话

  // ===================== 自定义事件 =====================
  @Event onStopRecording: () => void;            // 停止录音事件回调

  // ===================== 组件内部状态 =====================
  @Local private waveSpeed    : number = 0.08;  // 波纹动画速度
  @Local private waveAmplitude: number = 10;    // 波纹震动幅度
  @Local private waveHeight   : number = 50;     // 波纹基准高度



  /**
   * 监听说话状态变化
   */
  @Monitor('isTalking')
  private handleRecordingChange() {
    if (this.isTalking) {
      this.waveSpeed     = 0.25;   // 说话时加速波纹
      this.waveAmplitude = 15;    // 增大波纹幅度
    } else {
      this.waveSpeed     = 0.08;   // 恢复正常速度
      this.waveAmplitude = 10;     // 恢复默认幅度
    }
  }

  /**
   * 构建UI布局
   */
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 波纹动画容器
      Column() {
        Blank().layoutWeight(1)  // 顶部留白

        // 波纹动画视图（绑定动态参数）
        WaveView({
          waveSpeed    : this.waveSpeed,
          waveAmplitude: this.waveAmplitude,
          waveHeight   : this.waveHeight
        })
      }

      // 内容区域（居中显示）
      Column({ space: 5 }) {
        // 录音状态提示
        Text("录音中...")
          .fontSize(20)
          .fontColor(0x808080)  // 灰色文本
          .margin({ top: 20 })

        // 停止录音按钮
        IconButton({
          icon          : $r('app.media.stopcircle'),
          iconSize      : 50,
          iconColor     : Color.Red,
          onClickCallBack: () => {
            this.onStopRecording?.()  // 触发停止回调
          }
        })
      }
      .width('100%')  // 内容区域宽度100%
    }
    .height('100%')      // 容器高度100%
    .onAppear(() => this.handleRecordingChange())  // 初始化波纹参数
  }
}