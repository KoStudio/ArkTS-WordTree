// import { CredentialCallBack, QCloudCredential } from '@tencentcloud/cos';
// import { http } from '@kit.NetworkKit';
// import { BusinessError } from '@kit.BasicServicesKit';
//
// ///not using
// export class CosCredential {
//   /**
//    * 获取 STS 临时密钥
//    */
//   public static sessionCredential: CredentialCallBack = (request)=>{
//     return new Promise((resolve, reject) => {
//       // 首先从您的临时密钥服务器获取包含了密钥信息的响应
//       let httpRequest = http.createHttp();
//       httpRequest.request(
//         // 请替换为具体的 sts 临时密钥获取服务 url
//         "http://127.0.0.1/sts",
//         { method: http.RequestMethod.GET },
//         (err: BusinessError, data: http.HttpResponse) => {
//           if (!err) {
//             const stsSessionQCloudCredentials: StsSessionQCloudCredentials = JSON.parse(data.result.toString());
//             let credential : QCloudCredential = new QCloudCredential();
//             credential.secretID               = stsSessionQCloudCredentials.credentials.tmpSecretId;
//             credential.secretKey              = stsSessionQCloudCredentials.credentials.tmpSecretKey;
//             credential.token                  = stsSessionQCloudCredentials.credentials.sessionToken;
//
//             // 建议返回服务器时间作为签名的开始时间，避免由于用户手机本地时间偏差过大导致请求过期
//             // startDate 和 expirationDate 均为 Date 类型，此处通过毫秒时间戳构造 Date，
//             // sts 响应的时间戳一般单位为秒，因此需要乘以1000，如果您的临时密钥服务响应的时间单位为毫秒，则无需乘以1000
//             credential.startDate              = new Date(stsSessionQCloudCredentials.startTime * 1000);
//             credential.expirationDate         = new Date(stsSessionQCloudCredentials.expiredTime * 1000);
//             httpRequest.destroy();
//
//             // 最后返回临时密钥信息对象
//             resolve(credential);
//           } else {
//             httpRequest.destroy();
//             reject(err);
//           }
//         });
//     })
//   }
// }
//
// /**
//  * 临时密钥实体定义
//  */
// export class StsSessionQCloudCredentials{
//   credentials: StsCredentials;
//   startTime: number;
//   expiredTime: number;
//
//   constructor(credentials: StsCredentials, startTime: number, expiredTime: number) {
//     this.credentials = credentials;
//     this.startTime = startTime;
//     this.expiredTime = expiredTime;
//   }
// }
// export class StsCredentials{
//   tmpSecretId: string;
//   tmpSecretKey: string;
//   sessionToken: string;
//
//   constructor(tmpSecretId: string, tmpSecretKey: string, sessionToken: string) {
//     this.tmpSecretId = tmpSecretId;
//     this.tmpSecretKey = tmpSecretKey;
//     this.sessionToken = sessionToken;
//   }
// }