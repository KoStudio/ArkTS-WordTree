import { dAppCBookDbFolderPath } from "../../../../../../app/constants/AppDefines";

// CloudBook 的路径
export class CBookDbPath {

  baseName : string;   // 如：HONGEN_1

  constructor(baseName: string) {
    this.baseName = baseName;
  }

  /// CloudBook 的 sqlite 下载后的位置
  get sqlite() : string | null {
    if (dAppCBookDbFolderPath == null) {
      return null;
    }
    return dAppCBookDbFolderPath + "/" + this.baseName + ".sqlite";
  }

  /// 获取云端 Book Db 文件名
  get fileName() : string {
    return this.baseName + ".sqlite.zip";
  }
}

/// CloudBookList 的名称
export const CBookListName : string = "BookList";  // "BookList.sqlite.zip"