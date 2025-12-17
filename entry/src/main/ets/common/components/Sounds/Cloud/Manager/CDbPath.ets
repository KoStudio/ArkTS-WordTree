import { dAppCloudSoundFolderPath } from "../../../../../app/constants/AppDefines";

// MARK: - 数据库名称常量定义
export class CDBName {
  static readonly sounds: string = "CSoundData";
}

// MARK: - 路径处理类
export class CDbPath {

  // 纯名称属性
  private baseName: string;

  // 构造函数
  constructor(pureName: string) {
    this.baseName = pureName;
  }

  ///CloudSound的sound的sqlite位置
  get sqlite(): string {
    return `${dAppCloudSoundFolderPath}/${this.baseName}.sqlite`;
  }
}