//
//  CBookPath.ets
//  WordTree (HarmonyOS)
//
//  与 iOS CBookPath.swift 对齐：CloudBook 本地路径、列表与 BaseDict/Cigen 云端库 baseName。
//

import { LanguageManager } from '../../../../Language/LanguageManager'
import { dAppCBookDbFolderPath } from '../../../../../../app/constants/AppDefines'

// CloudBook 的路径（与 iOS `CBookDbPath` 一致）
export class CBookDbPath {

  // 如：HONGEN_1
  baseName: string

  constructor(baseName: string) {
    this.baseName = baseName
  }

  // CloudBook 的 sqlite 下载后的位置
  get sqlite(): string | null {
    if (dAppCBookDbFolderPath == null) {
      return null
    }
    return dAppCBookDbFolderPath + '/' + this.baseName + '.sqlite'
  }

  // 获取云端 Book Db 文件名（与 iOS `fileName` 一致）
  get fileName(): string {
    return this.baseName + '.sqlite.zip'
  }
}

// CloudBookList 的名称
export const CBookListName: string = 'BookList' // "BookList.sqlite.zip" 的 baseName 部分

// CloudBaseDict 简体中文名称
export const CBaseDictName_Cns: string = 'BaseDict' // "BaseDict.sqlite.zip"

// CloudBaseDict 繁体中文名称
export const CBaseDictName_Cnt: string = 'BaseDict_Cnt' // "BaseDict_Cnt.sqlite.zip"

// CloudCigenData 简体中文名称
export const CCigenDataName_Cns: string = 'CigenData_Cns' // "CigenData_Cns.sqlite.zip"

// CloudCigenData 繁体中文名称
export const CCigenDataName_Cnt: string = 'CigenData_Cnt' // "CigenData_Cnt.sqlite.zip"

// CloudBaseDict 的名称（根据当前语言选择；与 iOS `CBaseDictName` 一致）
export function getCBaseDictName(): string {
  if (LanguageManager.isSimpleChinese()) {
    return CBaseDictName_Cns
  }
  return CBaseDictName_Cnt
}

// CloudCigenData 的名称（根据当前语言选择；与 iOS `CCigenDataName` 一致）
export function getCCigenDataName(): string {
  if (LanguageManager.isSimpleChinese()) {
    return CCigenDataName_Cns
  }
  return CCigenDataName_Cnt
}
