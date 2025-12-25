import { SectionDatas } from "../../../../common/utils/array/SectionDatas"
import { WordUser } from "../../../../models/datas/myData/WordUser"
import json from "@ohos.util.json"
import { WordCardsViewConfig } from "../../../card/wordcard/WordCardsView"
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { TEUtility } from "../../../../common/utils/TEUtility";
import { ListWordRow } from "../../../../app/views/ListWordRow";

@ComponentV2
export struct SubListOneView {


  @Param @Require sectionWords      : SectionDatas<string, WordUser>
  @Param @Require indexers          : string[] = [];

  @Local selectedIndexOfIndexers    : number   = 0; //索引indexers的当前选中的索引

  @Local keyboardHeightPx           : number   = 0
  @Local scroller                   : Scroller = new Scroller();


  aboutToAppear(): void {
    ///可通过setKeyboardAvoidMode接口设置键盘避让模式为KeyboardAvoidMode.RESIZE，表示压缩模式
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET);
    // this.onChangeOfWords()
  }
  aboutToDisappear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
  }


  // @Monitor('sectionWords')
  // onChangeOfWords(){
  //   this.indexers = this.sectionWords.allSections().map(v=>v.charAt(0).toUpperCase())
  // }


  build() {
    Stack(){
      this.buildList()

      if (this.indexers.length > 0){
        // 字母表索引组件
        Row(){
          AlphabetIndexer({
            arrayValue: this.indexers,
            selected: this.selectedIndexOfIndexers
          })
            .onSelect((index: number) => {
              // 点击字母时滚动到对应位置（这里简单映射）
              this.scroller.scrollToIndex(index);
            })
        }
        .hitTestBehavior(HitTestMode.Transparent)
        .justifyContent(FlexAlign.End)
        .width('100%')
      }

    }
  }

  @Builder buildList(){
    Column() {
      List({ space: 0,scroller: this.scroller}) {
        // 内层unit列表
        ForEach(this.sectionWords.allSections(), (section: string, sectionIndex: number) => {
          ListItemGroup({ header: this.buildGroupHeader(section, sectionIndex), style: ListItemGroupStyle.NONE }) {

            ForEach(this.sectionWords.allDatasOfSectionIndex(sectionIndex), (word: WordUser, rowIndex: number) => {
              ListItem() {
                this.buildRowContent(word, rowIndex)
              }
              .onClick(()=>{
                this.handleRowClick(sectionIndex, rowIndex)
              })
              .margin({ bottom: 1 })
            },(word: WordUser, rowIndex: number)=>`${word.titleEn}_${rowIndex}`)

          }
        }, (section: string, sectionIndex: number) => `${section}_${sectionIndex}`)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .sticky(StickyStyle.Header)
      .onScrollIndex((start: number, end: number, center: number) => {
         this.updateSelectedIndexOnScroll(start)
      })

    }
    .padding({ top: 0 })
    .backgroundColor($r('app.color.color_transparent'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Start)
  }
  /**
   * 根据滚动位置更新选中的字母索引
   */
  private updateSelectedIndexOnScroll(index: number): void {
    const sections = this.sectionWords.allSections();

    ///ListGroup整体占一个索引，所以index是ListGroup的索引
    if (index >0 && index < sections.length) {

      let char = sections[index]
      let i = this.indexers.findIndex((ch, index)=> char === ch)

      if (i > 0 && i < this.indexers.length) {
          this.selectedIndexOfIndexers = i
      }
    }

  }


  @Builder
  buildGroupHeader(section: string, index: number) {
    Row() {
      Text(`● ${section}`)
        .margin({ top: 5, bottom: 5, left: 10, right: 10 })
        .fontColor(TEUtility.getSectionTextColor(index))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
      Blank().layoutWeight(1)
    }
    .justifyContent(FlexAlign.Start)
    .width('100%')
    .backgroundColor($r('app.color.color_obscure'))
  }

  @Builder
  buildRowContent(word: WordUser, rowIndex: number) {
    ListWordRow({no: undefined, word: word})

    // Row(){
    //
    //   ///left
    //   Column(){
    //
    //     Text(`${word.titleEn}`)
    //       .fontSize(18)
    //       .fontColor($r('app.color.color_text'))
    //
    //
    //     Text(word.wordJpClippedString)
    //       .fontSize(15)
    //       .fontColor($r('app.color.color_detail'))
    //       .margin({left: 15, top: 5})
    //
    //
    //   }
    //   .justifyContent(FlexAlign.Center)
    //   .alignItems(HorizontalAlign.Start)
    //
    //   //right
    //   Row({space: 10}){
    //     if (word.memo){
    //       //memo icon
    //       //TintImage({src: $r('app.media.learn_icon_memo'), iconSize: 20, colorStr:"#888888"})
    //       Image($r('app.media.learn_icon_memo'))
    //         .width(14)
    //         .height(17)
    //     }
    //
    //     //录音icon
    //     //TintImage({src: $r('app.media.learn_icon_voice')})
    //
    //   }
    //
    // }
    // .justifyContent(FlexAlign.SpaceBetween)
    // .alignItems(VerticalAlign.Center)
    // .width('100%')
    // .padding({left: 10, top: 5, bottom: 5})
    // .layoutWeight(1)
    // .backgroundColor($r('app.color.color_clear'))
    // .border({width: {bottom: 1}, style: BorderStyle.Dashed, color: $r('app.color.color_obscure')})
  }


  handleRowClick(sectionIndex: number, rowIndex: number){

    ///abc,still
    if (this.indexers.length > 0) {
      let words = this.sectionWords.allDatas()
      WordCardsViewConfig.open({words: words, initIndex: this.sectionWords.indexOfAllFromIndex(rowIndex, sectionIndex)})
    }else{
      //cate,fav,mistake
      let words = this.sectionWords.allDatasOfSectionIndex(sectionIndex)
      WordCardsViewConfig.open({words: words, initIndex: rowIndex})
    }
    //   goto card

  }
}

