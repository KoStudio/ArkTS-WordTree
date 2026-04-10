import { buildNavTitle } from "../../../app/constants/AppBuilders";
import { dAppVersion, dNavBackIcon, isDebugMode } from "../../../app/constants/AppDefines";
import { buildStandardMenu } from "../../../app/constants/AppFunctions";
import { IconButton } from "../../../app/views/buttons/IconButton";
import { TintImage } from "../../../app/views/TintImage";
import AlarmManager from "../../../common/components/Alarm/AlarmManager";
import { DateUtils } from "../../../common/utils/DateUtils";
import { ReviewUtils } from "../../../common/utils/ReviewUtils";
import { ItemOption, Toast } from "../../../common/utils/Toast";
import { SettingManager } from "../../../models/managers/setting/SettingManager";
import { UserManager } from "../../../models/managers/user/UserManager";
import { NavTo } from "../../../pages/NavPathManager";
import { LogOffViewConfig } from "../../login/LogOffView";
import { LoadingDialog } from "@kit.ArkUI";
import { LoginView } from "../../login/LoginView";
import { AdviceViewConfig } from "../../setting/AdviceView";
import { AboutViewConfig } from "../../setting/AboutView";
import { SearchManager } from "../../../models/datas/model/SearchManager";
import { SpeechRecordManager } from "../../../common/components/Speech/Recorder/SpeechRecordManager";
import { DeletedWordsViewConfig } from "../../setting/DeletedWordsView";
import { LanguageManager } from "../../../common/components/Language/LanguageManager";
import { getAppContext } from "../../../app/constants/AppContext";
import { AppLanguage } from "../../../common/components/Language/AppLanguage";
import { SubscribeManagerNotification } from "../../../common/iab/SubscribeManager";
import { SimpleEventBus } from "../../../common/components/eventbus/SimpleEventBus";
import { HwSubscriber } from "../../../common/iab/huawei/HwSubscriber";
import { SubscriptionInfoManager } from "../../../models/managers/subscription/SubscriptionInfoManager";
import { MemberManager } from "../../../models/managers/member/MemberManager";
import { getString, getStringF } from "../../../common/utils/ResourceUtils";
import { MemberView } from "../../setting/member/MemberView";
import { DiskStatus } from "../../../app/constants/DiskStatus";
import { CBookManager } from "../../../common/components/Sounds/Cloud/Download/CBook/CBookManager";
import { CSoundManager } from "../../../common/components/Sounds/Cloud/Manager/CSoundManager";
import { AudioTool } from "../../../common/components/Sounds/Player/AudioTool";
import { FileSizeUtils } from "../../../common/utils/FileSizeUtils";
import { UserData, UserDataJson } from "../../../models/managers/userdata/UserData";
import { UserDataManager } from "../../../models/managers/userdata/UserDataManager";
import { WordUserDbAccess } from "../../../models/datas/myData/WordUserDbAccess";
import { PlanManager } from "../../../models/managers/plan/plancurve/PlanManager";
import { CosDownloader } from "../../../common/components/Sounds/Cloud/Download/Downloader/CosDownloader";
import { MyMemosViewConfig } from "../../setting/mine/MyMemosView";
import { MyRecordsViewConfig } from "../../setting/mine/MyRecordsView";
import { BookManager, BookManagerNotification } from "../../../models/datas/book/BookManager";
import { PlanDbAccess } from "../../../models/managers/plan/plandb/PlanDbAccess";
import { SpeechRecordDbAccessor } from "../../../common/components/Speech/Recorder/SpeechRecordDbAccessor";
import { NetWorkTool } from "../../../common/utils/NetworkUtils";
import { GoldManager } from "../../../models/managers/gold/GoldManager";
import { MarqueeManager } from "../../../models/managers/marquee/MarqueeManager";
import { AppCfg } from "../../../models/managers/servercfg/AppCfgManager";

export namespace SetViewConfig {

  ///导航key
  export const NavKey = "SetView_show"

  ///打开方式
  export function open(){
    NavTo(SetViewConfig.NavKey, undefined, true)
  }

}

@ComponentV2
export struct SetView {

  @Local isReminderOn:     boolean     = AlarmManager.shared.isReminderEnabled()
  @Local selectedTime:     Date        = AlarmManager.shared.getSavedAlarmTime()

  @Local isShowLoginView:  boolean     = false
  @Local isShowMemberView: boolean     = false

  @Local   userManager                  : UserManager                     = UserManager.shared
  @Local   isLogin                      : boolean                         = UserManager.shared.isLogin()
  @Local   userData                     : UserData                        = new UserData()


  @Local subTitleForBackup?: ResourceStr
  @Local subTitleForRestore?: ResourceStr

  @Local   memberTitle                   : ResourceStr                     = $r('app.string.set_cell_txt_to_member')
  @Local   memberExpiryDate?            : string
  @Local   memberExpiryDateColor        : ResourceColor                   = $r('app.color.color_detail')
  @Local   memberIcon                   : Resource                        = $r('app.media.sdiamond')
  @Local   memberIconColor?             : string
  @Local   goldCountText                : string                          = '0'
  @Local   gainGoldPolicyText?          : string
  @Local   shareEncourageText?          : ResourceStr


  async aboutToAppear() {

    //获取 保存的提醒时间
    this.isReminderOn =  AlarmManager.shared.isReminderEnabled()
    this.selectedTime =  AlarmManager.shared.getSavedAlarmTime()

    // 加载用户备份数据
    this.loadUserData()

    //显示会员
    this.onChangeOfShowing()

    ///监听会员时间改变通知
    SimpleEventBus.on(SubscribeManagerNotification.expireDateUpdated, () => {
      this.showMemberInfo()
    })

  }


  aboutToDisappear(): void {
    ///移除 监听会员时间改变通知
    SimpleEventBus.off(SubscribeManagerNotification.expireDateUpdated)
  }

  onChangeOfShowing(){
    ///自动 恢复已经有的订阅(重新安装应用后)
    HwSubscriber.shared.restore()

    ///判断时间间隔，自动刷新订阅时间 6小时， Android版和iOS没有这个功能
    SubscriptionInfoManager.shared.autoRefreshSubscriptionInfoIfNeeds()

    ///显示会员信息
    this.showMemberInfo()

    // 显示金币信息与分享奖励说明。
    this.showGoldInfo()

    // 显示分享应用奖励说明。
    this.showShareEncourageInfo()
  }

  @Monitor('userManager.userId')
  onChangeOfLogin(){
    this.isLogin = UserManager.shared.isLogin()
    this.loadUserData()

    // 登录态变化后，同步刷新金币与分享说明。
    this.showGoldInfo()
    this.showShareEncourageInfo()
  }

  build() {

    NavDestination(){
      Column(){
        this.buildList()
      }
      .bindSheet($$this.isShowLoginView, this.buildLoginView(), { //登录
        detents: [SheetSize.LARGE],
        preferType: SheetType.CENTER,
        // title: {title: ''} ,
        backgroundColor: $r('app.color.colorPrimary'),
        showClose: false,
        onDisappear: () => {
          this.isShowLoginView = false
        }

      })
      .backgroundColor($r('app.color.color_obscure'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .title(buildNavTitle($r('app.string.set_nav_title')))
    .menus(buildStandardMenu(this.buildMenuItems()))
    .backButtonIcon(dNavBackIcon) //返回按钮
    .backgroundColor($r('app.color.colorPrimary'))

  }

  buildMenuItems(): NavigationMenuItem[] {
    return [
      {value: this.isLogin ? "退出登录" : "登录" , icon: undefined, action: () => {
          if (this.isLogin) {
            //退出登录
            this.confirmLogout()
          }else{
            //显示登录
            this.isShowLoginView = true
          }

        }
      }
    ]
  }

  @Builder buildList(){

    List({space: 20}) {

      // 用户头像区
      ListItemGroup({space: 0, style: ListItemGroupStyle.NONE}){
        // 卡片翻转设置
        ListItem({style: ListItemStyle.CARD}) {

          this.buildHeaderRow()

        }
        .height(80)
        .backgroundColor(Color.Transparent)

      }
      .bindSheet($$this.isShowMemberView, this.buildMemberView(), {
        detents: [SheetSize.FIT_CONTENT],
        preferType: SheetType.CENTER,
        showClose: false
      })

      /// 功能列表区
      ListItemGroup({space: 0, style: ListItemGroupStyle.NONE}){
        // 会员功能
        this.buildListItem({icon: this.memberIcon, iconColor: this.memberIconColor, title: this.memberTitle, textDown: this.memberExpiryDate, textDownColor: this.memberExpiryDateColor, onClicked: ()=>{
          this.isShowMemberView = true
        }})

      }
      .divider({strokeWidth: 1})

      ///删除操作组
      ListItemGroup({space: 0, style: ListItemGroupStyle.NONE}){
        // 学习履历删除
        this.buildListItem({icon: $r('app.media.set_icon_del_learn'), title: $r('app.string.setting_txt_learn'), onClicked: ()=>{
          this.confirmDeleteLearnTimes()
        }})

        // 测试结果删除
        this.buildListItem({icon: $r('app.media.set_icon_del_test'), title: $r('app.string.setting_txt_test'), onClicked: ()=>{
          this.confirmDeleteTestResult()
        }})

        // 复习列表清空
        this.buildListItem({icon: $r('app.media.set_icon_del_review'), title: $r('app.string.setting_txt_review'), onClicked: ()=>{
          this.confirmDeleteReviewList()
        }})

        // 录音清空
        this.buildListItem({icon: $r('app.media.set_icon_del_record'), title: $r('app.string.setting_txt_record'), onClicked: ()=>{
          this.confirmDeleteRecords()
        }})

        // 笔记删除
        this.buildListItem({icon: $r('app.media.set_icon_del_memo'), title: $r('app.string.setting_txt_memo'), onClicked: ()=>{
          this.confirmDeleteMemos()
        }})

        // 收藏夹清空
        this.buildListItem({icon: $r('app.media.set_icon_del_favorite'), title: $r('app.string.setting_txt_favorite'), onClicked: ()=>{
          this.confirmDeleteFavorites()
        }})

        // 恢复已经删除单词
        this.buildListItem({icon: $r('app.media.set_icon_del_deletedwords'), title: $r('app.string.set_txt_deleteword'), onClicked: ()=>{
          this.confirmDeletedWords()
        }})



      }
      .divider({strokeWidth: 1})


      ListItemGroup({space: 0, style: ListItemGroupStyle.NONE}){
        // 立即更新
        this.buildListItem({icon: $r('app.media.set_icon_do_download'), title: $r('app.string.set_more_txt_update_now'), onClicked: ()=>{
           this.actionDoUpdateBooks()
        }})

        // Wifi下自动更新
        this.buildListItem({icon: $r('app.media.set_icon_wifi_update'), title: $r('app.string.set_more_txt_update_auto'), builderType: CustomBuilderType.wifiAutoUpdateSwitch})


      }
      .divider({strokeWidth: 1})


      ListItemGroup({space: 0, style: ListItemGroupStyle.NONE}){
        // 我的笔记
        this.buildListItem({icon: $r('app.media.set_icon_del_review'), title: $r('app.string.set_more_txt_mine_memo'), onClicked: ()=>{
          MyMemosViewConfig.open()
        }})

        // 我的录音
        this.buildListItem({icon: $r('app.media.set_icon_record'), title: $r('app.string.set_more_txt_mine_record'), onClicked: ()=>{
          MyRecordsViewConfig.open()
        }})

        // 我的删除的单词
        this.buildListItem({icon: $r('app.media.set_icon_deleted'), title: $r('app.string.set_txt_word_deleted'), onClicked: ()=>{
          DeletedWordsViewConfig.open()
        }})

      }
      .divider({strokeWidth: 1})

      ///用户数据Group
      ListItemGroup({space: 0, style: ListItemGroupStyle.NONE}) {

        ///备份数据
        this.buildListItem({
          icon: $r('app.media.upload_line'), isSvg: true, title: $r('app.string.set_cell_txt_data_backup'),textDown: this.subTitleForBackup, onClicked: () => {
            /// 备份
            this.confirmBackupUserData()
          }
        })

        ///恢复数据
        this.buildListItem({
          icon: $r('app.media.download_line'), isSvg: true, title: $r('app.string.set_cell_txt_data_restore'), textDown: this.subTitleForRestore, onClicked: () => {
            /// 恢复
            this.confirmRestoreUserData()
          }
        })

      }
      .divider({strokeWidth: 1})


      ListItemGroup({space: 0, style: ListItemGroupStyle.NONE}){

        // 切换语言
        this.buildListItem({icon: $r('app.media.set_icon_del_test'), title: $r('app.string.change_language_title'), onClicked: ()=>{

          /// 切换 语言
          this.actionShowLanguages()
        }})


        // 效果音
        this.buildListItem({icon: $r('app.media.set_icon_del_set'), title: $r('app.string.setting_txt_soundeffect'), builderType: CustomBuilderType.seSwitch})

        // 启用记忆曲线
        this.buildListItem({icon: $r('app.media.flashem'), title: $r('app.string.set_txt_curve'), builderType: CustomBuilderType.curveSwitch})

        // 清空缓存
        this.buildListItem({icon: $r('app.media.document_remove'), title: $r('app.string.set_txt_cache'), onClicked: ()=>{

          /// 切换 语言
          this.confirmClearCache()
        }})

      }
      .divider({strokeWidth: 1})


      ListItemGroup({space: 0, style: ListItemGroupStyle.NONE}){


        ///设置提醒
        this.buildListItem({ icon: $r('app.media.bell'), isSvg: true, title: $r('app.string.set_cell_txt_remind_switch'), builderType: CustomBuilderType.remindSwitch })

        /// 提醒时间选择
        this.buildListItem({
          icon: $r('app.media.clock'), isSvg: true, title: $r('app.string.set_cell_txt_remind_time'), textRight: this.getSelectedTimeString(),onClicked: () => {
            /// 打开
            this.showTimePicker()
          }
        })

      }
      .divider({strokeWidth: 1})


      /// 关于组
      ListItemGroup({space: 0, style: ListItemGroupStyle.NONE}){


        ///意见反馈
        this.buildListItem({icon: $r('app.media.bubble_text'), isSvg: true, title: $r('app.string.set_cell_txt_advice'), onClicked: ()=>{
          /// 打开
          AdviceViewConfig.open()
        }})

        // 撰写评论
        this.buildListItem({icon: $r('app.media.set_icon_del_review'), title: $r('app.string.setting_txt_write_review'), onClicked: ()=>{
          /// 打开
          ReviewUtils.reviewThisApp()
        }})


        /// 分享应用的 Cell
        this.buildListItem({icon: $r('app.media.share'), isSvg: true, title: $r('app.string.set_cell_txt_share'), textDown: this.shareEncourageText, onClicked: ()=>{
          /// 打开
          this.shareApp()
        }})

        // 关于
        this.buildListItem({icon: $r('app.media.info'), isSvg: true, title: $r('app.string.set_cell_txt_about'), textDown: $r('app.string.set_cell_txt_version', dAppVersion), onClicked: ()=>{
          /// 打开关于
          AboutViewConfig.open()
        }})



      }
      .divider({strokeWidth: 1})


    }
    .backgroundColor($r('app.color.color_obscure'))
    .width('100%')
    .height('100%') // 确保高度小于内容高度以触发滚动
    .padding(0)
  }


  @Builder
  buildHeaderRow(){
    Row({space: 10}){
      Stack(){
        Circle()
          .width(50)
          .height(50)
          .fill(Color.Gray)
        //header image
        if (UserManager.shared.avatarPath){
          //avatar image
          Image(`file://${UserManager.shared.avatarPath}`)
            .width(50)
            .height(50)
            .objectFit(ImageFit.Contain)
            .borderRadius(25)
            .clip(true)
        }else{
          if (UserManager.shared.userName?.length ?? 0 > 0) {
            Text(UserManager.shared.userName?.charAt(0))
              .foregroundColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }

        }
      }

      Column({space: 4}){
        Row({space: 4}) {
          if (UserManager.shared.userName?.length ?? 0 > 0) {
            Text(UserManager.shared.userName)
              .fontSize(22)
              .fontColor($r('app.color.colorPrimary'))

            IconButton({icon: $r('app.media.profile_circled'), onClickCallBack: () => {
              LogOffViewConfig.open()
            }})
          }else{
            Text($r('app.string.set_txt_not_login'))
              .fontSize(22)
              .fontColor($r('app.color.colorPrimary'))
              .onClick(() =>{
                this.isShowLoginView = true
              })
          }
        }
        .alignItems(VerticalAlign.Center)

        // 与 iOS / Android 一致：金币或会员信息显示在用户名下方。
        if (!MemberManager.shared.isActive) {
          this.buildGoldInfoRow()
        }else{
          this.buildMemberInfoRow()
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 用户名下方金币行：与 iOS / Android 头部 `goldPanel` 一致。
  @Builder
  buildGoldInfoRow(): void {
    Row({ space: 5 }) {
      Image($r('app.media.golds'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)

      Text($r('app.string.set_txt_gold_txt'))
        .fontSize(12)
        .fontColor($r('app.color.color_title'))

      Text(this.goldCountText)
        .fontSize(12)
        .fontColor('#ed0ea3')

      // 无规则文案时隐藏“免费获得金币”按钮，与 iOS `btnGainGold.isHidden` 语义一致。
      if (this.gainGoldPolicyText && this.gainGoldPolicyText.length > 0) {
        Button($r('app.string.set_txt_btn_gain_gold'))
          .fontSize(12)
          .height(22)
          .padding({ left: 4, right: 4 })
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.color_link'))
          .onClick(() => {
            this.actionGainGold()
          })
      }
    }
    .alignItems(VerticalAlign.Center)
  }

  // 用户名下方会员行：与 iOS / Android 头部 `memberPanel` 一致。
  @Builder
  buildMemberInfoRow(): void {
    Row({ space: 5 }) {
      TintImage({src: $r('app.media.set_icon_crown'), colorStr: '#FFD700'})
        .width(25)
        .height(25)

      Text($r('app.string.set_txt_be_member'))
        .fontSize(12)
        .fontColor($r('app.color.color_gold'))
    }
    .alignItems(VerticalAlign.Center)
  }


  @Builder
  buildIcon(param: SetItemOption){
    TintImage({src: param.icon, colorStr: param.iconColor ?? "#cccccc", isSvg: param.isSvg})//474B7E
      .width(22)
      .height(22)
  }

  @Builder
  buildListItem(param: SetItemOption){
    // 收藏夹
    ListItem({style: ListItemStyle.NONE}) {

      Row({space: 10}){
        //图标
        // this.buildIcon(param.icon, param.iconColor, param.isSvg) //分开传入数后，会员变化后，UI未刷新，不能用两层@Builder
        this.buildIcon(param) //直接传入param则可以

        Column(){
          Row(){
            //文字
            Text(param.title)
              .fontWeight(FontWeight.Regular)
              .fontSize(16)

            //Blank()
            if (param.textRight) {
              //文字 右边
              Text(param.textRight)
                .fontWeight(FontWeight.Normal)
                .fontSize(15)
                .fontColor(param.textRightColor ?? Color.Gray)
            }

            /// 自定义组件
            if (param.builderType != undefined){
              this.customBuilder(param.builderType)
            }
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('92%')

          if (param.textDown){
            //文字 下面
            Text(param.textDown)
              .fontWeight(FontWeight.Normal)
              .fontColor(param.textDownColor ?? Color.Gray)
              .fontSize(14)
              .margin({top: 2})
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')


      }
      .padding({ left: 20, top: 10,bottom : 10, right: 20 })
      .width('100%')
      .onClick(()=>{

        //点击
        param.onClicked?.()
      })

    }
    .backgroundColor(Color.White)
  }

  @Builder
  customBuilder(type: CustomBuilderType): void {

    if (type === CustomBuilderType.remindSwitch){

      ///提醒 开关
      Toggle({type: ToggleType.Switch, isOn: $$this.isReminderOn})
        .selectedColor($r('app.color.color_switch_tint'))
        .onChange(async (isOn: boolean)=>{

          this.isReminderOn = isOn

          // 开启提醒，直接请求权限并设置提醒
          if(await AlarmManager.shared.setReminderEnabled(isOn)) {

            ///设置时间
            await AlarmManager.shared.setReminder(this.selectedTime)
          }else{
            //检查是否成功设置
            this.isReminderOn = false

          }
        })
    }else if (type === CustomBuilderType.seSwitch){
      ///se 开关
      Toggle({type: ToggleType.Switch, isOn: SettingManager.shared.soundEffect })
        .selectedColor($r('app.color.color_switch_tint'))
        .onChange(async (isOn: boolean)=>{
          SettingManager.shared.soundEffect    = isOn
        })
    }else if (type === CustomBuilderType.curveSwitch){
      ///启用curve 开关
      Toggle({type: ToggleType.Switch, isOn: SettingManager.shared.enableCurve })
        .selectedColor($r('app.color.color_switch_tint'))
        .onChange(async (isOn: boolean)=>{
          SettingManager.shared.enableCurve    = isOn
        })
    }else if (type === CustomBuilderType.wifiAutoUpdateSwitch){
      ///Wifi下自动更新
      Toggle({type: ToggleType.Switch, isOn: SettingManager.shared.enableCurve })
        .selectedColor($r('app.color.color_switch_tint'))
        .onChange(async (isOn: boolean)=>{
          SettingManager.shared.autoUpdate    = isOn
        })
    }
  }



  getSelectedTimeString() : string {
    // return this.selectedTime.toLocaleTimeString()
    const options: Intl.DateTimeFormatOptions = {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    };
    return this.selectedTime.toLocaleTimeString('zh-CN', options);
  }


  showTimePicker() {
    TimePickerDialog.show({
      selected: this.selectedTime,
      useMilitaryTime: true, //24小时制
      onAccept: async (result: TimePickerResult) => {
        console.info('Selected time:', result.hour, result.minute)
        // 更新时间为用户选择的值
        const newTime = new Date(this.selectedTime);
        newTime.setHours(result.hour, result.minute);
        this.selectedTime = newTime;

        //设置提醒
        await AlarmManager.shared.setReminder(newTime)
      }
    })


  }


  @Builder buildLoginView(){
    LoginView({onDismiss:(loginSucceed: boolean)=>{
      this.isShowLoginView = false

      if (loginSucceed) {

        ///加载用户数据
        this.loadUserData()
      }

    }})
  }

  @Builder buildMemberView() {
    MemberView({isShowing: this.isShowMemberView, $isShowing:(val: boolean)=>{

      //关闭会员页面
      this.isShowMemberView = val

      //显示会员信息
      this.showMemberInfo()
    }})
  }

  updateBackupRestoreSubtitle() {
    if (this.userData.updateDate || this.userData.createDate) {
      const dateStr = DateUtils.toDateTimeString(this.userData.updateDate ?? this.userData.createDate!)
      this.subTitleForBackup  =  $r('app.string.set_more_txt_last_backup', dateStr)
      this.subTitleForRestore =  getStringF($r('app.string.set_more_txt_restore_cloud'), (BookManager.shared.currentBook?.bookName ?? ""))
    }else {
      this.subTitleForBackup  = undefined
      this.subTitleForRestore = undefined
    }

  }

  private loadUserData(){
    if (!NetWorkTool.checkInternetConnection(false)) {
      return
    }

    if (!UserManager.shared.isLogin()) {
      this.userData.userId       = null
      this.userData.bookId       = null
      this.userData.createDate   = null
      this.userData.updateDate   = null
      this.userData.userDataAddr = null

      //更新UI
      this.updateBackupRestoreSubtitle()
      return
    }

    UserDataManager.loadUserData((succeed: boolean, msg: string | null, UserDataJsons: UserDataJson[] | null) => {

      // 与 iOS `SettingViewConroller.loadUserData` 一致：
      // 以 updateDate（或 createDate）最新的一条作为当前备份记录。
      if (succeed && UserDataJsons != null && UserDataJsons.length > 0) {
        let latestData = UserData.fromJson(UserDataJsons[0])

        for (let i = 1; i < UserDataJsons.length; i++) {
          const current     = UserData.fromJson(UserDataJsons[i])
          const latestTime  = latestData.updateDate?.getTime() ?? latestData.createDate?.getTime() ?? 0
          const currentTime = current.updateDate?.getTime() ?? current.createDate?.getTime() ?? 0

          if (currentTime > latestTime) {
            latestData = current
          }
        }

        this.userData.userId       = latestData.userId
        this.userData.bookId       = latestData.bookId
        this.userData.createDate   = latestData.createDate
        this.userData.updateDate   = latestData.updateDate
        this.userData.userDataAddr = latestData.userDataAddr
      } else {
        // 与 iOS 一致：拉取失败或无数据时，清空当前备份显示状态。
        this.userData.userId       = null
        this.userData.bookId       = null
        this.userData.createDate   = null
        this.userData.updateDate   = null
        this.userData.userDataAddr = null
      }

      //更新UI
      this.updateBackupRestoreSubtitle()
    })
  }

  ///显示会员信息
  showMemberInfo(){
    const expireDate = MemberManager.shared.expireDate;

    if (expireDate) {
      //购买过会员

      ///会员功能
      this.memberTitle             = $r('app.string.set_cell_txt_member')

      if (MemberManager.shared.isActive) {

        // 会员还在有效期
        this.memberExpiryDate       = getStringF($r('app.string.member_txt_will_expire'), MemberManager.shared.expireDateString);
        this.memberExpiryDateColor  = $r('app.color.color_detail')

        this.memberIcon             = $r('app.media.set_icon_crown')//sdiamonded
        this.memberIconColor        = undefined//'#FFD700' //gold color

      } else {

        // 会员已过期
        this.memberExpiryDate       = getStringF($r('app.string.member_txt_was_expired'), MemberManager.shared.expireDateString);
        this.memberExpiryDateColor  = $r('app.color.colorAccent')

        this.memberIcon             = $r('app.media.set_icon_crown')//
        this.memberIconColor        = undefined//green color '#ff1450' //red color
      }
    } else {
      ///升级为会员
      this.memberTitle              = $r('app.string.set_cell_txt_to_member')

      //未购买过会员
      this.memberExpiryDate         = undefined
      this.memberExpiryDateColor    = $r('app.color.color_detail')
      this.memberIcon               = $r('app.media.set_icon_crown')//sdiamond
      this.memberIconColor          = undefined //green color
    }

  }

  // 与 iOS `ProfileViewController.reloadDatas` / `actionGainGold` 对齐：
  // 刷新金币总数与“赚金币”规则文案。
  showGoldInfo(): void {
    // 会员不显示金币入口。
    if (MemberManager.shared.isActive) {
      this.goldCountText      = '0'
      this.gainGoldPolicyText = undefined
      return
    }

    this.goldCountText = `${GoldManager.shared.golds}`

    // 读取所有金币规则文案，显示在“赚金币”列表项下方。
    GoldManager.shared.loadPolicyTexts((texts: Array<string | null>) => {
      const text = texts
        .map((it: string | null) => (it ?? '').trim())
        .filter((it: string) => it.length > 0)
        .join('\n')

      this.gainGoldPolicyText = text.length > 0 ? text : undefined
    })
  }

  // 与 iOS `ProfileViewController` 中 shareapp cell 的副标题逻辑对齐：
  // 首次分享显示金币策略；已领过首奖后，显示每日发音奖励说明。
  showShareEncourageInfo(): void {
    // 会员不显示分享奖励提示。
    if (MemberManager.shared.isActive) {
      this.shareEncourageText = undefined
      return
    }

    // 已领过首次分享金币后，显示每日分享发音奖励说明。
    if (GoldManager.shared.getGoldProvideLastDateForShareApp() != null) {
      this.shareEncourageText = $r('app.string.set_cell_txt_share_info')
      return
    }

    // 首次分享前，显示分享赠金币策略文案。
    GoldManager.shared.loadPolicyTextWith(LanguageManager.isTraditionalChinese() ? AppCfg.G_WTT_ShareApp : AppCfg.G_WTS_ShareApp, (text: string | null) => {
      this.shareEncourageText = text ?? undefined
    })
  }

  // 打开“赚金币”规则说明弹窗。
  private actionGainGold(): void {
    // 无文案时，不显示弹窗。
    if (!this.gainGoldPolicyText || this.gainGoldPolicyText.length === 0) {
      return
    }

    // 显示金币规则说明。
    Toast.showSelectOptions(getString($r('app.string.set_txt_btn_gain_gold')), this.gainGoldPolicyText, undefined, $r('app.string.confirm_btn_ok'))
  }

  // 与 iOS `ProfileViewController` 的“分享应用”入口对齐：
  // 统一走分享成功后的金币/发音奖励逻辑。
  private shareApp(): void {
    // 通过统一分享入口发起分享，并复用前台回归后的奖励处理。
    MarqueeManager.shared.shareApp()
  }

  ///学习履历删除
  confirmDeleteLearnTimes(){

    Toast.showConfirm({ msg:$r('app.string.setting_msg_del_learn'), yesAction: async ()=>{
         await SearchManager.shared.deleteLearnTimes()
         Toast.showMessage($r('app.string.setting_msg_done_del_learn'))
      }
    })
  }

  ///测试结果删除
  confirmDeleteTestResult(){
    Toast.showConfirm({ msg:$r('app.string.setting_msg_del_test'), yesAction: async ()=>{
      await SearchManager.shared.deleteTestResults()
      Toast.showMessage($r('app.string.setting_msg_done_del_test'))
    }
    })
  }

  ///复习列表删除
  confirmDeleteReviewList(){
    Toast.showConfirm({ msg:$r('app.string.setting_msg_del_review'), yesAction: async ()=>{
      await SearchManager.shared.deleteReviewList()
      Toast.showMessage($r('app.string.setting_msg_done_del_review'))
    }
    })
  }

  ///录音清空
  confirmDeleteRecords(){
    Toast.showConfirm({ msg:$r('app.string.setting_msg_del_record'), yesAction: async ()=>{

      let recorder = new SpeechRecordManager()
      await recorder.removeAllSounds()
      Toast.showMessage($r('app.string.setting_msg_done_del_record'))
    }
    })
  }
  ///笔记删除
  confirmDeleteMemos(){
    Toast.showConfirm({ msg:$r('app.string.setting_msg_del_memo'), yesAction: async ()=>{
      await SearchManager.shared.deleteMemo()
      Toast.showMessage($r('app.string.setting_msg_done_del_memo'))
    }
    })
  }
  ///收藏夹清空
  confirmDeleteFavorites(){
    Toast.showConfirm({ msg:$r('app.string.setting_msg_del_favorite'), yesAction: async ()=>{
      await SearchManager.shared.deleteFavorites()
      Toast.showMessage($r('app.string.setting_msg_done_del_favorite'))
    }
    })
  }


  ///恢复已经删除单词
  confirmDeletedWords(){
    Toast.showConfirm({ msg:$r('app.string.word_delete_msg_recover_confirm'), yesAction: async ()=>{
      await SearchManager.shared.deleteDeletedWords()
      Toast.showMessage($r('app.string.word_delete_msg_recover_success'))
    }
    })
  }


  //确认清空缓存
  confirmClearCache(){
    Toast.showAlert({
      title: $r('app.string.alert_title_confirm'),
      message: $r('app.string.set_cell_txt_crm_btn_clear_cache'),
      secondaryButton: {value: $r('app.string.cfm_btn_cancel'), fontColor: Color.Gray, action: () => {}},
      primaryButton: {value: $r('app.string.set_cell_txt_crm_btn_clear_cache'), action: () => {

        SettingManager.shared.clearCache()
      }}
    })
  }


  ///确认 备份
  confirmBackupUserData(){
    if (!UserManager.shared.isLogin()) {
      Toast.showMessage($r('app.string.login_not_login'))
      return
    }

    Toast.showAlert({
      title: $r('app.string.alert_title_confirm'),
      message: $r('app.string.set_more_msg_backup'),
      secondaryButton: {value: $r('app.string.cfm_btn_cancel'), fontColor: Color.Gray, action: () => {}},
      primaryButton: {value: $r('app.string.set_alert_backup_btn_yes'), action: () => {

        //备份用户数据
        this.actionBackupUserData()

      }}
    })
  }


  ///确认 恢复
  confirmRestoreUserData(){
    if (!UserManager.shared.isLogin()) {
      Toast.showMessage($r('app.string.login_not_login'))
      return
    }

    Toast.showAlert({
      title: $r('app.string.alert_title_confirm'),
      message: $r('app.string.set_more_msg_restore'),
      secondaryButton: {value: $r('app.string.cfm_btn_cancel'), fontColor: Color.Gray, action: () => {}},
      primaryButton: {value: $r('app.string.set_alert_restore_btn_yes'), action: () => {

        //备份用户数据
        this.actionRestoreUserData()

      }}
    })
  }


  ///执行备份
  actionBackupUserData(){
    const bookName = BookManager.shared.currentBook?.bookName ?? ''

    // LoadingUtility.showLoading($r('app.string.set_msg_backuping'))
    Toast.showCustomDialog(()=> { this.buildLoadingDialog($r('app.string.set_more_ing_backup'))}, false)
    UserDataManager.upload((success: boolean, msg: string | null) => {
      // LoadingUtility.hideLoading()
      Toast.closeCustomDialog()

      if (success) {
        Toast.showMessage(getStringF($r('app.string.set_more_success_backup'), bookName))
        this.loadUserData()
      }else{
        Toast.showMessage(msg ?? getString($r('app.string.set_more_failure_backup')))
      }
    })
  }

  ///执行恢复
  actionRestoreUserData(){
    const bookName = BookManager.shared.currentBook?.bookName ?? ''

    if (!this.subTitleForBackup) {
      Toast.showMessage(getStringF($r('app.string.set_more_txt_restore_not_found'), bookName))
      return
    }

    if (!this.userData.userDataAddr) {
      Toast.showMessage(getStringF($r('app.string.set_more_txt_restore_not_found'), bookName))
      return
    }

    // LoadingUtility.showLoading($r('app.string.set_msg_restoreing'))
    Toast.showCustomDialog(()=> { this.buildLoadingDialog($r('app.string.set_more_ing_restore'))}, false)
    // this.loadingView.showLoading(`${getString($r('app.string.set_msg_restoreing'))}....`)
    UserDataManager.download(this.userData,
      (progress: number) => {
        //LoadingUtility.showProgress($r('app.string.set_msg_restoreing'), progress)
      },

      (success: boolean, msg: string | null) => {
        //LoadingUtility.hideLoading()
        Toast.closeCustomDialog()
        //   this.loadingView.hide()

        if (success) {
          Toast.showMessage($r('app.string.set_more_success_restore'))

          ///重新加载当前页面数据
          this.loadUserData()

          //检查 DB结构，刷新缓存
          this.refreshDbAndCache()

          // 通知依赖 learnDb 的页面刷新，与 iOS `NeedReloadDBData` 对齐
          SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)

        }else{
          Toast.showMessage(msg ?? getString($r('app.string.set_more_failure_backup')))
        }
      })

  }

  actionDoUpdateBooks(){

    const book = BookManager.shared.currentBook
    const name = book?.textDb
    if (name) {
      Toast.showMessage($r('app.string.set_more_msg_update_started'))
      CBookManager.shared.startUpdateBookCheckIfNeeds(name,null, true,undefined, (succeed: boolean, msg: string | null) => {
        Toast.showMessage($r('app.string.set_more_msg_update_finished'))
      })
    }


  }

  @Builder
  buildLoadingDialog(msg?: ResourceStr | null): void {
    LoadingDialog({
      content: msg ?? 'loading..'
    })
  }


  refreshDbAndCache(){

    //检查 DB结构
    WordUserDbAccess.shared.refreshDb()
    PlanDbAccess.shared.refreshDb()
    SpeechRecordDbAccessor.shared.refreshDb()

    //重新加载数据
    SearchManager.shared.refreshData()

    ///刷新当前Plan，不然会有缓存
    const currentPlanId = PlanManager.shared.plan?.planId;
    if (currentPlanId) {
      PlanManager.getPlanByPlanId(currentPlanId).then((plan)=>{
        PlanManager.shared.plan = plan
      })
    }

  }

  //确认退出登录
  confirmLogout(){
    Toast.showAlert({
      title: $r('app.string.alert_title_confirm'),//退出登录
      message: $r('app.string.set_alert_logut_msg'),
      secondaryButton: {value: $r('app.string.cfm_btn_cancel'), fontColor: Color.Gray, action: () => {}},
      primaryButton: {value: $r('app.string.set_btn_logout'), action: () => {
        //退出登录
        UserManager.shared.logout()

        ///加载用户数据
        this.loadUserData()

      }}
    })
  }

  ///切换 语言
  actionShowLanguages(){
    let options: ItemOption[] = [];

    let isCns = LanguageManager.getCurrentLanguage() === AppLanguage.Simplified
    let isCnt = LanguageManager.getCurrentLanguage() === AppLanguage.Traditional

    ///简体中文
    options.push(
      {text: `简体中文`, color: isCns ? $r('app.color.color_red') : $r('app.color.color_black') , action: ()=>{

        LanguageManager.switchLanguage(AppLanguage.Simplified)

      }})


    ///繁體中文
    options.push(
      {text: `繁體中文`, color: isCnt ? $r('app.color.color_red') : $r('app.color.color_black'),action: ()=>{
        LanguageManager.switchLanguage(AppLanguage.Traditional)
      }})

    // 显示
    Toast.showSelectOptions('', undefined, options)
  }
}

interface SetItemOption {
  icon: Resource
  iconColor?: string //ResourceColor
  title: ResourceStr
  textDown?: ResourceStr
  textDownColor?: ResourceColor
  textRight?: ResourceStr
  textRightColor?: ResourceColor
  builderType?: CustomBuilderType
  isSvg?: boolean
  onClicked?:() => void
}

enum CustomBuilderType {
  remindSwitch,
  seSwitch,
  curveSwitch,
  wifiAutoUpdateSwitch,
}
