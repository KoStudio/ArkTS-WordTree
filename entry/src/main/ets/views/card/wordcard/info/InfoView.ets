import { dMemberFlag } from '../../../../app/constants/AppDefines';
import { TextButton } from '../../../../app/views/buttons/TextButton';
import { SegmentButton, SegmentItem } from '../../../../app/views/SegmentButton';
import { getString } from '../../../../common/utils/ResourceUtils';
import { MemberManager } from '../../../../models/managers/member/MemberManager';
import { SettingManager } from '../../../../models/managers/setting/SettingManager';


@ComponentV2
export struct InfoView {


  @Param isForCard: boolean = false
  @Param isShowing: boolean         = false
  @Event $isShowing: (val: boolean) => void
  @Event onClickedBtnSort?: () => void

  @Local intervalText: string = `${SettingManager.shared.autoPlayInterval / 1000}秒`;

  @Local hideTranslation: boolean = SettingManager.shared.hideTranslation
  @Local autoPlaySound  : boolean = SettingManager.shared.autoPlaySound
  @Local autoPlaySoundEx: boolean = SettingManager.shared.autoPlaySoundEx
  @Local rollRepeat     : boolean = SettingManager.shared.rollRepeat

  // private infoWidth: number = 300
  // private infoHeight: number = 600


  build() {

    Stack() {


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

        //发音次数
        this.buildItemSeg(
          getString($r('app.string.learn_detail_info_txt_pron_times')),
          ()=>[{title: '1次', isEnabled: this.autoPlaySound}, {title: '2次', isEnabled: this.autoPlaySound}, {title: '3次', isEnabled: this.autoPlaySound}],
          ()=> (SettingManager.shared.pronTimes - 1), (v: number) => { SettingManager.shared.pronTimes = v + 1},
          (v: number) => {
            SettingManager.shared.pronTimes = v + 1
        })

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

        //自动发音间隔
        this.buildItemSeg(
          getString($r('app.string.learn_detail_info_txt_pron_gap')),
          ()=>[{title: '短', isEnabled: this.autoPlaySound || this.autoPlaySoundEx}, {title: '中', isEnabled: this.autoPlaySound || this.autoPlaySoundEx}, {title: '长', isEnabled: true}],
          ()=> (SettingManager.shared.pronGap), (v: number) => { SettingManager.shared.pronGap = v},
          (v: number) => {
            SettingManager.shared.pronGap = v
          })

        //发音播放速度
        this.buildItemSeg(
          getString($r('app.string.learn_detail_info_txt_pron_speed')),
          ()=>[{title: '0.8x', isEnabled: true}, {title: '1.0x', isEnabled: true}, {title: '1.2x', isEnabled: true}],
          ()=> (SettingManager.shared.pronSpeed), (v: number) => { SettingManager.shared.pronSpeed = v},
          (v: number) => {
            SettingManager.shared.pronSpeed = v
          })

        // ===== 循环播放 =====
        this.buildItemToggle($r('app.string.wordcard_info_repeat'), () => this.rollRepeat, (v: boolean) => { this.rollRepeat = v }, (isOn: boolean) => {
            SettingManager.shared.rollRepeat = isOn
          }
        )


        // 间隔时间设置行
        Row() {
          Text($r('app.string.wordcard_info_inteval'))
            .fontSize(14)
            .fontColor($r('app.color.color_text'))
            .textAlign(TextAlign.Start)

          Blank().layoutWeight(1)

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
              .fontColor($r('app.color.color_text'))
              .textAlign(TextAlign.Start)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        if (!this.isForCard){

          //字体大小
          this.buildItemSeg(
            getString($r('app.string.learn_detail_info_txt_font_style')),
            ()=>[{title: '小', isEnabled: true}, {title: '中', isEnabled: true}, {title: '大', isEnabled: true}],
            ()=> (SettingManager.shared.detailStyle), (v: number) => { SettingManager.shared.detailStyle = v},
            (v: number) => {
              SettingManager.shared.detailStyle = v
            })

          Row(){
            ///调整显示顺序
            TextButton({
              text: $r('app.string.learn_detail_info_txt_set_order'),
              bgColor: $r('app.color.color_btn_bg2'),
              minWidth: 220,
              onClickCallBack:()=>{
                this.onClickedBtnSort?.()
                this.$isShowing(false)
              }
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }


      }
      .width('100%')
      .padding({top: 10, bottom: 10, left: 5, right: 20})
      .margin({top: 5, bottom: 35,  left: 10, right: 20})

    }
    .backgroundColor(Color.White)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .alignContent(Alignment.TopStart)
    .width('100%')
    .padding({bottom: 30})
    .onClick(()=>{
      //this.$isShowing(true)
    })
  }

  @Builder
  buildItemToggle(text: ResourceStr, getter: () => boolean, setter: (v: boolean) => void, onChange: (v: boolean) => void) {
    Row({ space: 10 }) {
      Text(text)
        .fontSize(14)
        .fontColor($r('app.color.color_text'))
        .textAlign(TextAlign.Start)
      Blank()

      Toggle({ type: ToggleType.Switch, isOn: getter()})
        .selectedColor($r('app.color.color_btn_bg2'))
        .onChange((v: boolean) => {
          setter(v);     // 回写状态
          onChange(v);
        })
    }
    .width('100%')
    .padding({right: 66})
    .margin({top: 2, bottom: 5, left: 10, right: 10})
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  @Builder buildItemSeg(text: ResourceStr, items: ()=>SegmentItem[], getter: () => number, setter: (v: number) => void, onChange: (v: number) => void) {
    Row({ space: 10 }) {
      Text(text)
        .fontSize(14)
        .fontColor($r('app.color.color_text'))
        .textAlign(TextAlign.Start)
      Blank()


      SegmentButton({
        items: items(),
        selectedIndex: getter(),
        unselectedTextColor: $r('app.color.color_btn_bg2'),
        selectedBgColor: $r('app.color.color_btn_bg2'),
        btnBorderColor: $r('app.color.color_btn_bg2'),
        totalWidth: 200,
        onSelect: (index: number)=>{
          setter(index)
          onChange(index)
        }
      })
        .width(200)

    }
    .width('100%')
    .margin({top: 2, bottom: 5, left: 10, right: 10})
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)

  }
}