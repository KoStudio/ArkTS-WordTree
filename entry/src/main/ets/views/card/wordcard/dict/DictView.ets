import { IconButton } from "../../../../app/views/buttons/IconButton"
import { CSoundHelper } from "../../../../common/components/Sounds/Cloud/Manager/CSoundHelper"
import { AudioPlayer } from "../../../../common/components/Sounds/Player/CAudioPlayer"
import { CopyUtils } from "../../../../common/utils/CopyUtils"
import { getString } from "../../../../common/utils/ResourceUtils"
import { Toast } from "../../../../common/utils/Toast"
import { BaseWord } from "../../../../models/datas/basedict/BaseWord"
import { BaseWordDbAccess } from "../../../../models/datas/basedict/BaseWordDbAccess"
import { TitleItem } from "../../../../models/datas/basedict/utils/BaseWordUtility"
import { MemberManager } from "../../../../models/managers/member/MemberManager"


@ComponentV2
export struct DictView {

  @Param title: string = ''

  @Local isShowTip            : boolean         = false
  @Local baseWord             : BaseWord | null = null
  @Local titleItems           : TitleItem[]     = []
  @Local isVoiceButtonVisible : boolean         = true

  aboutToAppear(): void {
    ///无查询时，显示提示
    this.isShowTip = this.title.length ===0

    this.loadData()
  }

  build() {

    Column() {

      if (this.isShowTip){
        this.buildTipPanel()
      }else{
        this.buildUpPanel()

        this.buildMidPanel()

        this.buildDownPanel()
      }

    }
    .width('100%')
    .backgroundColor($r('app.color.color_dict_bg'))
    .alignItems(HorizontalAlign.Start)
  }


  /// 标题行
  @Builder buildUpPanel(){
  Row() {
   Row(){
     // 主标题
     Text(this.title)
       .fontSize(24)
       .minFontScale(0.1)
       .maxLines(1)
       .fontColor($r('app.color.color_dict_title'))

     if (this.isVoiceButtonVisible) {
       IconButton({icon: $r('app.media.btn_voice_1'), iconSize: 28,onClickCallBack: () =>{
         this.actionPlaySound()
       }})
         .margin({ left: 10, right: 5 })


     }
   }

    Blank().layoutWeight(1)

    // 复制按钮
    IconButton({icon: $r('app.media.plus'), iconSize: 22, onClickCallBack: ()=> {
      this.actionCopy()
    }})

  }
  .width('100%')
  .padding({left: 16, right: 16})
  .height(44)
  .border({width: {bottom: 1}, color: $r('app.color.color_line')})
  .justifyContent(FlexAlign.SpaceBetween)
  .alignItems(VerticalAlign.Center)
}

@Builder buildMidPanel(){
  // 音标
  Text(`${this.baseWord?.pronUs || ''}`)
    .fontSize(16)
    .fontColor($r('app.color.color_dict_subtitle'))
    .margin({ left: 25, top: 5, right: 5 })
    .width('100%')
    .textAlign(TextAlign.Start)
}

@Builder buildTipPanel(){
    Column(){

      // Tip
      Text('🔔【提示】')//📍㊙️🅰️🅱️❗️‼️❇️1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣🔴🟩🟦🟪🔔♦️
        .fontSize(24)
        .minFontScale(0.1)
        .maxLines(1)
        .fontColor($r('app.color.colorPrimaryDark'))
        .width('100%')
        .textAlign(TextAlign.Start)


     Column({space: 20}){
       // 1.点击单词，可查看中文注释
       Text(`1.${getString($r('app.string.base_dict_tip_text'))}`)
         .maxFontSize(22)
         .minFontScale(0.1)
         .maxLines(1)
         .fontColor($r('app.color.colorPrimary'))
         .width('100%')
         .textAlign(TextAlign.Start)


       // 2.下拉删除单词
       Text(`2.下拉页面，可以删除/恢复单词`)
         .maxFontSize(22)
         .minFontScale(0.1)
         .maxLines(1)
         .fontColor($r('app.color.colorPrimary'))
         .width('100%')
         .textAlign(TextAlign.Start)
     }
     .width('100%')
     .justifyContent(FlexAlign.Start)
     .margin({left: 10, top: 20})

    }
    .justifyContent(FlexAlign.Start)
    .padding(20)
    .width('100%')
    .height(300)

}


  // 词性释义面板
@Builder buildDownPanel(){
  Column({ space: 5 }) {
    ForEach(this.titleItems, (item: TitleItem, index: number) => {
      Row() {
        // 词性标签
        Text(item.pos)
          .fontSize(14)
          .fontColor($r('app.color.color_dict_pos'))
          .margin({ top: 5, right: 5 })

        // 词义解释
        Text(item.title)
          .fontSize(16)
          .fontColor($r('app.color.color_dict_detail'))
          .margin({ top: 5, right: 5 })
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis }) // 超出显示省略号
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
    })
  }
  .width('100%')
  .margin({ top: 10, bottom: 50 })
}

  // ============================================================
  // 加载信息（建议放后台线程）
  // ============================================================
  private async loadData() {
    if (this.title.length === 0) {
      return
    }

    // 转换为可搜索文本
    const searchText = this.getSearchableStr(this.title).toLowerCase();

    // 查询单词
    this.baseWord = await BaseWordDbAccess.shared.getBaseWordByText(searchText)

    if (this.baseWord !== null && this.baseWord !== undefined) {
      this.titleItems = this.baseWord.getTitleItems()
      
      ///预加载声音
      this.preLoadOneSound(this.baseWord.wordEnSoundText)
    }
  }

  // ============================================================
  // 处理可搜索字符串（去掉单引号后面的部分）
  // 例如：it's → it,  I'm → I,  can't → can
  // ============================================================
  private getSearchableStr(text: string): string {
    let qouteIndex: number = text.indexOf("'");

    if (qouteIndex !== -1) {
      return text.substring(0, qouteIndex);
    }
    return text;
  }

  /**
   * actionCopy: 从标题和副标题获取文本，合并并复制到剪贴板。
   */
  public actionCopy(): void {
    let text = this.title
    if (this.baseWord?.pronUs !== null) {
      text += "\n    " + this.baseWord?.pronUs
    }

    if (this.baseWord?.getTitleCnsJoined() !== null) {
      text += "\n" + this.baseWord?.getTitleCnsJoined();
    }

    //拷贝 到 粘贴板
    CopyUtils.copyText(text)

    // 显示复制成功的提示信息
    Toast.showMessage("内容已复制");

  }

  actionPlaySound(){
    ///会员检查
    if(!MemberManager.shared.checkWordPronUsable(true)){
      return;
    }

    this.playSound(this.baseWord?.wordEnSoundText)
  }

  // 预下载 (或合成) 词语的声音 (词语模式时)
  async preLoadOneSound(text?: string | null) {
    if (!text) {
      return
    }

    ///会员检查
    if(!MemberManager.shared.checkWordPronUsable(false)){
      return;
    }

    if (!(await CSoundHelper.isSoundCacheExists(text))) {

      // 启动（下载或合成）声音
      await CSoundHelper.startDownloadOrGenerateSound(text)
    }
  }


  /// [直接]播放 (汉字 or 词语的) 声音
  async playSound(text?: string | null) {
    if (!text) return;

    ///播放声音
    await AudioPlayer.shared.play(text)

  }
}


