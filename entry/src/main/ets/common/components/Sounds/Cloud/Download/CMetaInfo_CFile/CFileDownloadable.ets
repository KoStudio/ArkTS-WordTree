import { CMetaInfo } from "./CMetaInfo";

// MARK: - CFileDownloadable 等价 ArkTS 接口
export interface CFileDownloadable { //extends CDownloadable {

  /// 获取元数据
  /// @param fileName  文件名
  /// @param finished  回调 (meta: CMetaInfo | null, error: string | null)
  getFileMeta(
    fileName  : string,
    finished  : (meta: CMetaInfo | null, error: string | null) => void
  ) : void;


  /// 下载文件
  /// @param fileName     文件名
  /// @param proccessing  下载进度回调 (bytes: number)
  /// @param finished     完成回调 (url: string | null, meta: CMetaInfo | null, error: string | null)
  downloadFile(
    fileName     : string,
    proccessing  : (bytes: number) => void,
    finished     : (url: string | null, meta: CMetaInfo | null, error: string | null) => void
  ) : void;
}