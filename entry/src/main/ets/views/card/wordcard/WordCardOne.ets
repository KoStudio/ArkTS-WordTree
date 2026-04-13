import { IconButton } from '../../../app/views/buttons/IconButton';
import { IconTintButton } from '../../../app/views/buttons/IconTintButton';
import { TintImage } from '../../../app/views/TintImage';
import { WordClickableText } from '../../../app/views/WordClickableText';
import { TEUtility } from '../../../common/utils/TEUtility';
import { getString } from '../../../common/utils/ResourceUtils';
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus';
import { Toast } from '../../../common/utils/Toast';
import { WordUser } from '../../../models/datas/myData/WordUser';
import { WordDetail } from '../../../models/datas/word/WordDetail';
import { BookManagerNotification } from '../../../models/datas/book/BookManager';
import { MemberManager } from '../../../models/managers/member/MemberManager';
import { SettingManager } from '../../../models/managers/setting/SettingManager';
import {
  ShareMemoManager2,
  ShareMemoManager2Notification,
  ShareMemoNotificationPayload
} from '../../../models/managers/sharedata2/ShareMemoManager2';
import { ReclaimWordViewConfig } from '../../reclaimword/ReclaimWordView';
import { ComposeMemoViewConfig } from './memo/ComposeMemoView';


@ComponentV2
export struct WordCardOne {


  @Param @Require word                         : WordUser
  @Param @Require pageInfo                     : string                           = ''
  @Param wordIndexOnPage                       : number                           = 0

  @Event onClickedBtnWordPron: (word: WordUser) => void
  // 例句朗读：参数为例句英文文本（与 DetailCardOne 的 onClickedBtnExamplePron 语义一致）
  @Event onClickedBtnExamplePron: (text: string) => void
  @Event onClickedText: (text: string) => void
  @Event needOpenDetail: (word: WordUser) => void

  @Local settingManager                        : SettingManager                   = SettingManager.shared
  @Local isHideWordTranslation                 : boolean                          = SettingManager.shared.hideTranslation
  @Local isHideExampleTranslation              : boolean                          = SettingManager.shared.hideTranslation

  @Local isRefreshing                          : boolean                          = false
  @Local wordMemos                             : Array<Record<string, string>>    = []
  @Local wordDetail                            : WordDetail | null                = null    // 卡头绑定：释义/音标/例句（getWordDetail 含 EWord）

  private unsubShareMemoPrivate                : (() => void) | undefined         = undefined  // 笔记：私有变更
  private unsubShareMemoPublic                 : (() => void) | undefined         = undefined  // 笔记：公开变更
  private unsubBookUpdated                     : (() => void) | undefined         = undefined  // 课本或 EWord 等更新（与 DetailCardOne 同总线）

  // 进入组件：拉 WordDetail、订阅读笔记与课本更新
  aboutToAppear(): void {

    // 调用：拉取带 EWord 合并的详情供卡头绑定
    void this.loadCardDetail()

    this.reloadWordMemos()

    // 分支：尚未订阅笔记总线则注册（避免重复）
    if (this.unsubShareMemoPrivate === undefined) {

      // 调用：订阅笔记私有变更
      this.unsubShareMemoPrivate = SimpleEventBus.on<ShareMemoNotificationPayload>(
        ShareMemoManager2Notification.Name.PrivateChanged,
        (p?: ShareMemoNotificationPayload) => {
          this.handleShareMemoNotification(p)
        })

      // 调用：订阅笔记公开变更
      this.unsubShareMemoPublic = SimpleEventBus.on<ShareMemoNotificationPayload>(
        ShareMemoManager2Notification.Name.PublicChanged,
        (p?: ShareMemoNotificationPayload) => {
          this.handleShareMemoNotification(p)
        })
    }

    // 分支：尚未订阅课本更新则注册
    if (this.unsubBookUpdated === undefined) {

      // 调用：订阅 currentBookUpdated（EWord 保存后会 emit；invalidateDetail=true 内会 clear 再拉）
      this.unsubBookUpdated = SimpleEventBus.on(BookManagerNotification.currentBookUpdated, () => {
        void this.loadCardDetail(true)
      })
    }
  }

  // 离开组件：取消事件订阅，避免 Swiper 复用时重复回调
  aboutToDisappear(): void {

    // 分支：已订阅笔记私有变更则取消
    if (this.unsubShareMemoPrivate !== undefined) {
      this.unsubShareMemoPrivate()
      this.unsubShareMemoPrivate = undefined
    }

    // 分支：已订阅笔记公开变更则取消
    if (this.unsubShareMemoPublic !== undefined) {
      this.unsubShareMemoPublic()
      this.unsubShareMemoPublic = undefined
    }

    // 分支：已订阅课本更新则取消
    if (this.unsubBookUpdated !== undefined) {
      this.unsubBookUpdated()
      this.unsubBookUpdated = undefined
    }
  }

  // 拉取当前卡展示用 WordDetail（与 iOS CardView / Android CardView 使用 word.getWordDetail() 对齐）
  // invalidateDetail：为 true 时先丢 Word 上详情缓存再查库（课本/EWord 变更或 Swiper 换词）；为 false 时复用缓存
  async loadCardDetail(invalidateDetail: boolean = false): Promise<void> {

    if (invalidateDetail) {
      this.word.clearWordDetailCache()
    }

    // 调用：自 textDb/learnDb 加载并 applyEWordOverrideMap 到 WordDetail
    this.wordDetail = await this.word.getWordDetail() ?? null
  }

  // p：分享笔记事件负载；仅当前词条 titleEn 一致时刷新 memo 列表
  private handleShareMemoNotification(p?: ShareMemoNotificationPayload): void {

    // 分支：无负载则忽略
    if (!p) {
      return
    }

    // 分支：非本卡词条则忽略
    if (p.word.titleEn !== this.word.titleEn) {
      return
    }

    this.reloadWordMemos()
  }

  // 与 iOS / Android QuickLearn CardView 一致：合并自写笔记与收藏的分享笔记
  private reloadWordMemos(): void {

    // 调用：按当前 WordUser 拉合并后的笔记列表
    ShareMemoManager2.shared.loadLocalMemosOfWord(this.word, (localMemos: Array<Record<string, string>>) => {

      this.wordMemos = localMemos
    })
  }


  // 全局「隐藏译文」开关变更时，同步卡内显隐初值
  @Monitor('settingManager.hideTranslation')
  onChangeOfSetting(){
    this.isHideWordTranslation    = SettingManager.shared.hideTranslation
    this.isHideExampleTranslation = SettingManager.shared.hideTranslation
  }

  // @Param word 的 titleEn 变化时重拉 WordDetail（Swiper 子项复用或换词）
  @Monitor('word.titleEn')
  onWordTitleEnChanged(): void {

    // 调用：换词须丢旧详情缓存再拉（与 aboutToAppear 首拉、currentBookUpdated 一致语义）
    void this.loadCardDetail(true)
  }

  build() {
    Column() {
      // 2. 使用 Refresh 包裹你的普通视图
      Refresh({
        refreshing: $$this.isRefreshing, // 绑定刷新状态
        promptText:  this.word.isDeleted() ? '下拉恢复此单词..' :  '下拉删除此单词..'
      }) {

        Scroll() {
          Column() {

            this.buildMain()

            Blank().layoutWeight(1)
          }
          .backgroundColor(this.word.deleted ? '#88888888': Color.Transparent)

        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Auto)
      }
      .refreshOffset(70)
      .onRefreshing(()=>{
        this.actionRemoveWord()
      })
    }
    .width('100%')
    .height('100%')

  }

  @Builder buildMain(){
    Stack() {
      // 主线性布局容器
      Column() {
        Column(){
          // 学习状态和计数区域
          this.buildLearnPageInfoPanel();

          // 单词信息卡片区域
          this.buildWordTitlePanel()

          //例句
          this.buildExpamplePanel()


        }
        .justifyContent(FlexAlign.Start)
        .padding(10)

       Column(){
          //纠错
         this.buildReclaimPanel()

         // 笔记
         this.buildMemoPanel();
       }
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)

      // 已删除标签（默认隐藏，根据状态显示）
      if (this.word.deleted) {
        this.buildDeletedLabel();
      }
    }
    .alignContent(Alignment.Top)
    .width('100%')
  }

  // 构建学习状态和计数布局
  @Builder
  buildLearnPageInfoPanel() {
    Row(){
      // Image(this.word.deleted ?  $r('app.media.btn_learn_disable_1') :  $r('app.media.btn_learn_1'))
      //   .width(69)
      //   .height(26)
      //   .margin({left: 20})

      // Blank().layoutWeight(1)

      Text(this.pageInfo) //页码
        .fontColor(Color.Black)
        .fontSize(14)
        .margin({right: 2})

    }
    .width('100%')
    .padding(0)
    .margin(0)
    .justifyContent(FlexAlign.SpaceBetween)
    .height(26)
  }

  // 构建单词卡片布局
  @Builder
  buildWordTitlePanel() {
    Column({space: 10}) {
      // 单词标题行
      this.buildWordTitleRow();

      // 发音显示行
      this.buildPronunciationRow();

      // 日文翻译行
      this.buildWordTranslationRow();

      // 词性和分类图标行
      //this.buildWordAttributesRow();
    }
    //.width('100%')
    .padding({left: 10, right: 10 , top: 10, bottom: 10})
    //.margin({left: 10, right: 10})
    .backgroundColor(this.word.deleted ? $r('app.color.color_card_bg_disable') : $r('app.color.color_card_bg')) // 单词卡背景色
    .borderRadius(8)
  }

  // 构建单词标题行（英文单词 + 语音按钮）
  @Builder
  buildWordTitleRow() {
    Row(){
      // 英文单词
      Text(this.word.titleEn)
        .fontColor($r('app.color.color_card_title'))
        .maxFontSize(30)
        .minFontSize(0.1)
        .maxLines(1)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Start)
        .layoutWeight(1) // 占据剩余空间
        .onClick(()=>{
          this.needOpenDetail(this.word)
          //DetailCardsViewConfig.open({words: [this.word], initIndex: 0})
        })

      Blank().layoutWeight(1)

      //单词发音 按钮
      IconButton({ icon: $r('app.media.ic_langdu_nroaml'), iconSize: 26, onClickCallBack:()=>{ this.onClickedBtnWordPron(this.word) } })

    }
    .width('100%')
    .margin({ top: 5 })
  }

  @Builder buildExpamplePanel(){
    Column(){
      // 例句标题和语音按钮区域
      this.buildExampleTitlePronPanel();

      // 例句内容区域
      this.buildExampleContentPanel();
    }
    //.width('100%')
    .padding({left: 10, right: 10 , top: 10, bottom: 10})
    .margin({top:20})
    .backgroundColor(this.word.deleted ? $r('app.color.color_card_bg_disable') : $r('app.color.color_card_bg')) // 单词卡背景色
    .borderRadius(8)


  }


  // 构建发音显示行（绑定 WordDetail.pronUs，与 iOS CardView lblPron 对齐）
  @Builder
  buildPronunciationRow() {
    Text(`${this.wordDetail?.pronUs ?? ''}`)
      .width('100%')
      .fontSize(18)
      .fontColor($r('app.color.color_card_detail'))
      .textAlign(TextAlign.Start)
      .margin({ left: 30 })
  }

  // 构建释义行（绑定 WordDetail 上 titleCn1 裁剪与词性）
  @Builder
  buildWordTranslationRow() {
    Stack(){
      // 分支：隐藏译文时显示占位提示
      if (this.isHideWordTranslation){
        Text($r('app.string.wordcard_txt_show_translation'))
          .width('100%')
          .fontSize(18)
          .minFontScale(0.1)
          .fontColor($r('app.color.color_list_item_subtitle'))
          .textAlign(TextAlign.Center)
          .padding(5)
          .margin({ top: 5, bottom: 5})
          .backgroundColor($r('app.color.color_white'))

      // 分支：显示 WordDetail 上释义与词性（详情未到时为空串）
      }else{
        Row(){
          Text(this.wordDetail?.titleCn1Clipped ?? '')
            .layoutWeight(1)
            .fontSize(18)
            .minFontScale(0.1)
            .padding(5)
            .fontColor($r('app.color.color_card_subtitle'))
            .textAlign(TextAlign.Start)
            .margin({ top: 5, bottom: 5})

          Text(this.wordDetail?.titleCn1Kind ?? '')
            .fontSize(18)
            .minFontScale(0.1)
            .padding(5)
            .fontColor($r('app.color.color_text_marked'))
            .textAlign(TextAlign.Start)
            .margin({ top: 5, bottom: 5})
        }
        .width('100%')
      }
    }
    .onClick(()=>{

      // 与 Android / iOS：全局关闭「可隐藏译文」时不响应点击
      if (!SettingManager.shared.hideTranslation) {
        return
      }

      // 分支：非会员不可切换隐藏译文
      if(!MemberManager.shared.checkHideTransUsable(false)) {
        return
      }

      this.isHideWordTranslation = !this.isHideWordTranslation
    })


  }
  //
  // // 构建词性和分类图标行
  // @Builder
  // buildWordAttributesRow() {
  //   Row(){
  //     // 词性图标
  //     Image(this.getWordKindIcon())
  //       .width(19)
  //       .height(16)
  //
  //     // 分类图标
  //     Image(this.getCategoryIcon())
  //       .width(40)
  //       .height(12)
  //       .margin({ left: 10, right: 20 })
  //   }
  //   .width('100%')
  //   .justifyContent(FlexAlign.End)
  //   .margin({ top: 5 })
  // }

  // 构建例句标题和语音按钮区域
  @Builder
  buildExampleTitlePronPanel() {
    Row(){
      // 例句 标题
      Text($r('app.string.wordcard_txt_example'))
        .fontSize(22)
        .fontColor($r('app.color.color_text'))
        .textAlign(TextAlign.Start)

      Blank().layoutWeight(1)

      // 例句朗读：向父层传例句英文（WordDetail 优先，与 DetailCardOne 一致）
      IconButton({ icon: $r('app.media.ic_langdu_nroaml'), iconSize: 26, onClickCallBack:()=>{

        // 访问：例句英文仅来自 WordDetail（列表 Word 无 exampleEn1）
        this.onClickedBtnExamplePron(this.wordDetail?.exampleEn1 ?? '')
      } })
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .margin({ top: 16, bottom: 20 })
  }



  // 构建例句内容区域（英/中文例句仅绑定 WordDetail，与列表层模型一致）
  @Builder
  buildExampleContentPanel() {
    Column({ space: 5 }) {
      // 英文例句（可点查词）
      WordClickableText({
        text            : this.wordDetail?.exampleEn1 ?? '',
        highlightWords  : this.getHilightTexts(),
        onWordClick     : (word: string)=>{
          this.onClickedText(word)
        }
      })

      Stack(){
        // 分支：隐藏例句译文时占位
        if (this.isHideExampleTranslation){
          Text($r('app.string.wordcard_txt_show_translation'))
            .width('100%')
            .fontSize(18)
            .minFontScale(0.1)
            .fontColor($r('app.color.color_list_item_subtitle'))
            .textAlign(TextAlign.Center)
            .padding(5)
            .margin({ top: 5, bottom: 5})
            .backgroundColor($r('app.color.color_white'))

        // 分支：显示 WordDetail 上例句中文译文
        }else{

          // 例句中文译文（仅 WordDetail）
          Text(this.wordDetail?.exampleCn1 ?? '')
            .width('100%')
            .fontSize(20)
            .fontColor($r('app.color.color_card_subtitle'))
            .textAlign(TextAlign.Start)
            .padding(5)
            .margin({ top: 5, bottom: 5})
        }
      }
      .onClick(()=>{

        // 与 Android / iOS：全局关闭「可隐藏译文」时不响应点击
        if (!SettingManager.shared.hideTranslation) {
          return
        }

        // 分支：非会员不可切换例句译文显隐
        if(!MemberManager.shared.checkHideTransUsable(false)) {
          return
        }

        this.isHideExampleTranslation = !this.isHideExampleTranslation
      })


    }
    .width('100%')
    .margin({ top: 5, left: 5, right: 5 })
  }

  //纠错
  @Builder buildReclaimPanel(){
    Row(){
      Blank().layoutWeight(1)

      Button(){
        ///纠错
        Text($r('app.string.learn_detail_btn_reclaim'))
          .fontSize(15)
          .fontColor($r('app.color.color_text2'))

      }
      .backgroundColor(Color.Transparent)
      .onClick(()=> {
        ReclaimWordViewConfig.open({titleEn: this.word.titleEn || ''})
      })
    }
    .padding(20)
    .margin({bottom: 20})
    .width('100%')
  }
  // 构建备忘录标题区域
  @Builder
  buildMemoPanel() {
    Column(){

      if (this.wordMemos.length > 0) {
        // 笔记标题
        Text($r('app.string.wordcard_memo_txt_title')) //笔记
          .fontSize(14)
          .fontColor($r('app.color.color_detail'))
          .textAlign(TextAlign.Start)
          .margin({ top: 25, left: 10 })
      }

      Column(){
        if (this.wordMemos.length > 0) { // 有笔记

          ForEach(this.wordMemos, (memoDict: Record<string, string>, rowIndex: number) => {

            Column({ space: 6 }) {

              Column({ space: 4 }) {
                Text(memoDict[WordUser.KShareMemo_MemoText] ?? '')
                  .fontSize(16)
                  .fontColor($r('app.color.color_list_item_subtitle'))
                  .textAlign(TextAlign.Start)
                  .width('100%')

                Text(this.memoAuthorLineFor(memoDict))
                  .fontSize(12)
                  .fontColor($r('app.color.color_list_item_detail'))
                  .textAlign(TextAlign.Start)
                  .width('100%')
              }
              .width('100%')
              .onClick(() => {
                // 编辑笔记
                ComposeMemoViewConfig.open({ word: this.word, wordIndexOnPage: this.wordIndexOnPage })
              })

              Row(){
                // 删除按钮
                IconTintButton({
                  icon            : $r('app.media.trash'),
                  iconSize        : 26,
                  onClickCallBack : () => {
                    this.actionRemoveMemoAtRow(rowIndex)
                  }
                })
              }
              .padding({ right: 10 })
              .justifyContent(FlexAlign.End)
              .width('100%')
            }
            .width('100%')
            .padding({ top: 8, bottom: 10 })
            .border({
              width : { bottom: rowIndex < this.wordMemos.length - 1 ? 1 : 0 },
              style : BorderStyle.Dashed,
              color : $r('app.color.color_line')
            })
          },
            (memoDict: Record<string, string>, idx: number) =>
              `${idx}_${memoDict[WordUser.KShareMemo_MemoId] ?? ''}`)

        }else{
          ///写笔记
          Row(){
            TintImage({src: $r('app.media.ic_xuebiji'),colorStr: '#ffffffff',iconSize: 30})
              .margin({right: 5})

            Text($r('app.string.wordcard_memo_txt_tip'))///写笔记
              .fontColor($r('app.color.color_white'))
              .fontSize(16)
          }
          .padding(5)
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r('app.color.color_btn_bg2'))
          .borderRadius(5)
          .margin(5)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        }

      }
      .width('100%')
      .padding(10)
      .backgroundColor(this.word.deleted ? Color.Transparent : Color.White)
      .border({ width: { top: 1, bottom: 1, left: 0, right: 0 }, color: $r('app.color.color_line') })
      .onClick(()=>{
        //编辑笔记
        ComposeMemoViewConfig.open({ word: this.word, wordIndexOnPage: this.wordIndexOnPage })
      })


    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)

  }

  // 与 iOS / Android CardView 一致：根据 memoId 显示作者
  private memoAuthorLineFor(memoDict: Record<string, string>): string {

    const base      = getString($r('app.string.memo_author_txt'))
    const memoIdStr = memoDict[WordUser.KShareMemo_MemoId] ?? ''

    if (memoIdStr === ShareMemoManager2.PrivateMemoId) {
      return `${base}: ${getString($r('app.string.memo_author_self'))}`
    }

    return `${base}: ${memoDict[WordUser.KShareMemo_AuthorName] ?? ''}`
  }

  // 与 iOS / Android CardView 一致：支持删除自写笔记和收藏的分享笔记
  private actionRemoveMemoAtRow(rowIndex: number): void {

    const memoDict = this.wordMemos[rowIndex]

    if (!memoDict) {
      return
    }

    const memoIdStr = memoDict[WordUser.KShareMemo_MemoId] ?? ''

    if (memoIdStr === ShareMemoManager2.PrivateMemoId) {

      void ShareMemoManager2.shared.removeLocalSelfMemoFromWord(this.word, (succeed: boolean) => {

        if (succeed) {
          Toast.showMessage($r('app.string.memo_msg_remove_memo_success'))
          ShareMemoManager2.shared.postNotification(false, this.word, this.wordIndexOnPage)
          this.reloadWordMemos()
        }
      })
      return
    }

    let shareIndex = rowIndex

    if (this.word.memo !== null && (this.word.memo?.length ?? 0) > 0) {
      shareIndex = rowIndex - 1
    }

    ShareMemoManager2.shared.removeLocalShareMemoFromWordByIndex(this.word, shareIndex, (succeed: boolean) => {

      if (succeed) {
        Toast.showMessage($r('app.string.memo_msg_remove_memo_success'))
        ShareMemoManager2.shared.postNotification(false, this.word, this.wordIndexOnPage)
        this.reloadWordMemos()
      }
    })
  }

  // 构建已删除标签
  @Builder
  buildDeletedLabel() {
    Row(){
      Text($r('app.string.word_delete_lbl_txt_deleted')) //已删除
        .fontSize(25)
        .fontColor('#FF0000')
        .textAlign(TextAlign.Center)
        .padding(10)
        .borderRadius(15)
        .border({ width: 2, color: '#FF0000' })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')

  }
  actionRemoveWord(){
    //删除或恢复
    this.word.changeDeletedWord(!this.word.isDeleted())
    this.isRefreshing = false
  }

  getHilightTexts(): string [] {
    const word = this.word.titleEn || ''
    return [
      word,
      word + 's',
      word + 'es',
      word + 'ed',
      word + 'd',
      word + 'ing',
    ]
  }

  getCategoryIcon():Resource{
    return TEUtility.getCategoryIcon(this.word.partId)
  }

  getWordKindIcon():Resource {
   // return TEUtility.getWordKindIcon(this.word.wordKind)
    return $r('app.media.icon')
  }
}
