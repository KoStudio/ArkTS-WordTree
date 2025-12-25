import { buildNavTitle } from "../../../app/constants/AppBuilders";
import { dAppVersion, dNavBackIcon, isDebugMode } from "../../../app/constants/AppDefines";
import { buildStandardMenu } from "../../../app/constants/AppFunctions";
import { IconButton } from "../../../app/views/buttons/IconButton";
import { TintImage } from "../../../app/views/TintImage";
import AlarmManager from "../../../common/components/Alarm/AlarmManager";
import { DateUtils } from "../../../common/utils/DateUtils";
import { ReviewUtils } from "../../../common/utils/ReviewUtils";
import { ShareUtils } from "../../../common/utils/ShareUtils";
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
import { getStringF } from "../../../common/utils/ResourceUtils";
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
  @Local   shareEncourageText?          : ResourceStr
  private  needEncourageForShareApp     : boolean                          = false //记录是否需要奖励


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
  }

  @Monitor('userManager.userId')
  onChangeOfLogin(){
    this.isLogin = UserManager.shared.isLogin()
    this.loadUserData()
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
        .height(60)
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

        // 查看已删除单词
        this.buildListItem({icon: $r('app.media.set_icon_del_review'), title: $r('app.string.set_txt_word_deleted'), onClicked: ()=>{
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
        this.buildListItem({icon: $r('app.media.share'), isSvg: true, title: $r('app.string.set_cell_txt_share'), onClicked: ()=>{
          /// 打开
          ShareUtils.shareThisAppWithLoadedLink()
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
    Row({space: 5}){
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

      if (UserManager.shared.userName?.length ?? 0 > 0) {
        Text(UserManager.shared.userName)
        IconButton({icon: $r('app.media.profile_circled'), onClickCallBack: () => {
          LogOffViewConfig.open()
        }})
      }else{
        Text($r('app.string.set_txt_not_login'))
          .onClick(() =>{
            this.isShowLoginView = true
          })
      }

    }
    .width('100%')
  }


  @Builder
  buildIcon(param: SetItemOption){
    TintImage({src: param.icon, colorStr: param.iconColor ?? "#474B7E", isSvg: param.isSvg})
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
    if (this.userData.updateDate) {
      const dateStr = DateUtils.toDateTimeString(this.userData.updateDate)
      this.subTitleForBackup  =  $r('app.string.set_txt_data_last_backup', dateStr)
      this.subTitleForRestore =  $r('app.string.set_txt_data_to_restore')
    }else {
      this.subTitleForBackup  = undefined
      this.subTitleForRestore = undefined
    }

  }

  private loadUserData(){
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

      if (UserDataJsons != null && UserDataJsons?.length > 0) {
        const oneData              =  UserData.fromJson(UserDataJsons[0])
        this.userData.userId       = oneData.userId
        this.userData.bookId       = oneData.bookId
        this.userData.createDate   = oneData.createDate
        this.userData.updateDate   = oneData.updateDate
        this.userData.userDataAddr = oneData.userDataAddr
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

        this.memberIcon             = $r('app.media.sdiamonded')
        this.memberIconColor        = '#FFD700' //gold color

      } else {

        // 会员已过期
        this.memberExpiryDate       = getStringF($r('app.string.member_txt_was_expired'), MemberManager.shared.expireDateString);
        this.memberExpiryDateColor  = $r('app.color.colorAccent')

        this.memberIcon             = $r('app.media.sdiamonded')
        this.memberIconColor        = undefined//green color '#ff1450' //red color
      }
    } else {
      ///升级为会员
      this.memberTitle              = $r('app.string.set_cell_txt_to_member')

      //未购买过会员
      this.memberExpiryDate         = undefined
      this.memberExpiryDateColor    = $r('app.color.color_detail')
      this.memberIcon               = $r('app.media.sdiamond')
      this.memberIconColor          = undefined //green color
    }

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
      message: $r('app.string.set_alert_backup_msg'),
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
      message: $r('app.string.set_alert_restore_msg'),
      secondaryButton: {value: $r('app.string.cfm_btn_cancel'), fontColor: Color.Gray, action: () => {}},
      primaryButton: {value: $r('app.string.set_alert_restore_btn_yes'), action: () => {

        //备份用户数据
        this.actionRestoreUserData()

      }}
    })
  }


  ///执行备份
  actionBackupUserData(){
    // LoadingUtility.showLoading($r('app.string.set_msg_backuping'))
    Toast.showCustomDialog(()=> { this.buildLoadingDialog($r('app.string.set_msg_backuping'))}, false)
    UserDataManager.upload((success: boolean, msg: string | null) => {
      // LoadingUtility.hideLoading()
      Toast.closeCustomDialog()

      if (success) {
        Toast.showMessage($r('app.string.set_msg_backup_done'))
        this.loadUserData()
      }else{
        Toast.showMessage(`${$r('app.string.set_msg_backup_failed') }: ${msg}`)
      }
    })
  }

  ///执行恢复
  actionRestoreUserData(){

    if (!this.userData.userDataAddr) {
      Toast.showMessage("app.string.set_msg_restore_no_found")
      return
    }

    // LoadingUtility.showLoading($r('app.string.set_msg_restoreing'))
    Toast.showCustomDialog(()=> { this.buildLoadingDialog($r('app.string.set_msg_restoreing'))}, false)
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
          Toast.showMessage($r('app.string.set_msg_restore_done'))

          ///重新加载当前页面数据
          this.loadUserData()

          //检查 DB结构，刷新缓存
          this.refreshDbAndCache()

        }else{
          Toast.showMessage(`${$r('app.string.set_msg_restore_failed') }: ${msg}`)
        }
      })

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
    SearchManager.shared.refreshData()
    // PlanDbAccess.shared.refreshDb()


    // EBookDbAccess.shared.refreshDb()
    // CColorDbAccess.shared.refreshDb()
    // UPinyinDbAccess.shared.refreshDb()



    ///刷新当前Plan，不然会有缓存
    const currentPlanId = PlanManager.shared.plan?.planId;
    if (currentPlanId) {
      PlanManager.getPlanByPlanId(currentPlanId).then((plan)=>{
        PlanManager.shared.plan = plan
      })
    }
    //
    // //清空缓存
    // EBookManager.shared.clearCaches()
    // CColorManager.shared.clearCaches()
    // UPinyinManager.shared.clearCaches()
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
}