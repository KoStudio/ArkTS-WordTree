import { IconButton } from '../../../app/views/buttons/IconButton';
import { IconTintButton } from '../../../app/views/buttons/IconTintButton';
import { ColorPickerButton } from '../../../app/views/picker/colorpicer/ColorPickerButton';
import { TintImage } from '../../../app/views/TintImage';
import { WordClickableText } from '../../../app/views/WordClickableText';
import { TEUtility } from '../../../common/utils/TEUtility';
import { Toast } from '../../../common/utils/Toast';
import { SearchConstants, SearchManager } from '../../../models/datas/model/SearchManager';
import { WordUser } from '../../../models/datas/myData/WordUser';
import { MemberManager } from '../../../models/managers/member/MemberManager';
import { SettingManager } from '../../../models/managers/setting/SettingManager';
import { DetailCardsViewConfig } from '../detail/DetailCardsView';
import { ComposeMemoViewConfig } from './memo/ComposeMemoView';


@ComponentV2
export struct WordCardOne {


  @Param @Require word: WordUser
  @Param @Require pageInfo: string = ''

  @Event onClickedBtnWordPron: (word: WordUser) => void
  @Event onClickedBtnExamplePron: (word: WordUser) => void
  @Event onClickedText: (text: string) => void
  @Event needOpenDetail: (word: WordUser) => void

  @Local settingManager: SettingManager    = SettingManager.shared
  @Local isHideWordTranslation: boolean    = SettingManager.shared.hideTranslation
  @Local isHideExampleTranslation: boolean = SettingManager.shared.hideTranslation

  @Local isRefreshing: boolean = false


  @Monitor('settingManager.hideTranslation')
  onChangeOfSetting(){
    this.isHideWordTranslation    = SettingManager.shared.hideTranslation
    this.isHideExampleTranslation = SettingManager.shared.hideTranslation
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


  // 构建发音显示行
  @Builder
  buildPronunciationRow() {
    Text(`${this.word.pronEn}`)
      .width('100%')
      .fontSize(18)
      .fontColor($r('app.color.color_card_detail'))
      .textAlign(TextAlign.Start)
      .margin({ left: 30 })
  }

  // 构建日文翻译行
  @Builder
  buildWordTranslationRow() {
    Stack(){
      if (this.isHideWordTranslation){
        Text($r('app.string.wordcard_txt_show_translation'))
          .width('100%')
          .fontSize(18)
          .minFontScale(0.1)
          .fontColor('#ac8b56')
          .textAlign(TextAlign.Center)
          .padding(5)
          .margin({ top: 5, bottom: 5})
          .backgroundColor(Color.White)

      }else{
        Row(){
          Text(this.word.titleCn1Clipped)
            .layoutWeight(1)
            .fontSize(18)
            .minFontScale(0.1)
            .padding(5)
            .fontColor($r('app.color.color_card_subtitle'))
            .textAlign(TextAlign.Start)
            .margin({ top: 5, bottom: 5})

          Text(this.word.titleCn1Kind)
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
      ///会员检查
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

        // 例句语音按钮
        IconButton({ icon: $r('app.media.ic_langdu_nroaml'), iconSize: 26, onClickCallBack:()=>{ this.onClickedBtnExamplePron(this.word) } })
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .margin({ top: 16, bottom: 20 })
  }



  // 构建例句内容区域
  @Builder
  buildExampleContentPanel() {
    Column({ space: 5 }) {
      // 英文例句
      WordClickableText({
        text:this.word.exampleEn1 || '',
        highlightWords: this.getHilightTexts(),
        onWordClick:(word: string)=>{
          this.onClickedText(word)
        }
      })

      Stack(){
        if (this.isHideExampleTranslation){
          Text($r('app.string.wordcard_txt_show_translation'))
            .width('100%')
            .fontSize(18)
            .minFontScale(0.1)
            .fontColor('#555555')
            .textAlign(TextAlign.Center)
            .padding(5)
            .margin({ top: 5, bottom: 5})
            .backgroundColor(Color.White)

        }else{

          // 日文例句
          Text(this.word.exampleCn1)
            .width('100%')
            .fontSize(20)
            .fontColor($r('app.color.color_card_subtitle'))
            .textAlign(TextAlign.Start)
            .padding(5)
            .margin({ top: 5, bottom: 5})
        }
      }
      .onClick(()=>{
        ///会员检查
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
    }
    .padding(20)
    .margin({bottom: 20})
    .width('100%')
  }
  // 构建备忘录标题区域
  @Builder
  buildMemoPanel() {
    Column(){

      if (this.word.memo){
        //笔记 标题
        Text($r('app.string.wordcard_memo_txt_title')) //笔记
          .fontSize(14)
          .fontColor($r('app.color.color_detail'))
          .textAlign(TextAlign.Start)
          .margin({ top: 25, left:10 })
      }

      //笔记内容
      Column(){
        if (this.word.memo){ //有笔记

          Column(){
            Text(this.word.memo)
              .fontSize(16)
              .fontColor($r('app.color.color_list_item_subtitle'))
              .textAlign(TextAlign.Start)

            Row(){
              // 删除按钮
              IconTintButton({ icon: $r('app.media.trash'), iconSize: 26, onClickCallBack:()=>{ this.actionRemoveMemo() } })
            }
            .padding({right: 10})
            .justifyContent(FlexAlign.End)
            .width('100%')
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)

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
      .border({width: {top: 1, bottom: 1, left: 0, right: 0}, color: $r('app.color.color_line')})
      .onClick(()=>{
        //编辑笔记
        ComposeMemoViewConfig.open({word: this.word})
      })


    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)

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

  actionRemoveMemo(){
    //删除笔记
    SearchManager.shared.saveLocalMemoForWord(this.word, '');
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