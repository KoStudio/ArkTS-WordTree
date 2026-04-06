//
// CosUtils.ets
// WordTree (HarmonyOS)
//
// COS / 数据万象 CI 侧 HTTPS + V5 签名的工具方法（无单例状态）。
// 与 `CosXmlBaseService` 上传下载并存：后者覆盖 SDK 封装好的对象接口；
// 文本审核、图片审核等 CI REST 在鸿蒙 COS SDK 文档中无对等高级 API，
// 且业务模块无法 import 内嵌包 `@tencentcloud/foundation`，故在此用系统加解密与 http 实现与文档 7778 一致的签名。
//

import buffer from '@ohos.buffer';
import { BusinessError } from '@kit.BasicServicesKit';
import cryptoFramework from '@ohos.security.cryptoFramework';
import http from '@ohos.net.http';
import { QCloudCredential } from '@tencentcloud/cos';
import { StringEncoder } from '../../../../../utils/strings/StringEncrypt';
import { CosConfig, CurrentBucket } from './CosConstants';

const COS_TOKEN_HEADER = 'x-cos-security-token';

// 腾讯云 COS 签名用 URL 编码（与 SDK camSafeUrlEncode 一致）
function camSafeUrlEncode(str: string): string {

  return encodeURIComponent(str)
    .replace(/!/g, '%21')
    .replace(/'/g, '%27')
    .replace(/\(/g, '%28')
    .replace(/\)/g, '%29')
    .replace(/\*/g, '%2A');
}

// 摘要/HMAC 输出转十六进制小写串
function uint8ToHex(u: Uint8Array): string {

  let result = '';
  for (const item of u) {
    result += item.toString(16).padStart(2, '0');
  }
  return result;
}

// SHA1(utf8 字符串) 十六进制，用于 StringToSign
async function qlcoudSha1Utf8(str: string): Promise<string> {

  const data = new Uint8Array(buffer.from(str, 'utf-8').buffer);
  const md = cryptoFramework.createMd('SHA1');
  const chunk = 1024 * 1024;
  for (let i = 0; i < data.length; i += chunk) {
    const sub = data.subarray(i, i + chunk);
    await md.update({ data: sub });
  }
  const out = await md.digest();
  return uint8ToHex(out.data);
}

// HMAC-SHA1(utf8 plain, utf8 secret) 十六进制，用于 SignKey 与 qSignature
async function qcloudHmacSha1Utf8(plain: string, secret: string): Promise<string> {

  const msg = new Uint8Array(buffer.from(plain, 'utf-8').buffer);
  const keyData = new Uint8Array(buffer.from(secret, 'utf-8').buffer);
  const symKeyBlob: cryptoFramework.DataBlob = { data: keyData };
  const keyGenerator = cryptoFramework.createSymKeyGenerator('HMAC');
  const key = await keyGenerator.convertKey(symKeyBlob);
  const mac = cryptoFramework.createMac('SHA1');
  await mac.init(key);
  const chunk = 1024 * 1024;
  for (let i = 0; i < msg.length; i += chunk) {
    const sub = msg.subarray(i, i + chunk);
    await mac.update({ data: sub });
  }
  const macOut = await mac.doFinal();
  return uint8ToHex(macOut.data);
}

// 参与签名的 header/query 子集（排除 noSign 中的 key）
function getSignParams(headers: Map<string, string | undefined>, noSign: Set<string>): Map<string, string | undefined> {

  const temp = new Map<string, string | undefined>();
  const lowerNo = new Set(Array.from(noSign, v => v.toLowerCase()));
  for (const item of headers.keys()) {
    const keyL = item.toLowerCase();

    // 显式不参与签名的 key 跳过
    if (!lowerNo.has(keyL)) {
      temp.set(item, headers.get(item)!);
    }
  }
  return temp;
}

// 取出 map 的 key，经 camSafeUrlEncode 后小写排序，用于 q-header-list / q-url-param-list
function getObjectKeys(obj: Map<string, string | undefined>): string[] {

  const list: string[] = [];
  for (const key of obj.keys()) {
    list.push(camSafeUrlEncode(key).toLowerCase());
  }
  list.sort((a: string, b: string) => {
    const aV = a.toLowerCase();
    const bV = b.toLowerCase();
    return aV === bV ? 0 : (aV > bV ? 1 : -1);
  });
  return list;
}

// 将 header 或 query 的 map 拼成 key=value&... 且有序（签名原文的一部分）
function obj2str(obj: Map<string, string | undefined>, lowerCaseKey: boolean): string {

  const pieces: string[] = [];
  for (const key of obj.keys()) {
    let val = obj.get(key);
    val = val === undefined || val === null ? '' : ('' + val);
    const tKey = lowerCaseKey ? camSafeUrlEncode(key).toLowerCase() : camSafeUrlEncode(key);
    val = camSafeUrlEncode(val as string) || '';
    pieces.push(tKey + '=' + val);
  }
  pieces.sort((a: string, b: string) => {
    const aV = a.toLowerCase();
    const bV = b.toLowerCase();
    return aV === bV ? 0 : (aV > bV ? 1 : -1);
  });
  return pieces.join('&');
}

// 构造 Authorization 查询串（文档：请求签名 v5）
async function buildCosAuthorization(
  credential: QCloudCredential,
  methodLower: string,
  pathRaw: string,
  queries: Map<string, string | undefined>,
  headerParams: Map<string, string>
): Promise<string> {

  const SecretId = credential.secretID;
  const SecretKey = credential.secretKey;
  let now = Date.now() / 1000;

  // 若凭证带起始时间则按凭证为准
  if (credential.startDate) {
    now = credential.startDate.getTime() / 1000;
  }
  let exp = now + 1800;

  // 若凭证带过期时间则按凭证为准
  if (credential.expirationDate) {
    exp = credential.expirationDate.getTime() / 1000;
  }
  const qSignAlgorithm = 'sha1';
  const qAk = SecretId;
  const qSignTime = `${Math.floor(now)};${Math.floor(exp)}`;
  const qKeyTime = qSignTime;

  const headers = getSignParams(headerParams, new Set());
  const queriesSign = getSignParams(queries, new Set());

  // STS 临时密钥需带上 x-cos-security-token 参与签名与请求头
  if (credential.token && credential.token.length > 0) {
    headers.set(COS_TOKEN_HEADER, credential.token);
  }

  const qHeaderList = getObjectKeys(headers).join(';').toLowerCase();
  const qUrlParamList = getObjectKeys(queriesSign).join(';').toLowerCase();

  const signKey = await qcloudHmacSha1Utf8(qKeyTime, SecretKey ?? '');

  let path = pathRaw;

  // path 规范化：始终以 / 开头且不携带 query 段
  if (path.length === 0) {
    path = '/';
  } else if (path.substring(0, 1) !== '/') {
    path = '/' + path;
  }
  if (path.includes('?')) {
    path = path.split('?')[0];
  }
  path = decodeURI(path);

  const formatString = [methodLower, path, obj2str(queriesSign, true), obj2str(headers, true), ''].join('\n');
  const stringToSign = ['sha1', qSignTime, await qlcoudSha1Utf8(formatString), ''].join('\n');
  const qSignature = await qcloudHmacSha1Utf8(stringToSign, signKey);

  return [
    'q-sign-algorithm=' + qSignAlgorithm,
    'q-ak=' + qAk,
    'q-sign-time=' + qSignTime,
    'q-key-time=' + qKeyTime,
    'q-header-list=' + qHeaderList,
    'q-url-param-list=' + qUrlParamList,
    'q-signature=' + qSignature
  ].join('&');
}

// 组最终请求 URL（path 空时表示根路径 /）
function buildSignedUrl(host: string, pathNoLeading: string, queries: Map<string, string | undefined>): string {

  const slashPath = pathNoLeading.length > 0 ? `/${pathNoLeading}` : '/';
  let url = `https://${host}${slashPath}`;
  const qs = obj2str(getSignParams(queries, new Set()), true);

  // 无 query 时不追加 ?
  if (qs.length > 0) {
    url += `?${qs}`;
  }
  return url;
}

// pathNoLeading 转为签名用 path（前导 /）
function normalizePathForSign(pathNoLeading: string): string {

  // 根路径
  if (pathNoLeading.length === 0) {
    return '/';
  }
  return pathNoLeading.startsWith('/') ? pathNoLeading : '/' + pathNoLeading;
}

// 使用给定凭证发签名请求；响应体期望为字符串（XML/JSON 由调用方解析）
async function cosSignedHttpRequest(
  cred: QCloudCredential,
  method: http.RequestMethod,
  host: string,
  pathNoLeading: string,
  queries: Map<string, string | undefined>,
  body: string | undefined,
  contentType: string | undefined
): Promise<string> {

  const headers = new Map<string, string>();
  headers.set('Host', host);

  // POST/PUT 等有 body 时需 Content-Type 与 content-length 参与签名
  if (body !== undefined && contentType !== undefined) {
    headers.set('Content-Type', contentType);
    headers.set('content-length', `${body.length}`);
  }

  // 与 buildCosAuthorization 中 token 处理一致
  if (cred.token && cred.token.length > 0) {
    headers.set(COS_TOKEN_HEADER, cred.token);
  }

  const pathSign = normalizePathForSign(pathNoLeading);
  const methodLower = method === http.RequestMethod.GET ? 'get' : 'post';
  const auth = await buildCosAuthorization(cred, methodLower, pathSign, queries, headers);

  const headerRecord: Record<string, string> = {};
  headers.forEach((v, k) => {

    if (v !== undefined && v !== null) {
      headerRecord[k] = v;
    }
  });
  headerRecord['Authorization'] = auth;

  const url = buildSignedUrl(host, pathNoLeading, queries);

  return new Promise<string>((resolve, reject) => {
    const client = http.createHttp();

    client.request(url, {
      method,
      header: headerRecord,
      extraData: body,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 60000,
      readTimeout: 60000
    }, (err: BusinessError, data: http.HttpResponse) => {
      client.destroy();

      // 网络或框架错误
      if (err) {
        reject(err);
        return;
      }
      const code = data.responseCode;
      let text = '';

      // 与工程内 Http.ets 一致，STRING 时取 result
      if (data.resultType === http.HttpDataType.STRING) {
        text = data.result as string;
      }

      // HTTP 非 2xx 视为失败（CI 错误往往在 body 内需调用方再解析）
      if (code !== undefined && code !== null && (code < 200 || code >= 300)) {
        reject(new Error(`HTTP ${code}`));
        return;
      }
      resolve(text);
    });
  });
}

// MARK: - 对外工具（静态）

export class CosUtils {

  // 与 CosXmlServiceConfig 使用的 region 解密值一致（如 ap-shanghai）
  static resolvedRegion(): string {

    return StringEncoder.removedSalt(CosConfig.region)!!;
  }

  // 数据万象 CI Host：{bucket}.ci.{region}.myqcloud.com
  static ciAuditingHost(): string {

    return `${CurrentBucket}.ci.${CosUtils.resolvedRegion()}.myqcloud.com`;
  }

  // COS REST Host：{bucket}.cos.{region}.myqcloud.com
  static cosBucketHost(): string {

    return `${CurrentBucket}.cos.${CosUtils.resolvedRegion()}.myqcloud.com`;
  }

  // 使用传入凭证发起已签名 COS V5 HTTPS（CI 文本/图片审核 REST 等）
  // 参数 credential    ：SecretId/SecretKey 或 STS
  // 参数 method        ：GET / POST
  // 参数 host          ：ci 或 cos 域名，无协议
  // 参数 pathNoLeading ：对象路径或 text/auditing 等，无首 / ；根路径传 ''
  // 参数 queries       ：URL 查询参数，参与签名
  // 参数 body          ：可选，POST 正文
  // 参数 contentType   ：与 body 同时非空时写入头并参与签名
  static signedCosRequest(
    credential: QCloudCredential,
    method: http.RequestMethod,
    host: string,
    pathNoLeading: string,
    queries: Map<string, string | undefined>,
    body: string | undefined,
    contentType: string | undefined
  ): Promise<string> {

    return cosSignedHttpRequest(credential, method, host, pathNoLeading, queries, body, contentType);
  }
}
