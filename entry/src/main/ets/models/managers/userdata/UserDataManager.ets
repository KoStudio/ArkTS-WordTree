//
//  UserDataManager.ets
//  与 iOS `UserDataManager2.swift` 同一职责：Dcs user_data / user_data_ebook + 转调 CUserDataManager
//

import { UserData, UserDataCodingKeys, UserDataJson } from './UserData'
import { UserManager } from '../user/UserManager'
import { Route, Servers } from '../../networks/Server_Routes'
import { HttpUtils } from '../../networks/HttpUtils'
import { Http } from '../../networks/Http'
import { dAppName } from '../../../app/constants/AppDefines'
import { BookManager } from '../../datas/book/BookManager'
import { CUserDataManager } from './CUserData/CUserDataManager'
import { UserDataEBook, UserDataEBookJson, UserDataEBookKeys } from './UserDataEBook'


// MARK: - 用户数据管理器（对齐 iOS `UserDataManager2`）
export class UserDataManager {

  // MARK: - 用户数据加载

  /**
   * 获取当前书在 Dcs 上的用户数据记录。EBook 仅在有 serverEBookId 时才有备份，无则直接返回空。
   * （与 iOS `UserDataManager2.loadUserData` 一致：仅 `guard userId`、`guard book`，无单独 isLogin。）
   * @param completion 是否成功、消息、用户数据列表（JSON 行）
   */
  static loadUserData(completion: (succeed: boolean, msg: string | null, userDataJsons: UserDataJson[] | null) => void): void {

    const userId = UserManager.shared.userId

    // 与 iOS：`guard let userId = ... else { return }`（不回调）
    if (userId === null || userId === undefined) {
      return
    }

    const book = BookManager.shared.currentBook

    // 与 iOS：`guard let book = ... else { return }`
    if (!book) {
      return
    }

    // EBook 未备份过则无 serverEBookId，服务器上无对应 UserData，不发起请求
    if (book.isEBook && !book.hasServerEBookId) {
      completion(true, null, [])
      return
    }

    const bookId = book.hasServerEBookId ? (book.serverEBookId ?? 0) : (book.bookId ?? 0)

    const url                          = `${Servers.getRouteUrl(Route.user_data)}`
    const params: HttpUtils.HttpParams = {}

    params[UserDataCodingKeys.userId]  = userId.toString()
    params[UserDataCodingKeys.bookId]  = bookId.toString()
    params[UserDataCodingKeys.appName] = dAppName

    Http.request(url, HttpUtils.Method.GET, params, completion)
  }

  // MARK: - 数据上传 / 下载（转调 CUserDataManager）

  /**
   * 上传当前书用户数据（内部转调 CUserDataManager，learnDb/EBook 内容走 COS，路径写回 Dcs）
   * @param completion 是否成功、错误信息
   */
  static upload(completion: (succeed: boolean, msg: string | null) => void): void {

    CUserDataManager.upload(completion)
  }

  /**
   * 下载用户数据并解压到当前书目录（EBook 时先下 EBook 内容再 learnDb，均从 COS）
   * @param userData 云端一条备份记录
   * @param onProgress 下载进度（鸿蒙用 number；iOS 为 UInt）
   * @param completion 是否成功、错误信息
   */
  static download(
    userData: UserData,
    onProgress: (percent: number) => void,
    completion: (succeed: boolean, msg: string | null) => void
  ): void {

    CUserDataManager.download(userData, onProgress, completion)
  }

  // MARK: - user_data_ebook（与 iOS 顺序、语义一致）

  /**
   * 获取当前用户备份在 Dcs 上的 EBook 列表，用于「下载我备份的 EBook」列表页
   * @param completion 是否成功、消息、列表（失败时 iOS 为 nil，鸿蒙失败分支与列表解析策略一致）
   */
  static loadUserDataEBookList(
    completion: (succeed: boolean, msg: string | null, list: UserDataEBook[] | null) => void
  ): void {

    const userId = UserManager.shared.userId

    // 与 iOS：`guard let userId` 否则 not logged in
    if (userId === null || userId === undefined) {
      completion(false, 'not logged in', null)
      return
    }

    const url                          = `${Servers.getRouteUrl(Route.user_data_ebook)}/list`
    const params: HttpUtils.HttpParams = {}

    params[UserDataEBookKeys.userId]  = userId.toString()
    params[UserDataEBookKeys.appName] = dAppName

    Http.request<UserDataEBookJson>(url, HttpUtils.Method.GET, params,
      (succeed: boolean, msg: string | null, data: UserDataEBookJson[] | null) => {

        // 失败或空 data：列表页给空数组，避免 UI 判 null
        if (!succeed || data === null) {
          completion(succeed, msg, [])
          return
        }

        completion(true, null, UserDataEBook.fromJsonArray(data))
      })
  }

  /**
   * Dcs 创建 EBook 记录，返回 serverBookId（bookId）；服务端统一返回 { code, msg, data: [bookId] }
   * @param bookName 书名
   * @param textDbAddr 首次可为空
   * @param unitsCount 单元数
   * @param wordsCount 单词数
   * @param completion 是否成功、消息、服务端 bookId
   */
  static createEBookRecord(
    bookName: string | null,
    textDbAddr: string | null,
    unitsCount: number,
    wordsCount: number,
    completion: (succeed: boolean, msg: string | null, bookId: number | null) => void
  ): void {

    const userId = UserManager.shared.userId

    if (userId === null || userId === undefined) {
      completion(false, 'not logged in', null)
      return
    }

    const url                          = `${Servers.getRouteUrl(Route.user_data_ebook)}/create`
    const params: HttpUtils.HttpParams = {}

    params[UserDataEBookKeys.userId]      = userId.toString()
    params[UserDataEBookKeys.bookName]    = bookName ?? ''
    params[UserDataEBookKeys.textDbAddr]  = textDbAddr ?? ''
    params[UserDataEBookKeys.unitsCount]  = unitsCount
    params[UserDataEBookKeys.wordsCount]  = wordsCount
    params[UserDataEBookKeys.appName]     = dAppName

    Http.request<number>(url, HttpUtils.Method.POST, params,
      (succeed: boolean, msg: string | null, data: number[] | null) => {

        // 与 iOS：`completion(succeed, msg, data?.first)`
        if (!succeed || data === null || data.length < 1) {
          completion(succeed, msg, null)
          return
        }

        const raw = data[0]

        completion(true, null, typeof raw === 'number' ? raw : null)
      })
  }

  /**
   * Dcs 更新 EBook 元数据（每次备份后写回 bookName、textDbAddr、unitsCount、wordsCount）
   * @param bookId serverBookId
   * @param bookName 书名
   * @param textDbAddr COS 教材 zip 对象名等
   * @param unitsCount 单元数
   * @param wordsCount 单词数
   * @param completion 是否成功、消息
   */
  static updateEBookMeta(
    bookId: number,
    bookName: string | null,
    textDbAddr: string | null,
    unitsCount: number,
    wordsCount: number,
    completion: (succeed: boolean, msg: string | null) => void
  ): void {

    const userId = UserManager.shared.userId

    if (userId === null || userId === undefined) {
      completion(false, 'not logged in')
      return
    }

    const url                          = `${Servers.getRouteUrl(Route.user_data_ebook)}/update_meta`
    const params: HttpUtils.HttpParams = {}

    params[UserDataEBookKeys.userId]      = userId.toString()
    params[UserDataEBookKeys.bookId]     = bookId.toString()
    params[UserDataEBookKeys.bookName]   = bookName ?? ''
    params[UserDataEBookKeys.textDbAddr]  = textDbAddr ?? ''
    params[UserDataEBookKeys.unitsCount] = unitsCount
    params[UserDataEBookKeys.wordsCount] = wordsCount
    params[UserDataEBookKeys.appName]    = dAppName

    Http.send(url, HttpUtils.Method.POST, params, completion)
  }

  /**
   * Dcs 更新用户数据路径（learnDb zip 的 COS 路径写回）
   * （与 iOS 一致：`userId`/`bookId` 以数值提交，非字符串）
   * @param userId 用户 id
   * @param bookId 书 id
   * @param userDataAddr COS 对象名
   * @param completion 是否成功、消息
   */
  static updateUserData(
    userId: number,
    bookId: number,
    userDataAddr: string | null,
    completion: (succeed: boolean, msg: string | null) => void
  ): void {

    const url                          = `${Servers.getRouteUrl(Route.user_data)}/update`
    const params: HttpUtils.HttpParams = {}

    params[UserDataCodingKeys.userId]       = userId
    params[UserDataCodingKeys.bookId]       = bookId
    params[UserDataCodingKeys.userDataAddr] = userDataAddr ?? ''
    params[UserDataCodingKeys.appName]      = dAppName

    Http.send(url, HttpUtils.Method.POST, params, completion)
  }

  /**
   * Dcs 按 book_id + user_id 取一条 EBook 记录（含 textDbAddr）
   * @param bookId serverBookId
   * @param completion 是否成功、消息、记录列表
   */
  static getEBookRecord(
    bookId: number,
    completion: (succeed: boolean, msg: string | null, list: UserDataEBook[] | null) => void
  ): void {

    const userId = UserManager.shared.userId

    if (userId === null || userId === undefined) {
      completion(false, 'not logged in', null)
      return
    }

    const url                          = `${Servers.getRouteUrl(Route.user_data_ebook)}/get`
    const params: HttpUtils.HttpParams = {}

    params[UserDataEBookKeys.userId]  = userId.toString()
    params[UserDataEBookKeys.bookId]  = bookId.toString()
    params[UserDataEBookKeys.appName] = dAppName

    Http.request<UserDataEBookJson>(url, HttpUtils.Method.GET, params,
      (succeed: boolean, msg: string | null, data: UserDataEBookJson[] | null) => {

        if (!succeed || data === null) {
          completion(succeed, msg, null)
          return
        }

        completion(true, null, UserDataEBook.fromJsonArray(data))
      })
  }

  // MARK: - 扩展（iOS `UserDataManager2` 未暴露；与 `CUserDataManager.doDownloadLearnDb` 一致，供列表仅恢复 learnDb）

  /**
   * 仅从 COS 下载 learnDb zip 并解压
   * @param userData 备份记录（含 userDataAddr）
   * @param onProgress 下载进度
   * @param completion 是否成功、消息
   */
  static downloadLearnDbOnly(
    userData: UserData,
    onProgress: (progress: number) => void,
    completion: (succeed: boolean, msg: string | null) => void
  ): void {

    CUserDataManager.doDownloadLearnDb(userData, onProgress, completion)
  }
}
