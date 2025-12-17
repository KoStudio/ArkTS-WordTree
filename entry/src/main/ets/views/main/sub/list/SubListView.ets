import { WordUser } from "../../../../models/datas/myData/WordUser";
import { SearchManager } from "../../../../models/datas/model/SearchManager";
import { SectionDatas } from "../../../../common/utils/array/SectionDatas";
import { SubListOneView } from "./SubListOneView";
import { BgImage } from "../../../../app/views/BgImage";

@ComponentV2
export struct SubListView {

  @Param isShowing        : boolean                          = false;
  @Param refreshSearch    : boolean                          = false;

  @Local wordsAbc         : SectionDatas<string, WordUser>   = new SectionDatas();
  @Local wordsCategory    : SectionDatas<string, WordUser>   = new SectionDatas();
  @Local wordsFavorite    : SectionDatas<string, WordUser>   = new SectionDatas();
  @Local wordsWrang       : SectionDatas<string, WordUser>   = new SectionDatas();
  @Local wordsStill       : SectionDatas<string, WordUser>   = new SectionDatas();

  @Local indexersAbc      : string[]                          = [];
  @Local indexersCategory : string[]                          = [];
  @Local indexersFavorite : string[]                          = [];
  @Local indexersWrang    : string[]                          = [];
  @Local indexersStill    : string[]                          = [];

  @Local filtedWords      : WordUser[]                        = [];
  @Local private selectedIndex : number                       = 0; // 当前选中标签页索引

  @Local isSearching      : boolean                           = false;
  @Local searchText       : string                            = '';
  private focusController                                     = this.getUIContext().getFocusController();
  private searchController: SearchController                  = new SearchController();

  get wordsList(): SectionDatas<string, WordUser>[]{
    return [
      this.wordsAbc,
      this.wordsCategory,
      this.wordsFavorite,
      this.wordsWrang,
      this.wordsStill
    ]
  }

  get indexersList(): string[][]{
    return [
      this.indexersAbc,
      this.indexersCategory,
      this.indexersFavorite,
      this.indexersWrang,
      this.indexersStill
    ]
  }


  get tabTitles(): ResourceStr[] {
    return [
      $r('app.string.cat_tab_title_abc'),
      $r('app.string.cat_tab_title_category'),
      $r('app.string.cat_tab_title_favorite'),
      $r('app.string.cat_tab_title_mistake'),
      $r('app.string.cat_tab_title_still'),
    ]
  }


  aboutToAppear(): void {
    this.search()
  }

  @Monitor('isShowing')
  onChangeOfShowing(){
    if (this.isShowing) {
      this.loadData()
    }
  }

  @Monitor('selectedIndex')
  onChangeOfSelectedIndex(){
    this.loadData()
  }

  @Monitor('refreshSearch')
  onChangeOfRefresh(){
    ///返回时也要刷新
    if (this.isShowing && this.selectedIndex > 1) {
      //收藏，常错，未测，有可能变化，需要刷新
      this.loadData()
    }
  }

  build() {
    Stack(){
      //通用 背景
      BgImage()

      Column(){
        this.SearchPanel()
        this.buildTabList()
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .height('100%')

    }

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
          this.changeSearchState(true)
        })
        .onChange((val)=>{
          this.searchText = val
          this.search(this.searchText)
        })
        .onSubmit((value: string) => {
          //this.search(this.searchText)
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
          this.changeSearchState(false)
        })
      }
    }
    .width('100%')
    .height(36)
    .backgroundColor($r('app.color.color_white'))
    .padding(2)
    .margin({top: 10, left: 10, right: 10, bottom: 2})
    .align(Alignment.Bottom)
  }

  // === Tab构建器 ===
  @Builder
  tabBuilder(index: number, title: string | Resource) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor($r('app.color.color_white'))
    }
    .width('100%')
    .height(40)
    .backgroundColor(this.selectedIndex === index? '#F88178' : '#5E9BEC')
    .justifyContent(FlexAlign.SpaceAround);
  }

  @Builder buildTabList(){
    Tabs({ index: this.selectedIndex }) {
      // ForEach(this.wordsList, (words: SectionDatas<string, WordUser>, index: number) => {
      //   TabContent() {
      //     SubListOneView({sectionWords: words, indexers: this.indexersList[index]})
      //   }
      //   .tabBar(this.tabBuilder(index, this.tabTitles[index]))
      //
      // });

      TabContent() { SubListOneView({sectionWords: this.wordsAbc     , indexers: this.indexersAbc})}     .tabBar(this.tabBuilder(0,  $r('app.string.cat_tab_title_abc')))
      TabContent() { SubListOneView({sectionWords: this.wordsCategory, indexers: this.indexersCategory})}.tabBar(this.tabBuilder(1,  $r('app.string.cat_tab_title_category')))
      TabContent() { SubListOneView({sectionWords: this.wordsFavorite, indexers: this.indexersFavorite})}.tabBar(this.tabBuilder(2,  $r('app.string.cat_tab_title_favorite')))
      TabContent() { SubListOneView({sectionWords: this.wordsWrang   , indexers: this.indexersWrang})}   .tabBar(this.tabBuilder(3,  $r('app.string.cat_tab_title_mistake')))
      TabContent() { SubListOneView({sectionWords: this.wordsStill   , indexers: this.indexersStill})}   .tabBar(this.tabBuilder(4,  $r('app.string.cat_tab_title_still')))
    }
    .layoutWeight(1)
    .onChange((index: number) => {
      this.selectedIndex = index;
    });
  }

  loadData(){
    this.loadSubData(this.selectedIndex)
  }

  loadSubData(index: number){
    switch (index){
      case 0: this.wordsAbc         = SearchManager.shared.queryForCharGroup(this.filtedWords, false); this.indexersAbc      = this.wordsAbc.allSections().map(v => v.charAt(0).toLowerCase());  break;
      case 1: this.wordsCategory    = SearchManager.shared.queryForCategory(this.filtedWords);         this.indexersCategory = [];                                                               break;
      case 2: this.wordsFavorite    = SearchManager.shared.queryForFavorite(this.filtedWords);         this.indexersFavorite = [];                                                               break;
      case 3: this.wordsWrang       = SearchManager.shared.queryForWrangTimes(this.filtedWords);       this.indexersWrang    = [];                                                               break;
      case 4: this.wordsStill       = SearchManager.shared.queryForCharGroup(this.filtedWords, true);  this.indexersStill    = this.wordsStill.allSections().map(v => v.charAt(0).toLowerCase()); break;
    }

  }

  changeSearchState(toSearch: boolean){
    this.isSearching = toSearch

    if (toSearch) {
      //do nothing
    }else{

      this.searchController.clearPreviewText()
      this.focusController.clearFocus()
      this.searchText = ''
    }
  }

  async search(text: string | null = null) {
    this.filtedWords           = SearchManager.shared.querySearch(this.searchText)
    this.loadData()
  }

}