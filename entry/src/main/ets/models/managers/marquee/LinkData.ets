//
// LinkData.ets
// WordTree (HarmonyOS)
//
// 与 iOS `LinkData.swift` / Android `LinkData.kt` 字段一致（type / param / limit）；
// 建模与解析方式对齐 `Instruction.ets`（constructor + 静态工厂）。
//

// 服务器 OpenLink JSON（可嵌在 Instruction.link 字符串中）
export class LinkData {

  type  : string | null = null
  param : string | null = null
  limit : string | null = null

  // json：parse 后的字典；缺省表示空模型
  constructor(json?: Record<string, Object>) {

    // 仅在有字典时解析字段
    if (json) {
      this.type  = (json['type']  as string) ?? null
      this.param = (json['param'] as string) ?? null
      this.limit = (json['limit'] as string) ?? null
    }
  }

  // jsonString：整段 JSON 文本；非法或空串时得到 null（与 iOS `linkData(from:)` 一致）
  static linkData(jsonString: string | null | undefined): LinkData | null {

    if (!jsonString || jsonString.length === 0) {
      return null
    }

    try {
      const o = JSON.parse(jsonString) as Record<string, Object>

      return new LinkData(o)
    } catch (_e) {
      return null
    }
  }
}

// LinkLimit：与 iOS `LinkLimit` 一致（member / nonmember / all）
export enum LinkLimit {
  Member = 'member',
  Nonmember = 'nonmember',
  All = 'all'
}

// value：服务端 limit 字段；未知或未填视为 all（与 iOS `init?(rawValue: String?)` 的 default = all）
export function linkLimitFromValue(value: string | null | undefined): LinkLimit {

  if (value === 'member') {
    return LinkLimit.Member
  }

  if (value === 'nonmember') {
    return LinkLimit.Nonmember
  }

  if (value === 'all') {
    return LinkLimit.All
  }

  return LinkLimit.All
}

// LinkType：与 iOS `LinkType` 中 Marquee 用到的子集一致
export enum LinkType {
  Instruction = 'instruction',
  ShareApp = 'share_app',
  MemberBuy = 'member_buy'
}

// value：JSON 的 type 字段；无法识别时得到 null
export function linkTypeFromValue(value: string | null | undefined): LinkType | null {

  if (value === LinkType.Instruction) {
    return LinkType.Instruction
  }

  if (value === LinkType.ShareApp) {
    return LinkType.ShareApp
  }

  if (value === LinkType.MemberBuy) {
    return LinkType.MemberBuy
  }

  return null
}
