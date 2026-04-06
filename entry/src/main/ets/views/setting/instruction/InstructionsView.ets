//
// InstructionsView.ets
// WordTree (HarmonyOS)
//
// 与 Android `InstructionsActivity.kt` 对齐：分组列表、点击 http(s) 链接用 LinkView 打开。
//

import { buildNavTitle } from '../../../app/constants/AppBuilders'
import { dNavBackIcon } from '../../../app/constants/AppDefines'
import { LinkViewConfig } from '../../../app/views/LinkView'
import { NetWorkTool } from '../../../common/utils/NetworkUtils'
import { Toast } from '../../../common/utils/Toast'
import { Instruction } from '../../../models/managers/instruction/Instruction'
import { InstructionManager } from '../../../models/managers/instruction/InstructionManager'
import { NavTo } from '../../../pages/NavPathManager'

interface InstructionSection {
  section: string
  items: Instruction[]
}

export namespace InstructionsViewConfig {

  export const NavKey: string = 'InstructionsView_show'

  export function open(): void {
    NavTo(InstructionsViewConfig.NavKey, undefined, true)
  }
}

@ComponentV2
export struct InstructionsView {

  @Local grouped: InstructionSection[] = []

  aboutToAppear(): void {
    this.loadDatas()
  }

  loadDatas(): void {

    if (!NetWorkTool.checkInternetConnection(false)) {
      return
    }

    InstructionManager.loadInstructions(false, (succeed: boolean, msg: string | null, list: Instruction[] | null) => {

      if (!succeed) {
        Toast.showMessage(msg ?? 'error')
        return
      }

      const map: Record<string, Instruction[]> = {}

      for (const ins of list ?? []) {
        const sec = ins.type ?? '-'
        if (!map[sec]) {
          map[sec] = []
        }
        map[sec].push(ins)
      }

      const next: InstructionSection[] = Object.keys(map).map((k: string): InstructionSection => {
        return { section: k, items: map[k] }
      })

      this.grouped = next
    })
  }

  build() {
    NavDestination() {
      List({ space: 0 }) {

        ForEach(this.grouped, (sec: InstructionSection) => {

          ListItemGroup({ header: this.headerBuilder(sec.section), style: ListItemGroupStyle.NONE }) {

            ForEach(sec.items, (ins: Instruction, rowIdx: number) => {
              ListItem() {
                Column({ space: 4 }) {
                  Text(ins.title ?? '')
                    .fontSize(16)
                    .width('100%')
                }
                .padding(12)
                .width('100%')
              }
              .onClick(() => {
                const link = ins.link

                if (link != null &&
                  (link.startsWith('http://') || link.startsWith('https://'))) {
                  LinkViewConfig.open({ title: ins.title ?? link, url: link })
                }
              })
            }, (ins: Instruction, rowIdx: number) => `ins_${ins.idx ?? rowIdx}_${rowIdx}`)
          }
        }, (sec: InstructionSection, secIdx: number) => `sec_${sec.section}_${secIdx}`)
      }
      .width('100%')
      .height('100%')
      .divider({ strokeWidth: 1, color: $r('app.color.color_gray_light') })
      .backgroundColor($r('app.color.color_obscure'))
    }
    .title(buildNavTitle($r('app.string.instruction_nav_title')))
    .backButtonIcon(dNavBackIcon)
    .backgroundColor($r('app.color.colorPrimary'))
  }

  @Builder
  headerBuilder(section: string) {
    Text(section)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .width('100%')
      .padding({
        left: 12,
        right: 12,
        top: 10,
        bottom: 6
      })
      .backgroundColor($r('app.color.color_gray_light'))
  }
}
