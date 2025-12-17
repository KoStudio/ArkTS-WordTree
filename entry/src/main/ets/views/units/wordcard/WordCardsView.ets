import { IconTintButton } from "../../../app/views/buttons/IconTintButton"
import { logEvent } from "../../../common/components/Logger/Logger"
import { WordUser } from "../../../models/datas/myData/WordUser"
import { SettingManager } from "../../../models/managers/setting/SettingManager"
import { WordCardOne } from "./WordCardOne"
import { SearchManager } from "../../../models/datas/model/SearchManager"
import { NavPop, NavPopTop, NavTo } from "../../../pages/NavPathManager"
import { buildNavTitle } from "../../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../../app/constants/AppDefines"
import { getString, getStringF } from "../../../common/utils/ResourceUtils"
import { BgCardImage } from "../../../app/views/BgCardImage"
import { awaitDelay, buildStandardMenu, CustomNavigationMenuItem } from "../../../app/constants/AppFunctions"
import { FavoriteStarButton } from "../../../app/views/buttons/FavoriteStarButton"
import { DictView } from "./dict/DictView"
import { InfoView } from "./info/InfoView"
import { SpeechRecordManager } from "../../../common/components/Speech/Recorder/SpeechRecordManager"
import { RecordingView } from "../../../common/components/Speech/Recorder/RecordingView"
import PermissionManager from "../../../common/components/Alarm/PermissionManager"
import { getAppContext } from "../../../app/constants/AppContext"
import { AudioPlayer } from "../../../common/components/Sounds/Player/CAudioPlayer"
import { CSoundHelper } from "../../../common/components/Sounds/Cloud/Manager/CSoundHelper"
import { ItemOption, Toast } from "../../../common/utils/Toast"
import { QuestionMode, QuizManager, QuizType } from "../../../models/datas/model/QuizManager"
import { QuizStartViewConfig } from "../../quiz/start/QuizStartView"
import { VersionChecker } from "../../../common/components/VersionChecker/VersionChecker"
import { MemberManager } from "../../../models/managers/member/MemberManager"
import { MemberView } from "../../setting/member/MemberView"
import { NavBarView } from "../../../app/views/NavBarView"
import { NavBarCommonView } from "../../../app/views/NavBarCommonView"

export namespace WordCardsViewConfig {

  ///导航key
  export const NavKey = "WordCardsView_show"

  ///打开方式
  export function open(param: Param){
    if (param.words.length > 0) {
      NavTo(WordCardsViewConfig.NavKey, param, true)
    }
  }

  export interface Param {
    words      : WordUser[]
    initIndex  : number
  }

}

@ComponentV2
export struct WordCardsView {

  /// 参数
  @Param @Require words                : WordUser[]               // 初始卡片文本内容数组（用于区分 initText）
  @Param initIndex                     : number        = 0        // 初始显示的卡片索引

  /// 本地状态变量声明
  @Local private pageIndex             : number        = 0        // 当前显示的卡片索引
  @Local swiperController              : SwiperController = new SwiperController() // 控制滑动视图

  @Local private recordManager         : SpeechRecordManager = new SpeechRecordManager() // 语音录音管理器
  @Local private isTalking             : boolean       = false     // 是否正在语音识别

  @Local private isShowRecording       : boolean       = false     // 是否正在录音
  @Local private isShowInfoView        : boolean       = false     // 是否显示设置 info 弹窗
  @Local private isShowDictView        : boolean       = false     // 是否显示字典 info 弹窗
  @Local private showingDictText       : string        = ''        // 字典正在显示的文本
  @Local private isShowMemberView      : boolean       = false

  @Local private isEnableContrast      : boolean       = false

  @Local isRolling                     : boolean       = false
  @Local settingManager                : SettingManager = SettingManager.shared
  @Local rollInterval                  : number        = SettingManager.shared.autoPlayInterval
  @Local isRepeat                      : boolean       = SettingManager.shared.rollRepeat

  @Monitor('settingManager.autoPlayInterval')
  onChangeOfRollInterval(){
    this.rollInterval = SettingManager.shared.autoPlayInterval
  }

  @Monitor('settingManager.rollRepeat')
  onChangeOfRollRepeat(){
    this.isRepeat = SettingManager.shared.rollRepeat
  }

  get word():WordUser {
    return this.words[this.pageIndex]
  }

  aboutToAppear(): void {
    this.pageIndex = this.initIndex

    //加载声音
    this.onChangeOfPageIndex()

    ///显示一次提示
    VersionChecker.shared.runOnceWithTokenSync('WordCardTip_1', ()=>{
      setTimeout(() => { this.isShowDictView = true; }, 1000)
    })

    ///会员检查 并恢复默认设置
    if (!MemberManager.shared.isActive) {
      SettingManager.shared.restoreSettingsForNonMember()
    }

    logEvent("CardsView_showed") //日志
  }

  @Monitor("pageIndex")
  async onChangeOfPageIndex(){

    //显示信息
    this.showInfo()

    //准备声音
    this.preLoadSound()

    //自动发音
    this.autoPlaySound()

    //保存学习进度
    this.saveLearn()

    logEvent("CardsView_pageChanged") //日志
  }


  build() {

    NavDestination(){

      Stack(){

        //背景
        BgCardImage()

        Column(){

          this.buildNavBar()
          this.buildHeadView()
          this.buildMidView()
          this.buildFootView()
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      //.backgroundColor($r('app.color.color_background'))
    }
    .hideTitleBar(true) //这里使用buildNavBar
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .menus(buildStandardMenu(this.buildMenuItems()))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色

  }

  getNavTitle(): ResourceStr | null | undefined {
    return getStringF($r('app.string.str_unit_no'), this.words[this.pageIndex].unitId ?? '')
  }

  @Builder buildNavBar(){
    NavBarCommonView({title: this.getNavTitle(), rightItems: this.buildMenuItems()})
  }

  // === 导航菜单 ===
  buildMenuItems(): CustomNavigationMenuItem[] {
    return [
      {value: "more", icon: $r('app.media.moreh'), isSvg: true, action: () => {
        this.actionPopmenu()
      }
      }
    ]
  }


  @Builder buildHeadView(){
    Stack(){
      Image($r('app.media.card_subnav_bg'))
        .width('100%')
        .height(44)
        .objectFit(ImageFit.Fill)

      Row(){
        //left
        Row({space: 10}){

          //正确
          Row(){
            Text($r('app.string.wordcard_result_right'))
              .fontSize(14)

            Text(`${this.word.correctedTimes}`)
              .fontColor($r('app.color.color_red'))

            Text($r('app.string.wordcard_result_times'))
              .fontSize(14)
          }

          Row(){
            ///不正确
            Text($r('app.string.wordcard_result_wrong'))
              .fontSize(14)

            Text(`${this.word.wrangTimes}`)
              .fontColor($r('app.color.color_blue'))
              .fontSize(14)

            Text($r('app.string.wordcard_result_times'))
              .fontSize(14)
          }

        }


        //right
        Row(){
          //收藏按钮
          FavoriteStarButton({word: this.word})

        }

      }
      .padding(0)
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }

  }

  @Builder buildMidView(){

    Column(){

      // 卡片滑动视图
      Swiper(this.swiperController) {
        ForEach(this.words, (word: WordUser, index: number) => {

          WordCardOne({word: word,
            pageInfo: `${index + 1}/${this.words.length}`,
            onClickedBtnWordPron:(wd: WordUser)=>{
              // this.playSound(wd.wordEnSoundText)
              this.actionPlayWordSound(wd.wordEnSoundText)
            },

            onClickedBtnExamplePron:(wd: WordUser)=>{
              // this.playSound(wd.exampleEn)
              this.actionPlayExampleSound(wd.exampleEn)
            },
            onClickedText:(text: string)=>{
              this.showingDictText = text
              this.isShowDictView = true
            },
          })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .index(this.pageIndex) // 当前显示索引
      .autoPlay(this.isRolling) // 自动播放
      .indicator(false) // 隐藏指示器
      .loop(this.isRepeat) //循环
      .interval(this.rollInterval)//自动播放 间隔
      .cachedCount(2) // 提升滑动性能
      .curve(Curve.EaseOut) // 设置动画曲线
      .onChange((index: number) => {
        this.pageIndex = index // 滑动时更新索引
      })
      .onContentWillScroll((result: SwiperContentWillScrollResult) => {

        return true
      })
    }
    .layoutWeight(1)
    .bindSheet($$this.isShowDictView, this.buildDictView(), {
      detents: [SheetSize.FIT_CONTENT],
      preferType: SheetType.BOTTOM,
      showClose: false,
      onDisappear:()=>{
        this.showingDictText   = ''
      }
    })

  }

  ///创建DictView
  @Builder buildDictView(){
    DictView({title: this.showingDictText})

  }

  private loadData(){

  }

  async showInfo(){
    this.isEnableContrast = await this.recordManager.isExistsSound(this.word.wordEn!)
  }

  ///显示转到测验或挑战页面的弹出选项
  private actionPopmenu(){
    let options: ItemOption[] = []


    ///立即测验
    options.push(
      {text: getString($r('app.string.wordcard_detail_to_test_btn_test')),action: ()=>{
        //我要测验
        QuizManager.shared.questionMode = QuestionMode.Normal
        this.openTestStart()
      }})

    ///拼写练习
    options.push(
      {text: getString($r('app.string.wordcard_detail_to_test_btn_spell')),action: ()=>{
        //拼写练习
        QuizManager.shared.questionMode = QuestionMode.Spell
        this.openTestStart()
      }})

    Toast.showSelectOptions($r('app.string.wordcard_detail_to_test_msg'),undefined, options, $r('app.string.wordcard_detail_to_test_btn_cancel'))

  }

  //打开QuizStart
  openTestStart(){
    QuizManager.shared.quizType    = QuizType.Custom
    QuizManager.shared.customWords = this.words
    QuizStartViewConfig.open()
  }

  @Builder buildFootView(){

    Row(){

      ///left info
      // Stack(){
        IconTintButton({icon: $r('app.media.card_btn_info_1'), iconColor: $r('app.color.color_footTint'), iconSize: 28, onClickCallBack: ()=>{ this.actionInfo() }})
          .bindSheet($$this.isShowInfoView, this.buildInfoView(), {
            detents: [SheetSize.FIT_CONTENT],
            preferType: SheetType.BOTTOM,
            showClose: false,
            backgroundColor: Color.Transparent,
            modalTransition:ModalTransition.ALPHA,
            mode: SheetMode.EMBEDDED,
            onDisappear:()=>{
              SettingManager.shared.save()
            }
          })
      // }
      // .hitTestBehavior(HitTestMode.Block)
      // .bindMenu(this.buildInfoView())

      Blank().layoutWeight(1)

      ///mid roll
      IconTintButton({icon: this.isRolling ? $r('app.media.card_btn_stop_1') :  $r('app.media.card_btn_roll_1'), iconColor: $r('app.color.color_footTint'), iconSize: 28, onClickCallBack: ()=>{ this.actionRoll() }})
        .margin({left: 30})

      Blank().layoutWeight(1)

      //right
      Row({space: 10}){
        /// record
        IconTintButton({icon: $r('app.media.card_btn_record_1'), iconColor: $r('app.color.color_footTint'), iconSize: 28, onClickCallBack: ()=>{ this.actionRecord() }})
          .bindSheet($$this.isShowRecording, this.buildRecordingView(), {
            detents: [SheetSize.FIT_CONTENT],
            preferType: SheetType.BOTTOM,
            title: {title:'录音中..'} ,
            backgroundColor: $r('app.color.colorPrimaryDark'),
            onAppear: () => {

              ///开始录音
              this.recordManager.startRecord(this.word.wordEn)

            },

            onDisappear: async  () => {

              ///延迟1秒
              awaitDelay(1000)

              //停止录音
              this.recordManager.stopRecord()

              ///对比按钮 可用
              this.isEnableContrast = true
            }

          })

        /// contrast
        IconTintButton({icon: $r('app.media.card_btn_contrast_1'), iconColor: $r('app.color.color_footTint'), iconSize: 28, isEnabled: this.isEnableContrast, onClickCallBack: ()=>{ this.actionContrast() }})

      }
    }
    .width('100%')
    .backgroundColor($r('app.color.color_foot'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .justifyContent(FlexAlign.Start)
    .padding(10)
    .bindSheet($$this.isShowMemberView, this.buildMemberView(), {
      detents: [SheetSize.FIT_CONTENT],
      preferType: SheetType.CENTER,
      showClose: false
    })

  }


  @Builder buildRecordingView() {
    Stack(){
      RecordingView({isTalking: this.isTalking ,
        onStopRecording: async () => {
          this.recordManager.stopRecord();        // 停止录音
          this.isShowRecording = false;          // 关闭界面
        }
      })
    }
    .width('100%')
    .height(300)


  }

  @Builder buildInfoView(){
    InfoView({isShowing: this.isShowInfoView, $isShowing:(val) => {
      SettingManager.shared.save()
      this.isShowInfoView = false
    }})
      .height(300)
  }


  @Builder buildMemberView() {
    MemberView({isShowing: this.isShowMemberView, $isShowing:(val: boolean)=>{
      //关闭会员页面
      this.isShowMemberView = val

      //准备声音
      this.preLoadSound()

    }})
  }

  ///actions
  actionInfo(){
    this.isShowInfoView = true
  }

  actionRoll(){

    if (!this.isRolling) {
      this.swiperController.showNext() //滚动一次
    }

    this.isRolling = !this.isRolling
  }

  async actionRecord(){
    ///会员检查
    if(!MemberManager.shared.checkRecordUsable(true)){
      return;
    }

    if(await PermissionManager.ensurePermissionWithRetry( getAppContext(),
      ["ohos.permission.MICROPHONE"],
      "要使用录音功能，请开启麦克风访问权限。",
      "录音功能，需要开启麦克风访问权限")){

      this.isShowRecording = true //通过，再次开启
    }
  }

  async actionContrast(){
    //听
    this.recordManager.startPlay(this.word.wordEn!)
  }

  async preLoadSound() {

    ///会员检查
    if(!MemberManager.shared.checkWordPronUsable(false)){
      return;
    }

    const pageCnt: number        = this.words.length;
    const index: number          = this.pageIndex;

    const preCachPageCnt: number = 1;
    const pageStart: number      = Math.max(index - preCachPageCnt, 0);
    const pageEnd: number        = Math.min(index + preCachPageCnt + 1, pageCnt);

    ///遍历 每一页
    for (let page = pageStart; page < pageEnd; page++) {

      ///预 加载 单词发音
      await this.preLoadOneSound(this.words[page].wordEnSoundText)

      ///预 加载 例句发音
      await this.preLoadOneSound(this.words[page].exampleEn)
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

  actionPlayWordSound(text: string | null){
    ///会员检查
    if(!MemberManager.shared.checkWordPronUsable(true)){
      this.isShowMemberView = true
      return;
    }

    this.playSound(text)
  }

  actionPlayExampleSound(text: string | null){
    ///会员检查
    if(!MemberManager.shared.checkExamplePronUsable(true)){
      this.isShowMemberView = true
      return;
    }

    this.playSound(text)
  }

  /// [直接]播放 (汉字 or 词语的) 声音
  async playSound(text: string | null) {
    if (!text) return;

    ///播放声音
    await AudioPlayer.shared.play(text)

    logEvent("CardsView_playSound") //日志
  }

  // 自动发音
  async autoPlaySound(){

    ///会员检查
    if(!MemberManager.shared.checkAutoPronUsable(false)){
      return;
    }

    // 单词 自动发音
    if (SettingManager.shared.autoPlaySound) {
      await AudioPlayer.shared.play(this.word.wordEnSoundText)
    }

    //例句
    if (SettingManager.shared.autoPlaySoundEx) {
      //排队播放
      await AudioPlayer.shared.prepareToPlay(this.word.exampleEn)
    }

  }

  //保存学习进度
  async saveLearn(){
    await SearchManager.shared.incrementLearnTimesForWord(this.word)
  }

}