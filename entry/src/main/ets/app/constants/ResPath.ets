import { PathUtility } from "../../common/utils/PathUtility";
import { AppConstants } from "./AppConstants";

/**
 * 资源路径定义类
 * 对应Kotlin的data class ResPath
 */
export class ResPath {
  name: string;
  assetPath: string;
  filePath: string;

  constructor(name: string, assetPath: string, filePath: string = AppConstants.dataBasePath + assetPath) {
    this.name       = name;
    this.assetPath  = assetPath;
    this.filePath   = filePath;

    let ext = PathUtility.getExtension(assetPath)
    if (ext ==='zip') {
      this.filePath = AppConstants.dataBasePath + PathUtility.removeSuffix(assetPath) || ''
    }

  }

  /**
   * 获取文件在应用沙箱中的绝对路径
   * @returns string 完整文件路径
   */
  getFilePath(): string {
    return this.filePath;
  }
}

/**
 * 资源名称常量
 */
export class ResName {

  // Book
  static readonly Book = new ResPath("Book", "Datas/0_Books/0_BookCate/BookList.sqlite.zip");


  // // Word_Cns
  // static readonly Word_Cns = new ResPath("Word_Cns", "Datas/Word_Cns.sqlite");
  //
  // // Word_Cnt
  // static readonly Word_Cnt = new ResPath("Word_Cnt", "Datas/Word_Cnt.sqlite");

  // BaseDict_Cns
  static readonly BaseDict_Cns = new ResPath("BaseDict_Cns", "Datas/91_BaseDict/BaseDict.sqlite.zip");

  // BaseDict_Cnt
  static readonly BaseDict_Cnt = new ResPath("BaseDict_Cnt", "Datas/91_BaseDict/BaseDict_Cnt.sqlite.zip");


  //Cigen_Cns
  static readonly Cigen_Cns = new ResPath("Cigen_Cns", "Datas/92_Cigen/CigenData_Cns.sqlite.zip");

  //Cigen_Cnt
  static readonly Cigen_Cnt = new ResPath("Cigen_Cnt", "Datas/92_Cigen/CigenData_Cnt.sqlite.zip");




  /**
   * 获取所有数据库资源
   */
  static get allDatabases(): ResPath[] {
    return [
      ResName.Book,
      // ResName.Word_Cns,
      // ResName.Word_Cnt,
      // ResName.BaseDict_Cns,
      // ResName.BaseDict_Cnt
    ];
  }
}

/**
 * 封面图片资源定义类
 * 对应 Kotlin object Img
 */
export class ResImg {
  // 洪恩


  /**
   * 获取所有封面图片资源
   */
  static get allImages(): ResPath[] {
    return [

    ]
  }
}