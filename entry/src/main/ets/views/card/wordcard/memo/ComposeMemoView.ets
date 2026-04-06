//
// ComposeMemoView.ets
// WordTree (HarmonyOS)
//
// 与 iOS `ShareData2/ComposeMemoView.swift` 对齐：本地编辑、保存/分享、公开列表分页、收藏与删除。
//

import { buildNavTitle } from "../../../../app/constants/AppBuilders"
import { dNavBackIcon } from "../../../../app/constants/AppDefines"
import { buildStandardMenu, CustomNavigationMenuItem } from "../../../../app/constants/AppFunctions"
import { TextButton } from "../../../../app/views/buttons/TextButton"
import { IconTintButton } from "../../../../app/views/buttons/IconTintButton"
import { LoginView } from "../../../login/LoginView"
import { LanguageManager } from "../../../../common/components/Language/LanguageManager"
import { logEvent } from "../../../../common/components/Logger/Logger"
import { SimpleEventBus } from "../../../../common/components/eventbus/SimpleEventBus"
import { NetWorkTool } from "../../../../common/utils/NetworkUtils"
import { getString, getStringF } from "../../../../common/utils/ResourceUtils"
import { Toast } from "../../../../common/utils/Toast"
import { WordUser } from "../../../../models/datas/myData/WordUser"
import { AppCfgManager } from "../../../../models/managers/servercfg/AppCfgManager"
import { CosAuditResult, CosAuditor } from "../../../../common/components/Sounds/Cloud/Audit/CosAuditor"
import { Memo2 } from "../../../../models/managers/sharedata2/Memo2"
import {
  ShareMemoManager2,
  ShareMemoManager2Notification,
  ShareMemoNotificationPayload
} from "../../../../models/managers/sharedata2/ShareMemoManager2"
import { UserManager } from "../../../../models/managers/user/UserManager"
import { NavTo } from "../../../../pages/NavPathManager"

export namespace ComposeMemoViewConfig {

  export const NavKey: string = 'ComposeMemoView_show'

  // param：词条与卡片页内索引（通知刷新用）
  export function open(param: Param): void {
    NavTo(ComposeMemoViewConfig.NavKey, param, true)
  }

  export interface Param {
    word            : WordUser
    wordIndexOnPage : number
  }
}

@ComponentV2
export struct ComposeMemoView {

  @Param @Require word: WordUser
  @Param wordIndexOnPage: number = 0

  @Local content: string = ''
  @Local memos: Memo2[] = []
  @Local isLoading: boolean = false
  @Local isEditing: boolean = false
  @Local loadedTimes: number = 0
  @Local refreshTrigger: number = 0
  @Local isLoadingMore: boolean = false
  @Local hasMoreData: boolean = true
  @Local isRefreshingList: boolean = false
  @Local favoritedMemoIds: number[] = []
  @Local isShowLoginView: boolean = false
  @Local menuRefreshKey: number = 0

  private readonly memoLetterLimit: number = ShareMemoManager2.MemoLetterLimit

  private busUnsubPublic: (() => void) | undefined = undefined

  aboutToAppear(): void {

    this.content = this.word.memo ?? ''
    this.updateFavoritedMemoIds()
    this.loadData()

    if (this.busUnsubPublic === undefined) {

      this.busUnsubPublic = SimpleEventBus.on<ShareMemoNotificationPayload>(
        ShareMemoManager2Notification.Name.PublicChanged,
        (p?: ShareMemoNotificationPayload) => {

          if (!p) {
            return
          }

          if (p.word.titleEn !== this.word.titleEn) {
            return
          }

          this.loadData()
        })
    }
  }

  aboutToDisappear(): void {

    if (this.busUnsubPublic !== undefined) {
      this.busUnsubPublic()
      this.busUnsubPublic = undefined
    }
  }

  build() {

    NavDestination() {
      Column() {

        Column({ space: 12 }) {

          TextArea({ text: this.content })
            .height(100)
            .width('100%')
            .padding(4)
            .backgroundColor($r('app.color.color_obscure'))
            .borderRadius(8)
            .onChange((v: string) => {
              this.content = v
              this.refreshButtonState()
            })

          Row() {

            Blank().layoutWeight(1)

            Text(`${this.content.trim().length}/${this.memoLetterLimit}`)
              .fontSize(12)
              .fontColor(this.content.trim().length > this.memoLetterLimit ? Color.Red :
              $r('app.color.color_detail'))
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
        detents: [SheetSize.LARGE],
        preferType: SheetType.CENTER,
        showClose: false,
        onDisappear: () => {
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

  @Builder
  buildLoginSheet() {
    LoginView({
      onDismiss: (_loginSucceed: boolean) => {
        this.isShowLoginView = false
      }
    })
  }

  // 与 SwiftUI isSaveEnabled 一致
  private get isSaveEnabled(): boolean {

    const count = this.content.trim().length

    return count > 0 && count <= this.memoLetterLimit
  }

  private refreshButtonState(): void {
  }

  private getNavTitle(): ResourceStr {
    return this.word.titleEn ?? ''
  }

  private buildMenuItems(): CustomNavigationMenuItem[] {

    const label = this.isEditing ? $r('app.string.memo_compose_menu_done') : $r('app.string.memo_compose_menu_edit')

    return [
      {
        value: label,
        action: () => {
          this.isEditing = !this.isEditing
          this.menuRefreshKey++
        }
      } as CustomNavigationMenuItem
    ]
  }

  @Builder
  memoListSection() {
    Column() {

      Text($r('app.string.memo_pub_memo_title'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 12
        })
        .backgroundColor($r('app.color.color_obscure'))

      if (this.isLoading && this.memos.length === 0) {

        LoadingProgress()
          .width(40)
          .height(40)
          .margin(24)
      } else if (this.memos.length === 0) {

        Text($r('app.string.memo_msg_no_share_memo'))
          .width('100%')
          .padding(24)
      } else {

        Refresh({ refreshing: $$this.isRefreshingList }) {

          List({ space: 0 }) {

            ForEach(this.memos, (memo: Memo2, index: number) => {
              ListItem() {
                this.memoRowBuilder(memo, index)
              }
              .onAppear(() => {

                if (index >= this.memos.length - 5) {
                  this.loadMoreIfNeeded()
                }
              })
            }, (memo: Memo2, index: number) => `m_${memo.memoId ?? index}_${this.refreshTrigger}`)
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

        Text($r('app.string.online_search_load_no_more'))
          .fontSize(12)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(12)
      }
    }
    .layoutWeight(1)
    .width('100%')
    .backgroundColor($r('app.color.color_background'))
  }

  @Builder
  memoRowBuilder(memo: Memo2, index: number) {

    Column({ space: 8 }) {

      Text(memo.memoText ?? '')
        .fontSize(16)
        .width('100%')
        .padding({ left: 16, right: 16, top: 12 })

      Row() {

        Text(this.authorLabel(memo))
          .fontSize(12)
          .fontColor(memo.isSelfCreated() ? $r('app.color.color_detail') : $r('app.color.color_gray_dark'))
          .layoutWeight(1)

        if (memo.isSelfCreated()) {

          IconTintButton({
            icon: $r('app.media.trash'),
            iconSize: 22,
            onClickCallBack: () => {
              this.actionDeleteMemo(memo, index)
            }
          })

          Text('—')
            .fontSize(18)
            .opacity(0.4)
            .width(28)
        } else {

          Text(this.isMemoAdded(memo) ? '♥' : '♡')
            .fontSize(22)
            .width(36)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.actionToggleFavorite(memo, index)
            })
        }

        Text(`${memo.favCount ?? 0}`)
          .fontSize(12)
          .margin({ left: 4 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })
    }
    .width('100%')
    .backgroundColor($r('app.color.color_background'))
    .onClick(() => {

      if (!memo.isSelfCreated()) {
        this.actionToggleFavorite(memo, index)
      }
    })
  }

  private authorLabel(memo: Memo2): string {

    const base = getString($r('app.string.memo_author_txt'))

    if (memo.isSelfCreated()) {
      return `${base}: ${memo.userName ?? ''}(${getString($r('app.string.memo_author_self'))})`
    }

    return `${base}: ${memo.userName ?? ''}`
  }

  private actionSave(): void {

    logEvent('memo_save', { word: this.word.titleEn ?? '' })

    const trimmed = this.content.trim()

    // 仅简体且开启笔记审核时走 COS（与 iOS dLanguageCode + hans 一致，此处用语种管理简繁）
    if (LanguageManager.isSimpleChinese() && AppCfgManager.shared.isCosAuditCheckForMemo_is_ON()) {

      const auditor = new CosAuditor()

      auditor.audit(trimmed, (succeed: boolean, result: CosAuditResult, msg: string | null) => {

        // 审核服务失败则仍保存（与 iOS 一致）
        if (!succeed) {
          void this.doSave()
          return
        }

        // 判定不合规
        if (result !== CosAuditResult.Normal) {

          if (msg !== null && msg.length > 0) {
            Toast.showMessage(msg)
          } else {
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

  private async doSave(): Promise<void> {

    await ShareMemoManager2.shared.saveLocalMemo(this.content.trim(), this.word, (succeed: boolean) => {

      if (succeed) {
        Toast.showMessage($r('app.string.memo_msg_save_success'))
        ShareMemoManager2.shared.postNotification(false, this.word, this.wordIndexOnPage)
      }
    })
  }

  private actionSaveAndShare(): void {

    logEvent('memo_share', { word: this.word.titleEn ?? '' })

    // 需登录
    if (!UserManager.shared.isLogin()) {
      this.isShowLoginView = true
      return
    }

    // 网络
    if (!NetWorkTool.checkInternetConnection(true)) {
      return
    }

    const trimmed = this.content.trim()

    // 与 iOS 一致：分享分支只判断 AppCfg 开关（不区分简繁）
    if (AppCfgManager.shared.isCosAuditCheckForMemo_is_ON()) {

      const auditor = new CosAuditor()

      auditor.audit(trimmed, (succeed: boolean, result: CosAuditResult, msg: string | null) => {

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

  private async doSaveAndShare(): Promise<void> {

    Toast.showMessage($r('app.string.memo_msg_share_start'))

    ShareMemoManager2.shared.saveAndShareMemo(this.content.trim(), this.word, (succeed: boolean) => {

      if (succeed) {
        Toast.showMessage($r('app.string.memo_msg_share_success'))
        ShareMemoManager2.shared.postNotification(false, this.word, this.wordIndexOnPage)
        ShareMemoManager2.shared.postNotification(true, this.word, this.wordIndexOnPage)
        this.loadData()
      }
    })
  }

  private actionDeleteMemo(memo: Memo2, index: number): void {

    const memoId = memo.memoId

    if (memoId === null) {
      return
    }

    if (!NetWorkTool.checkInternetConnection(true)) {
      return
    }

    const next = [...this.memos]

    next.splice(index, 1)
    this.memos = next

    ShareMemoManager2.shared.removePublicMemoWithMemoId(memoId, (succeed: boolean) => {

      if (succeed) {
        Toast.showMessage($r('app.string.memo_msg_remove_share_success'))
        ShareMemoManager2.shared.postNotification(true, this.word, this.wordIndexOnPage)
      } else {
        this.loadData()
      }
    })
  }

  private actionToggleFavorite(memo: Memo2, index: number): void {

    if (this.isMemoAdded(memo)) {
      this.removeFavorite(memo, index)
    } else {
      this.addFavorite(memo, index)
    }
  }

  private removeFavorite(memo: Memo2, index: number): void {

    const memoId = memo.memoId

    if (memoId === null) {
      return
    }

    this.favoritedMemoIds = this.favoritedMemoIds.filter((id) => id !== memoId)

    const shareMemos = this.word.shareMemos

    if (shareMemos) {
      this.word.shareMemos = shareMemos.filter((d) =>
      (d[WordUser.KShareMemo_MemoId] ?? '') !== String(memoId))
    }

    const oldFav = memo.favCount ?? 0

    if (index < this.memos.length) {
      const arr = [...this.memos]
      arr[index] = this.memos[index].withFavCount(Math.max(oldFav - 1, 0))
      this.memos = arr
    }

    ShareMemoManager2.shared.removeLocalShareMemoFromWordWithMemoId(this.word, memoId, (succeed: boolean) => {

      if (succeed) {
        Toast.showMessage($r('app.string.memo_msg_remove_memo_success'))
        ShareMemoManager2.shared.postNotification(false, this.word, this.wordIndexOnPage)
      } else {
        this.favoritedMemoIds = [...this.favoritedMemoIds, memoId]

        if (shareMemos) {

          const restore: Record<string, string> = {}
          restore[WordUser.KShareMemo_MemoText] = memo.memoText ?? ''
          restore[WordUser.KShareMemo_AuthorName] = memo.userName ?? '-'
          restore[WordUser.KShareMemo_MemoId] = String(memoId)
          this.word.shareMemos = [...shareMemos, restore]
        }

        if (index < this.memos.length) {
          const arr = [...this.memos]
          arr[index] = this.memos[index].withFavCount(oldFav)
          this.memos = arr
        }

        this.loadData()
      }
    })
  }

  private addFavorite(memo: Memo2, index: number): void {

    const memoId = memo.memoId

    if (memoId === null) {
      return
    }

    const cur = this.word.shareMemos ?? []

    if (cur.length >= ShareMemoManager2.PrivateMemoLimit) {
      Toast.showMessage(
        getStringF($r('app.string.memo_msg_add_share_error'), ShareMemoManager2.PrivateMemoLimit))
      return
    }

    this.favoritedMemoIds = [...this.favoritedMemoIds, memoId]

    const newMemo: Record<string, string> = {}
    newMemo[WordUser.KShareMemo_MemoText] = memo.memoText ?? ''
    newMemo[WordUser.KShareMemo_AuthorName] = memo.userName ?? '-'
    newMemo[WordUser.KShareMemo_MemoId] = String(memoId)

    this.word.shareMemos = [...cur, newMemo]

    const oldFav = memo.favCount ?? 0

    if (index < this.memos.length) {
      const arr = [...this.memos]
      arr[index] = this.memos[index].withFavCount(oldFav + 1)
      this.memos = arr
    }

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

        this.loadData()
      }
    })
  }

  private loadData(): void {

    const wordEn = this.word.titleEn

    if (!wordEn) {
      return
    }

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

      if (loaded.length < ShareMemoManager2.FetchMemoLimit) {
        this.hasMoreData = false
      }

      if (loaded.length === 0) {
        Toast.showMessage($r('app.string.memo_msg_no_share_memo'))
      }
    })
  }

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

        if (loaded.length < ShareMemoManager2.FetchMemoLimit) {
          this.hasMoreData = false
        }

        resolve()
      })
    })

    this.isRefreshingList = false
  }

  private loadMoreIfNeeded(): void {

    const wordEn = this.word.titleEn

    if (!wordEn) {
      return
    }

    if (!NetWorkTool.checkInternetConnection(false)) {
      return
    }

    if (this.isLoadingMore || !this.hasMoreData) {
      return
    }

    const nextPage = this.loadedTimes + 1

    this.isLoadingMore = true

    ShareMemoManager2.shared.loadPublicMemosOfWord(wordEn, nextPage, (newMemos: Memo2[]) => {

      if (newMemos.length > 0) {
        this.memos = [...this.memos, ...newMemos]
        this.loadedTimes = nextPage

        if (newMemos.length < ShareMemoManager2.FetchMemoLimit) {
          this.hasMoreData = false
        }
      } else {
        this.hasMoreData = false
      }

      this.isLoadingMore = false
    })
  }

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
</think>
修复实现：`Memo2` 应用 `@Observed` 或可变副本；完善 `ComposeMemoView` 的 `addFavorite` 结尾；添加字符串资源；修正 `Memo2` 的可变更新方式。

<｜tool▁calls▁begin｜><｜tool▁call▁begin｜>
Read