//
//  EWordEditManager.ets
//  WordTree
//
// 配置可编辑字段：显示名称、DB 字段键、是否存在于 Word 表中（EBook 写回用）。
//

import { getString } from '../../../common/utils/ResourceUtils'
import { MemberManager } from '../member/MemberManager'

//MARK: - EWordEditableField

/// 可编辑字段枚举，与 Word 表列或 EWord 扩展字段对应
export enum EWordEditableField {
  //    pronEn       = 'item7',
  pronUs       = 'item8',
  titleCn1     = 'item9',
  titleCn2     = 'item10',
  titleCn3     = 'item11',
  //    wordImage   = 'item12',
  wordChange   = 'item13',
  synWords     = 'item14',
  asynWords    = 'item15',
  exampleEn1   = 'item16',
  exampleCn1   = 'item17',
  exampleEn2   = 'item18',
  exampleCn2   = 'item19',
  exampleEn3   = 'item20',
  exampleCn3   = 'item21',
  usedPhrase   = 'item22',
  en2En        = 'item23',
  discriminate = 'item24',

  // 词根、同根词等不在 Word 表中的字段，仅存 EWord
  root         = 'root',
  cognates     = 'cognates'
}

/// 与 iOS `CaseIterable` / `allCases` 顺序一致，供 `availableFields` 过滤
const ALL_EWORD_FIELDS: EWordEditableField[] = [
  EWordEditableField.pronUs,
  EWordEditableField.titleCn1,
  EWordEditableField.titleCn2,
  EWordEditableField.titleCn3,
  EWordEditableField.wordChange,
  EWordEditableField.synWords,
  EWordEditableField.asynWords,
  EWordEditableField.exampleEn1,
  EWordEditableField.exampleCn1,
  EWordEditableField.exampleEn2,
  EWordEditableField.exampleCn2,
  EWordEditableField.exampleEn3,
  EWordEditableField.exampleCn3,
  EWordEditableField.usedPhrase,
  EWordEditableField.en2En,
  EWordEditableField.discriminate,
  EWordEditableField.root,
  EWordEditableField.cognates
]

export class EWordEditManager {
  /// DB 字段键（EWordOverride 表 fieldKey，或 Word 表列名）
  static fieldKey(field: EWordEditableField): string {
    return field as string
  }

  /// 显示名称（用于 Picker 列表和编辑页标题）
  static displayName(field: EWordEditableField): string {
    switch (field) {
      case EWordEditableField.pronUs:       return getString($r('app.string.eword_field_pron_us'))
      case EWordEditableField.titleCn1:     return getString($r('app.string.eword_field_title_cn1'))
      case EWordEditableField.titleCn2:     return getString($r('app.string.eword_field_title_cn2'))
      case EWordEditableField.titleCn3:     return getString($r('app.string.eword_field_title_cn3'))
      case EWordEditableField.wordChange:   return getString($r('app.string.eword_field_word_change'))
      case EWordEditableField.synWords:     return getString($r('app.string.eword_field_syn_words'))
      case EWordEditableField.asynWords:    return getString($r('app.string.eword_field_asyn_words'))
      case EWordEditableField.exampleEn1:   return getString($r('app.string.eword_field_example_en1'))
      case EWordEditableField.exampleCn1:   return getString($r('app.string.eword_field_example_cn1'))
      case EWordEditableField.exampleEn2:   return getString($r('app.string.eword_field_example_en2'))
      case EWordEditableField.exampleCn2:   return getString($r('app.string.eword_field_example_cn2'))
      case EWordEditableField.exampleEn3:   return getString($r('app.string.eword_field_example_en3'))
      case EWordEditableField.exampleCn3:   return getString($r('app.string.eword_field_example_cn3'))
      case EWordEditableField.usedPhrase:   return getString($r('app.string.eword_field_used_phrase'))
      case EWordEditableField.en2En:        return getString($r('app.string.eword_field_en2en'))
      case EWordEditableField.discriminate: return getString($r('app.string.eword_field_discriminate'))
      case EWordEditableField.root:         return getString($r('app.string.eword_field_root'))
      case EWordEditableField.cognates:     return getString($r('app.string.eword_field_cognates'))
    }
  }

  /// 该字段是否存在于 Word 表中（EBook 编辑时可直接写 Word 表）
  static existsInWordTable(field: EWordEditableField): boolean {
    switch (field) {
      case EWordEditableField.pronUs:
      case EWordEditableField.titleCn1:
      case EWordEditableField.titleCn2:
      case EWordEditableField.titleCn3:
      case EWordEditableField.wordChange:
      case EWordEditableField.synWords:
      case EWordEditableField.asynWords:
      case EWordEditableField.exampleEn1:
      case EWordEditableField.exampleCn1:
      case EWordEditableField.exampleEn2:
      case EWordEditableField.exampleCn2:
      case EWordEditableField.exampleEn3:
      case EWordEditableField.exampleCn3:
      case EWordEditableField.usedPhrase:
      case EWordEditableField.en2En:
      case EWordEditableField.discriminate:
        return true
      case EWordEditableField.root:
      case EWordEditableField.cognates:
        return false
    }
  }

  /// 根据当前会员权限返回可用字段列表。
  /// - 词根助记（root）: 仅在 `checkCigenUsable` 为 true 时显示；
  /// - 同根词（cognates）: 仅在 `checkSameRootUsable` 为 true 时显示。
  static availableFields(): EWordEditableField[] {
    const canUseCigen = MemberManager.shared.checkCigenUsable(false)
    const canUseSameRoot = MemberManager.shared.checkSameRootUsable(false)

    return ALL_EWORD_FIELDS.filter((f: EWordEditableField) => {
      switch (f) {
        case EWordEditableField.root:          return canUseCigen
        case EWordEditableField.cognates:      return canUseSameRoot
        default:                               return true
      }
    })
  }
}
