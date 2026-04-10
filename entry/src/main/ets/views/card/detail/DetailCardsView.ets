import { IconTintButton } from "../../../app/views/buttons/IconTintButton"
import { logEvent } from "../../../common/components/Logger/Logger"
import { WordUser } from "../../../models/datas/myData/WordUser"
import { SettingManager } from "../../../models/managers/setting/SettingManager"
import { SearchManager } from "../../../models/datas/model/SearchManager"
import { NavPop, NavPopTop, NavTo } from "../../../pages/NavPathManager"
import { buildNavTitle } from "../../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../../app/constants/AppDefines"
import { getString, getStringF } from "../../../common/utils/ResourceUtils"
import { BgCardImage } from "../../../app/views/BgCardImage"
import { awaitDelay, buildStandardMenu, CustomNavigationMenuItem } from "../../../app/constants/AppFunctions"
import { FavoriteStarButton } from "../../../app/views/buttons/FavoriteStarButton"
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
import { DetailCardOne } from "./DetailCardOne"
import { DictView } from "../wordcard/dict/DictView"
import { InfoView } from "../wordcard/info/InfoView"
import { DetailItemSortView } from "./detailitemsort/DetailItemSortView"
import { SimpleEventBus } from "../../../common/components/eventbus/SimpleEventBus"
import {
  ShareMemoManager2Notification,
  ShareMemoNotificationPayload
} from "../../../models/managers/sharedata2/ShareMemoManager2"
import { DetailItemNotification } from "../../../models/managers/detailitem/DetailItemManager"
import { Plan } from "../../../models/managers/plan/plancurve/Plan"
import { DayOf } from "../../../models/managers/plan/plancurve/DayOf"
import { OnlineSearchWordsViewConfig } from "../../onlinesearch/OnlineSearchWordsView"
import { DailyCountManager, DailyCountType } from "../../../models/managers/member/DailyCountManaer"
import { WordDetail } from "../../../models/datas/word/WordDetail"
import { BookManager } from "../../../models/datas/book/BookManager"
import { EWordItemPickerView } from "../../eword/EWordItemPickerView"
import { EBookSelectView } from "../../ebook/EBookSelectView"
import { GoldManager } from "../../../models/managers/gold/GoldManager"

export namespace DetailCardsViewConfig {

  ///导航key
  export const NavKey = "DetailCardsView_show"

  ///打开方式
  export function open(param: Param){
    if (param.words.length > 0) {
      NavTo(DetailCardsViewConfig.NavKey, param, true)
    }
  }

  export interface Param {
    words      : WordUser[]
    initIndex  : number

    plan?      : Plan  | null
    dayOf?     : DayOf | null
  }

}

// 统一管理 DetailCardsView 中单一 bindSheet 的内容类型，避免多个 bindSheet 同层互相抢占。
enum DetailSheetType {
  None         = 0,
  EWordPicker  = 1,
  EBookSelect  = 2
}

@ComponentV2
export struct DetailCardsView {

  /// 参数
  @Param @Require words                    : WordUser[]             // 初始卡片文本内容数组（用于区分 initText）
  @Param initIndex                         : number                 = 0                              // 初始显示的卡片索引
  @Param plan?                             : Plan | null            = null                           // 用于学习记录
  @Param dayOf?                            : DayOf | null           = null                           // 用于学习记录

  /// 本地状态变量声明
  @Local private pageIndex                      : number                 = 0                              // 当前显示的卡片索引
  @Local swiperController                       : SwiperController       = new SwiperController()         // 控制滑动视图
  @Local private recordManager                  : SpeechRecordManager    = new SpeechRecordManager()      // 语音录音管理器
  @Local private isTalking                      : boolean                = false                          // 是否正在语音识别
  @Local private isShowRecording                : boolean                = false                          // 是否正在录音
  @Local private isShowInfoView                 : boolean                = false                          // 是否显示设置 info 弹窗
  @Local private isShowDictView                 : boolean                = false                          // 是否显示字典 info 弹窗
  @Local private showingDictText                : string                 = ''                             // 字典正在显示的文本
  @Local private isShowMemberView               : boolean                = false
  @Local private isShowDetailSort               : boolean                = false                          // 是否显示详细项目排序面板
  @Local private isShowDetailSheet              : boolean                = false                          // 单一 Sheet 显示开关（避免同层多个 bindSheet 抢占）
  @Local private detailSheetType                : DetailSheetType        = DetailSheetType.None           // 当前单一 Sheet 的内容类型
  @Local private wordDetailForEWordPicker       : WordDetail | null      = null                           // EWord 编辑使用的临时 detail
  @Local private wordDetailForEBookSelect       : WordDetail | null      = null                           // EBook 保存使用的临时 detail
  @Local private isEnableContrast               : boolean                = false
  @Local isRolling                              : boolean                = false
  @Local shareMemoUiTick                        : number                 = 0
  @Local settingManager                         : SettingManager         = SettingManager.shared
  @Local rollInterval                           : number                 = SettingManager.shared.autoPlayInterval
  @Local isRepeat                               : boolean                = SettingManager.shared.rollRepeat

  private shareMemoUnsubPrivate          : (() => void) | undefined = undefined
  private shareMemoUnsubPublic           : (() => void) | undefined = undefined

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

      // 与 iOS `DetailViewController.viewDidAppear` 一致：非会员进入学习详情时检查每日学习金币。
      GoldManager.shared.provideGoldsForEveryDayStudyIfNeedsWithBlock(null)
    }

    // ShareMemoManager2 同步公开/私有笔记变更（与 iOS NotificationCenter 一致）
    if (this.shareMemoUnsubPrivate === undefined) {

      this.shareMemoUnsubPrivate = SimpleEventBus.on<ShareMemoNotificationPayload>(
        ShareMemoManager2Notification.Name.PrivateChanged,
        (p?: ShareMemoNotificationPayload) => {
          this.handleShareMemoNotification(p)
        })

      this.shareMemoUnsubPublic = SimpleEventBus.on<ShareMemoNotificationPayload>(
        ShareMemoManager2Notification.Name.PublicChanged,
        (p?: ShareMemoNotificationPayload) => {
          this.handleShareMemoNotification(p)
        })
    }

    logEvent("CardsView_showed") //日志
  }

  aboutToDisappear(): void {

    this.shareMemoUnsubPrivate?.()
    this.shareMemoUnsubPrivate = undefined
    this.shareMemoUnsubPublic?.()
    this.shareMemoUnsubPublic = undefined
  }

  private handleShareMemoNotification(p?: ShareMemoNotificationPayload): void {

    if (!p) {
      return
    }

    const en = p.word.titleEn

    if (!en) {
      return
    }

    if (this.words.some((w: WordUser) => w.titleEn === en)) {
      this.shareMemoUiTick++
    }
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
        // BgCardImage()

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
      .backgroundColor($r('app.color.color_background'))
      .bindSheet($$this.isShowDetailSheet, this.buildDetailSheet(), {
        detents         : [SheetSize.LARGE],
        preferType      : SheetType.CENTER,
        backgroundColor : $r('app.color.colorPrimary'),
        showClose       : false,
        onDisappear     : () => {
          // 记录关闭前类型：onDisappear 触发后会立即重置 detailSheetType
          const oldType = this.detailSheetType
          this.isShowDetailSheet = false
          this.detailSheetType   = DetailSheetType.None

          // 分支：关闭前是 EWord 选择 Sheet，清理 EWord 的临时 detail 并刷新当前卡片缓存
          if (oldType === DetailSheetType.EWordPicker && this.wordDetailForEWordPicker !== null) {
            this.wordDetailForEWordPicker = null

            const w = this.words[this.pageIndex]
            w.clearWordDetailCache()
            this.shareMemoUiTick++
          // 分支：关闭前是 EBook 选择 Sheet，清理 EBook 的临时 detail 并刷新当前卡片缓存
          } else if (oldType === DetailSheetType.EBookSelect && this.wordDetailForEBookSelect !== null) {
            this.wordDetailForEBookSelect = null

            const w = this.words[this.pageIndex]
            w.clearWordDetailCache()
            this.shareMemoUiTick++
          }
        }
      })
    }
    .hideTitleBar(true) //这里使用buildNavBar
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .menus(buildStandardMenu(this.buildMenuItems()))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色

  }

  getNavTitle(): ResourceStr | null | undefined {
    // return getStringF($r('app.string.str_unit_no'), this.words[this.pageIndex].unitId ?? '')
    return this.word.unitName
  }

  @Builder buildNavBar(){
    NavBarCommonView({title: this.getNavTitle(), rightItems: this.buildMenuItems()})
  }

  // === 导航菜单 ===
  buildMenuItems(): CustomNavigationMenuItem[] {
    return [
      {value: "trash", icon: $r('app.media.trash'), isSvg: true, action: () => {
        this.actionTrash()
      } },

      {value: "search", icon: $r('app.media.search'), isSvg: true, action: () => {

        this.actionSearch()
      } },

      {value: "more", icon: $r('app.media.moreh'), isSvg: true, action: () => {
        this.actionPopmenu()
      } },
    ]
  }


  @Builder buildHeadView(){
    Stack(){
      // Image($r('app.media.card_subnav_bg'))
      //   .width('100%')
      //   .height(44)
      //   .objectFit(ImageFit.Fill)

      Row(){
        //left
        Row({space: 20}){

          //正确
          Row(){
            Image($r('app.media.ic_zhengque'))
              .width(18)
              .height(18)
              .objectFit(ImageFit.Fill)

            Text($r('app.string.wordcard_result_right'))
              .fontSize(14)

            Text(`${this.word.correctedTimes}`)
              .fontColor($r('app.color.color_green'))

            Text($r('app.string.wordcard_result_times'))
              .fontSize(14)
          }

          Row(){
            ///不正确
            Image($r('app.media.ic_buzhengqu'))
              .width(18)
              .height(18)
              .objectFit(ImageFit.Fill)

            Text($r('app.string.wordcard_result_wrong'))
              .fontSize(14)

            Text(`${this.word.wrangTimes}`)
              .fontColor($r('app.color.color_red'))
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
      .padding(5)
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }

  }

  @Builder buildMidView(){

    Column(){

      // 卡片滑动视图
      Swiper(this.swiperController) {
        ForEach(this.words, (word: WordUser, index: number) => {

          DetailCardOne({
            word: word,
            pageInfo: `${index + 1}/${this.words.length}`,
            wordIndexOnPage: index,
            onClickedBtnWordPron:(wd: WordUser)=>{
              // this.playSound(wd.wordEnSoundText)
              this.actionPlayWordSound(wd.wordEnSoundText)
            },

            onClickedBtnExamplePron:(text: string)=>{
              // this.playSound(wd.exampleEn)
              this.actionPlayExampleSound(text)
            },
            onClickedText:(text: string)=>{
              if (!MemberManager.shared.checkDictShowable(true, true)) {
                return
              }

              this.showingDictText = text
              this.isShowDictView = true
            },
            onNeedEditWord:()=>{
              void this.openEWordItemPickerForCurrentWord()
            },
          })
        }, (word: WordUser, index: number) => `${word.titleEn}_${index}_${this.shareMemoUiTick}`)
      }
      .width('100%')
      .layoutWeight(1)
      .index(this.pageIndex) // 当前显示索引
      .autoPlay(this.isRolling) // 自动播放
      .indicator(false) // 隐藏指示器
      .loop(this.isRepeat) //循环
      .interval(this.rollInterval)//自动播放 间隔
      .cachedCount(1) // 提升滑动性能
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
    DictView({title: this.showingDictText, isShowing: this.isShowDictView!!})

  }

  private loadData(){

  }

  async showInfo(){
    this.isEnableContrast = await this.recordManager.isExistsSound(this.word.titleEn!)
  }

  private actionTrash(){
    this.word.changeDeletedWord(!this.word.isDeleted())
  }

  private actionSearch(){
    OnlineSearchWordsViewConfig.open()
  }

  ///显示转到测验或挑战页面的弹出选项（与 iOS DetailViewController.actionPopmenu 顺序、文案一致）
  private actionPopmenu(){

    // 与 iOS `stopRoll()` 一致：弹出菜单时停止自动翻页
    if (this.isRolling) {
      this.isRolling = false
    }

    logEvent("CardsView_detail_popmenu")

    const options: ItemOption[] = []

    // LEARN_DETAIL_TO_TEST_BTN_TEST
    options.push({
      text   : getString($r('app.string.learn_detail_to_test_btn_test')),
      action : () => {
        QuizManager.shared.questionMode = QuestionMode.Normal
        this.openTestStart()
      }
    })

    // LEARN_DETAIL_TO_TEST_BTN_CHLG
    options.push({
      text   : getString($r('app.string.learn_detail_to_test_btn_chlg')),
      action : () => {
        QuizManager.shared.questionMode = QuestionMode.Challenge
        this.openTestStart()
      }
    })

    // LEARN_DETAIL_TO_TEST_BTN_SPELL
    options.push({
      text   : getString($r('app.string.learn_detail_to_test_btn_spell')),
      action : () => {
        QuizManager.shared.questionMode = QuestionMode.Spell
        this.openTestStart()
      }
    })

    // EWORD_EDIT_ACTION → editCurrentWord()
    options.push({
      text   : getString($r('app.string.eword_edit_action')),
      action : () => {
        void this.openEWordItemPickerForCurrentWord()
      }
    })

    // EBOOK_SAVE_AS → EBookSelectView
    options.push({
      text   : getString($r('app.string.ebook_save_as')),
      action : () => {
        void this.openEBookSelectForCurrentWord()
      }
    })

    Toast.showSelectOptions(
      $r('app.string.learn_detail_to_test_msg'),
      undefined,
      options,
      $r('app.string.learn_detail_to_test_btn_cancel'))
  }

  /// 打开当前页词条的 EWord 字段选择 Sheet（与 iOS editCurrentWord 对齐）
  private async openEWordItemPickerForCurrentWord(): Promise<void> {

    const w = this.words[this.pageIndex]

    w.clearWordDetailCache()

    const detail = await w.getWordDetail()

    // 分支：当前词条无详情时，不打开 Sheet。
    if (detail === null) {
      return
    }

    this.wordDetailForEWordPicker = detail
    this.detailSheetType          = DetailSheetType.EWordPicker
    this.isShowDetailSheet        = true
  }

  /// 打开当前页词条的 EBook 选择 Sheet（与 iOS present EBookSelectView 对齐）
  private async openEBookSelectForCurrentWord(): Promise<void> {

    const w = this.words[this.pageIndex]

    w.clearWordDetailCache()

    const detail = await w.getWordDetail()

    // 分支：当前词条无详情时，不打开 Sheet。
    if (detail === null) {
      return
    }

    this.wordDetailForEBookSelect = detail
    this.detailSheetType          = DetailSheetType.EBookSelect
    this.isShowDetailSheet        = true
  }

  @Builder
  // 单一 Sheet 出口：按 detailSheetType 分发 EWord/EBook 页面（参考 BooksLocalView 的单 bindSheet 模式）。
  buildDetailSheet() {
    // 分支：当前类型为 EWordPicker，构建 EWord 字段选择页。
    if (this.detailSheetType === DetailSheetType.EWordPicker && this.wordDetailForEWordPicker !== null) {

      EWordItemPickerView({
        originalDetail : this.wordDetailForEWordPicker as WordDetail,
        isEBook        : BookManager.shared.currentBook?.isEBook === true,
        isOnlineWord   : this.word.isOnlineWord,
        onDismiss      : () => {

          this.isShowDetailSheet = false
        }
      })
    // 分支：当前类型为 EBookSelect，构建 EBook 选择页。
    } else if (this.detailSheetType === DetailSheetType.EBookSelect && this.wordDetailForEBookSelect !== null) {

      EBookSelectView({
        originalDetail : this.wordDetailForEBookSelect as WordDetail,
        onDismiss        : () => {

          this.isShowDetailSheet = false
        }
      })
    }
  }

  /// 打开 QuizStart（自定义范围：当前卡片集）
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
            mode: SheetMode.OVERLAY,
            onDisappear:()=>{
              SettingManager.shared.save()
            }
          })
      // }
      // .hitTestBehavior(HitTestMode.Block)
      // .bindMenu(this.buildInfoView())

      Blank().layoutWeight(1)

      //mid
      Row({space: 20}){
        ///prev
        IconTintButton({icon: $r('app.media.arrow_prev_1'), iconColor: $r('app.color.color_footTint'), iconSize: 28, onClickCallBack: ()=>{ this.actionPrev() }})

        ///mid roll
        IconTintButton({icon: this.isRolling ? $r('app.media.card_btn_stop_1') :  $r('app.media.card_btn_roll_1'), iconColor: $r('app.color.color_footTint'), iconSize: 28, onClickCallBack: ()=>{ this.actionRoll() }})

        ///next
        IconTintButton({icon: $r('app.media.arrow_next_1'), iconColor: $r('app.color.color_footTint'), iconSize: 28, onClickCallBack: ()=>{ this.actionNext() }})

      }
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
              this.recordManager.startRecord(this.word.titleEn)

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
      .bindSheet($$this.isShowDetailSort, this.buildDetailSortView(), {
        detents: [SheetSize.FIT_CONTENT],
        preferType: SheetType.CENTER,//使用center在Folder上展开时能正常居中显示
        //title: {title:$r('app.string.detail_item_sort_nav_title')} ,
        showClose: false
      })

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
    }, onClickedBtnSort: ()=>{

      //调整显示顺序
      this.isShowDetailSort = true
    }})
      //.height(300)
  }


  @Builder buildMemberView() {
    MemberView({isShowing: this.isShowMemberView, $isShowing:(val: boolean)=>{
      //关闭会员页面
      this.isShowMemberView = val

      //准备声音
      this.preLoadSound()

    }})
  }

  @Builder buildDetailSortView() {
    DetailItemSortView({
      isShowing: this.isShowDetailSort!!,
      onClose: (changed: boolean) => {

        if (changed) {
          //重新显示数据
          //发送通知 order改变
          SimpleEventBus.emit(DetailItemNotification.Name.ItemVisibleOrderChanged)
        }

      }})
      .width('100%')
  }

  ///actions
  actionInfo(){
    this.isShowInfoView = true
  }

  actionPrev(){
    this.swiperController.showPrevious()
  }

  actionNext(){
    this.swiperController.showNext()
  }

  actionRoll(){

    if (!this.isRolling) {
      this.swiperController.showNext() //滚动一次
    }

    this.isRolling = !this.isRolling
  }

  async actionRecord(){
    ///会员检查
    // if(!MemberManager.shared.checkRecordUsable(true)){
    //   return;
    // }

    if(await PermissionManager.ensurePermissionWithRetry( getAppContext(),
      ["ohos.permission.MICROPHONE"],
      "要使用录音功能，请开启麦克风访问权限。",
      "录音功能，需要开启麦克风访问权限")){

      this.isShowRecording = true //通过，再次开启
    }
  }

  async actionContrast(){
    //听
    this.recordManager.startPlay(this.word.titleEn!)
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
      await this.preLoadOneSound(this.words[page].exampleEn1)
      const wordDetail = await this.words[page].getWordDetail()
      if (wordDetail) {
        await this.preLoadOneSound(wordDetail.exampleEn2)
        await this.preLoadOneSound(wordDetail.exampleEn3)
      }
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

    // 记录当前的 发音次数
    DailyCountManager.shared.increase(DailyCountType.wordPron)
  }

  actionPlayExampleSound(text: string | null){
    ///会员检查
    if(!MemberManager.shared.checkExamplePronUsable(true, true)){
      this.isShowMemberView = true
      return;
    }

    this.playSound(text)

    // 记录当前的 发音次数
    DailyCountManager.shared.increase(DailyCountType.examplePron)
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
      ///播放一次
      await AudioPlayer.shared.play(this.word.wordEnSoundText)

      //播放2，3次
      const pronTimes = SettingManager.shared.pronTimes
      if (pronTimes > 1) {
        for (let j = 0; j < pronTimes - 1; j++) {
          AudioPlayer.shared.prepareToPlay(this.word.wordEnSoundText)
        }
      }
    }



    //例句
    if (SettingManager.shared.autoPlaySoundEx) {
      //排队播放
      await AudioPlayer.shared.prepareToPlay(this.word.exampleEn1)
      const wordDetail = await this.word.getWordDetail()
      if (wordDetail) {
        await AudioPlayer.shared.prepareToPlay(wordDetail.exampleEn2)
        await AudioPlayer.shared.prepareToPlay(wordDetail.exampleEn3)
      }
    }

  }

  //保存学习进度
  async saveLearn(){
    await SearchManager.shared.incrementLearnTimesForWord(this.word)


    //记忆曲线保存记录
    if (this.plan && this.dayOf && this.word.idx) {
      this.plan?.saveLearned(this.word.idx, this.dayOf)
    }
  }

}
