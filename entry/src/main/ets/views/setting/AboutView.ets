import { buildNavTitle } from '../../app/constants/AppBuilders';
import { dNavBackIcon } from '../../app/constants/AppDefines';
import { AppSettings } from '../../app/constants/AppSettings';
import { LinkViewConfig } from '../../app/views/LinkView';
import { NavTo } from '../../pages/NavPathManager';
import { ReclaimViewConfig } from './ReclaimView';


export namespace AboutViewConfig {

  ///导航key
  export const NavKey = "AboutView_show"

  ///打开方式
  export function open(){
    NavTo(NavKey, undefined, true)
  }

}


@ComponentV2
export struct AboutView {


  build() {
    NavDestination(){
      Stack(){

        this.buildList()
      }
      .backgroundColor($r('app.color.color_obscure'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .title(buildNavTitle($r('app.string.about_nav_title')))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary'))
  }

  @Builder buildList(){
    List({space: 20}) {
      ListItemGroup({space: 16, style: ListItemGroupStyle.NONE}){

        ///隐私政策
        ListItem() {
          Row(){
            Text($r('app.string.about_btn_privacy'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .padding({left: 20, top: 10, bottom: 10, right: 10})
        .onClick((event:ClickEvent) => {
          ///隐私政策
          LinkViewConfig.open({title: $r('app.string.about_btn_privacy'), url: AppSettings.Address.privacy})

        })
        ///儿童隐私政策
        ListItem() {
          Row(){
            Text($r('app.string.about_btn_privacy_kid'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .padding({left: 20, top: 10, bottom: 10, right: 10})
        .onClick((event:ClickEvent) => {
          ///儿童隐私政策
          LinkViewConfig.open({title: $r('app.string.about_btn_privacy_kid'), url: AppSettings.Address.privacy_kid})

        })

        ///服务协议
        ListItem() {
          Row(){
            Text($r('app.string.about_btn_term'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .padding({left: 20, top: 10, bottom: 10, right: 10})
        .onClick((event:ClickEvent) => {
          ///服务协议
          LinkViewConfig.open({title: $r('app.string.about_btn_term'), url: AppSettings.Address.terms})
        })

        ///联系客服
        ListItem() {
          Row(){
            Text($r('app.string.about_btn_contact'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .padding({left: 20, top: 10, bottom: 10, right: 10})
        .onClick((event:ClickEvent) => {
          ///联系客服
          LinkViewConfig.open({title: $r('app.string.about_btn_contact'), url: AppSettings.Address.contact})

        })

        ///投诉
        ListItem() {
          Row(){
            Text($r('app.string.about_btn_reclaim'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .padding({left: 20, top: 10, bottom: 10, right: 10})
        .onClick((event:ClickEvent) => {
          ///投诉
          ReclaimViewConfig.open()

        })

      }
      .backgroundColor(Color.White)
      .itemDivider()


      ListItemGroup({space: 16, style: ListItemGroupStyle.NONE}) {

        //ICP备案号
        ListItem() {
          Row() {
            Text('ICP备案号')
            Blank()
            Text(AppSettings.ICP.code)
              .fontColor(Color.Gray)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .padding({left: 20, top: 10, bottom: 10, right: 10})
        .onClick((event: ClickEvent) => {
          //ICP备案号
          LinkViewConfig.open({ title: AppSettings.ICP.title, url: AppSettings.ICP.addr }, true)//在浏览器中打开

        })
      }
      .backgroundColor(Color.White)
      .itemDivider()

    }
    .backgroundColor($r('app.color.color_obscure'))
    .width('100%')
    .height('100%')
  }

}
///列表分隔线
@Extend(ListItemGroup) function itemDivider(){
  .divider({strokeWidth: 1, startMargin: 10, endMargin: 10, color: '#338aa5b2' })
}

