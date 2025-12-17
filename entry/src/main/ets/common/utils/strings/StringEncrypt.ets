import util from '@ohos.util';
import { buffer } from '@kit.ArkTS';


/**
 * 字符串扩展工具类
 * 提供Base64编码/解码和加盐/去盐功能
 */
export class StringEncoder {
  /**
   * 将字符串进行Base64编码
   * @param str 要编码的字符串
   * @returns Base64编码后的字符串或null
   */
  static encodedToBase64(str: string | null): string | null {
    return new Base64Encoder(str).encodedString();
  }

  /**
   * 将Base64字符串解码
   * @param str Base64编码的字符串
   * @returns 解码后的原始字符串或null
   */
  static decodedFromBase64(str: string | null): string | null {
    return new Base64Encoder(str).decodedString();
  }

  /**
   * 给字符串添加随机盐值
   * @param str 要加盐的字符串
   * @returns 加盐后的字符串或null
   */
  static addedSalt(str: string | null): string | null {
    return SaltUtil.addSalt(str);
  }

  /**
   * 从字符串中去除盐值
   * @param str 加了盐的字符串
   * @returns 去除盐值后的字符串或null
   */
  static removedSalt(str: string | null): string | null {
    return SaltUtil.removeSalt(str);
  }

  /**
   * 先进行Base64编码再加盐
   * @param str 要处理的字符串
   * @returns 处理后的字符串或null
   */
  static encodeAndAddSalt(str: string | null): string | null {
    const encoded = StringEncoder.encodedToBase64(str);
    return encoded ? StringEncoder.addedSalt(encoded) : null;
  }

  /**
   * 先去盐再进行Base64解码
   * @param str 要处理的字符串
   * @returns 处理后的字符串或null
   */
  static decodeAfterRemoveSalt(str: string | null): string | null {
    const withoutSalt = StringEncoder.removedSalt(str);
    return withoutSalt ? StringEncoder.decodedFromBase64(withoutSalt) : null;
  }
}



/**
 * Base64 编码解码器
 * 提供字符串与Base64格式之间的相互转换功能
 */
export class Base64Encoder {
  // 要编码或解码的字符串
  private str: string | null;

  /**
   * 构造函数
   * @param str 要处理的字符串，可为null
   */
  constructor(str: string | null) {
    this.str = str;
  }

  /**
   * 将Base64字符串解码为原始字符串
   * @returns 解码后的字符串，如果输入无效则返回null
   */
  decodedString(): string | null {
    if (!this.str) {
      return null;
    }

    try {
      const base64 = new util.Base64Helper();
      const decodedData = base64.decodeSync(this.str);

      // 将Uint8Array转为字符串
      return this.uint8ArrayToString(decodedData);
    } catch (err) {
      console.error(`Base64解码失败: ${err}`);
      return null;
    }
  }

  /**
   * 将字符串编码为Base64格式
   * @returns Base64编码后的字符串，如果输入无效则返回null
   */
  encodedString(): string | null {
    if (!this.str) {
      return null;
    }

    try {
      const base64 = new util.Base64Helper();
      const data = this.stringToUint8Array(this.str);
      return base64.encodeToStringSync(data);
    } catch (err) {
      console.error(`Base64编码失败: ${err}`);
      return null;
    }
  }

  /**
   * 字符串转Uint8Array
   * @param str 要转换的字符串
   * @returns Uint8Array
   */
  private stringToUint8Array(str: string): Uint8Array {
    // 方案1：推荐使用buffer.from（API 9+）
    return new Uint8Array(buffer.from(str, 'utf-8').buffer);

    // 方案2：TextEncoder标准方案（需处理缓冲区）
    // const encoder = new util.TextEncoder('utf-8');
    // const arr = new Uint8Array(encoder.getEncodedLength(str));
    // encoder.encodeIntoUint8Array(str, arr);
    // return arr;
  }

  /**
   * Uint8Array转字符串
   * @param arr 要转换的Uint8Array
   * @returns 字符串
   */
  private uint8ArrayToString(data: Uint8Array): string {
    // let str = '';
    // for (let i = 0; i < data.length; i++) {
    //   str += String.fromCharCode(data[i]);
    // }
    // return decodeURIComponent(escape(str)); // 关键转换步骤

    // const decoder = util.TextDecoder.create('utf-8', {
    //   fatal: false,
    //   ignoreBOM: true
    // });
    // return decoder.decodeToString(data, { stream: false });

    return buffer.from(data.buffer).toString('utf-8');
  }


}


/**
 * 加盐工具类，提供字符串加盐和去盐功能
 * 用于增强字符串的安全性，防止简单解码
 */
export class SaltUtil {
  // 盐值字符集，包含大小写字母和数字
  private static readonly SALT_CHARS: string =
    "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

  /**
   * 给字符串添加随机盐值
   * @param str 要加盐的原始字符串，可为null
   * @param saltCount 盐值字符数量，默认为2
   * @returns 加盐后的字符串，如果输入为null则返回null
   *
   * @example
   * const original = "sensitiveData";
   * const salted = SaltUtil.addSalt(original); // 如"xysensitiveData"
   */
  static addSalt(str: string | null, saltCount: number = 2): string | null {
    // 如果输入字符串为null或undefined，直接返回null
    if (!str) {
      return null;
    }

    let salt = "";
    const charsLength = SaltUtil.SALT_CHARS.length;

    // 生成指定数量的随机盐值字符
    for (let i = 0; i < saltCount; i++) {
      // 生成随机索引
      const randomIndex = Math.floor(Math.random() * charsLength);
      // 从字符集中获取随机字符
      salt += SaltUtil.SALT_CHARS.charAt(randomIndex);
    }

    // 返回盐值+原始字符串的组合
    return salt + str;
  }

  /**
   * 从字符串中去除盐值
   * @param str 加了盐的字符串，可为null
   * @param saltCount 盐值字符数量，默认为2
   * @returns 去除盐值后的原始字符串，如果输入为null或空则原样返回
   *
   * @example
   * const salted = "xysensitiveData";
   * const original = SaltUtil.removeSalt(salted); // "sensitiveData"
   */
  static removeSalt(str: string | null, saltCount: number = 2): string | null {
    // 如果输入字符串为null、undefined或空字符串，直接返回
    if (!str) {
      return str;
    }

    // 去除前saltCount个字符（盐值）
    return str.substring(saltCount);
  }
}
