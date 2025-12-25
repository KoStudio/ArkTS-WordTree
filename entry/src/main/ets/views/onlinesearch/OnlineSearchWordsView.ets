import { buildNavTitle } from '../../app/constants/AppBuilders';
import { dNavBackIcon } from '../../app/constants/AppDefines';
import { HighlightText } from '../../app/views/HighlightText';
import { OnlineWord } from '../../models/managers/onlinesearch/OnlineWord';
import { OnlineWordManager } from '../../models/managers/onlinesearch/OnlineWordManager';
import { DetailCardsViewConfig } from '../card/detail/DetailCardsView';
import { SearchManager } from '../../models/datas/model/SearchManager';
import { NavTo } from '../../pages/NavPathManager';
import { WordUser } from '../../models/datas/myData/WordUser';
import { NoDataPanel } from '../../app/views/NoDataView';
import { LoadingDialog } from '@kit.ArkUI';
import { Toast } from '../../common/utils/Toast';
import { MemberManager } from '../../models/managers/member/MemberManager';
import { DailyCountManager, DailyCountType } from '../../models/managers/member/DailyCountManaer';


export namespace OnlineSearchWordsViewConfig {

  ///导航key
  export const NavKey = "OnlineSearchWordsView_show"

  ///打开方式
  export function open(){
    NavTo(NavKey, undefined, true, false)
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
    setTimeout(()=> {
      this.getUIContext().getFocusController().requestFocus("searchText")
    }, 100)

  }


  build() {
    NavDestination(){
      Column(){
        this.SearchPanel()
        if (this.searchResults.length > 0 ){
          this.buildList()
        }else{
          NoDataPanel({message: $r('app.string.online_search_input_tip')})
        }

      }
      .backgroundColor($r('app.color.color_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

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
        .id('searchText')
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
      Column({space: 10}){

        // Text(`${word.titleEn}`)
        //   .fontSize(18)
        //   .fontColor($r('app.color.color_text'))
        HighlightText({
          content: word.titleEn || '',
          keyword: this.searchText,
          normalColor: $r('app.color.color_title'),
          textStyle: {
            fontSize: 18,
            maxLines: 1
          },

        })

        HighlightText({
          content: word.getTitleCnsJoined(),
          keyword: this.searchText,
          normalColor: $r('app.color.color_detail'),
          textStyle: {
            fontSize: 15,
            maxLines: 3
          },

        })
        // Text(word.getTitleCnsJoined())
        //   .fontSize(15)
        //   .fontColor($r('app.color.color_detail'))
        //   .margin({left: 15, top: 5})


      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)



    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding({left: 10, top: 5, bottom: 5})
    .layoutWeight(1)
    .backgroundColor($r('app.color.color_clear'))
    .border({width: {bottom: 1}, style: BorderStyle.Dashed, color: $r('app.color.color_obscure')})
  }



  // 执行搜索
  private async search(val: string): Promise<void> {
    if (!this.searchText.trim()) {
      this.errorMessage = '请输入搜索内容';
      return;
    }

    ///会员检查
    if (!MemberManager.shared.checkOnlineDictUsable()) {
      return
    }
    //记录次数
    DailyCountManager.shared.increase(DailyCountType.onlineDict)

    this.isLoading = true;
    this.errorMessage = '';
    this.searchResults = [];

    try {
      Toast.showCustomDialog(()=> { this.buildLoadingDialog($r('app.string.online_search_loading'))}, false)

      OnlineWordManager.shared.searchWords(this.searchText.trim(), 0, (success: boolean, msg: string | null, words: OnlineWord[] | null) => {
        Toast.closeCustomDialog()
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

  @Builder
  buildLoadingDialog(msg?: ResourceStr | null): void {
    LoadingDialog({
      content: msg ?? 'searching..'
    })
  }

  handleRowClick(rowIndex: number, word: WordUser){

    /////显示在线查询单字
    SearchManager.shared.searchWord(word.titleEn, (wordUser: WordUser | null)=>{
      if (wordUser) {
        DetailCardsViewConfig.open({words: [wordUser], initIndex : 0})
      }
    })
  }
}

