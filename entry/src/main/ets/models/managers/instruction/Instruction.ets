//
// Instruction.ets
// WordTree (HarmonyOS)
//
// 与 iOS `Instruction` 字段一致；与服务端交互时的解析方式对齐 `ServerCfg`（constructor + fromArray）。
//

// 服务器 Instruction 表对应的一条记录（idx / type / title / link）
export class Instruction {

  idx   : number | null = null
  type  : string | null = null
  title : string | null = null
  link  : string | null = null

  // json：Http 响应 `data` 中的单条对象；缺省表示空模型
  constructor(json?: Record<string, Object>) {

    // 仅在有字典时解析字段
    if (json) {
      this.idx   = (json['idx']   as number) ?? null
      this.type  = (json['type']  as string) ?? null
      this.title = (json['title'] as string) ?? null
      this.link  = (json['link']  as string) ?? null
    }
  }

  // arr：Http 返回的 `data` 数组；null 时得到空数组（与 `ServerCfg.fromArray` 一致）
  static fromArray(arr: Object[] | null): Instruction[] {

    // 无数组则视为 0 条
    if (!arr) {
      return []
    }

    // 逐条映射为模型

    return arr.map((o) => new Instruction(o as Record<string, Object>))
  }
}
