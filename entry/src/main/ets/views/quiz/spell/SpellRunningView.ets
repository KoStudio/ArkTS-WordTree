import { buildNavTitle } from "../../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../../app/constants/AppDefines"
import { BgImage } from "../../../app/views/BgImage"
import { IconButton } from "../../../app/views/buttons/IconButton"
import { TextButton } from "../../../app/views/buttons/TextButton"
import { SEService, SEType } from "../../../common/components/SoundEffect/SEManager"
import { CSoundHelper } from "../../../common/components/Sounds/Cloud/Manager/CSoundHelper"
import { AudioPlayer } from "../../../common/components/Sounds/Player/CAudioPlayer"
import { shakeRotate } from "../../../common/components/animation/AnimationShake"
import { getStringF } from "../../../common/utils/ResourceUtils"
import { Toast } from "../../../common/utils/Toast"
import { QuizManager } from "../../../models/datas/model/QuizManager"
import { WordUser } from "../../../models/datas/myData/WordUser"
import { NavPop, NavPopTop, NavTo } from "../../../pages/NavPathManager"
import { QuizResultViewConfig } from "../result/QuizResultView"
import { TextAnimator } from "../../../common/components/animation/TextAnimator"
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { logEvent } from "../../../common/components/Logger/Logger"
import { MemberManager } from "../../../models/managers/member/MemberManager"


export namespace SpellRunningViewConfig {

  ///导航key
  export const NavKey = "SpellRunningView_show"

  ///打开方式
  export function open(){
    NavTo(NavKey, undefined, true)
  }

}


@ComponentV2
export struct SpellRunningView {



  @Local question                  : WordUser | null            = null
  @Local lblNoText                 : string | null              = null
  @Local lblQuestionText           : string | null              = null
  @Local txtAnswerText             : string | null              = null
  @Local txtAnswerColor            : ResourceColor              = Color.Black
  @Local lblCorrectAnswer          : string | null              = null
  @Local lblTip                    : ResourceStr = $r('app.string.spell_running_txt_input_answer')
  @Local lblTipColor               : ResourceColor = Color.Black
  @Local lblPlaceHolder            : ResourceStr | null = null// $r('app.string.spell_running_txt_try_again')
  @Local isShowCorrectAnswer       : boolean = false


  ///动画控制变量
  @Local lblTipShakeRotateAngle: number = 0

  private keyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.NONE

  aboutToAppear(): void {
    logEvent("spell_running_showed") //日志
  }

  build() {
    NavDestination(){
      Stack(){

        //通用 背景
         BgImage()

        Column() {

          this.buildContent()

        }
        .width('100%')
        .height('100%')

      }

    }
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色
    .onShown(()=>{
      //暂存 （因为有可能从subListOneView过来的）
      this.keyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode()

      ///可通过setKeyboardAvoidMode接口设置键盘避让模式为KeyboardAvoidMode.RESIZE，表示压缩模式
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE);

      setTimeout(()=>{
        //显示第一问
        this.beginQuiz()
      }, 100)

    })
    .onHidden(()=>{
      this.getUIContext().setKeyboardAvoidMode(this.keyboardAvoidMode);
    })

  }

  getNavTitle(): ResourceStr {
    return getStringF($r('app.string.str_unit_no'), this.question?.unitId ?? '')
  }


  @Builder
  buildContent() {
    Column() {

      this.buildQuestionPanel()

    }
    .backgroundColor($r('app.color.color_obscure'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .padding(20)
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }


  @Builder
  buildQuestionPanel() {
    Column(){

      Row(){
        Text(this.lblNoText)
          .fontColor($r('app.color.color_black'))
      }
      .padding(5)
      .width('100%')
      .justifyContent(FlexAlign.End)


      Column() {
        //Question
        Row() {
          Text(this.lblQuestionText)
            .textAlign(TextAlign.Start)
            .fontSize(38)
            .fontColor($r('app.color.color_link'))
            .minFontScale(0.1)
            .fontColor($r('app.color.color_black'))
        }
        .padding({ left: 10, right: 20 })
        .width('100%')
        .justifyContent(FlexAlign.Start)



        Row() {
          ///正确答案
          Text(this.lblCorrectAnswer)
            .fontSize(22)
            .minFontScale(1)
            .maxLines(1)
            .fontColor(Color.Green)
            .visibility(this.isShowCorrectAnswer ? Visibility.Visible : Visibility.Hidden)

          //发音
          IconButton({ icon: $r('app.media.btn_voice_1'), iconSize: 26, onClickCallBack:()=>{ this.actionPlaySound(this.question) } })
        }
        .padding({top: 10, left: 10, right: 50 })
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Column(){

          Row() {
            //输入 回答
            TextInput({ text: $$this.txtAnswerText, placeholder: this.lblPlaceHolder })
              .type(InputType.Email)
              // .onChange((value: string) => {
              //   this.txtAnswerText = value;
              // })
              .id('txtAnswer')
              .layoutWeight(1)
              .fontSize(22)
              .fontColor(this.txtAnswerColor)
              //.height(50)
              .backgroundColor(Color.White)
              .border({width: {bottom: 1}, color: $r('app.color.colorPrimary'),radius: 0})
              // .margin({ top: 2 })
              .padding(0)
              // .showUnderline(true)
              // .underlineColor($r('app.color.colorPrimary'))
              // .underlineColor({ normal: $r('app.color.colorPrimary'), typing: $r('app.color.color_pink'), error: Color.Red, disable: Color.Gray })
              .enterKeyType(EnterKeyType.Done)

              .onSubmit((enterKey: EnterKeyType, event: SubmitEvent) => {
                this.checkAnswer(this.txtAnswerText)

                // 调用keepEditableState方法，输入框保持编辑态
                event.keepEditableState();

              })


            ///不知道
            TextButton({
              text: $r('app.string.spell_running_btn_unknown'),
              minWidth: 66,
              onClickCallBack: ()=>{ this.actionUnknown() }
            })

          }
          .padding({left: 10, right: 10 })
          .width('100%')
          .margin({top: 10})
          .justifyContent(FlexAlign.End)
          .alignItems(VerticalAlign.Bottom)

         Row(){
           //输入答案
           Text(this.lblTip)
             .fontSize(12)
             .fontColor(this.lblTipColor)
             .rotate({angle: this.lblTipShakeRotateAngle})
         }
         .width('100%')
         .justifyContent(FlexAlign.Start)
         .padding({left: 10, top: 5, bottom: 10 })
        }

      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor(Color.White)
    .borderRadius(5)
    .width('100%')
    .margin(2)
    .layoutWeight(1)
    .margin({bottom: 320})
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
  }


  beginQuiz(){

    QuizManager.shared.prepareRun()
    this.showNextQuestion()

  }

  // MARK: - 显示下一个题目
  showNextQuestion(): void {
    this.question = QuizManager.shared.nextQuestion();
    if (this.question) {
      this.show(this.question);
    }
  }

  // MARK: - show(question: string)
  async show(question: WordUser): Promise<void> {
    const allCnt             = QuizManager.shared.questionWords.length;
    const curNo              = QuizManager.shared.showingIndex + 1;


    //Question
    this.lblNoText           = `${curNo}/${allCnt}`;
    this.lblQuestionText     = question.wordJpClippedString;
    this.lblCorrectAnswer    = question.titleEn;

    //重置
    this.txtAnswerText       = ''
    this.txtAnswerColor      = Color.Black
    this.isShowCorrectAnswer = false
    this.lblTipColor         = Color.Black
    this.lblTip              = $r('app.string.spell_running_txt_input_answer')
    this.lblPlaceHolder      = null

    //获得焦点
    this.focusOnAnswer()

    // 预下载词语声音
    this.preLoadSound()

    // 自动发音
    this.autoPlaySound();

    logEvent("spell_running_words") //日志
  }

  checkAnswer(answerText: string | null) {
    if (this.isShowCorrectAnswer) {
      //防止连续点击
      return;
    }

    //回答为空 时
    if (answerText === null || answerText.length === 0) {
      this.lblTipColor = Color.Red
      this.shakeTip()
      return
    }

    this.isShowCorrectAnswer = true //显示正确答案
    const isRight = QuizManager.shared.checkSpell(answerText)
    if (isRight) {
      QuizManager.shared.addCorrectWord(this.question!);
      this.txtAnswerColor = Color.Green
      this.lblTipColor    = Color.Green
      this.lblTip         = $r('app.string.spell_running_txt_right')
      SEService.shared.playSound(SEType.Correct)
    } else {
      QuizManager.shared.addWrongWord(this.question!);

      this.txtAnswerColor = Color.Red
      this.lblTipColor    = Color.Red
      this.lblTip         = $r('app.string.spell_running_txt_wrong')
      SEService.shared.playSound(SEType.Wrong)
    }


    //下一问
    this.gotoNext()
  }

  focusOnAnswer(){
    this.getUIContext().getFocusController().requestFocus("txtAnswer")
  }

  shakeTip() {
    shakeRotate({
      setAngle: (angle) => this.lblTipShakeRotateAngle = angle,
      times: 4,
      angle: 6,
      duration: 50,
      onFinished: () => console.log("Shake finished")
    })
  }

  actionUnknown(){
    TextAnimator.setFadeInText(
      (t) => this.txtAnswerText = t,  // 绑定状态
      this.lblCorrectAnswer || '',
      2,                      // 显示完 2 秒后开始擦除
      () => {
        //"文本显示 + 擦除完成"
        this.lblPlaceHolder = $r('app.string.spell_running_txt_try_again')
      }
    )
  }
  actionBack(){
    Toast.closeCustomDialog()
    NavPop()
  }
  actionTop(){
    Toast.closeCustomDialog()
    NavPopTop()
  }
  actionRetry(){

    this.beginQuiz()
    // this.refreshTimerKey += 1
    Toast.closeCustomDialog()
  }
  actionResume(){
    Toast.closeCustomDialog()
  }

  actionRunning(seconds: number){
    if (seconds > 0 && seconds <= 3) {
      SEService.shared.playSound(SEType.Warning)
    }
  }


  actionPlaySound(word: WordUser | null){
    ///会员检查
    if(!MemberManager.shared.checkWordPronUsable(true)){
      return;
    }

    if (word) {
      this.playSound(word!.wordEnSoundText)
    }
  }

  gotoNext(){
    setTimeout(()=>{

      if (QuizManager.shared.showingIndex === QuizManager.shared.questionWords.length - 1) {
        //go to result
        SEService.shared.playSound(SEType.Fanfare)
        QuizResultViewConfig.open()
      }else{
        // this.isPaused = false
        this.showNextQuestion()
        // this.refreshTimerKey += 1

      }

    }, 3000) //等待1秒


  }

  async preLoadSound() {
    ///会员检查
    if(!MemberManager.shared.checkWordPronUsable(false)){
      return;
    }

    const pageCnt: number        = QuizManager.shared.questionWords.length;
    const index: number          = QuizManager.shared.showingIndex

    const preCachPageCnt: number = 1;
    const pageStart: number      = Math.max(index - preCachPageCnt, 0);
    const pageEnd: number        = Math.min(index + preCachPageCnt + 1, pageCnt);

    ///遍历 每一页
    for (let page = pageStart; page < pageEnd; page++) {

      ///预 加载 单词发音
      await this.preLoadOneSound(QuizManager.shared.questionWords[page].wordEnSoundText)

    }

  }

  // 预下载 (或合成) 词语的声音 (词语模式时)
  async preLoadOneSound(text?: string | null) {
    if (!text) {
      return
    }

    if (!(await CSoundHelper.isSoundCacheExists(text))) {

      // 启动（下载或合成）声音
      await CSoundHelper.startDownloadOrGenerateSound(text)
    }
  }


  /// [直接]播放 (汉字 or 词语的) 声音
  async playSound(text?: string | null) {
    if (!text) return;

    ///播放声音
    await AudioPlayer.shared.play(text)
  }

  // 自动发音
  async autoPlaySound(){
    // 单词 自动发音
    if (QuizManager.shared.questionPronounce) {
      // 延迟 1 秒
      setTimeout(async () => {
        await this.playSound(this.question?.wordEnSoundText)
      }, 300);

    }

  }

}