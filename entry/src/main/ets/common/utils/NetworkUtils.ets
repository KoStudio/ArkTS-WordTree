import connection from '@ohos.net.connection';
import prompt from '@ohos.prompt';
import { Toast } from './Toast';

export class NetWorkTool {

  /**
   * 检查是否有网络连接
   * @param showMessage 是否显示提示信息
   */
  static checkInternetConnection(showMessage: boolean = true): boolean {
    const netHandle = connection.getDefaultNetSync();
    if (!netHandle || netHandle.netId < 100) {
      if (showMessage) {
        Toast.showMessage($r('app.string.network_not_available'))
      }
      return false;
    }
    return true;
  }


  /**
   * 判断当前网络是否为 WiFi
   */
  // static isWifiConnection(): boolean {
  //   const netHandle = connection.getDefaultNetSync();
  //   if (!netHandle || netHandle.netId < 100) {
  //     return false;
  //   }
  //   const bearType = connection.getBearerTypeSync(netHandle);
  //   return bearType === connection.NetBearType.BEARER_WIFI;
  // }

}