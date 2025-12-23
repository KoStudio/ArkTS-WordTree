import { getString } from "../../../common/utils/ResourceUtils";


@ObservedV2
export class CigenWord {
  @Trace idx: number | null = null;
  @Trace cid: number | null = null;
  @Trace vid: number | null = null;
  @Trace titleEn: string | null = null;
  @Trace mnemonic: string | null = null;
  @Trace desc: string | null = null;

  getVName(): string | null {
    switch (this.vid) {
      case 1: return getString($r('app.string.cigen_vname_1')); // "前缀"
      case 2: return getString($r('app.string.cigen_vname_2')); // "前缀"
      case 3: return getString($r('app.string.cigen_vname_3')); // "词根"
      case 4: return getString($r('app.string.cigen_vname_4')); // "后缀"
      case 5: return getString($r('app.string.cigen_vname_5')); // "后缀"
      case 6: return getString($r('app.string.cigen_vname_6')); // "词缀"
      default: return null;
    }
  }


  public getDetail(): string | null {
    let detail: string | null = null
    const desc = this.desc
    if (desc) {
      const vname = this.getVName()
      if (vname) {
        // 〈后辍〉ban = prohibit, 表示「禁止」
        detail = "    〈" + vname + "〉" + desc
      } else {
        // ban = prohibit, 表示「禁止」
        detail = "    " + desc
      }
    }

    return detail
  }
}