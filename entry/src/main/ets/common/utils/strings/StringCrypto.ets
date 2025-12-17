
//import cryptoFramework from '@ohos.security.cryptoFramework';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import buffer from '@ohos.buffer';

/**
 * 加密工具类 (Stage 模型)
 * 提供字符串的 SHA1、SHA256 和 MD5 哈希计算功能（Promise模式）
 * 所有方法直接返回Promise，无需回调函数
 */
export class StringCrypto {

  /**
   * 计算字符串的 SHA1 哈希值
   * @param input 输入字符串
   * @returns 十六进制格式的哈希值
   */
  static async sha1(input: string): Promise<string> {
    return StringCrypto._computeHash(input, 'SHA1');
  }

  /**
   * 计算字符串的 SHA256 哈希值
   * @param input 输入字符串
   * @returns 十六进制格式的哈希值
   */
  static async sha256(input: string): Promise<string> {
    return StringCrypto._computeHash(input, 'SHA256');
  }

  /**
   * 计算字符串的 MD5 哈希值
   * @param input 输入字符串
   * @returns 十六进制格式的哈希值
   */
  static async md5(input: string): Promise<string> {
    return StringCrypto._computeHash(input, 'MD5');
  }

  /**
   * 私有方法：通用哈希计算（Promise实现）
   * @param input 输入字符串
   * @param algorithm 哈希算法
   * @returns 十六进制格式的哈希值
   */
  private static async _computeHash(
    input: string,
    algorithm: string
  ): Promise<string> {
    try {
      // 1. 创建哈希实例
      const hash = cryptoFramework.createMd(algorithm);

      // 2. 使用Buffer进行UTF-8编码（兼容ArkTS类型系统）
      const encodedData: Uint8Array = new Uint8Array(buffer.from(input, 'utf-8').buffer);

      // 3. 创建DataBlob对象
      const dataBlob: cryptoFramework.DataBlob = {
        data: encodedData
      };

      // 4. 链式异步操作：更新数据 → 计算摘要
      await hash.update(dataBlob);
      const digest = await hash.digest();

      // 5. 转换为十六进制字符串并返回
      return StringCrypto._toHexString(digest.data);

    } catch (error) {
      // 6. 统一错误处理
      throw new Error(`哈希计算失败: ${error instanceof Error ? error.message : '未知错误'}`);
    }
  }

  /**
   * 私有方法：字节数组转十六进制字符串
   * @param bytes Uint8Array字节数组
   * @returns 十六进制字符串
   */
  private static _toHexString(bytes: Uint8Array): string {
    return Array.from(bytes)
      .map(byte => byte.toString(16).padStart(2, '0'))
      .join('');
  }
}

// import cryptoFramework from '@ohos.security.cryptoFramework';
// import buffer from '@ohos.buffer';
//
// /**
//  * 加密工具类 (Stage 模型)
//  * 提供字符串的 SHA1、SHA256 和 MD5 哈希计算功能（回调模式）
//  */
// export class StringCrypto {
//
//   static sha1(input: string, callback: (error: Error | null, result: string | null) => void): void {
//     StringCrypto._computeHash(input, 'sha1', callback);
//   }
//
//   static sha256(input: string, callback: (error: Error | null, result: string | null) => void): void {
//     StringCrypto._computeHash(input, 'sha256', callback);
//   }
//
//   static md5(input: string, callback: (error: Error | null, result: string | null) => void): void {
//     StringCrypto._computeHash(input, 'md5', callback);
//   }
//
//   private static _computeHash(
//     input: string,
//     algorithm: string,
//     callback: (error: Error | null, result: string | null) => void
//   ): void {
//     try {
//       const hash = cryptoFramework.createMd(algorithm);
//
//       // ✅ 显式类型注解，避免 ArkTS 检查错误
//       const encodedData: Uint8Array = new Uint8Array(buffer.from(input, 'utf-8').buffer);
//
//       const dataBlob: cryptoFramework.DataBlob = {
//         data: encodedData
//       };
//
//       hash.update(dataBlob)
//         .then(() => hash.digest())
//         .then(digest => {
//           const hexResult = StringCrypto._toHexString(digest.data);
//           callback(null, hexResult);
//         })
//         .catch((err: Error) => {
//           callback(new Error(`哈希计算失败: ${(err as Error).message}`), null);
//         });
//
//     } catch (error) {
//       callback(error as Error, null);
//     }
//   }
//
//   private static _toHexString(bytes: Uint8Array): string {
//     return Array.from(bytes)
//       .map(byte => byte.toString(16).padStart(2, '0'))
//       .join('');
//   }
// }