import {
  PhotoPickerComponent,
  PickerController,
  PickerOptions,
  BaseItemInfo,
  ItemInfo,
  PhotoBrowserInfo,
  ItemType,
  ClickType,
  ReminderMode,
  photoAccessHelper
} from '@kit.MediaLibraryKit'
import { NavBarView } from '../../NavBarView'
import { NavTitleView } from '../../NavTitleView'

@ComponentV2
export struct ImagePickerButton {
  // ======== 外部可配置参数 ========
  @Event onImagePicked                 : (uri: string | null) => void                    // 选中图片回调
  @Param btnWidth                      : number              = 80                 // 按钮宽度
  @Param btnHeight                     : number              = 80                 // 按钮高度
  @Param cornerRadius                  : number              = 12                 // 圆角
  @Param icon                          : Resource            = $r('app.media.addimg') // 默认图标
  @Param bgColor                       : ResourceColor       = Color.Transparent  // 按钮背景色

  // ======== 内部状态 ========
  @Local private pickerOptions         : PickerOptions       = new PickerOptions()
  @Local private pickerController      : PickerController    = new PickerController()
  @Local private selectedUri           : string | null       = null               // 当前选中图片 URI
  @Local private preselectedUris       : string[]            = []                 // 预选中列表（若需要同步）
  @Local private isShowPhotoPicker     : boolean             = false              // 是否显示保存弹窗

  // ======== 生命周期 ========
  aboutToAppear() {
    // 仅显示图片
    this.pickerOptions.MIMEType                   = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
    // 最多选中一张
    this.pickerOptions.maxSelectNumber            = 1
    // 超出数量时提醒方式
    this.pickerOptions.maxSelectedReminderMode    = ReminderMode.TOAST
    // 支持拍照入口
    this.pickerOptions.isPhotoTakingSupported     = false
    // 若有预选中 URI，可初始化
    if (this.selectedUri) {
      //this.pickerOptions.preselectedUris = [ this.selectedUri ]
    }
    this.pickerOptions.preselectedUris = []
  }

  // ======== 构建主界面（按钮） ========
  build() {
    // 使用 bindMenu 弹出 PhotoPickerComponent（与 WeightPickerButton 一致）
    Image(this.selectedUri || this.icon)
      .width(this.btnWidth)
      .height(this.btnHeight)
      .borderRadius(this.cornerRadius)
      // .objectFit(this.selectedUri ? ImageFit.Cover : ImageFit.Contain)
      .objectFit(ImageFit.Fill)
      .backgroundColor(this.bgColor)
      .clip(true)
      //.bindMenu(this.buildPickerMenu()) // 🔹 使用 bindMenu 弹出选择器
      .bindSheet($$this.isShowPhotoPicker, this.buildPickerMenu(), {
        detents: [SheetSize.FIT_CONTENT],
        preferType: SheetType.CENTER,//使用center在Folder上展开时能正常居中显示
        //title: {title:$r('app.string.detail_item_sort_nav_title')} ,
        showClose: false
      })
      .onClick(()=>{
        this.isShowPhotoPicker = true
      })
  }

  // ======== 构建 bindMenu 内容（PhotoPickerComponent） ========
  @Builder
  private buildPickerMenu() {
    Column(){

      NavBarView({
        title: $r('app.string.photo_picker_nav_title'),

        // 左侧按钮数组
        leftButtons: [
          {
            icon: $r('app.media.back'),
            onClick: () => {
              // this.selectedUri = null
              // this.onImagePicked(null)
              this.isShowPhotoPicker = false
            }
          }
        ],

        // 右侧按钮数组
        rightButtons: [
          {
            icon: $r('app.media.done'),
            onClick: () => {
              this.isShowPhotoPicker = false
            }
          }
        ],
      })
    }
    PhotoPickerComponent({
      pickerOptions        : this.pickerOptions,
      pickerController     : this.pickerController,
      onItemClicked        : (itemInfo: ItemInfo, clickType: ClickType): boolean => this.onItemClicked(itemInfo, clickType),
      onExitPhotoBrowser   : (_info: PhotoBrowserInfo): boolean => this.onExit(_info),
      onPickerControllerReady: (): void => this.onPickerControllerReady()
    })
      .width('100%')
      .height('100%')
  }

  // ======== 点击资源回调（由 PhotoPickerComponent 调用） ========
  private onItemClicked(itemInfo: ItemInfo, clickType: ClickType): boolean {
    if (!itemInfo || !itemInfo.uri) {
      return false
    }

    const uri = itemInfo.uri

    // 点击相机项：允许系统拉起相机（返回 true）
    if (itemInfo.itemType === ItemType.CAMERA) {
      return true
    }

    // 选中图片处理
    if (clickType === ClickType.SELECTED) {
      // 更新当前选中 URI 并回调外部
      this.selectedUri                   = uri
      this.preselectedUris               = [ uri ]
      this.pickerOptions.preselectedUris = [ uri ]   // 保持 picker 的预选中项同步
      try { this.onImagePicked(uri) } catch (e) {}
      return true
    }

    // 取消选中（如果需要同步逻辑，可在这里处理）
    return true
  }

  // ======== PickerController 就绪回调（可用于外部控制 picker） ========
  private onPickerControllerReady(): void {
    // 可以在这里通过 this.pickerController 调用 setData / setPhotoBrowserItem 等 API
    // 例如：this.pickerController.setData(DataType.SET_SELECTED_URIS, this.preselectedUris)
  }

  // ======== 退出图片浏览器（或 picker） ========
  private onExit(_info: PhotoBrowserInfo): boolean {
    // 关闭弹层后无需额外操作（bindMenu 会自动收起）
    return true
  }
}