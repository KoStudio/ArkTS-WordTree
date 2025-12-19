import { buildNavTitle } from "../../../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../../../app/constants/AppDefines"
import { BgCardImage } from "../../../../app/views/BgCardImage"
import { TextStyleButton, TextStyleButtonStyle } from "../../../../app/views/buttons/TextStyleButton"
import { WordUser } from "../../../../models/datas/myData/WordUser"
import { NavPop, NavTo } from "../../../../pages/NavPathManager"
import { SearchModifier } from "@kit.ArkUI"
import { SearchManager } from "../../../../models/datas/model/SearchManager"
import { buildStandardMenu } from "../../../../app/constants/AppFunctions"
import { FocusController } from "@ohos.arkui.UIContext"

export namespace ComposeMemoViewConfig {

  ///导航key
  export const NavKey = "ComposeMemoView_show"

  ///打开方式
  export function open(param: Param){
    NavTo(ComposeMemoViewConfig.NavKey, param, true)
  }

  export interface Param {
    word     : WordUser

  }

}

@ComponentV2
export struct ComposeMemoView {

  @Param @Require word     : WordUser

  @Local content: string = '';              // 用户输入内容
  @Local isSendButtonEnabled: boolean = false; // 发送按钮状态
  @Local characterCount: number = 0;       // 字符计数

  // === 常量 ===
  private readonly MAX_COUNT: number = 500; // 最大字符数
  private readonly MIN_COUNT: number = 1;   // 最小字符数

  @Local textAreaController: FocusController = new FocusController();

  aboutToAppear(): void {
    this.content = this.word.memo ?? ''
  }


  build() {

    NavDestination() {
      Stack() {
        //背景
        BgCardImage()

        Column({ space: 16 }) {
          // 文本编辑区域
          this.buildTextEditor();

          ///保存按钮
          TextStyleButton({
            style: TextStyleButtonStyle.ACCENT,
            text: $r('app.string.memo_compose_btn_save'), onClickCallBack: () => {
              this.actionSave()
            },
            isEnabled: this.isSendButtonEnabled,
          })
            .height(50)
            .margin({ top: 20 })


          Blank()
        }
        .padding(16)
        .width('100%')
        .height('100%')
        .onAppear(() => this.refreshUIState()) // 视图显示时初始化
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .title(buildNavTitle(this.getNavTitle()))
    .menus(buildStandardMenu(this.buildMenuItems()))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary')) // 背景色

  }

  getNavTitle(): ResourceStr | null | undefined {
    return this.word.titleEn
  }

  // === 导航菜单 ===
  buildMenuItems(): NavigationMenuItem[] {
    return [
      {
        value : "edit",
        icon  : $r('app.media.edit'),
        action: () => {
          // 编辑，显示 键盘
          this.actionEdit();
        }
      },
    ];
  }

  /// 构建文本编辑区域
  @Builder buildTextEditor() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 文本输入框
      TextArea({ text: this.content })
        .height(180)
        .width('100%')
        .id('txtContent')
        .backgroundColor('#ffe9ba')
        .borderRadius(5)
        .border({ width: 1, color: '#ffe9ba' })
        .onChange((value: string) => {
          this.content = value;
          this.refreshUIState();
        });

      // 字符计数器
      Text(`${this.characterCount}/${this.MAX_COUNT}`)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ right: 10, bottom: 5 });
    }
  }
  actionEdit(){
    this.getUIContext().getFocusController().requestFocus("txtContent")
  }



  /** 刷新UI状态 */
  private refreshUIState() {
    const trimmedContent     = this.content.trim();
    this.characterCount      = trimmedContent.length;
    this.isSendButtonEnabled = this.characterCount > this.MIN_COUNT && this.characterCount <= this.MAX_COUNT;
  }



  /** 发送反馈 */
  private async actionSave() {

    await SearchManager.shared.saveLocalMemoForWord(this.word, this.content)

    //返回
    NavPop()
  }

}