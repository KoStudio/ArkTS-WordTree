import { buildNavTitle } from '../../app/constants/AppBuilders';
import { dNavBackIcon } from '../../app/constants/AppDefines';
import { AppTextInput } from '../../app/views/AppTextInput';
import { HighlightText } from '../../app/views/HighlightText';
import { WordUser } from '../../models/datas/myData/WordUser';
import { OnlineWord } from '../../models/managers/onlinesearch/OnlineWord';
import { OnlineWordManager } from '../../models/managers/onlinesearch/OnlineWordManager';
import { DetailCardsViewConfig } from '../card/detail/DetailCardsView';
import { SearchModifier } from '@kit.ArkUI';
import { SearchManager } from '../../models/datas/model/SearchManager';
import { NavTo } from '../../pages/NavPathManager';


export namespace OnlineSearchWordsViewConfig {

  ///导航key
  export const NavKey = "OnlineSearchWordsView_show"

  ///打开方式
  export function open(){
    NavTo(NavKey, undefined, true)
  }


}

@ComponentV2
export struct OnlineSearchWordsView {
  

  @Local searchResults: WordUser[] = []; // 搜索结果
  @Local isLoading: boolean = false; // 加载状态
  @Local errorMessage: string = ''; // 错误信息

  @Local isSearching      : boolean                           = false;
  @Local searchText       : string                            = '';
  private focusController                                     = this.getUIContext().getFocusController();
  private searchController: SearchController                  = new SearchController();

  aboutToAppear(): void {
    // 页面显示时的初始化
  }


  build() {
    NavDestination(){
      Stack(){
        this.SearchPanel()
        this.buildList()
      }

    }
    .title(buildNavTitle(this.getNavTitle())) // 设置导航栏标题
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色

  }

  getNavTitle(): ResourceStr {
    return  $r('app.string.online_search_nav_title')

  }

  // MARK: - Search Panel
  @Builder SearchPanel() {
    Row() {
      Search({placeholder: '', value: $$this.searchText, controller: this.searchController})
        .backgroundColor($r('app.color.color_obscure'))
        .layoutWeight(1)
        .enterKeyType(EnterKeyType.Search)
        .enableHapticFeedback(true)
        //.enableKeyboardOnFocus(true)
        //.enablePreviewText(true)
        .onBlur(()=>{
          //this.searchText = ''
          //this.changeSearchState(false)
        })
        .onFocus(()=>{
          // this.changeSearchState(true)
        })
        // .onChange((val)=>{
        //   this.searchText = val
        //   this.search(this.searchText)
        // })
        .onSubmit((value: string) => {
          this.searchText = value
          this.search(this.searchText)
        })
        .onEditChange((data: boolean) => {
        })


      if (this.isSearching){

        Button(){
          Text($r('app.string.search_btn_cancel') )
        }
        //.width(60)
        .padding(5)
        .backgroundColor(Color.Transparent)
        .fontColor($r('app.color.color_link'))
        .onClick(()=>{
          //this.changeSearchState(false)
          this.clearSearch()
        })
      }
    }
    .width('100%')
    // .height(50)
    .backgroundColor($r('app.color.colorPrimary'))
    // .padding(2)
    .padding({top: 2, left: 10, right: 10, bottom: 0})
    .align(Alignment.Bottom)
  }

  @Builder buildList(){
    Column() {
      List({ space: 0}) {
        ForEach(this.searchResults, (word: WordUser, rowIndex: number) => {
          ListItem() {
            this.buildRowContent(word, rowIndex)
          }
          .onClick(()=>{
            this.handleRowClick(rowIndex, word)
          })
          .margin({ bottom: 1 })
        },(word: WordUser, rowIndex: number)=>`${word.titleEn}_${rowIndex}`)

      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)



    }
    .padding({ top: 0 })
    .backgroundColor($r('app.color.color_transparent'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Start)
  }


  @Builder
  buildGroupHeader(section: string, index: number) {
    Row() {

    }
    .justifyContent(FlexAlign.Start)
    .width('100%')
    .backgroundColor($r('app.color.color_obscure'))
  }

  @Builder
  buildRowContent(word: WordUser, rowIndex: number) {
    Row(){

      ///left
      Column(){

        Text(`${word.titleEn}`)
          .fontSize(18)
          .fontColor($r('app.color.color_text'))


        Text(word.wordJpClippedString)
          .fontSize(15)
          .fontColor($r('app.color.color_detail'))
          .margin({left: 15, top: 5})


      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)

      //right
      Row({space: 10}){
        if (word.memo){
          //memo icon
          //TintImage({src: $r('app.media.learn_icon_memo'), iconSize: 20, colorStr:"#888888"})
          Image($r('app.media.learn_icon_memo'))
            .width(14)
            .height(17)
        }

        //录音icon
        //TintImage({src: $r('app.media.learn_icon_voice')})

      }

    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding({left: 10, top: 5, bottom: 5})
    .layoutWeight(1)
    .backgroundColor($r('app.color.color_clear'))
    .border({width: {bottom: 1}, style: BorderStyle.Dashed, color: $r('app.color.color_obscure')})
  }


  handleRowClick(rowIndex: number, word: WordUser){

    /////显示在线查询单字
    SearchManager.shared.searchWord(word.titleEn, (wordUser: WordUser | null)=>{
      if (wordUser) {
        DetailCardsViewConfig.open({words: [wordUser], initIndex : 0})
      }
    })
  }

  // 执行搜索
  private async search(val: string): Promise<void> {
    if (!this.searchText.trim()) {
      this.errorMessage = '请输入搜索内容';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    this.searchResults = [];

    try {
      OnlineWordManager.shared.searchWords(this.searchText.trim(), 0, (success: boolean, msg: string | null, words: OnlineWord[] | null) => {
          this.isLoading = false;
          if (success && words) {
            this.searchResults = words.map(v => v.asWordUser());
            if (words.length === 0) {
              this.errorMessage = '未找到相关单词';
            }
          } else {
            this.errorMessage = msg || '搜索失败，请重试';
          }
        }
      );
    } catch (error) {
      this.isLoading = false;
      this.errorMessage = `搜索出错: ${error}`;
    }
  }

  // 清空搜索
  private clearSearch(): void {
    this.searchText = '';
    this.searchResults = [];
    this.errorMessage = '';
  }

}

