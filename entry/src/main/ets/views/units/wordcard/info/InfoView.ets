import { dMemberFlag } from '../../../../app/constants/AppDefines';
import { getString } from '../../../../common/utils/ResourceUtils';
import { MemberManager } from '../../../../models/managers/member/MemberManager';
import { SettingManager } from '../../../../models/managers/setting/SettingManager';


@ComponentV2
export struct InfoView {


  @Param isShowing: boolean         = false
  @Event $isShowing: (val: boolean) => void

  @Local intervalText: string = `${SettingManager.shared.autoPlayInterval / 1000}秒`;

  @Local hideTranslation: boolean = SettingManager.shared.hideTranslation
  @Local autoPlaySound  : boolean = SettingManager.shared.autoPlaySound
  @Local autoPlaySoundEx: boolean = SettingManager.shared.autoPlaySoundEx
  @Local rollRepeat     : boolean = SettingManager.shared.rollRepeat

  build() {

    Stack() {

      // Column()
      //   .width('100%')
      //   .height('100%')
      //   .backgroundColor($r('app.color.color_black'))

      Image($r('app.media.card_info_bg'))
        .objectFit(ImageFit.Fill)
        .width(220)
        .height(260)

      // 设置面板
      Column() {
        // ===== 隐藏翻译 =====
        this.buildItemToggle(getString($r('app.string.wordcard_info_hidetranslation')) + dMemberFlag, () => this.hideTranslation, (v: boolean) => { this.hideTranslation = v }, (isOn: boolean) => {
            SettingManager.shared.hideTranslation = isOn

            /// 会员检查
            if (!MemberManager.shared.checkHideTransUsable(true)) {
              //0.5秒后 关闭
              setTimeout(() => { this.hideTranslation = false; SettingManager.shared.hideTranslation = false; }, 500)
            }
          }
        )

        // ===== 自动发音 =====
        this.buildItemToggle( getString($r('app.string.wordcard_info_autopronunce')) + dMemberFlag, () => this.autoPlaySound, (v: boolean) => { this.autoPlaySound = v }, (isOn: boolean) => {
            SettingManager.shared.autoPlaySound = isOn

            /// 会员检查
            if (!MemberManager.shared.checkAutoPronUsable(true)) {
              //0.5秒后 关闭
              setTimeout(() => { this.autoPlaySound = false; SettingManager.shared.autoPlaySound = false; }, 500)
            }
          }
        )

        // ===== 例句自动发音 =====
        this.buildItemToggle(
          getString($r('app.string.wordcard_info_autopronunce_ex')) + dMemberFlag, () => this.autoPlaySoundEx, (v: boolean) => { this.autoPlaySoundEx = v }, (isOn: boolean) => {
            SettingManager.shared.autoPlaySoundEx = isOn

            /// 会员检查
            if (!MemberManager.shared.checkAutoPronUsable(true)) {
              //0.5秒后 关闭
              setTimeout(() => { this.autoPlaySoundEx = false; SettingManager.shared.autoPlaySoundEx = false; }, 500)
            }
          }
        )

        // ===== 循环播放 =====
        this.buildItemToggle($r('app.string.wordcard_info_repeat'), () => this.rollRepeat, (v: boolean) => { this.rollRepeat = v }, (isOn: boolean) => {
            SettingManager.shared.rollRepeat = isOn
          }
        )


        // 间隔时间设置行
        Row() {
          Text($r('app.string.wordcard_info_inteval'))
            .fontSize(14)
            .fontColor($r('app.color.color_white'))
            .textAlign(TextAlign.Start)

          // 右侧滑块和文本容器
          Column() {
            Slider({  value: SettingManager.shared.autoPlayInterval / 1000, min: 1, max: 60, step: 1, style: SliderStyle.OutSet })
              .width(110)
              .onChange((value: number) => {
                SettingManager.shared.autoPlayInterval = Math.round(value * 1000);
                this.intervalText                      = `${value}秒`;
              })

            Text(this.intervalText)
              .fontSize(13)
              .fontColor($r('app.color.color_white'))
              .textAlign(TextAlign.Start)
          }
          .alignItems(HorizontalAlign.Start)
        }

        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
      }
      .width(200)
      //.height(260)
      .padding({top: 10, bottom: 10, left: 5, right: 10})
      .margin({top: 5, bottom: 35,  left: 10, right: 10})

    }
    .backgroundColor(Color.Transparent)
    .alignContent(Alignment.TopStart)
    .width('100%')
    .padding({bottom: 30})
    .onClick(()=>{
      this.$isShowing(true)
    })
  }

  @Builder
  buildItemToggle(text: ResourceStr, getter: () => boolean, setter: (v: boolean) => void, onChange: (v: boolean) => void) {
    Row({ space: 10 }) {
      Text(text)
        .fontSize(14)
        .fontColor($r('app.color.color_white'))
        .textAlign(TextAlign.Start)
      Blank()

      Toggle({ type: ToggleType.Switch, isOn: getter() })
        .onChange((v: boolean) => {
          setter(v);     // 回写状态
          onChange(v);
        })
    }
    .width(200)
    .margin({top: 2, bottom: 5, left: 10, right: 10})
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

}