import { UnitsViewConfig } from "../../units/UnitsView"
import { SearchConstants } from "../../../models/datas/model/SearchManager"

@ComponentV2
export struct SubLearnView {
  build() {
    Stack(){
      this.buildBtns()
    }
  }

  @Builder buildBtns(){
    Column({ space: 10 }) {

      // panel 1
      Column() {

        this.buildBtn($r('app.string.cat_txt_level_1'), ()=>{
          this.actionOpenUnits(SearchConstants.CATEGORY_ID_LEVEL_1)
        })
      }
      .padding({left: 40})
      .justifyContent(FlexAlign.Center)
      .width('100%')

      // panel 2
      Column() {

        this.buildBtn($r('app.string.cat_txt_level_2'), ()=>{
          this.actionOpenUnits(SearchConstants.CATEGORY_ID_LEVEL_2)
        })
      }
      .padding({left: 80})
      .justifyContent(FlexAlign.Center)
      .width('100%')

      // panel 3
      Column() {
        this.buildBtn($r('app.string.cat_txt_level_3'), ()=>{
          this.actionOpenUnits(SearchConstants.CATEGORY_ID_LEVEL_3)
        })
      }
      .padding({right: 50})
      .justifyContent(FlexAlign.Center)
      .width('100%')

      // panel 4
      Column() {
        this.buildBtn($r('app.string.cat_txt_level_all'), ()=>{
          this.actionOpenUnits(SearchConstants.CATEGORY_ID_ALL)
        })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')

    }
    .width('100%')
    .height('86%')
    .justifyContent(FlexAlign.SpaceAround)
  }

  @Builder buildBtn(text: ResourceStr, onClickCallback: () => void){
    Stack(){
      Image($r('app.media.btn_level_1'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .position({ x: 0, y: 0 })

      Text(text)
        .fontSize(16)
        .fontColor($r('app.color.colorPrimary'))
        .width('100%')
        .height('100%')
        .align(Alignment.Center)
        .textAlign(TextAlign.Center)
        .margin(5)
    }
    .width(100)
    .height(100)
    .alignContent(Alignment.Center)
    .onClick((event: ClickEvent) =>{
      onClickCallback()
    })
  }

  actionOpenUnits(cateId: number){
    UnitsViewConfig.open({categoryId: cateId})
  }
}