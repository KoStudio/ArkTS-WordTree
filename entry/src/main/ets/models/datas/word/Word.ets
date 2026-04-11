import { Constants } from "../../../app/constants/Constants";
import { AppUtility } from "../../../common/utils/AppUtility";
import { StringEncoder } from "../../../common/utils/strings/StringEncrypt";
import { EWordEditableField } from "../../managers/eword/EWordEditManager";
import { SearchManager } from "../model/SearchManager";
import { WordDetail } from "./WordDetail";

export class Word {
  idx             : number | null = null;
  partId          : number | null = null;
  partName        : string | null = null;

  unitId          : number | null = null;
  unitNo          : number | null = null;
  unitName        : string | null = null;

  titleEn         : string | null = null;
  titleCn1        : string | null = null;
  titleCn2        : string | null = null;
  titleCn3        : string | null = null;

  pronEn          : string | null = null;
  pronUs          : string | null = null;
  exampleEn1      : string | null = null;
  exampleCn1      : string | null = null;

  private wordDetail                : WordDetail | null                 = null
  private wordDetailLoadingPromise : Promise<WordDetail | null> | null = null

  // 与 iOS `OnlineWord.Constant`（PartId 999 / UnitId 0）一致，用于判断是否在线搜索词
  get isOnlineWord(): boolean {
    const p = this.partId
    const u = this.unitId

    // partId / unitId 缺省时不可判定为在线词
    if (p === null || p === undefined || u === null || u === undefined) {
      return false
    }

    return p === 999 && u === 0
  }

  // 使详情缓存失效（EWord 保存后需重新查库并合并 Override）
  // 分支：除已缓存结果外，也要清理进行中的 Promise，避免旧请求结果回写。
  clearWordDetailCache(): void {
    this.wordDetail                = null
    this.wordDetailLoadingPromise = null
  }

  // async getWordDetail(): Promise<WordDetail | null> {
  //   if (!this.wordDetail) {
  //     this.wordDetail = await SearchManager.shared.getWordDbAccess()?.getWordDetailByTitleEn(this.titleEn) ?? null
  //   }
  //   return this.wordDetail
  // }

  async getWordDetail(): Promise<WordDetail | null> {
    // 分支：已有详情缓存时，直接返回，避免重复查库。
    if (this.wordDetail) {
      return this.wordDetail
    }

    // 分支：已有进行中的加载任务时，直接复用同一个 Promise，避免并发重复查库。
    const runningPromise = this.wordDetailLoadingPromise

    if (runningPromise !== null) {
      return await runningPromise
    }

    // 分支：无缓存且无进行中任务时，启动一次加载并登记 Promise。
    const createdPromise = this.loadWordDetailFromDbAndApplyOverrides()
    this.wordDetailLoadingPromise = createdPromise

    try {
      // 调用：等待唯一加载任务完成，并落入详情缓存。
      const loaded = await createdPromise

      this.wordDetail = loaded
      return loaded
    } finally {
      // 加载结束后清理进行中标记，后续由缓存命中或重新发起加载。
      this.wordDetailLoadingPromise = null
    }
  }

  // 读取详情并应用 EWord 覆盖（供 getWordDetail 统一复用，避免并发重复执行）
  private async loadWordDetailFromDbAndApplyOverrides(): Promise<WordDetail | null> {
    const titleEn = this.titleEn

    // 从当前课本 textDb 的 Word 表按 titleEn 查询详情
    let detail = await SearchManager.shared.getWordDbAccess()?.getWordDetailByTitleEn(titleEn) ?? null

    // 主词库中不存在时再查 learnDb 的 WordOnlineTemp
    if (detail === null){

      // 动态 import，减轻模块启动依赖
      let it = await import('../myData/WordUserDbAccess')

      // 读取在线临时表中的完整词条
      detail = await it.WordUserDbAccess.shared.getOnlineWordDetailByTitleEn(titleEn) ?? null
    }

    // 已得到详情且能确定 titleEn 时，合并 EWordOverride 展示覆盖
    if (detail !== null && titleEn) {

      // 动态 import EWordManager：避免 `Word -> EWordManager -> ... -> Word` 的模块初始化时序风险。
      // 在方法内部按需加载，可将潜在循环依赖从“模块加载期”延后到“运行期调用点”。
      const ewm = await import('../../managers/eword/EWordManager')

      // 加载该词在 learnDb 中的 [fieldKey: value]
      const ov = await ewm.EWordManager.shared.loadOverrides(titleEn);

      // 将覆盖应用到 WordDetail（含 root、cognates 等扩展字段）
      detail.applyEWordOverrideMap(ov);
    }

    return detail
  }

  /**
   * 列表层合并 EWord 覆盖（与 iOS `Word.applyEWordOverrideMap(forWord:)` 一致，目前仅 titleCn1）。
   */
  applyEWordOverrideMap(map: Record<string, string>): void {
    const k = EWordEditableField.titleCn1 as string;

    // 与 iOS 列表层一致：仅当存在 item9 覆盖时才替换释义 1
    if (map[k] !== undefined && map[k] !== null) {
      this.titleCn1 = map[k];
    }
  }

  get titleEnEncodeToBase64(): string | null {
    return StringEncoder.encodedToBase64(this.titleEn)
  }

  get titleEnEncodeAndAddSalt(): string | null {
    return StringEncoder.encodeAndAddSalt(this.titleEn)
  }

  get wordEnSoundText(): string {
    return `${this.titleEn}_ti_u`
  }

  get titleCn1Clipped(): string {
    return AppUtility.getClippedStringWithoutKindFrom(this.titleCn1 || '')
  }

  get titleCn1ClippedShort(): string {
    return AppUtility.getClippedStringSeperatedFirstPartFrom(this.titleCn1 || '')
  }

  get titleCn1Kind(): string {
    return AppUtility.getKindOfString(this.titleCn1 || '')
  }

  /**
   * 将多个中文释义合并为一个字符串（去重）
   */
  getTitleCnsJoined(): string {
    const titles: string[] = [];

    if (this.titleCn1) {
      titles.push(this.titleCn1);
    }
    if (this.titleCn2) {
      titles.push(this.titleCn2);
    }
    if (this.titleCn3) {
      titles.push(this.titleCn3);
    }

    return AppUtility.getJoinedStringByRemovingDuplications(
      titles,
      Constants.TitleTextJp.wordsMaxPart
    );
  }
}
