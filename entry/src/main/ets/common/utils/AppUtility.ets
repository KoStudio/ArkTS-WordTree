

import common from '@ohos.app.ability.common';

// ============================================================
// 常量定义
// ============================================================

const STR_POINT_HALF: string = ".";   // 半角点
const STR_OMIT_HALF: string = "..."; // 半角三个点
const STR_OMIT_FULL: string = "……";   // 全角省略号
const STR_COMMA_HALF: string = ";";   // 半角分号(;)
const STR_COMMA_FULL: string = "；";   // 全角分号(；)
const STR_COMMA_SUB_HALF: string = ","; // 半角逗号(,)
const STR_COMMA_SUB_FULL: string = "，"; // 全角逗号(，)

// ============================================================
// 数据模型定义
// ============================================================

/**
 * 每一个翻译包含：词性 + 单字翻译
 */
export class TitleItem {
  public pos: string | null = null;   // 词性 nullable
  public title: string = ""; // 单字翻译

  equals(obj: Object): boolean {
    if (obj instanceof TitleItem) {
      const other = obj as TitleItem;
      if (this.pos === null && other.pos === null) {
        return true;
      }
      if (this.pos !== null) {
        return this.pos === other.pos;
      } else {
        return false;
      }
    }
    return false;
  }
}

// ============================================================
// 主工具类
// ============================================================

export class AppUtility {

  // ================== 资源相关方法 ==================

  /**
   * Used for iab gold icon
   * @returns 图标资源ID数组
   */
  static getIabGoldIconResIds(): number[] {
    const ids: number[] = [
      // $r('app.media.gold_iap1'),
      // $r('app.media.gold_iap2'),
      // $r('app.media.gold_iap3')
    ];
    return ids;
  }

  /**
   * Used for Quiz Top icon
   * @returns 测验顶部图标资源ID数组
   */
  static getQuizTopIconResIds(): number[] {
    const ids: number[] = [
      // $r('app.media.quiz_top_icon_0'),
      // $r('app.media.quiz_top_icon_1'),
      // $r('app.media.quiz_top_icon_2'),
      // $r('app.media.quiz_top_icon_3'),
      // $r('app.media.quiz_top_icon_4')
    ];
    return ids;
  }

  /**
   * Used for Quiz top Text
   * @param context 上下文对象
   * @returns 测验顶部文本数组
   */
  static getQuizTopTextStrings(context: common.Context): string[] {
    const texts: string[] = [
      context.resourceManager.getStringSync($r('app.string.test_top_txt_unit').id),
      context.resourceManager.getStringSync($r('app.string.test_top_txt_all').id),
      context.resourceManager.getStringSync($r('app.string.test_top_txt_part').id),
      context.resourceManager.getStringSync($r('app.string.test_top_txt_mistake').id),
      context.resourceManager.getStringSync($r('app.string.test_top_txt_favorite').id)
    ];
    return texts;
  }

  // ================== 数据处理方法 ==================

  /**
   * 根据数字返回大小
   * @param size 字节大小
   * @returns 格式化后的尺寸字符串
   */
  static getSizeStringFromBytes(size: number): string {
    const b: number = 1;
    const k: number = 1024 * b;
    const m: number = 1024 * k;
    const g: number = 1024 * m;

    const gg: number = size / g;
    if (gg > 1) {
      return `${gg.toFixed(1)}GB`;
    }

    const mm: number = size / m;
    if (mm > 1) {
      return `${mm.toFixed(1)}MB`;
    }

    const kk: number = size / k;
    return `${Math.round(kk)}KB`;
  }

  /**
   * 获取收藏等级星号字符串
   * @param favoriteLevel 收藏等级
   * @returns 星号字符串
   */
  static getStarOfFavoriteLevel(favoriteLevel: number): string {
    return "★".repeat(favoriteLevel);
  }

  /**
   * used for section title
   * @param wrangTimes 错误次数
   * @returns 区间名称
   */
  static getSectionOfWrangTimes(wrangTimes: number): string | null {
    if (wrangTimes === 1) {
      return AppUtility.getNameOfMistake("Mistake_1_Only");
    } else if (wrangTimes > 1 && wrangTimes <= 3) {
      return AppUtility.getNameOfMistake("Mistake_1_3");
    } else if (wrangTimes > 3 && wrangTimes <= 5) {
      return AppUtility.getNameOfMistake("Mistake_3_5");
    } else if (wrangTimes > 5 && wrangTimes <= 10) {
      return AppUtility.getNameOfMistake("Mistake_5_10");
    } else if (wrangTimes > 10) {
      return AppUtility.getNameOfMistake("Mistake_10_Over");
    } else {
      return null; // 0次时
    }
  }

  /**
   * used for quiz select
   * @param mistake 错误类型
   * @returns 错误类型名称
   */
  static getNameOfMistake(mistake: string): string {
    // 需要在实际使用时传入context
    // 这里返回空字符串，实际使用时应从资源文件获取
    return "";
  }

  // ================== 字符串处理方法 ==================

  /**
   * 从指定的中文翻译中获取第一个分号前的部分(包含词性.意思，如: n.食物)
   * @param srcText 源文本
   * @returns 处理后的文本
   */
  private static getFirstPartFrom(srcText: string): string {
    const strComma: string = STR_COMMA_HALF;
    const strComma2: string = STR_COMMA_FULL;
    const strCommaSub: string = STR_COMMA_SUB_HALF;
    const strCommaSub2: string = STR_COMMA_SUB_FULL;

    let str: string = srcText;
    const indexNoFound: number = -1;

    // (1) 首先按换行符分割出第一行
    let index: number = str.indexOf("\n");
    if (index !== indexNoFound) {
      str = str.substring(0, index);
    }

    // (2) 查找第二个间隔符之前的部分
    index = str.indexOf(strComma, str.indexOf(strComma) + 1);
    if (index !== indexNoFound) {
      str = str.substring(0, index);
    } else {
      index = str.indexOf(strComma2, str.indexOf(strComma2) + 1);
      if (index !== indexNoFound) {
        str = str.substring(0, index);
      }
    }

    // (3) 若太长了，则只查找第一个间隔符之前的部分
    let strLength: number = AppUtility.getLengthOfStringWithoutKind(str);
    if (strLength > (10 + 1)) {
      index = str.indexOf(strComma);
      if (index !== indexNoFound) {
        str = str.substring(0, index);
      } else {
        index = str.indexOf(strComma2);
        if (index !== indexNoFound) {
          str = str.substring(0, index);
        }
      }
    }

    // 再次用逗号检查
    strLength = AppUtility.getLengthOfStringWithoutKind(str);
    if (strLength > (12 + 1)) {
      // (4) 查找第二个子间隔符之前的部分
      index = str.indexOf(strCommaSub2, str.indexOf(strCommaSub2) + 1);
      if (index !== indexNoFound) {
        str = str.substring(0, index);
      } else {
        index = str.indexOf(strCommaSub, str.indexOf(strCommaSub) + 1);
        if (index !== indexNoFound) {
          str = str.substring(0, index);
        }
      }
    }

    // (5) 若太长了，则只查找第一个子间隔符之前的部分
    strLength = AppUtility.getLengthOfStringWithoutKind(str);
    if (strLength > (12 + 1)) {
      index = str.indexOf(strCommaSub2);
      if (index !== indexNoFound) {
        str = str.substring(0, index);
      } else {
        index = str.indexOf(strCommaSub);
        if (index !== indexNoFound) {
          str = str.substring(0, index);
        }
      }
    }

    return str;
  }

  /// 查找去除kind之后的字符串长度
  private static getLengthOfStringWithoutKind(str: string): number {
    const strPoint: string = STR_POINT_HALF;
    const indexNoFound: number = -1;
    let strLength: number = 0;

    if (str) {
      strLength = str.length;
      const index: number = str.indexOf(strPoint);
      if (index !== indexNoFound) {
        strLength = str.substring(index).length;
      }
    }
    return strLength;
  }

  /// get original kind
  private static getKindFrom(srcText: string): string | null {
    let str: string = AppUtility.getFirstPartFrom(srcText);
    const strPoint: string = STR_POINT_HALF;
    let kind: string | null = null;
    const indexNoFound: number = -1;

    str = AppUtility.replaceOmitAndPoint(str);
    const index: number = str.lastIndexOf(strPoint);
    if (index !== indexNoFound) {
      kind = str.substring(0, index);
    }
    return kind;
  }

  // replace omit and remove last point
  private static replaceOmitAndPoint(srcText: string): string {
    let str: string = srcText;
    const strPoint: string = STR_POINT_HALF;
    const strOmitHalf: string = STR_OMIT_HALF;
    const strOmitFull: string = STR_OMIT_FULL;
    const indexNoFound: number = -1;

    str = str.replace(strOmitHalf, strOmitFull);
    const index: number = str.lastIndexOf(strPoint);
    if (index !== indexNoFound && index === str.length - 1) {
      str = str.substring(0, index);
    }
    return str;
  }

  /// clip cn string to get kind
  static getKindOfString(srcText: string): string {
    const str: string | null = AppUtility.getKindFrom(srcText);
    return AppUtility.getTextOfKindString(str || "");
  }

  /// clip cn string, only get first translation
  static getClippedStringSeperatedFirstPartFrom(srcText: string): string {
    let str: string = AppUtility.getFirstPartFrom(srcText);
    str = AppUtility.getClippedStringWithoutKindFrom(str);
    return str;
  }

  /// clip cn string, only get translation
  static getClippedStringWithoutKindFrom(srcText: string): string {
    let str: string = srcText;
    const kind: string | null = AppUtility.getKindFrom(srcText);
    if (kind !== null) {
      const indexNoFound: number = -1;
      const index: number = str.indexOf(kind);
      if (index !== indexNoFound) {
        const indexFromPoint: number = index + kind.length + 1;
        str = str.substring(indexFromPoint);
      }
    }
    return str;
  }

  // ================== 文本处理高级方法 ==================

  /// 合并相同pos的翻译，并且去除重复part, 返回重新组合好的pos + title数组
  static getJoinedTitleItemsByRemovingDuplications(srcTexts: string[], maxParts: number): TitleItem[] {
    const titleItems: TitleItem[] = [];

    for (const srcText of srcTexts) {
      const srcTextsSub: string[] = srcText.split("\n");
      for (const srcTextSub of srcTextsSub) {
        if (srcTextSub.length === 0) {
          continue;
        }

        const title: string = AppUtility.getClippedStringWithoutKindFrom(srcTextSub);
        const pos: string | null = AppUtility.getKindFrom(srcTextSub);

        const titleItem: TitleItem = new TitleItem();
        titleItem.pos = AppUtility.getTextOfKindString(pos || "");
        titleItem.title = title;

        const existedIndex: number = titleItems.findIndex(item => item.equals(titleItem));
        if (existedIndex !== -1) {
          const existedItem: TitleItem = titleItems[existedIndex];
          existedItem.title += ";" + title;
        } else {
          titleItems.push(titleItem);
        }
      }
    }

    for (const titleItem of titleItems) {
      // 这里需要StringDealUtility的实现，暂时简化处理
      let title: string = titleItem.title;
      if (maxParts !== 0) {
        const parts: string[] = title.split(';');
        title = parts.slice(0, maxParts).join(';');
      }
      titleItem.title = title;
    }

    return titleItems;
  }

  /// 合并相同pos的翻译，并且去除重复part
  static getJoinedStringByRemovingDuplications(srcTexts: string[], maxParts: number): string {
    const titleItems: TitleItem[] = AppUtility.getJoinedTitleItemsByRemovingDuplications(srcTexts, maxParts);
    const dstTexts: string[] = [];

    for (const titleItem of titleItems) {
      let title: string = titleItem.title;
      if (titleItem.pos !== null && titleItem.pos.length > 0) {
        title = titleItem.pos + " " + title;
      }
      dstTexts.push(title);
    }

    return dstTexts.join("\n");
  }

  // ================== 词性类型转换 ==================
  /**
   * 返回单词类型，如：动词，形容词。。
   * - kindStr 词性标识符：如：n,v,vt,vi,adj,adv
   */
  static getTextOfKindString(kindStr: string): string {
    let rtnStr: string = "";

    if (kindStr) {
      // 使用资源引用方式获取本地化字符串
      const kindMap: Record<string, Resource> = {
        "n"        : $r('app.string.word_kind_n'),
        "v"        : $r('app.string.word_kind_v'),
        "vt"       : $r('app.string.word_kind_vt'),
        "vi"       : $r('app.string.word_kind_vi'),
        "vt.& vi"  : $r('app.string.word_kind_vt_vi'),
        "vt.&vi"   : $r('app.string.word_kind_vt_vi'),
        "adj"      : $r('app.string.word_kind_adj'),
        "adv"      : $r('app.string.word_kind_adv'),
        "pron"     : $r('app.string.word_kind_pron'),
        "prep"     : $r('app.string.word_kind_prep'),
        "aux"      : $r('app.string.word_kind_aux'),
        "abbr"     : $r('app.string.word_kind_abbr'),
        "conj"     : $r('app.string.word_kind_conj'),
        "art"      : $r('app.string.word_kind_art'),
        "int"      : $r('app.string.word_kind_int'),
        "interj"   : $r('app.string.word_kind_interj'),
        "det"      : $r('app.string.word_kind_det'),
        "num"      : $r('app.string.word_kind_num'),
        "phr"      : $r('app.string.word_kind_phr')
      };

      const resource: Resource | undefined = kindMap[kindStr];
      if (resource) {
        // 在实际使用时需要传入 context 来获取字符串值
        // 这里返回资源对象，调用方需要根据 context 获取实际字符串
        return kindStr; // 临时返回原值，实际使用时需要处理
      } else {
        rtnStr = kindStr;
      }
    }

    return rtnStr;
  }

  /**
   * 获取本地化字符串
   * @param stringResId 字符串资源ID
   * @returns 本地化字符串
   */
  static getLocalizedString(context: common.Context, stringResId: number): string {
    return context.resourceManager.getStringSync(stringResId);
  }

  // ================== JSON处理方法 ==================

  static getMapFromJson(json: string): Record<string, string> {
    try {
      return JSON.parse(json) as Record<string, string>;
    } catch (error) {
      console.error("JSON解析错误:", error);
      return {};
    }
  }

  static getListFromJson(json: string): Array<Record<string, string>> {
    try {
      return JSON.parse(json) as Array<Record<string, string>>;
    } catch (error) {
      console.error("JSON解析错误:", error);
      return [];
    }
  }

  static getJsonFromList(list: Array<Record<string, string>>): string | null {
    return JSON.stringify(list);
  }
}