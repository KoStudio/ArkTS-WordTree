import { buildNavTitle } from "../../../app/constants/AppBuilders";
import { dMemberFlag, dNavBackIcon } from "../../../app/constants/AppDefines";
import { DebugFlg } from "../../../app/debug/DebugFlg";
import { BgImage } from "../../../app/views/BgImage";
import { TextStyleButton, TextStyleButtonStyle } from "../../../app/views/buttons/TextStyleButton";
import { SegmentButton, SegmentItem } from "../../../app/views/SegmentButton";
import { getString } from "../../../common/utils/ResourceUtils";
import { Toast } from "../../../common/utils/Toast";
import {
  QuestionMode, QuestionOrder,
  QuestionScope,
  QuestionSpeed,
  QuestionType,
  QuizManager, QuizType
} from "../../../models/datas/model/QuizManager";
import { MemberManager } from "../../../models/managers/member/MemberManager";
import { NavTo } from "../../../pages/NavPathManager";
import { QuizChallengeViewConfig } from "../running/QuizChallengeView";
import { QuizRunningViewConfig } from "../running/QuizRunningView";
import { SpellRunningViewConfig } from "../spell/SpellRunningView";

export namespace QuizStartViewConfig {

  ///导航key
  export const NavKey = "QuizStartView_show"

  ///打开方式
  export function open(){
    NavTo(NavKey, undefined, true)
  }

}

@ComponentV2
export struct QuizStartView {

  @Local private visiblePanels: number[]           = [];

  @Local private questionMode: QuestionMode        = QuizManager.shared.questionMode       //QuestionMode.Normal;
  @Local private questionCount: SegQuestionCount   = QuizManager.shared.questionCount      //SegQuestionCount.Ten;
  @Local private questionSpeed: QuestionSpeed      = QuizManager.shared.questionSpeed      //QuestionSpeed.Normal;
  @Local private questionOrder: QuestionOrder      = QuizManager.shared.questionOrder      //QuestionOrder.SerialNo;
  @Local private questionPronounce: boolean        = QuizManager.shared.questionPronounce  //false;
  @Local private questionType: QuestionType        = QuizManager.shared.questionType       //QuestionType.Eiwa;
  @Local private questionScope: QuestionScope      = QuizManager.shared.questionScope      //QuestionScope.all

  @Local private scopeCount: number                = 0;
  @Local private startButtonEnabled: boolean       = false;

  @Local private segmentItemsMode      :SegmentItem[]     = []
  @Local private segmentItemsCount     :SegmentItem[]     = []
  @Local private segmentItemsSpeed     :SegmentItem[]     = []
  @Local private segmentItemsOrder     :SegmentItem[]     = []
  @Local private segmentItemsPronounce :SegmentItem[]     = []
  @Local private segmentItemsType      :SegmentItem[]     = []
  @Local private segmentItemsScope     :SegmentItem[]     = []

  @Local refreshKey: number = 1

  aboutToAppear() {
    this.segmentItemsMode      = this.createSegmentItems(SegType.Mode);
    this.segmentItemsCount     = this.createSegmentItems(SegType.Count);
    this.segmentItemsSpeed     = this.createSegmentItems(SegType.Speed);
    this.segmentItemsOrder     = this.createSegmentItems(SegType.Order);
    this.segmentItemsPronounce = this.createSegmentItems(SegType.Pronounce);
    this.segmentItemsType      = this.createSegmentItems(SegType.Type);
    this.segmentItemsScope     = this.createSegmentItems(SegType.Scope);

    this.loadScopeWords()
    this.layoutSubViews();

    if (DebugFlg.isDebugMode()) {
      Toast.showMessage(`scopeCount: ${this.scopeCount}`)
    }
  }

  loadScopeWords(){
    this.scopeCount = QuizManager.shared.loadScopeWords().length;
    this.refreshControlState();

    if (DebugFlg.isDebugMode()) {
      Toast.showDebugMessage(`scopeCount: ${this.scopeCount}`)
    }
  }


  // MARK: - 构建页面
  build() {
    NavDestination() {
      Stack() {
        BgImage()

        Column() {
          this.buildContentView()
          this.buildFooter()
        }
      }
    }
    .title(buildNavTitle(this.getNavTitle()))
    .backButtonIcon(dNavBackIcon)
    .backgroundColor($r('app.color.colorPrimary'))
  }

  private getNavTitle(): ResourceStr {
    return $r('app.string.nav_title_quiz_start');
  }

  // MARK: - 主内容
  @Builder
  buildContentView() {
    Column() {
      ForEach(this.visiblePanels, (panelType: number) => {
        this.buildPanel(panelType)
      },(panelType: number , index: number) => `${panelType}_${this.refreshKey}`)
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
    .padding(10)
    .layoutWeight(1)
  }

  // MARK: - 底部 Start 按钮
  @Builder
  buildFooter() {
    Row() {
      TextStyleButton({
        style:           TextStyleButtonStyle.SOLID,
        text:            $r('app.string.quiz_start_btn_text'),
        minWidth:        180,
        isEnabled:       this.startButtonEnabled,
        onClickCallBack: () => { this.actionStart() }
      })
    }
    .padding(16)
    .width('100%')
    .backgroundColor($r('app.color.color_foot'))
    .justifyContent(FlexAlign.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  // MARK: - 单个 Panel
  @Builder
  buildPanel(panelType: SegType) {
    Column() {
      Text(this.getPanelTitle(panelType))
        .width('100%')
        .height(30)
        .fontSize(16)
        .fontColor('#000000')
        .textAlign(TextAlign.Start)

      SegmentButton({
        items:         this.getSegmentItems(panelType),
        selectedIndex: this.getSelectedIndex(panelType),
        totalWidth:    '100%',
        onSelect:      (index: number) => this.handleSegmentChange(panelType, index)
      })
    }
    .width('100%')
    .margin({ bottom: 10 })
    .padding(5)
  }


  private getSegmentItems(panelType: SegType): SegmentItem[] {
    switch (panelType) {
      case SegType.Mode:      return this.segmentItemsMode;
      case SegType.Count:     return this.segmentItemsCount;
      case SegType.Speed:     return this.segmentItemsSpeed;
      case SegType.Order:     return this.segmentItemsOrder;
      case SegType.Pronounce: return this.segmentItemsPronounce;
      case SegType.Type:      return this.segmentItemsType;
      case SegType.Scope:     return this.segmentItemsScope;
      default:                return [];
    }
  }

  // MARK: - 获取 SegmentButton Items
  private createSegmentItems(panelType: SegType): SegmentItem[] {

    // 否则初始化
    const items: SegmentItem[] = [];

    switch (panelType) {
      case SegType.Mode:

        items.push({ title: $r('app.string.quiz_start_mode_normal'),    isEnabled: true });
        items.push({ title: $r('app.string.quiz_start_mode_challenge'), isEnabled: true });
        break;

      case SegType.Count:
        items.push({ title: $r('app.string.quiz_start_count_10'),    isEnabled: true });
        items.push({ title: $r('app.string.quiz_start_count_20'),    isEnabled: true });
        items.push({ title: $r('app.string.quiz_start_count_50'),    isEnabled: true });
        items.push({ title: $r('app.string.quiz_start_count_100'),   isEnabled: true });
        break;

      case SegType.Speed:
        items.push({ title: $r('app.string.quiz_start_speed_slow'),    isEnabled: true });
        items.push({ title: $r('app.string.quiz_start_speed_normal'),  isEnabled: true });
        items.push({ title: $r('app.string.quiz_start_speed_fast'),    isEnabled: true });
        break;

      case SegType.Order:
        items.push({ title: $r('app.string.quiz_start_order_no'),      isEnabled: true });
        items.push({ title: $r('app.string.quiz_start_order_random'),  isEnabled: true });
        break;

      case SegType.Pronounce:
        items.push({ title: $r('app.string.quiz_start_pronounce_on'),  isEnabled: true });
        items.push({ title: $r('app.string.quiz_start_pronounce_off'), isEnabled: true });
        break;

      case SegType.Type:
        items.push({ title: $r('app.string.quiz_start_type_eiwa'),    isEnabled: true });
        items.push({ title: $r('app.string.quiz_start_type_waei'),    isEnabled: true });
        break;

        case SegType.Scope:
        items.push({ title: $r('app.string.test_question_scope_all'),      isEnabled: true });
        items.push({ title: $r('app.string.test_question_scope_still'),    isEnabled: true });
        items.push({ title: $r('app.string.test_question_scope_wrang'),    isEnabled: true });
        break;

      default:
        break;
    }
    return items;
  }


  // MARK: - 面板显示逻辑
  private layoutSubViews(): void {
    this.visiblePanels = [];
    const quizType: QuizType = QuizManager.shared.quizType;

    switch (quizType) {
      case QuizType.Custom:
      case QuizType.Unit:
        this.visiblePanels.push(SegType.Scope, SegType.Type, SegType.Speed, SegType.Order, SegType.Pronounce);
        break;

      case QuizType.All:
      case QuizType.Category:
      case QuizType.Mistake:
      case QuizType.Favorite:
      case QuizType.Review:
        this.visiblePanels.push(SegType.Scope,  SegType.Count, SegType.Type, SegType.Speed, SegType.Order, SegType.Pronounce);
        break;

      default:
        this.visiblePanels.push(SegType.Scope,  SegType.Type, SegType.Speed, SegType.Order, SegType.Pronounce);
    }

    // ///拼写时
    // if (this.questionMode === QuestionMode.Spell) {
    //
    //   ///不可选择 测验模式
    //   const modeIndex  = this.visiblePanels.indexOf(SegType.Mode);
    //   if (modeIndex >= 0) this.visiblePanels.splice(modeIndex, 1);
    //
    //   ///不可选择 速度
    //   const speedIndex = this.visiblePanels.indexOf(SegType.Speed);
    //   if (speedIndex >= 0) this.visiblePanels.splice(speedIndex, 1);
    // }
  }

  // MARK: - 处理 SegmentButton 变化
  private handleSegmentChange(panelType: SegType, selectedIndex: number): void {
    switch (panelType) {
      case SegType.Mode:
        this.questionMode = selectedIndex;
        this.layoutSubViews();
        this.refreshControlState();
        break;

        case SegType.Scope:
        this.questionScope = [QuestionScope.All, QuestionScope.Still, QuestionScope.Mistake][selectedIndex]
        this.updateQuizManagerSettings()
        this.loadScopeWords()
        this.refreshControlState();
        break;

      case SegType.Count:
        this.questionCount = [SegQuestionCount.Ten, SegQuestionCount.Twenty, SegQuestionCount.Fifty, SegQuestionCount.Hundred][selectedIndex];
        break;

      case SegType.Speed:
        this.questionSpeed = [QuestionSpeed.Slow, QuestionSpeed.Normal, QuestionSpeed.Fast][selectedIndex];
        break;

      case SegType.Order:
        this.questionOrder = selectedIndex;
        break;

      case SegType.Pronounce:

        this.questionPronounce = (selectedIndex === 0);

        if (this.questionPronounce) {

          ///会员检查
          if(!MemberManager.shared.checkAutoPronUsable(true)) {
            setTimeout(()=> {
              this.questionPronounce = false
              this.refreshControlState();
            }, 0.5)
          }

        }
        break;

      case SegType.Type:
        this.questionType = selectedIndex;
        this.refreshControlState();
        break;
    }
  }

  // MARK: - 获取当前选中 index
  private getSelectedIndex(panelType: SegType): number {
    switch (panelType) {
      case SegType.Mode:       return this.questionMode;
      case SegType.Count:      return [SegQuestionCount.Ten, SegQuestionCount.Twenty, SegQuestionCount.Fifty, SegQuestionCount.Hundred].indexOf(this.questionCount);
      case SegType.Speed:      return [QuestionSpeed.Slow, QuestionSpeed.Normal, QuestionSpeed.Fast].indexOf(this.questionSpeed);//this.questionSpeed;
      case SegType.Order:      return this.questionOrder;
      case SegType.Pronounce:  return this.questionPronounce ? 0 : 1;
      case SegType.Type:       return this.questionType;
      case SegType.Scope:      return [QuestionScope.All, QuestionScope.Still, QuestionScope.Mistake].indexOf(this.questionScope);
      default:                 return 0;
    }
  }

  // MARK: - 刷新控件状态
  private refreshControlState(): void {
    const scopeCount  = QuizManager.shared.scopeWords.length;
    this.scopeCount   = scopeCount;

    // 可选题量数组（显式列出枚举值，兼容 ArkTS）
    const validCounts: SegQuestionCount[] = [
      SegQuestionCount.Ten,
      SegQuestionCount.Twenty,
      SegQuestionCount.Fifty,
      SegQuestionCount.Hundred
    ];

    // 根据 scopeCount 自动调整 questionCount
    if (scopeCount < SegQuestionCount.Ten && scopeCount > 0) {
      this.questionCount = scopeCount
    } else if (!validCounts.includes(this.questionCount)) {
      this.questionCount = SegQuestionCount.Ten;
    }

    this.updateSegmentAvailability();
    this.startButtonEnabled = scopeCount > 0;
    this.refreshKey += 1
  }


  // MARK: - 更新 SegmentButton 可用性
  private updateSegmentAvailability(): void {

    if (this.questionCount < 10) {//再テスト(間違うのみ)の時に、前回の数が１０より少ない可能性がある
      QuizManager.shared.questionCount = 10
      this.questionCount = QuizManager.shared.questionCount
    }else if (
      this.questionCount != 10
        && this.questionCount != 20
        && this.questionCount != 50
        && this.questionCount != 100
    ) {//无法正确显示选择时
      QuizManager.shared.questionCount = 10
      this.questionCount = QuizManager.shared.questionCount
    }


    const thresholds: SegQuestionCount[] = [
      SegQuestionCount.Ten,
      SegQuestionCount.Twenty,
      SegQuestionCount.Fifty,
      SegQuestionCount.Hundred
    ];

    // -------------------------------
    // 1️⃣ 更新题量面板按钮是否可用
    // -------------------------------
    const newCountItems: SegmentItem[] = [];
    for (let i = 0; i < this.segmentItemsCount.length; i++) {
      const oldItem = this.segmentItemsCount[i];
      newCountItems.push({ title: oldItem.title, isEnabled: this.scopeCount >= thresholds[i]
      });
    }
    this.segmentItemsCount = [...newCountItems]

    // -------------------------------
    // 2️⃣ 挑战模式下禁用题型和发音按钮
    // -------------------------------
    switch (this.questionMode){
      case QuestionMode.Normal:
        // Normal 模式全部启用
        this.segmentItemsType      = [... this.segmentItemsType.map(item => ({ title: item.title, isEnabled: true } as SegmentItem))]
        this.segmentItemsPronounce = [... this.segmentItemsPronounce.map(item => ({ title: item.title, isEnabled: true } as SegmentItem))]
        break;

      case QuestionMode.Challenge:
        this.questionType          = QuestionType.Eiwa
        this.segmentItemsType      = [... this.segmentItemsType.map(item => ({ title: item.title, isEnabled: false } as SegmentItem))]
        break;

      case QuestionMode.Spell:
        // 拼写模式禁用题型按钮
        this.segmentItemsType      = [... this.segmentItemsType.map(item => ({ title: item.title, isEnabled: false } as SegmentItem))]
        this.questionType          = QuestionType.Waei
        break;
    }

    //出題種類
    switch (this.questionType){
      case QuestionType.Eiwa://英→和
        if (this.questionMode === QuestionMode.Normal) { //这里有问题，暂时也iOS和Android一样，以后同步修改 by ko 2025.12.03
          this.segmentItemsPronounce = [... this.segmentItemsPronounce.map(item => ({ title: item.title, isEnabled: true } as SegmentItem))]
        }
        break;

      case QuestionType.Waei://和→英
        if (this.questionMode === QuestionMode.Spell) {
          this.segmentItemsPronounce = [... this.segmentItemsPronounce.map(item => ({ title: item.title, isEnabled: true } as SegmentItem))]
        }else{
          this.segmentItemsPronounce = [... this.segmentItemsPronounce.map(item => ({ title: item.title, isEnabled: false } as SegmentItem))]
          this.questionPronounce     = false
        }
        break;
    }



  }

  // MARK: - 辅助：获取 Panel 标题
  private getPanelTitle(panelType: SegType): ResourceStr {
    switch (panelType) {
      case SegType.Mode:       return $r('app.string.quiz_start_txt_mode');
      case SegType.Count:      return $r('app.string.quiz_start_txt_count');
      case SegType.Speed:      return $r('app.string.quiz_start_txt_speed');
      case SegType.Order:      return $r('app.string.quiz_start_txt_order');
      case SegType.Pronounce:  return getString($r('app.string.quiz_start_txt_pronounce')) + dMemberFlag;
      case SegType.Type:       return $r('app.string.quiz_start_txt_type');
      case SegType.Scope:      return $r('app.string.test_question_scope_txt');
      default:                 return '';
    }
  }


  // MARK: - 更新 QuizManager 设置
  private updateQuizManagerSettings(): void {
    QuizManager.shared.questionMode       = this.questionMode;
    QuizManager.shared.questionType       = this.questionType;
    QuizManager.shared.questionSpeed      = this.questionSpeed;
    QuizManager.shared.questionOrder      = this.questionOrder;
    QuizManager.shared.questionPronounce  = this.questionPronounce;
    QuizManager.shared.questionCount      = this.questionCount;
    QuizManager.shared.questionScope      = this.questionScope;
  }

  // MARK: - Start 按钮事件
  private actionStart(): void {
    this.updateQuizManagerSettings()
    QuizManager.shared.createNewQuiz();

    if (this.questionMode === QuestionMode.Spell) {
      SpellRunningViewConfig.open()
    }else if(this.questionMode === QuestionMode.Challenge) {
      QuizChallengeViewConfig.open()
    }else{
      QuizRunningViewConfig.open()
    }

  }

}



// MARK: - Panel 类型枚举
enum SegType {
  Mode       = 1,
  Count      = 2,
  Speed      = 3,
  Order      = 4,
  Pronounce  = 5,
  Type       = 6,
  Scope      = 7
}

// MARK: - 可选题量枚举
enum SegQuestionCount {
  Ten        = 10,
  Twenty     = 20,
  Fifty      = 50,
  Hundred    = 100
}
