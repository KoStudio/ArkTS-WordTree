import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HttpUtils } from './HttpUtils';
import { Servers } from './Server_Routes';
import { StringCrypto } from '../../common/utils/strings/StringCrypto';
import { DebugLog } from '../../app/debug/DebugLog';
import { StringEncoder } from '../../common/utils/strings/StringEncrypt';


// HTTP工具类（完全静态方法）
export class Http {
  /**
   * 发送HTTP请求的快捷方法
   * @param url 请求地址
   * @param method 请求方法，默认GET
   * @param params 请求参数，默认null
   * @param callback 回调函数，返回成功状态和错误信息
   */
  static send(
    url: string,
    method: HttpUtils.Method = HttpUtils.Method.GET, // 默认GET请求
    params: HttpUtils.HttpParams = null, // 可选参数
    callback: (succeed: boolean, msg: string | null) => void
  ) {
    // 调用底层HTTP模块，忽略返回的data字段
    Http.request(url, method, params, (succeed: boolean, msg: string | null, data: Object[] | null) => { ///这里的data返回值为空，所以Object[]只是占位处理
      callback(succeed, msg); // 透传结果
    });
  }

  /**
   * 发起HTTP请求（返回数组数据）
   * @param url 请求URL
   * @param method HTTP方法
   * @param params 请求参数
   * @param callback 回调函数
   */
  static request<T>(
    url: string,
    method: HttpUtils.Method = HttpUtils.Method.GET,
    params: HttpUtils.HttpParams = null,
    callback: (succeed: boolean, msg: string | null, data: T[] | null) => void
  ): void {
    Http._request(url, method, params, (responseData: string | null) => {
      if (!responseData) {
        callback(false, "响应数据为空", null);
        return;
      }

      try {
        // 4. 使用类型断言替代any - 符合ArkTS规范
        const jsonData: HttpUtils.ReceivedData<T> = JSON.parse(responseData) as HttpUtils.ReceivedData<T>;

        // 5. 运行时类型校验（增强安全性）
        // if (typeof jsonData.code === 'number' && typeof jsonData.msg === 'string') {
          const succeedCode = Http._isSucceed(jsonData.code);
          const msg         = Http._localizedMsg(jsonData.code, jsonData.msg)
          callback(succeedCode, msg, jsonData.data ?? null);
        // } else {
        //   callback(false, "无效的响应格式", null);
        // }
      } catch (error) {
        // 6. 安全类型转换（避免any）
        const errMsg = (error as Error).message;
        callback(false, `JSON解析失败: ${errMsg}`, null);
      }
    });
  }

  /**
   * 发起HTTP请求（仅返回操作结果）
   * @param url 请求URL
   * @param method HTTP方法
   * @param params 请求参数
   * @param callback 回调函数
   */
  static async requestPromise<T>(
    url: string,
    method: HttpUtils.Method = HttpUtils.Method.GET,
    params: HttpUtils.HttpParams = null
  ): Promise<HttpUtils.HttpResponse<T>> {

    const responseData = await Http._requestPromise(url, method, params)
    if (responseData) {
      const jsonData: HttpUtils.ReceivedData<T> = JSON.parse(responseData) as HttpUtils.ReceivedData<T>;

      // if (typeof jsonData.code === 'number' && typeof jsonData.msg === 'string') {
        const succeedCode = Http._isSucceed(jsonData.code);
        const msg         = Http._localizedMsg(jsonData.code, jsonData.msg)
        return {succeed: succeedCode, msg: msg, data: jsonData.data ?? null}
      // } else {
      //   ///无效的响应格式
      //   return {succeed: false, msg: "无效的响应格式", data: null}
      // }
    }

    return {succeed: false, msg: "Response data is null", data: null}
  }



  // 私有方法：执行实际HTTP请求
  private static _request(
    url: string,
    method: HttpUtils.Method,
    params: HttpUtils.HttpParams,
    callback: (responseData: string | null) => void
  ): void {
    const httpRequest = http.createHttp();

    let finalUrl = url;
    let requestParams: string | null = null;

    // GET请求处理查询参数
    if (method === HttpUtils.Method.GET && params) {
      finalUrl = `${url}?${Http._buildQueryString(params)}`;
    } else if (params) {
      requestParams = JSON.stringify(params);
    }

    DebugLog.d(`[HTTP] ${finalUrl} [${method}]`);

    Http._createHeaders().then((headers) => {
      // 发送HTTP请求
      httpRequest.request(
        finalUrl,
        {
          method: HttpUtils.Functions.toRequestMethod(method),
          extraData: requestParams,
          expectDataType: http.HttpDataType.STRING, // 确保返回字符串
          header: headers ,
          connectTimeout: 10000, // 10秒连接超时
          readTimeout: 10000      // 10秒读取超时
        },
        (err: BusinessError, data: http.HttpResponse) => {
          // 销毁请求对象释放资源
          httpRequest.destroy();

          if (err) {
            DebugLog.e(`[HTTP] 请求失败: ${JSON.stringify(err)}`);
            callback(null);
          } else {
            // 处理响应数据
            if (data.resultType === http.HttpDataType.STRING) {
              callback(data.result as string);
            } else {
              DebugLog.e('[HTTP] 响应类型不是字符串');
              callback(null);
            }
          }
        }
      );
    })
      .catch((err: Error)=>{
        DebugLog.e(`[HTTP] create header error: ${err.message}`);
        callback(null);
      })

  }

  // MARK: - 核心请求方法
  /**
   * 执行实际HTTP请求（Promise封装）
   * @param url 请求URL
   * @param method HTTP方法
   * @param params 请求参数
   * @returns Promise封装的响应数据
   */
  private static async _requestPromise(
    url: string,
    method: HttpUtils.Method,
    params: HttpUtils.HttpParams
  ): Promise<string | null> {
    const httpRequest = http.createHttp();  // 创建HTTP请求实例
    let finalUrl = url;
    let requestParams: string | null = null;

    // 1. 处理GET请求参数
    if (method === HttpUtils.Method.GET && params) {
      finalUrl = `${url}?${Http._buildQueryString(params)}`;
    } else if (params) {
      requestParams = JSON.stringify(params);
    }

    DebugLog.d(`[HTTP] ${finalUrl} [${method}]`);

    try {
      // 2. 创建请求头 [6](@ref)
      const headers = await Http._createHeaders();

      // 3. 发送HTTP请求 [7](@ref)
      const responsePromise: Promise<http.HttpResponse> = httpRequest.request(
        finalUrl,
        {
          method: HttpUtils.Functions.toRequestMethod(method),
          extraData: requestParams,
          expectDataType: http.HttpDataType.STRING,
          header: headers,
          connectTimeout: 10000,
          readTimeout: 10000
        }
      );

      const response = await responsePromise;

      // 4. 处理响应数据
      if (response.resultType === http.HttpDataType.STRING) {
        return response.result as string;
      } else {
        DebugLog.e('[HTTP] 响应类型不是字符串');
        return null;
      }
    } catch (err) {
      // 5. 错误处理
      const businessErr = err as BusinessError;
      DebugLog.e(`[HTTP] 请求失败: ${JSON.stringify(businessErr)}`);
      return null;
    } finally {
      // 6. 确保资源释放 [8](@ref)
      httpRequest.destroy();
    }
  }


  // 构建查询字符串
  private static _buildQueryString(params: HttpUtils.HttpParams): string {
    if (!params) return '';

    return Object.keys(params)
      .map(key => {
        const value = params[key];
        // 安全编码参数
        return `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`
      })
      .join('&');
  }

  // 判断请求是否成功（根据业务状态码）
  private static _isSucceed(code?: number): boolean {
    //return code >= 200 && code < 300;
    return HttpUtils.Functions.succeed(code)
  }

  private static _localizedMsg(code?: number, msg?: string): string | null {
    return HttpUtils.Functions.localizeMessage(code, msg) ?? null
  }

  private static async _createHeaders(): Promise<Record<string, string>> {
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const signString = `${StringEncoder.decodeAfterRemoveSalt(Servers.Secure.appKey)}${timestamp}${StringEncoder.decodeAfterRemoveSalt(Servers.Secure.appSecret)}`;
    const sign = await StringCrypto.md5(signString)
    const deviceType = 'Android'

    // 创建一个空对象
    const headers: Record<string, string> = {};

    // 使用方括号语法添加属性，这样即使属性名不是标识符也可以
    headers[HttpUtils.Header.appKey]    = StringEncoder.decodeAfterRemoveSalt(Servers.Secure.appKey)||'';
    headers[HttpUtils.Header.timestamp] = timestamp;
    headers[HttpUtils.Header.sign]      = sign;
    headers[HttpUtils.Header.device]    = deviceType;
    headers['Content-Type']             = 'application/json';

    return headers;
  }

}
