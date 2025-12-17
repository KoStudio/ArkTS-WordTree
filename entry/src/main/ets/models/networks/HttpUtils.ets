import { getString } from "../../common/utils/ResourceUtils";
import { http } from "@kit.NetworkKit";

// 定义HTTP相关的枚举和常量
export namespace HttpUtils {


  // 1. 定义严格参数类型 - 避免any/unknown
  export type HttpParamValue = string | number | boolean | Object;
  export type HttpParams = Record<string, HttpParamValue> | null;


  /** 完整HTTP响应类型 */
  export interface HttpResponse<T> {
    succeed: boolean;
    msg: string | null;
    data: T[] | null; // 泛型数据
  }

  // 3. 定义API响应接口 - 使用明确类型替代any
  export interface ReceivedData<T> {
    code?: number;
    msg?: string;
    data?: T[];
  }

  // HTTP请求方法枚举
  export enum Method {
    GET    = "GET",
    POST   = "POST",
    DELETE = "DELETE",
    PUT    = "PUT"
  }


  // Http Header中的参数名
  export class Header {
    // 每次发起Http请求 都需要在Header中 加入下面这4个参数
    static readonly appKey: string    = "appkey";
    static readonly timestamp: string = "timestamp";
    static readonly sign: string      = "sign";   // MD5
    static readonly sign2: string     = "sign2";  // SHA256
    static readonly device: string    = "device";
  }

  // Http 参数名：
  export class Param {
    // 请求的分页参数名称
    static readonly page: string = "page";

  }

  export class ContentType {
    // 数据被编码为名称/值对。这是标准的编码格式。
    static readonly x_www_form_urlencoded: string = "application/x-www-form-urlencoded";

    // 数据被编码为一条消息，页上的每个控件对应消息中的一个部分。
    static readonly multipart: string = "multipart/form-data";

    // 数据以纯文本形式(text/json/xml/html)进行编码，其中不含任何控件或格式字符。postman软件里标的是RAW。
    static readonly textplain: string = "text/plain";
  }


  export class Functions {
    // MARK: - 根据Code判断是否成功
    /**
     * 根据Code判断是否成功
     * @param code 状态码，可选
     * @returns 返回是否成功
     */
    static succeed(code?: number): boolean {
      return (code !== undefined ? (code > 0) : true);
    }

    // MARK: - 根据Code返回本地化的消息
    /**
     * 根据Code返回本地化的消息
     * @param code 状态码，可选
     * @param serverMsg 服务端返回的原始消息（未本地化消息，也可能是Error）
     * @returns 返回本地化后的消息
     */
    static localizeMessage(code?: number, serverMsg?: string): string | undefined {
      let msg: string | undefined = serverMsg;

      switch (code) {
        case -402: msg = getString($r('app.string.server_code_m402')); break;
        case -405: msg = getString($r('app.string.server_code_m405')); break;
        case -406: msg = getString($r('app.string.server_code_m406')); break;
        case -410: msg = getString($r('app.string.server_code_m410')); break;
        case -701: msg = getString($r('app.string.server_code_m701')); break;
        case -702: msg = getString($r('app.string.server_code_m702')); break;
        default: msg = serverMsg;
      }

      return msg;
    }

    // 3. 枚举转换方法（核心修复）
    static toRequestMethod(method: Method): http.RequestMethod {
      // 4. 使用switch-case进行安全类型转换[1,2](@ref)
      switch (method) {
        case Method.GET:
          return http.RequestMethod.GET;
        case Method.POST:
          return http.RequestMethod.POST;
        case Method.PUT:
          return http.RequestMethod.PUT;
        case Method.DELETE:
          return http.RequestMethod.DELETE;
        default:
        // 5. 默认返回GET方法
          return http.RequestMethod.GET;
      }
    }
  }
}

