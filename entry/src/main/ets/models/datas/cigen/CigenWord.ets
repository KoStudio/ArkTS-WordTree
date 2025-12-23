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
      case 1: return this.getResourceString('cigen_vname_1'); // "前缀"
      case 2: return this.getResourceString('cigen_vname_2'); // "前缀"
      case 3: return this.getResourceString('cigen_vname_3'); // "词根"
      case 4: return this.getResourceString('cigen_vname_4'); // "后缀"
      case 5: return this.getResourceString('cigen_vname_5'); // "后缀"
      case 6: return this.getResourceString('cigen_vname_6'); // "词缀"
      default: return null;
    }
  }

  private getResourceString(resName: string): string {
    return getString($r(resName))
  }
}