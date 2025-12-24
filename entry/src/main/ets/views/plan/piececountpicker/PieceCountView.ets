import { TextButton } from "../../../app/views/buttons/TextButton"
import { TextCheckBox } from "../../../app/views/buttons/TextCheckBox"
import { NumberPickerView } from "../../../app/views/NumberPickerView"

// 限制定义
class Limit  {
  static readonly dayMin = 0     // 总数大于5个时才有效
  static readonly dayMax = 500   // 总数小于500时才有效
}

@ComponentV2
export struct PieceCountSlideView {

  @Param @Require title: string
  @Param @Require initCount: number

  @Local countPerDay: number = 0
  @Local isRepeat: boolean   = false
  @Event pickerHandler: (count: number, repeat: boolean) => void


  aboutToAppear(): void {
    this.countPerDay = this.initCount
  }

  build() {

    Column() {

      // 标题区域
      Row() {
        Text(this.title)// 第2天
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .margin({ bottom: 4 })
      }
      .backgroundColor($r('app.color.colorPrimary'))
      .width('100%')
      .height(44)
      .padding(12)


      Row({ space: 8}) {
        // 标签
        Text($r('app.string.piececount_txt_study'))// 学习
          .fontSize(14)
          .fontColor($r('app.color.color_text'))

        Blank().layoutWeight(0.5)

        // 使用 NumberPickerView
        NumberPickerView({
          minValue: Limit.dayMin,
          maxValue: Limit.dayMax,
          selectedValue: this.countPerDay,
          onSelected: (val: number) => {
            this.countPerDay = val
          }
        })
          .width('60%')
          .height(50)

        Blank().layoutWeight(0.5)

        // 单位
        Text($r('app.string.piececount_txt_unit'))// 个
          .fontSize(14)
          .fontColor($r('app.color.color_text'))
          .margin({right: 10})
      }
      .padding(10)

      Row(){
        ///同时修改此后所有日期的学习个数
        TextCheckBox({text: $r('app.string.piececount_txt_chk_repeat'), checked: this.isRepeat!!})
      }
      .width('100%')
      .margin({top: 16, left: 10})
      .justifyContent(FlexAlign.Start)

      Row() {
        // 确定按钮
        TextButton({
          text: $r('app.string.piececount_btn_ok'), minWidth: 160, onClickCallBack: () => {
            this.pickerHandler?.(this.countPerDay, this.isRepeat)
          }
        })

      }
      .padding(16)
    }
    .backgroundColor($r('app.color.color_white'))
    .width('100%')
  }
}