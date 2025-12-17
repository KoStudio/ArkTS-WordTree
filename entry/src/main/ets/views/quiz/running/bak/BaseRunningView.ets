// import { BgCardImage } from "../../../app/views/BgCardImage"
// import { BgImage } from "../../../app/views/BgImage"
// import { FavoriteStarButton } from "../../../app/views/buttons/FavoriteStarButton"
// import { IconButton } from "../../../app/views/buttons/IconButton"
// import { IconTintButton } from "../../../app/views/buttons/IconTintButton"
// import { TextFrameButton } from "../../../app/views/buttons/TextFrameButton"
// import { SEService, SEType } from "../../../common/components/SoundEffect/SEManager"
// import { CSoundHelper } from "../../../common/components/Sounds/Cloud/Manager/CSoundHelper"
// import { AudioPlayer } from "../../../common/components/Sounds/Player/CAudioPlayer"
// import { CountDownTimerView } from "../../../common/components/timer/CountDownTimerView"
// import { getStringF } from "../../../common/utils/ResourceUtils"
// import { Toast } from "../../../common/utils/Toast"
// import { QuestionType, QuizManager } from "../../../models/datas/model/QuizManager"
// import { WordUser } from "../../../models/datas/myData/WordUser"
// import { NavPop, NavPopTop, NavTo } from "../../../pages/NavPathManager"
// import { QuizResultViewConfig } from "../result/QuizResultView"
// import { FadeInOutMov } from "./FadeInOutMov"
//
//
//
// const defaultAnswerColors     : ResourceColor[]            = new Array(8).fill($r('app.color.colorPrimary'))
// @ComponentV2
// export struct BaseRunningView {
//
//   @BuilderParam answerPanelUp?: ((answers: string[], onClickedAt:(index: number) => void) => void)
//   @BuilderParam answerPanelDown: (answers: string[], onClickedAt:(index: number) => void) => void
//
//   @Local refreshTimerKey           : number                     = 0
//   @Local CountDownTimerViewRef     : CountDownTimerView | null  = null        // 倒计时Timer引用
//
//   @Local question                  : WordUser | null            = null
//   @Local lblNoText                 : string | null              = null
//   @Local lblQuestionText           : string | null              = null
//
//   @Local isPaused                  : boolean                    = false
//   @Local fadeMovRef?               : FadeInOutMov                                     // 保存组件实例
//
//   @Local isAnswerEnabled           : boolean                    = true
//   @Local answerTexts               : string[]                   = new Array(8).fill('')//['', '', '', '']
//   @Local answerColors              : ResourceColor[]            = [...defaultAnswerColors]
//
//
//   build() {
//     NavDestination(){
//       Stack(){
//
//         //通用 背景
//         BgImage()
//
//         Column() {
//           this.buildNavBar()
//
//           this.buildContent()
//
//         }
//         .width('100%')
//         .height('100%')
//
//       }
//
//     }
//     .hideTitleBar(true)
//     .onShown(()=>{
//
//       setTimeout(()=>{
//         //显示第一问
//         this.beginQuiz()
//       }, 1000)
//
//     })
//     .onBackPressed(()=>{
//
//       //返回上上一页
//       this.actionPause()
//
//       return true
//     })
//     //.title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
//     //.backButtonIcon(dNavBackIcon) //返回按钮
//     //.backgroundColor($r('app.color.colorPrimary')) // 背景色
//
//   }
//
//   getNavTitle(): ResourceStr {
//     return getStringF($r('app.string.str_unit_no'), this.question?.unitId ?? '')
//   }
//   // ================================================================
//   // Header 区域
//   // ================================================================
//   @Builder
//   buildNavBar() {
//     Stack() {
//       // 中间标题
//       Text(this.getNavTitle())
//         .fontSize(20)
//         .fontWeight(FontWeight.Bold)
//         .fontColor(Color.White)
//         .alignSelf(ItemAlign.Center)
//
//       // 顶部左右按钮区域
//       Row() {
//         // 左侧按钮组
//         IconTintButton({
//           icon: $r('app.media.pause'),
//           iconColor: $r('app.color.color_white'),
//           iconSize: 26,
//           onClickCallBack: () =>{ this.actionPause() }
//         })
//         // 中间留空自动分隔
//         Blank().layoutWeight(1)
//
//         ///暂停/继续
//         CountDownTimerView({
//           totalSeconds: QuizManager.shared.questionSpeed ,
//           isPaused: this.isPaused,
//           restartKey: this.refreshTimerKey,
//           onTick: (remainSeconds: number)=>{ this.actionRunning(remainSeconds)},
//           onFinish:()=>{ this.actionNext()},
//           onAppearring:(ref: CountDownTimerView)=>{
//             this.CountDownTimerViewRef = ref
//           }
//         })
//       }
//       .alignItems(VerticalAlign.Center)
//       .width('100%')
//       .padding({ left: 16, right: 16 })
//     }
//     .constraintSize({minHeight: 50})
//     .backgroundColor($r('app.color.colorPrimary'))
//     .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
//
//   }
//
//
//   // ================================================================
//   // Content 区域（问题 + 答案）
//   // ================================================================
//   @Builder
//   buildContent() {
//     Column() {
//       if (this.answerPanelUp && this.answerTexts.length === 8){
//         this.answerPanelUp?.(this.answerTexts.slice(0, 4), (index: number)=>{
//           let answerIndex = index
//           this.checkAnswer(answerIndex)
//         })
//       }
//       this.buildQuestionPanel()
//
//       // this.buildAnswerPanel()
//
//       this.answerPanelDown(this.answerTexts.length === 8 ? this.answerTexts.slice(-4) : this.answerTexts,(index: number)=>{
//         let answerIndex = index
//         if(this.answerTexts.length === 8){
//           answerIndex += 4
//           this.checkAnswer(answerIndex)
//         }
//
//       })
//
//     }
//     .id('contentBar')
//     .width('100%')
//     .layoutWeight(1)
//     .alignItems(HorizontalAlign.Center)
//   }
//
//   // ================================================================
//   // Question Panel
//   // ================================================================
//   @Builder
//   buildQuestionPanel() {
//     Stack() {
//       // 背景
//       Image($r('app.media.quiz_question_bg'))
//         .width('100%')
//         .height('100%')
//         .objectFit(ImageFit.Fill)
//
//       Column(){
//         // noPanel
//         Row() {
//           Text(this.lblNoText)
//             .fontColor($r('app.color.color_black'))
//
//           //收藏按钮
//           if (this.question){
//             FavoriteStarButton({word: this.question})
//           }
//
//         }
//         .width('100%')
//         .height(44)
//         .justifyContent(FlexAlign.SpaceBetween)
//         .padding({ left: 5, right: 10 })
//         .id('noPanel')
//
//         // top line
//         Image($r('app.media.quiz_seperator'))
//           .width('100%')
//           .height(1)
//           .position({ x: 0, y: 43 })
//           .id('imgLine')
//
//         // Question Text
//         Column() {
//           Text(this.lblQuestionText)
//             .textAlign(TextAlign.Center)
//             .fontSize(38)
//             .minFontScale(0.1)
//             .maxLines(1)
//             .fontColor($r('app.color.color_black'))
//         }
//         .width('100%')
//         .layoutWeight(1)
//         .justifyContent(FlexAlign.Center)
//         .padding({ left: 10, right: 10, top: 10, bottom: 1 })
//         .align(Alignment.Center)
//
//         //发音
//         Row() {
//           IconButton({ icon: $r('app.media.btn_voice_1'), iconSize: 26, onClickCallBack:()=>{ this.actionPlaySound(this.question) } })
//         }
//         .padding({ left: 5, right: 10 })
//         .height(44)
//         .width('100%')
//         .justifyContent(FlexAlign.End)
//
//
//         // bottom line
//         Image($r('app.media.quiz_seperator'))
//           .width('100%')
//           .height(1)
//           .align(Alignment.Bottom)
//           .id('imgLine2')
//
//       }
//
//       // move image
//       // Image($r('app.media.mov_right_1'))
//       //   .width(320)
//       //   .height(126)
//       //   .visibility(Visibility.Hidden)
//       //   .align(Alignment.Center)
//       //   .id('imgMove')
//       Row() {
//         FadeInOutMov({
//           imageWidth: 320,
//           imageHeight: 126,
//           onAppearing: (ref)=>{
//             this.fadeMovRef = ref
//           }
//         })
//       }
//       .hitTestBehavior(HitTestMode.None)
//       .width('100%')
//       .height('100%')
//       .justifyContent(FlexAlign.Center)
//       .alignItems(VerticalAlign.Center)
//     }
//     .id('questionPanel')
//     .width('100%')
//     .height(158)
//   }
//
//   // // ================================================================
//   // // Answer Panel
//   // // ================================================================
//   // @Builder
//   // buildAnswerPanel() {
//   //   Stack(){
//   //     BgCardImage()
//   //
//   //     Column({ space: 10 }) {
//   //       ForEach([0, 1, 2, 3], (index: number) => {
//   //         this.buildAnswerButton(index)
//   //       })
//   //     }
//   //     .width('100%')
//   //     .height('100%')
//   //     .justifyContent(FlexAlign.SpaceAround)
//   //     .padding(10)
//   //   }
//   //   .width('100%')
//   //   .layoutWeight(1)
//   // }
//
//   refreshAnswerColors(){
//
//     // 重置颜色
//     this.answerColors = [...defaultAnswerColors]
//   }
//
//
//   // @Builder
//   // buildAnswerButton(index: number) {
//   //   TextFrameButton({
//   //     text: this.answerTexts[index],
//   //     fontColor: this.answerColors[index],
//   //     minWidth: 300,
//   //     minHeight: 44,
//   //     isEnabled: this.isAnswerEnabled,
//   //     onClickCallBack: () => {
//   //       this.checkAnswer(index)
//   //     }
//   //   })
//   // }
//
//   beginQuiz(){
//
//     this.isPaused         = false
//     this.refreshTimerKey += 1
//     QuizManager.shared.prepareRun()
//     this.showNextQuestion()
//
//   }
//
//   // MARK: - 显示下一个题目
//   showNextQuestion(): void {
//     this.question = QuizManager.shared.nextQuestion();
//     if (this.question) {
//       this.show(this.question);
//     }
//   }
//
//   // MARK: - show(question: string)
//   async show(question: WordUser): Promise<void> {
//     const allCnt         = QuizManager.shared.questionWords.length;
//     const curNo          = QuizManager.shared.showingIndex + 1;
//
//
//     //Question
//     const isEiwa         = QuizManager.shared.questionType === QuestionType.Eiwa
//     this.lblNoText       = `${curNo}/${allCnt}`;
//     this.lblQuestionText = isEiwa ? question.wordEn : question.wordJp;
//
//     //Answer
//     const answers    = QuizManager.shared.getAnswerTextOfShowingQuestion()
//     this.answerTexts = [...answers]; // 一次性赋值 → UI 自动刷新
//
//     this.isAnswerEnabled = true
//
//     ///恢复按钮文本颜色
//     this.refreshAnswerColors()
//
//     // 预下载词语声音
//     this.preLoadSound()
//
//     // 自动发音
//     this.autoPlaySound();
//
//   }
//
//   checkAnswer(index: number) {
//
//     const isRight = QuizManager.shared.checkAnswer(index);
//
//     this.isPaused = true
//
//     this.isAnswerEnabled = false
//
//     // 重置颜色
//    this.refreshAnswerColors()
//
//     if (isRight) {
//       QuizManager.shared.addCorrectWord(this.question!);
//       this.answerColors[index] = Color.Red;
//       this.fadeMovRef?.showRight()
//       SEService.shared.playSound(SEType.Correct)
//     } else {
//       QuizManager.shared.addWrongWord(this.question!);
//
//       if (index !== -1) {
//         this.answerColors[index] = Color.Blue;
//       }
//
//       const correctIndex = QuizManager.shared.correctIndexOfAnswers;
//       this.answerColors[correctIndex] = Color.Red;
//       this.fadeMovRef?.showWrong()
//       SEService.shared.playSound(SEType.Wrong)
//     }
//
//
//     //下一问
//     this.gotoNext()
//   }
//
//   actionPause(){
//
//     this.isPaused = true
//     Toast.showCustomDialog(()=>{ this.buildPauseDialogView() }, true, true, ()=>{
//       this.isPaused = false
//     })
//   }
//
//   @Builder buildPauseDialogView(){
//
//     Column(){
//
//       Row({space: 30}){
//         IconButton({ icon: $r('app.media.quiz_pause_btn_return_1'), iconSize: 32, onClickCallBack: ()=>{ this.actionBack() }})
//         IconButton({ icon: $r('app.media.quiz_pause_btn_tomenu_1'), iconSize: 32, onClickCallBack: ()=>{ this.actionTop() }})
//         IconButton({ icon: $r('app.media.quiz_pause_btn_retry_1'), iconSize: 32, onClickCallBack: ()=>{ this.actionRetry()}})
//       }
//
//       Row({space: 20}){
//         IconButton({ icon: $r('app.media.quiz_pause_btn_close_1'), iconSize: 32, onClickCallBack: ()=>{ this.actionResume() }})
//       }
//       .margin({top: 50, bottom: 50})
//     }
//     .backgroundColor(Color.Transparent)
//     .justifyContent(FlexAlign.Center)
//     .alignItems(HorizontalAlign.Center)
//   }
//
//   actionBack(){
//     Toast.closeCustomDialog()
//     NavPop()
//   }
//   actionTop(){
//     Toast.closeCustomDialog()
//     NavPopTop()
//   }
//   actionRetry(){
//
//     this.beginQuiz()
//     this.refreshTimerKey += 1
//     Toast.closeCustomDialog()
//   }
//   actionResume(){
//     Toast.closeCustomDialog()
//   }
//
//   actionRunning(seconds: number){
//     if (seconds > 0 && seconds <= 3) {
//       SEService.shared.playSound(SEType.Warning)
//     }
//   }
//
//   actionNext(){
//     this.checkAnswer(-1)
//   }
//
//   actionPlaySound(word: WordUser | null){
//     if (word) {
//       this.playSound(word!.wordEnSoundText)
//     }
//   }
//
//   gotoNext(){
//     setTimeout(()=>{
//
//       if (QuizManager.shared.showingIndex === QuizManager.shared.questionWords.length - 1) {
//         //go to result
//         SEService.shared.playSound(SEType.Fanfare)
//         QuizResultViewConfig.open()
//       }else{
//         this.isPaused = false
//         this.showNextQuestion()
//         this.refreshTimerKey += 1
//
//       }
//
//     }, 1000) //等待1秒
//
//
//   }
//
//   async preLoadSound() {
//
//     const pageCnt: number        = QuizManager.shared.questionWords.length;
//     const index: number          = QuizManager.shared.showingIndex
//
//     const preCachPageCnt: number = 1;
//     const pageStart: number      = Math.max(index - preCachPageCnt, 0);
//     const pageEnd: number        = Math.min(index + preCachPageCnt + 1, pageCnt);
//
//     ///遍历 每一页
//     for (let page = pageStart; page < pageEnd; page++) {
//
//       ///预 加载 单词发音
//       await this.preLoadOneSound(QuizManager.shared.questionWords[page].wordEnSoundText)
//
//     }
//
//   }
//
//   // 预下载 (或合成) 词语的声音 (词语模式时)
//   async preLoadOneSound(text?: string | null) {
//     if (!text) {
//       return
//     }
//
//     if (!(await CSoundHelper.isSoundCacheExists(text))) {
//
//       // 启动（下载或合成）声音
//       await CSoundHelper.startDownloadOrGenerateSound(text)
//     }
//   }
//
//
//   /// [直接]播放 (汉字 or 词语的) 声音
//   async playSound(text?: string | null) {
//     if (!text) return;
//
//     ///播放声音
//     await AudioPlayer.shared.play(text)
//   }
//
//   // 自动发音
//   async autoPlaySound(){
//     // 单词 自动发音
//     if (QuizManager.shared.questionPronounce) {
//       // 延迟 1 秒
//       setTimeout(async () => {
//         await this.playSound(this.question?.wordEnSoundText)
//       }, 300);
//
//     }
//
//   }
//
// }