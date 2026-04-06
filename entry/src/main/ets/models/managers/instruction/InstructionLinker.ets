//
// InstructionLinker.ets
// WordTree (HarmonyOS)
//
// 与 iOS `InstructionLinker.swift` 对齐：Instruction 列表缓存、按 idx 懒加载全表、
// `showLinkWithInstruction` 用内链 `LinkView` 打开（对应 iOS `showLink(link:title:)`）。
//

import { LinkViewConfig } from '../../../app/views/LinkView'
import { Instruction } from './Instruction'
import { InstructionManager } from './InstructionManager'

export class InstructionLinker {

  public static shared: InstructionLinker = new InstructionLinker()

  private cachedInstructions: Instruction[] = []

  private constructor() {
    // 与 iOS 单例 init：预拉一次 idx=100（具体条目是否存在由服务端决定）
    void this.loadInstructionsIfNeeds(100)
  }

  // idx：Instruction 主键；命中缓存或拉全表后用 `LinkView` 打开 link（主线程调度，对齐 iOS `DispatchQueue.main.async`）
  showLinkWithInstruction(idx: number): void {
    // 无效 idx 直接返回
    if (idx <= 0) {
      return
    }

    this.loadInstructionsIfNeeds(idx, (instruction: Instruction | null) => {

      setTimeout(() => {
        const title = instruction?.title
        const link = instruction?.link

        // 标题与链接齐全才展示（与 iOS `if let title, let link` 一致）
        if (title != null && link != null && title.length > 0 && link.length > 0) {

          LinkViewConfig.open({ title: title, url: link })
        }
      }, 0)
    })
  }

  // idx：要查找的 Instruction；completion：缓存命中或整表刷新后的单条（找不到则为 null）
  loadInstructionsIfNeeds(
    idx: number,
    completion: ((instruction: Instruction | null) => void) | null = null
  ): void {
    if (idx <= 0) {
      completion?.(null)
      return
    }

    const hit = this.cachedInstructions.find((it) => it.idx === idx)
    if (hit !== undefined) {
      completion?.(hit)
      return
    }

    // 与 iOS：未命中时 `loadInstructions(needAll: true)` 拉全表并替换缓存
    InstructionManager.loadInstructions(true, (succeed: boolean, _msg: string | null, inslist: Instruction[] | null) => {

      // 请求失败或无数据时不覆盖已有缓存（与 iOS `if let inss = inslist` 行为一致）
      if (!succeed || inslist === null) {
        completion?.(null)
        return
      }

      this.cachedInstructions = []
      this.cachedInstructions.push(...inslist)

      const found = this.cachedInstructions.find((it) => it.idx === idx)

      if (found !== undefined) {
        completion?.(found)
        return
      }

      completion?.(null)
    })
  }

  // 清空缓存（与 iOS `clear` 一致）
  clear(): void {
    this.cachedInstructions = []
  }
}
