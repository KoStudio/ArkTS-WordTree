import { LanguageManager } from '../../../common/components/Language/LanguageManager';
import { Http } from '../../networks/Http';
import { HttpUtils } from '../../networks/HttpUtils';
import { Servers, Route } from '../../networks/Server_Routes';
import { OnlineWord, OnlineWordConstant, CodingKeys } from './OnlineWord';

// MARK: - OnlineWordManager 管理器
export class OnlineWordManager {
  private static instance: OnlineWordManager | null = null

  private constructor() {
    // 私有构造函数
  }

  /// 获取单例实例
  static get shared(): OnlineWordManager {
    if (!OnlineWordManager.instance) {
      OnlineWordManager.instance = new OnlineWordManager()
    }
    return OnlineWordManager.instance
  }

  /// 查询单词详情
  loadWord(titleEn: string, completion: (success: boolean, msg: string | null, word: OnlineWord | null) => void): void {
    const params: HttpUtils.HttpParams = {}
    params[CodingKeys.TitleEn] = titleEn

    const isCurCnt = LanguageManager.isTraditionalChinese()
    const subRoute = isCurCnt ? "word_cnt" : "word_cns"
    const url = `${Servers.getRouteUrl(Route.word)}/${subRoute}`

    Http.request(url, HttpUtils.Method.GET, params, (succeed: boolean, msg: string | null, result: Object[] | null) => {
      if (!succeed || !result) {
        completion(false, msg, null)
        return
      }

      try {
        // 解析JSON数据
        const list = OnlineWord.fromArray(result)
        // 返回第一条数据
        completion(true, msg, list.length > 0 ? list[0] : null)
      } catch (error) {
        completion(false, `JSON解析失败: ${error}`, null)
      }
    })
  }

  /// 中英文模糊查询
  searchWords(text: string, pageIndex: number = 0, completion: (success: boolean, msg: string | null, words: OnlineWord[] | null) => void): void {
    const params: HttpUtils.HttpParams = {}
    params['text'] = text
    params[HttpUtils.Param.page] = pageIndex // 页面索引

    const isCurCnt = LanguageManager.isTraditionalChinese()
    const subRoute = isCurCnt ? "word_cnt" : "word_cns"
    const url = `${Servers.getRouteUrl(Route.search)}/${subRoute}`

    Http.request(url, HttpUtils.Method.GET, params, (succeed: boolean, msg: string | null, result: Object[] | null) => {
      if (!succeed || !result) {
        completion(false, msg, null)
        return
      }

      try {
        // 解析JSON数据
        const list = OnlineWord.fromArray(result)
        completion(true, msg, list)
      } catch (error) {
        completion(false, `JSON解析失败: ${error}`, null)
      }
    })
  }
  //
  // /// Promise版本的查询单词详情
  // async loadWordPromise(titleEn: string): Promise<{ success: boolean; msg: string | null; word: OnlineWord | null }> {
  //   return new Promise((resolve) => {
  //     this.loadWord(titleEn, (success, msg, word) => {
  //       resolve({ success, msg, word })
  //     })
  //   })
  // }
  //
  // /// Promise版本的中英文模糊查询
  // async searchWordsPromise(text: string, pageIndex: number = 0): Promise<{ success: boolean; msg: string | null; words: OnlineWord[] | null }> {
  //   return new Promise((resolve) => {
  //     this.searchWords(text, pageIndex, (success, msg, words) => {
  //       resolve({ success, msg, words })
  //     })
  //   })
  // }
}