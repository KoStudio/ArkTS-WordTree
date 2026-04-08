//
// ComposeMemoView.ets
// WordTree (HarmonyOS)
//
// 与 iOS `ShareData2/ComposeMemoView.swift` 对齐：本地编辑、保存/分享、公开列表分页、收藏与删除。
//

import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { buildStandardMenu, CustomNavigationMenuItem } from '../../../app/constants/AppFunctions'
import { TextButton } from '../../../app/views/buttons/TextButton'
import { IconTintButton } from '../../../app/views/buttons/IconTintButton'
import { LoginView } from '../../../views/login/LoginView'
import { LanguageManager } from '../../../common/components/Language/LanguageManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { NetWorkTool } from '../../../common/utils/NetworkUtils'
import { getString, getStringF } from '../../../common/utils/ResourceUtils'
import { Toast } from '../../../common/utils/Toast'
import { WordUser } from '../../datas/myData/WordUser'
import { AppCfgManager } from '../servercfg/AppCfgManager'
import { CosAuditResult, CosAuditor } from '../../../common/components/Sounds/Cloud/Audit/CosAuditor'
import { Memo2 } from './Memo2'
import {
  ShareMemoManager2,
  ShareMemoManager2Notification,
  ShareMemoNotificationPayload
} from './ShareMemoManager2'
import { UserManager } from '../user/UserManager'
import { NavTo } from '../../../pages/NavPathManager'

// 导航打开 ComposeMemo 页所需的参数与 NavKey
export namespace ComposeMemoViewConfig {

  // 路由名称（与 NavigationTo 注册一致）
  export const NavKey: string = 'ComposeMemoView_show'

  // param：词条与卡片页内索引（通知刷新用）
  export function open(param: Param): void {

    // 跳转到笔记编辑页
    NavTo(ComposeMemoViewConfig.NavKey, param, true)
  }

  export interface Param {

    word             : WordUser
    wordIndexOnPage  : number
  }
}

@ComponentV2
export struct ComposeMemoView {

  @Param @Require word             : WordUser
  @Param          wordIndexOnPage : number = 0

  @Local content          : string = ''
  @Local memos            : Memo2[] = []
  @Local isLoading        : boolean = false
  @Local isEditing        : boolean = false
  @Local loadedTimes      : number = 0
  @Local refreshTrigger   : number = 0
  @Local isLoadingMore    : boolean = false
  @Local hasMoreData      : boolean = true
  @Local isRefreshingList : boolean = false
  @Local favoritedMemoIds  : number[] = []
  @Local isShowLoginView   : boolean = false
  @Local menuRefreshKey    : number = 0

  private readonly memoLetterLimit : number = ShareMemoManager2.MemoLetterLimit
  private readonly memoTextAreaId  : string = 'compose_memo_text_area'

  private busUnsubPublic: (() => void) | undefined = undefined

  // 收起笔记输入框键盘
  private dismissMemoKeyboard(): void {

    // 清除输入框焦点以关闭软键盘
    this.getUIContext().getFocusController().clearFocus()
  }

  // 页面出现时初始化正文、收藏 id、公开列表，并订阅公开列表变更
  aboutToAppear(): void {

    this.content = this.word.memo ?? ''
    this.updateFavoritedMemoIds()
    this.loadData()

    // 仅订阅一次事件总线
    if (this.busUnsubPublic === undefined) {

      // 公开笔记变化时刷新当前词的列表
      this.busUnsubPublic = SimpleEventBus.on<ShareMemoNotificationPayload>(
        ShareMemoManager2Notification.Name.PublicChanged,
        (p?: ShareMemoNotificationPayload) => {

          // 无负载则忽略
          if (!p) {
            return
          }

          // 非当前词则忽略
          if (p.word.titleEn !== this.word.titleEn) {
            return
          }

          this.loadData()
        })
    }
  }

  // 页面消失时取消订阅
  aboutToDisappear(): void {

    if (this.busUnsubPublic !== undefined) {
      this.busUnsubPublic()
      this.busUnsubPublic = undefined
    }
  }

  // 构建页面根布局与导航栏
  build() {

    NavDestination() {
      Column() {

        Column({ space: 12 }) {

          TextArea({ text: this.content })
            .id(this.memoTextAreaId)
            .height(100)
            .width('100%')
            .padding(4)
            .backgroundColor($r('app.color.color_obscure'))
            .borderRadius(8)
            .fontColor($r('app.color.color_text'))
            .onChange((v: string) => {
              this.content = v
              this.refreshButtonState()
            })

          Row() {

            Blank().layoutWeight(1)

            Text(`${this.content.trim().length}/${this.memoLetterLimit}`)
              .fontSize(12)
              .fontColor(this.content.trim().length > this.memoLetterLimit ? Color.Red :
                $r('app.color.color_text'))
          }
          .width('100%')

          Row({ space: 16 }) {

            TextButton({
              text: $r('app.string.memo_compose_btn_save'),
              bgColor: this.isSaveEnabled ? $r('app.color.color_btn_bg2') : $r('app.color.color_gray'),
              onClickCallBack: () => {
                this.actionSave()
              },
              isEnabled: this.isSaveEnabled
            })
              .layoutWeight(1)
              .height(48)

            TextButton({
              text: $r('app.string.memo_compose_btn_save_share'),
              bgColor: this.isSaveEnabled ? $r('app.color.color_btn_bg2') : $r('app.color.color_gray'),
              onClickCallBack: () => {
                this.actionSaveAndShare()
              },
              isEnabled: this.isSaveEnabled
            })
              .layoutWeight(1)
              .height(48)
          }
          .width('100%')
        }
        .padding(16)
        .width('100%')
        .backgroundColor($r('app.color.color_background'))

        Divider().color($r('app.color.color_gray_light'))

        this.memoListSection()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.color_background'))
      .bindSheet($$this.isShowLoginView, this.buildLoginSheet(), {
        detents     : [SheetSize.LARGE],
        preferType  : SheetType.CENTER,
        showClose   : false,
        onDisappear : () => {
          this.isShowLoginView = false
        }
      })
    }
    .title(buildNavTitle(this.getNavTitle()))
    .menus(buildStandardMenu(this.buildMenuItems()))
    .backButtonIcon(dNavBackIcon)
    .backgroundColor($r('app.color.colorPrimary'))
    .key(`memo_menu_${this.menuRefreshKey}`)
  }

  // 半屏登录页
  @Builder
  buildLoginSheet() {

    LoginView({
      onDismiss: (_loginSucceed: boolean) => {
        this.isShowLoginView = false
      }
    })
  }

  // 保存按钮是否可用（字数在 (0, 上限]）
  private get isSaveEnabled(): boolean {

    const count = this.content.trim().length

    return count > 0 && count <= this.memoLetterLimit
  }

  // 输入变化时占位（与 iOS refreshButtonState 一致，由 @Local 驱动按钮态）
  private refreshButtonState(): void {
  }

  // 导航标题为词条英文名
  private getNavTitle(): ResourceStr {
    return this.word.titleEn ?? ''
  }

  // 构建导航栏「编辑 / 完成」菜单项
  private buildMenuItems(): CustomNavigationMenuItem[] {

    const label = this.isEditing ? $r('app.string.memo_compose_menu_done') :
      $r('app.string.memo_compose_menu_edit')

    return [
      {
        value  : label,
        action : () => {

          this.isEditing = !this.isEditing
          this.menuRefreshKey++

          // 进入编辑：聚焦输入框
          if (this.isEditing) {

            // 延后请求焦点，等待菜单与布局稳定
            setTimeout(() => {

              // 将焦点移到笔记输入框
              this.getUIContext().getFocusController().requestFocus(this.memoTextAreaId)
            }, 100)
          } else {

            // 完成编辑：收起键盘
            this.dismissMemoKeyboard()
          }
        }
      } as CustomNavigationMenuItem
    ]
  }

  // 公开笔记列表区域（含加载、空态、下拉刷新、分页）
  @Builder
  memoListSection() {
    Column() {

      Text($r('app.string.memo_pub_memo_title'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.color_text'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({
          left   : 16,
          right  : 16,
          top    : 12,
          bottom : 12
        })
        .backgroundColor($r('app.color.color_obscure'))

      // 首次加载且无数据
      if (this.isLoading && this.memos.length === 0) {

        LoadingProgress()
          .width(40)
          .height(40)
          .margin(24)
      } else if (this.memos.length === 0) {

        // 无公开笔记
        Text($r('app.string.memo_msg_no_share_memo'))
          .width('100%')
          .padding(24)
          .fontColor($r('app.color.color_text'))
      } else {

        Refresh({ refreshing: $$this.isRefreshingList }) {

          List({ space: 0 }) {

            ForEach(this.memos, (memo: Memo2, index: number) => {
              ListItem() {
                this.memoRowBuilder(memo, index)
              }
              .onAppear(() => {

                // 接近列表尾部时加载下一页
                if (index >= this.memos.length - 5 && !this.isLoadingMore && this.hasMoreData) {
                  this.loadMoreIfNeeded()
                }
              })
            },
              (memo: Memo2, index: number) => `${memo.memoId ?? index}_${this.refreshTrigger}`)
          }
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: $r('app.color.color_gray_light') })
        }
          .onRefreshing(() => {
            void this.refreshData()
          })
          .layoutWeight(1)
          .width('100%')
      }

      // 分页加载中指示
      if (this.isLoadingMore) {

        Row() {
          LoadingProgress()
            .width(32)
            .height(32)
            .margin(12)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (!this.hasMoreData && this.memos.length > 10) {

        // 已无更多分页数据
        Text($r('app.string.online_search_load_no_more'))
          .fontSize(12)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(12)
          .fontColor($r('app.color.color_text'))
      }
    }
    .layoutWeight(1)
    .width('100%')
    .backgroundColor($r('app.color.color_background'))
  }

  // memo：一行公开笔记；index：在 memos 中的下标
  @Builder
  memoRowBuilder(memo: Memo2, index: number) {

    Column({ space: 8 }) {

      Text(memo.memoText ?? '')
        .fontSize(16)
        .fontColor($r('app.color.color_list_item_subtitle'))
        .width('100%')
        .padding({ left: 16, right: 16, top: 12 })

      Row() {

        Text(this.authorLabel(memo))
          .fontSize(12)
          .fontColor(memo.isSelfCreated() ? $r('app.color.color_text') :
            $r('app.color.color_list_item_detail'))
          .layoutWeight(1)

        // 本人笔记：删公开 + 禁用收藏占位
        if (memo.isSelfCreated()) {

          IconTintButton({
            icon             : $r('app.media.trash'),
            iconSize         : 22,
            onClickCallBack  : () => {
              this.actionDeleteMemo(memo, index)
            }
          })

          // 与 iOS 禁用态收藏图标占位一致
          Text('♡')
            .fontSize(22)
            .width(36)
            .textAlign(TextAlign.Center)
            .opacity(0.35)
        } else {

          // 他人笔记：心形仅展示，点击整行切换收藏（避免与外层 Column.onClick 重复触发）
          Text(this.isMemoAdded(memo) ? '♥' : '♡')
            .fontSize(22)
            .width(36)
            .textAlign(TextAlign.Center)
            .fontColor($r('app.color.color_text'))
        }

        Text(`${memo.favCount ?? 0}`)
          .fontSize(12)
          .fontColor($r('app.color.color_text'))
          .margin({ left: 4 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })
    }
    .width('100%')
    .backgroundColor($r('app.color.color_background'))
    .onClick(() => {

      // 他人行整行点击可切换收藏
      if (!memo.isSelfCreated()) {
        this.actionToggleFavorite(memo, index)
      }
    })
  }

  // memo：当前行模型；返回作者展示文案
  private authorLabel(memo: Memo2): string {

    const base = getString($r('app.string.memo_author_txt'))

    // 本人带「自己」后缀
    if (memo.isSelfCreated()) {
      return `${base}: ${memo.userName ?? ''}(${getString($r('app.string.memo_author_self'))})`
    }

    return `${base}: ${memo.userName ?? ''}`
  }

  // 仅保存到本地（可走 COS 审核）
  private actionSave(): void {

    const trimmed = this.content.trim()

    // 简体且开启笔记审核时先走 COS
    if (LanguageManager.isSimpleChinese() && AppCfgManager.shared.isCosAuditCheckForMemo_is_ON()) {

      const auditor = new CosAuditor()

      auditor.audit(trimmed, (succeed: boolean, result: CosAuditResult, msg: string | null) => {

        // 审核接口失败仍允许保存
        if (!succeed) {
          void this.doSave()
          return
        }

        // 内容未通过审核
        if (result !== CosAuditResult.Normal) {

          if (msg !== null && msg.length > 0) {

            // 展示服务端返回提示
            Toast.showMessage(msg)
          } else {

            // 展示通用审核失败文案
            Toast.showMessage($r('app.string.memo_msg_audit_fail'))
          }
          return
        }

        void this.doSave()
      })
    } else {

      void this.doSave()
    }
  }

  // 写入 DB 并发私有变更通知
  private async doSave(): Promise<void> {

    // 持久化本地笔记字段
    await ShareMemoManager2.shared.saveLocalMemo(this.content.trim(), this.word, (succeed: boolean) => {

      if (succeed) {

        // 提示成功
        Toast.showMessage($r('app.string.memo_msg_save_success'))

        // 通知卡片刷新私有笔记区
        ShareMemoManager2.shared.postNotification(false, this.word, this.wordIndexOnPage)
      }
    })
  }

  // 保存并分享到服务端（登录 + 网络 + 审核）
  private actionSaveAndShare(): void {

    // 未登录则弹出登录
    if (!UserManager.shared.isLogin()) {
      this.isShowLoginView = true
      return
    }

    // 无网络则拦截（带提示）
    if (!NetWorkTool.checkInternetConnection(true)) {
      return
    }

    const trimmed = this.content.trim()

    // 分享路径在 AppCfg 开启审核时不区分简繁
    if (AppCfgManager.shared.isCosAuditCheckForMemo_is_ON()) {

      const auditor = new CosAuditor()

      auditor.audit(trimmed, (succeed: boolean, result: CosAuditResult, msg: string | null) => {

        // 审核接口异常则仍尝试分享
        if (!succeed) {
          void this.doSaveAndShare()
          return
        }

        if (result !== CosAuditResult.Normal) {

          if (msg !== null && msg.length > 0) {
            Toast.showMessage(msg)
          } else {
            Toast.showMessage($r('app.string.memo_msg_audit_fail'))
          }
          return
        }

        void this.doSaveAndShare()
      })
    } else {

      void this.doSaveAndShare()
    }
  }

  // 调分享接口并双发公私通知、刷新列表
  private async doSaveAndShare(): Promise<void> {

    Toast.showMessage($r('app.string.memo_msg_share_start'))

    // 本地保存成功后已在 saveAndShareMemo 外层保证；此处请求服务端
    ShareMemoManager2.shared.saveAndShareMemo(this.content.trim(), this.word, (succeed: boolean) => {

      if (succeed) {

        Toast.showMessage($r('app.string.memo_msg_share_success'))

        ShareMemoManager2.shared.postNotification(false, this.word, this.wordIndexOnPage)
        ShareMemoManager2.shared.postNotification(true, this.word, this.wordIndexOnPage)

        this.loadData()
      }
    })
  }

  // memo：要删的公开笔记；index：列表下标（乐观移除）
  private actionDeleteMemo(memo: Memo2, index: number): void {

    const memoId = memo.memoId

    // 无有效 id
    if (memoId === null) {
      return
    }

    if (!NetWorkTool.checkInternetConnection(true)) {
      return
    }

    const next = [...this.memos]

    next.splice(index, 1)

    this.memos = next
    this.refreshTrigger++

    // 请求服务端删除公开笔记
    ShareMemoManager2.shared.removePublicMemoWithMemoId(memoId, (succeed: boolean) => {

      if (succeed) {

        Toast.showMessage($r('app.string.memo_msg_remove_share_success'))

        ShareMemoManager2.shared.postNotification(true, this.word, this.wordIndexOnPage)
      } else {

        // 失败则整体重拉列表恢复状态
        this.loadData()
      }
    })
  }

  // memo：目标笔记；index：列表下标
  private actionToggleFavorite(memo: Memo2, index: number): void {

    // 已收藏则取消，否则添加
    if (this.isMemoAdded(memo)) {
      this.removeFavorite(memo, index)
    } else {
      this.addFavorite(memo, index)
    }
  }

  // 取消收藏他人笔记（乐观更新 UI；shareMemos 仅由 ShareMemoManager2 删除，否则 removeLocalShareMemoFromWordWithMemoId 找不到行）
  private removeFavorite(memo: Memo2, index: number): void {

    const memoId = memo.memoId

    if (memoId === null) {
      return
    }

    this.favoritedMemoIds = this.favoritedMemoIds.filter((id) => id !== memoId)

    const oldFav = memo.favCount ?? 0

    if (index < this.memos.length) {
      const arr = [...this.memos]
      arr[index] = this.memos[index].withFavCount(Math.max(oldFav - 1, 0))
      this.memos = arr
    }

    this.refreshTrigger++

    // 写库并请求 fav -1（内部从 word.shareMemos 按 memoId 删除）
    ShareMemoManager2.shared.removeLocalShareMemoFromWordWithMemoId(this.word, memoId, (succeed: boolean) => {

      if (succeed) {

        Toast.showMessage($r('app.string.memo_msg_remove_memo_success'))

        ShareMemoManager2.shared.postNotification(false, this.word, this.wordIndexOnPage)
      } else {

        this.favoritedMemoIds = [...this.favoritedMemoIds, memoId]

        if (index < this.memos.length) {
          const arr = [...this.memos]
          arr[index] = this.memos[index].withFavCount(oldFav)
          this.memos = arr
        }

        this.refreshTrigger++

        // 与列表/DB 对齐
        this.loadData()
      }
    })
  }

  // 收藏他人笔记（受 PrivateMemoLimit 限制；乐观更新 + 回滚）
  private addFavorite(memo: Memo2, index: number): void {

    const memoId = memo.memoId

    if (memoId === null) {
      return
    }

    const cur = this.word.shareMemos ?? []

    // 超过本词私人收藏上限
    if (cur.length >= ShareMemoManager2.PrivateMemoLimit) {

      Toast.showMessage(
        getStringF($r('app.string.memo_msg_add_share_error'), ShareMemoManager2.PrivateMemoLimit))
      return
    }

    // 不在此处写入 word.shareMemos：addLocalShareMemo 会追加一条，重复写入会导致同一笔记出现两条
    this.favoritedMemoIds = [...this.favoritedMemoIds, memoId]

    const oldFav = memo.favCount ?? 0

    if (index < this.memos.length) {
      const arr = [...this.memos]
      arr[index] = this.memos[index].withFavCount(oldFav + 1)
      this.memos = arr
    }

    this.refreshTrigger++

    // 写库并请求 fav +1
    ShareMemoManager2.shared.addLocalShareMemo(memo, this.word, (succeed: boolean) => {

      if (succeed) {

        Toast.showMessage($r('app.string.memo_msg_add_share_success'))

        ShareMemoManager2.shared.postNotification(false, this.word, this.wordIndexOnPage)
      } else {

        this.favoritedMemoIds = this.favoritedMemoIds.filter((id) => id !== memoId)
        this.word.shareMemos = this.word.shareMemos.filter((d) =>
          (d[WordUser.KShareMemo_MemoId] ?? '') !== String(memoId))

        if (index < this.memos.length) {
          const arr = [...this.memos]
          arr[index] = this.memos[index].withFavCount(oldFav)
          this.memos = arr
        }

        this.refreshTrigger++
        this.loadData()
      }
    })
  }

  // 拉取第 0 页公开列表并排序（本人优先）
  private loadData(): void {

    const wordEn = this.word.titleEn

    // 无英文标题无法请求
    if (!wordEn) {
      return
    }

    // 无网则清空列表展示
    if (!NetWorkTool.checkInternetConnection(false)) {
      this.memos = []
      this.isLoading = false
      return
    }

    this.isLoading = true
    this.loadedTimes = 0
    this.hasMoreData = true

    ShareMemoManager2.shared.loadPublicMemosOfWord(wordEn, 0, (loaded: Memo2[]) => {

      this.memos = loaded
      this.isLoading = false
      this.updateFavoritedMemoIds()
      this.refreshTrigger++

      if (loaded.length < ShareMemoManager2.FetchMemoLimit) {
        this.hasMoreData = false
      }

      // 空列表给提示（与 iOS 一致）
      if (loaded.length === 0) {
        Toast.showMessage($r('app.string.memo_msg_no_share_memo'))
      }
    })
  }

  // 下拉刷新：重置分页并拉第 0 页
  private async refreshData(): Promise<void> {

    const wordEn = this.word.titleEn

    if (!wordEn) {
      this.isRefreshingList = false
      return
    }

    if (!NetWorkTool.checkInternetConnection(false)) {
      this.isRefreshingList = false
      return
    }

    this.loadedTimes = 0
    this.hasMoreData = true

    await new Promise<void>((resolve) => {

      ShareMemoManager2.shared.loadPublicMemosOfWord(wordEn, 0, (loaded: Memo2[]) => {

        this.memos = loaded
        this.updateFavoritedMemoIds()
        this.refreshTrigger++

        if (loaded.length < ShareMemoManager2.FetchMemoLimit) {
          this.hasMoreData = false
        }

        resolve()
      })
    })

    this.isRefreshingList = false
  }

  // 列表接近底部时请求下一页
  private loadMoreIfNeeded(): void {

    const wordEn = this.word.titleEn

    if (!wordEn) {
      return
    }

    if (!NetWorkTool.checkInternetConnection(false)) {
      return
    }

    // 正在加载或已无更多则跳过
    if (this.isLoadingMore || !this.hasMoreData) {
      return
    }

    const nextPage = this.loadedTimes + 1

    this.isLoadingMore = true

    ShareMemoManager2.shared.loadPublicMemosOfWord(wordEn, nextPage, (newMemos: Memo2[]) => {

      if (newMemos.length > 0) {
        this.memos = [...this.memos, ...newMemos]
        this.loadedTimes = nextPage
        this.refreshTrigger++

        if (newMemos.length < ShareMemoManager2.FetchMemoLimit) {
          this.hasMoreData = false
        }
      } else {

        this.hasMoreData = false
      }

      this.isLoadingMore = false
    })
  }

  // memo：判断是否已收入本词 shareMemos 或 favoritedMemoIds
  private isMemoAdded(memo: Memo2): boolean {

    const memoId = memo.memoId

    if (memoId === null) {
      return false
    }

    if (this.favoritedMemoIds.includes(memoId)) {
      return true
    }

    return this.word.shareMemos?.some((d) => (d[WordUser.KShareMemo_MemoId] ?? '') === String(memoId)) ?? false
  }

  // 根据 word.shareMemos 重建已收藏 memo_id 列表（供心形态）
  private updateFavoritedMemoIds(): void {

    const next: number[] = []
    const shareMemos = this.word.shareMemos

    if (shareMemos) {

      for (const memoDict of shareMemos) {

        const memoIdStr = memoDict[WordUser.KShareMemo_MemoId]

        if (memoIdStr !== undefined) {
          const memoId = parseInt(memoIdStr, 10)

          if (!Number.isNaN(memoId)) {
            next.push(memoId)
          }
        }
      }
    }

    this.favoritedMemoIds = next
  }
}
