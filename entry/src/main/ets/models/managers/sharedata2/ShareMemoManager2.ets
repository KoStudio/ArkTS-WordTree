//
// ShareMemoManager2.ets
// WordTree (HarmonyOS)
//
// 与 iOS `ShareMemoManager2.swift`、Android `ShareMemoManager2.kt` 对齐：
// 笔记保存/分享、公开列表分页、本地收藏与收藏数更新。
//

import { AppSettings } from '../../../app/constants/AppSettings'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'
import { DeviceUtil } from '../../../common/utils/DeviceUtils'
import { Http } from '../../networks/Http'
import { HttpUtils } from '../../networks/HttpUtils'
import { Route, Servers } from '../../networks/Server_Routes'
import { BookManager } from '../../datas/book/BookManager'
import { WordUser } from '../../datas/myData/WordUser'
import { WordUserDbAccess } from '../../datas/myData/WordUserDbAccess'
import { UserManager } from '../user/UserManager'
import { Memo2 } from './Memo2'

// Notification.Name / UserInfoKey（与 iOS `ShareMemoManager2.Notification` 字符串一致）
export namespace ShareMemoManager2Notification {

  export namespace Name {

    export const PrivateChanged: string = 'ShareMemoManager2_Notification_Private_Changed'
    export const PublicChanged: string = 'ShareMemoManager2_Notification_Public_Changed'
  }

  export namespace UserInfoKey {

    export const Word: string = 'Notification_userInfo_key_word'
    export const WordIndexOnPage: string = 'Notification_userInfo_key_wordIndexOnPage'
  }
}

// SimpleEventBus 负载（对应 Notification userInfo）
export interface ShareMemoNotificationPayload {

  word           : WordUser
  wordIndexOnPage: number
}

export class ShareMemoManager2 {

  // 每页 20 条数据，与服务器端一致
  static readonly FetchMemoLimit: number = 20
  // 每个单词最多收藏 5 条笔记
  static readonly PrivateMemoLimit: number = 5
  // 笔记字数限制
  static readonly MemoLetterLimit: number = 500
  // 自笔记 MemoId（与 loadLocalMemosOfWord 中的 "999999999" 对齐）
  static readonly PrivateMemoId: string = '999999999'

  private static instance: ShareMemoManager2 | null = null

  // 单例
  static get shared(): ShareMemoManager2 {

    if (!ShareMemoManager2.instance) {
      ShareMemoManager2.instance = new ShareMemoManager2()
    }

    return ShareMemoManager2.instance
  }

  // 禁止外部构造
  private constructor() {
  }

  // 切回主线程回调（对齐 iOS DispatchQueue.main.async）
  private runOnMain(block: () => void): void {

    setTimeout(block, 0)
  }

  // publicChanged：true 发公开列表变更；word：关联单词；wordIndexOnPage：卡片页内索引
  postNotification(publicChanged: boolean, word: WordUser, wordIndexOnPage: number): void {

    const name = publicChanged ? ShareMemoManager2Notification.Name.PublicChanged :
      ShareMemoManager2Notification.Name.PrivateChanged

    const payload: ShareMemoNotificationPayload = {
      word: word,
      wordIndexOnPage: wordIndexOnPage
    }

    SimpleEventBus.emit(name, payload)
  }

  // MARK: - Save & Share Memo

  // 保存本地笔记；memoText：正文；word：当前词条；finished：是否成功
  async saveLocalMemo(memoText: string, word: WordUser, finished: (succeed: boolean) => void): Promise<void> {

    word.memo = memoText

    try {

      await WordUserDbAccess.shared.saveWordUser(word)

      this.runOnMain(() => {
        finished(true)
      })
    } catch (_e) {

      this.runOnMain(() => {
        finished(false)
      })
    }
  }

  // 分享笔记到服务器；memoText：正文；word：当前词条；finished：是否成功
  shareMemo(memoText: string, word: WordUser, finished: (succeed: boolean) => void): void {

    const wordEn = word.titleEn

    // 缺少单词英文
    if (!wordEn || wordEn.length === 0) {
      this.runOnMain(() => {
        finished(false)
      })
      return
    }

    const userId = UserManager.shared.userId

    // 未登录
    if (userId === null) {
      this.runOnMain(() => {
        finished(false)
      })
      return
    }

    const userName = UserManager.shared.userName ?? ''
    const book = BookManager.shared.currentBook

    // 无当前课本
    if (!book) {
      this.runOnMain(() => {
        finished(false)
      })
      return
    }

    const bookId = book.bookId
    const bookName = book.bookName ?? ''

    // 缺少 bookId
    if (bookId === null) {
      this.runOnMain(() => {
        finished(false)
      })
      return
    }

    const url = Servers.getRouteUrl(Route.memo)

    const params: HttpUtils.HttpParams = {}

    params['book_id'] = bookId
    params['book_name'] = bookName
    params['word_en'] = wordEn
    params['memo_text'] = memoText
    params['user_id'] = String(userId)
    params['user_name'] = userName
    params['device_idfv'] = DeviceUtil.getStableUUID()
    params['device_type'] = AppSettings.App.deviceType
    params['sns_type'] = UserManager.shared.loginType !== null ?
      String(UserManager.shared.loginType) : ''

    // POST 提交分享
    Http.send(url, HttpUtils.Method.POST, params, (succeed: boolean, _msg: string | null) => {

      this.runOnMain(() => {
        finished(succeed)
      })
    })
  }

  // 保存并分享笔记
  saveAndShareMemo(memoText: string, word: WordUser, finished: (succeed: boolean) => void): void {

    void this.saveLocalMemo(memoText, word, (ok: boolean) => {

      // 本地未写入成功则不再请求分享
      if (!ok) {
        finished(false)
        return
      }

      this.shareMemo(memoText, word, finished)
    })
  }

  // MARK: - Load Memos

  // 加载公开笔记列表（分页）；wordEn：单词；page：页码（从 0 起）；finished：列表
  loadPublicMemosOfWord(wordEn: string, page: number, finished: (memos: Memo2[]) => void): void {

    const url = Servers.getRouteUrl(Route.memo)

    const params: HttpUtils.HttpParams = {}

    params['word_en'] = wordEn
    params['page'] = page

    Http.request(url, HttpUtils.Method.GET, params,
      (succeed: boolean, _msg: string | null, data: Object[] | null) => {

        this.runOnMain(() => {

          // 请求失败或空数据
          if (!succeed || !data) {
            finished([])
            return
          }

          const memos = data.map((o) => new Memo2(o as Record<string, Object>))

          const sorted: Memo2[] = []
          const curId = UserManager.shared.userId

          // 已登录：自己的笔记排最前
          if (curId !== null) {

            const selfMemo = memos.find((m) => m.userId === curId)

            if (selfMemo !== undefined) {
              sorted.push(selfMemo)
            }

            for (const m of memos) {

              if (m.userId !== curId) {
                sorted.push(m)
              }
            }
          } else {

            sorted.push(...memos)
          }

          finished(sorted)
        })
      })
  }

  // 加载本地笔记（收藏的 + 自己的一条虚拟项用单独 UI 处理时可参考；与 iOS 一致返回字典列表）
  loadLocalMemosOfWord(word: WordUser, finished: (localMemos: Array<Record<string, string>>) => void): void {

    const localMemos: Array<Record<string, string>> = []

    const shared = word.shareMemos

    // 从收藏的分享笔记
    if (shared && shared.length > 0) {
      localMemos.push(...shared)
    }

    const memo = word.memo

    // 本地笔记（自己添加的）
    if (memo !== null && memo.length > 0) {

      const selfMemo: Record<string, string> = {}

      selfMemo[WordUser.KShareMemo_MemoText] = memo
      selfMemo[WordUser.KShareMemo_AuthorName] = 'Self'
      selfMemo[WordUser.KShareMemo_MemoId] = ShareMemoManager2.PrivateMemoId

      localMemos.splice(0, 0, selfMemo)
    }

    this.runOnMain(() => {
      finished(localMemos)
    })
  }

  // MARK: - Add & Remove Local Memos

  // 添加收藏的分享笔记
  addLocalShareMemo(memo: Memo2, word: WordUser, finished: (succeed: boolean) => void): void {

    if (!word.shareMemos) {
      word.shareMemos = []
    }

    // 已达上限
    if (word.shareMemos.length >= ShareMemoManager2.PrivateMemoLimit) {
      this.runOnMain(() => {
        finished(false)
      })
      return
    }

    const memoId = memo.memoId

    // 无效 id
    if (memoId === null) {
      this.runOnMain(() => {
        finished(false)
      })
      return
    }

    const newMemo: Record<string, string> = {}

    newMemo[WordUser.KShareMemo_MemoText] = memo.memoText ?? ''
    newMemo[WordUser.KShareMemo_AuthorName] = memo.userName ?? '-'
    newMemo[WordUser.KShareMemo_MemoId] = String(memoId)

    word.shareMemos = [...word.shareMemos, newMemo]

    void WordUserDbAccess.shared.saveWordUser(word).then(() => {

      // 收藏数 +1
      this.incrementFavCount(1, memoId, (_ok: boolean) => {

        this.runOnMain(() => {
          finished(true)
        })
      })
    }).catch(() => {

      this.runOnMain(() => {
        finished(false)
      })
    })
  }

  // 删除本地自己的笔记正文（清空 memo 字段）
  async removeLocalSelfMemoFromWord(word: WordUser, finished: (succeed: boolean) => void): Promise<void> {

    word.memo = null

    try {

      await WordUserDbAccess.shared.saveWordUser(word)

      this.runOnMain(() => {
        finished(true)
      })
    } catch (_e) {

      this.runOnMain(() => {
        finished(false)
      })
    }
  }

  // 删除收藏的笔记（通过索引）；indexOfLocalMemos：shareMemos 下标
  removeLocalShareMemoFromWordByIndex(word: WordUser, indexOfLocalMemos: number,
    finished: (succeed: boolean) => void): void {

    const shareMemos = word.shareMemos

    // 无收藏列表或下标越界
    if (!shareMemos || indexOfLocalMemos >= shareMemos.length) {
      this.runOnMain(() => {
        finished(false)
      })
      return
    }

    const memoIdStr = shareMemos[indexOfLocalMemos][WordUser.KShareMemo_MemoId]
    const memoId = memoIdStr !== undefined ? parseInt(memoIdStr, 10) : Number.NaN

    // 无法解析 memo_id
    if (Number.isNaN(memoId)) {
      this.runOnMain(() => {
        finished(false)
      })
      return
    }

    const next = [...shareMemos]

    next.splice(indexOfLocalMemos, 1)
    word.shareMemos = next

    void WordUserDbAccess.shared.saveWordUser(word).then(() => {

      // 收藏数 -1
      this.incrementFavCount(-1, memoId, (_ok: boolean) => {

        this.runOnMain(() => {
          finished(true)
        })
      })
    }).catch(() => {

      this.runOnMain(() => {
        finished(false)
      })
    })
  }

  // 删除收藏的笔记（通过 memoId）
  removeLocalShareMemoFromWordWithMemoId(word: WordUser, memoId: number,
    finished: (succeed: boolean) => void): void {

    const shareMemos = word.shareMemos

    // 无收藏列表
    if (!shareMemos) {
      this.runOnMain(() => {
        finished(false)
      })
      return
    }

    let removeIdx = -1

    for (let i = 0; i < shareMemos.length; i++) {

      const mid = shareMemos[i][WordUser.KShareMemo_MemoId]
      const v = mid !== undefined ? parseInt(mid, 10) : Number.NaN

      if (!Number.isNaN(v) && v === memoId) {
        removeIdx = i
        break
      }
    }

    // 未找到
    if (removeIdx < 0) {
      this.runOnMain(() => {
        finished(false)
      })
      return
    }

    const next = [...shareMemos]

    next.splice(removeIdx, 1)
    word.shareMemos = next

    void WordUserDbAccess.shared.saveWordUser(word).then(() => {

      // 收藏数 -1
      this.incrementFavCount(-1, memoId, (_ok: boolean) => {

        this.runOnMain(() => {
          finished(true)
        })
      })
    }).catch(() => {

      this.runOnMain(() => {
        finished(false)
      })
    })
  }

  // 从服务器删除公开笔记
  removePublicMemoWithMemoId(memoId: number, finished: (succeed: boolean) => void): void {

    const url = `${Servers.getRouteUrl(Route.memo)}/${memoId}`

    Http.send(url, HttpUtils.Method.DELETE, null, (succeed: boolean, _msg: string | null) => {

      this.runOnMain(() => {
        finished(succeed)
      })
    })
  }

  // MARK: - Update Fav Count

  // 更新点赞/收藏数量（增量）；amount：+1 / -1；memoId：笔记 id
  incrementFavCount(amount: number, memoId: number, finished: (succeed: boolean) => void): void {

    const url = `${Servers.getRouteUrl(Route.memo)}/fav`

    const params: HttpUtils.HttpParams = {}

    params['memo_id'] = memoId
    params['fav_count'] = amount

    Http.send(url, HttpUtils.Method.POST, params, (succeed: boolean, _msg: string | null) => {

      this.runOnMain(() => {
        finished(succeed)
      })
    })
  }
}
