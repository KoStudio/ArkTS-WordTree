import { getString } from '../../../../common/utils/ResourceUtils';
import { BaseWordConstants } from './BaseWordConstants';
import { StringDealUtilityForBaseWord } from './StringDealUtilityForBaseWord';

/**
 * 每一个翻译包含： 词性 + 单字翻译
 */
export interface TitleItem {
  pos: string | null;   // 词性 nullable
  title: string;        // 单字翻译
}

/**
 * BaseWordUtility
 */
export class BaseWordUtility {

  // 字符常量
  private static readonly STR_POINT_HALF      = ".";    // 半角 点
  private static readonly STR_OMIT_HALF       = "...";  // 半角 三个点
  private static readonly STR_OMIT_FULL       = "……";  // 全角省略号
  private static readonly STR_COMMA_HALF      = ";";    // ①半角分号(;)
  private static readonly STR_COMMA_FULL      = "；";   // ②全角分号(；)
  private static readonly STR_COMMA_SUB_HALF  = ",";    // ③半角逗号(,)
  private static readonly STR_COMMA_SUB_FULL  = "，";   // ④全角逗号(，)

  /// 判断两个 TitleItem 是否相等（只比较 pos）
  static isTitleItemEqual(a: TitleItem, b: TitleItem): boolean {
    if (a.pos === null && b.pos === null) {
      return true;
    }
    if (a.pos !== null) {
      return a.pos === b.pos;
    }
    return false;
  }

  /**
   * 从指定的中文翻译中获取第一个分号前的部分(包含词性.意思，如: n.食物)
   */
  static getFirstPartFromText(srcText: string): string {
    let strComma     = BaseWordUtility.STR_COMMA_HALF;
    let strComma2    = BaseWordUtility.STR_COMMA_FULL;
    let strCommaSub  = BaseWordUtility.STR_COMMA_SUB_HALF;
    let strCommaSub2 = BaseWordUtility.STR_COMMA_SUB_FULL;

    let str = srcText;
    const indexNoFound = -1;

    // (1) 首先按换行符分割出第一行
    let index = str.indexOf("\n");
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
    let strLength = BaseWordUtility.getLengthOfStringWithoutKind(str);
    if (strLength > 11) {
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

    ///////////////////////////////////////////////
    // 再次用 逗号检查
    strLength = BaseWordUtility.getLengthOfStringWithoutKind(str);
    if (strLength > 13) {
      // (4) 查找第二个 子间隔符 之前的部分
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

    // (5) 若太长了，则只查找第一个 子间隔符 之前的部分
    strLength = BaseWordUtility.getLengthOfStringWithoutKind(str);
    if (strLength > 13) {
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
    ///////////////////////////////////////////////

    return str;
  }

  /// 查找去除kind之后的字符串长度
  static getLengthOfStringWithoutKind(str: string): number {
    const strPoint = BaseWordUtility.STR_POINT_HALF;
    const indexNoFound = -1;
    let strLength = 0;

    if (str != null) {
      strLength = str.length;
      const index = str.indexOf(strPoint);
      if (index !== indexNoFound) {
        strLength = str.substring(index).length;
      }
    }
    return strLength;
  }

  /// 获取原始词性
  static getKindFromText(srcText: string): string | null {
    let str = BaseWordUtility.getFirstPartFromText(srcText);
    const strPoint = BaseWordUtility.STR_POINT_HALF;
    const indexNoFound = -1;
    let kind: string | null = null;

    str = BaseWordUtility.replaceOmitAndPoint(str);

    const index = str.lastIndexOf(strPoint);
    if (index !== indexNoFound) {
      kind = str.substring(0, index);
    }
    return kind;
  }

  /// 替换省略号并去除末尾点
  static replaceOmitAndPoint(srcText: string): string {
    let str = srcText;
    const strPoint     = BaseWordUtility.STR_POINT_HALF;
    const strOmitHalf  = BaseWordUtility.STR_OMIT_HALF;
    const strOmitFull  = BaseWordUtility.STR_OMIT_FULL;
    const indexNoFound = -1;

    str = str.replace(strOmitHalf, strOmitFull);

    const index = str.lastIndexOf(strPoint);
    if (index !== indexNoFound && index === str.length - 1) {
      str = str.substring(0, index);
    }
    return str;
  }

  /// 截取翻译文本，不包含词性
  static getClippedStringWithoutKindFromText(srcText: string): string {
    let str = srcText;
    const kind = BaseWordUtility.getKindFromText(srcText);
    if (kind != null) {
      const indexNoFound = -1;
      const index = str.indexOf(kind);
      if (index !== indexNoFound) {
        const indexFromPoint = index + kind.length + 1;
        str = str.substring(indexFromPoint);
      }
    }
    return str;
  }

  /// 合并相同pos的翻译，并去重，返回 TitleItem 数组
  static getJoinedTitleItemsByRemovingDuplications(srcTexts: string[], maxParts: number): TitleItem[] {
    const titleItems: TitleItem[] = [];

    for (const srcText of srcTexts) {
      const srcTextsSub = srcText.split("\n");
      for (const srcTextSub of srcTextsSub) {
        if (srcTextSub.length === 0) continue;

        const title = BaseWordUtility.getClippedStringWithoutKindFromText(srcTextSub);
        const pos   = BaseWordUtility.getKindFromText(srcTextSub);

        const titleItem: TitleItem = {
          pos: pos ? BaseWordUtility.getTextOfKindString(pos) : null,
          title
        };

        const existedIndex = titleItems.findIndex(t => BaseWordUtility.isTitleItemEqual(t, titleItem));
        if (existedIndex !== -1) {
          titleItems[existedIndex].title = titleItems[existedIndex].title + BaseWordConstants.TitleTextJp.wordsSperator + title;
        } else {
          titleItems.push(titleItem);
        }
      }
    }

    const result: TitleItem[] = [];
    for (const item of titleItems) {
      let processedTitle: string | null = StringDealUtilityForBaseWord.removedDuplications(item.title);
      if (maxParts !== 0) {
        processedTitle = StringDealUtilityForBaseWord.clipIfNeedsMaxParts(processedTitle, maxParts);
      }
      const newItem: TitleItem = {
        pos: item.pos,
        title: processedTitle !== null ? processedTitle : ''
      };
      result.push(newItem);
    }

    return result;
  }

  /// 合并相同pos的翻译，并去重，返回字符串
  static getJoinedStringByRemovingDuplications(srcTexts: string[], maxParts: number): string {
    const titleItems = BaseWordUtility.getJoinedTitleItemsByRemovingDuplications(srcTexts, maxParts);

    const dstTexts = titleItems.map(item => {
      return item.pos ? `${item.pos}.${item.title}` : item.title;
    });

    const joinedStr = StringDealUtilityForBaseWord.joinTexts(dstTexts, BaseWordConstants.TitleTextJp.linesSeperator);
    return joinedStr ?? '';
  }

  /// 返回单词类型字符串，如动词、形容词等
  static getTextOfKindString(kindStr: string | null): string {
    let rtnStr = "";
    if (kindStr != null) {
      if (kindStr === "n")            rtnStr = getString($r('app.string.word_kind_n'));
      else if (kindStr === "v")       rtnStr = getString($r('app.string.word_kind_v'));
      else if (kindStr === "vt")      rtnStr = getString($r('app.string.word_kind_vt'));
      else if (kindStr === "vi")      rtnStr = getString($r('app.string.word_kind_vi'));
      else if (kindStr === "vt.& vi") rtnStr = getString($r('app.string.word_kind_vt_vi'));
      else if (kindStr === "vt.&vi")  rtnStr = getString($r('app.string.word_kind_vt_vi'));
      else if (kindStr === "adj")     rtnStr = getString($r('app.string.word_kind_adj'));
      else if (kindStr === "adv")     rtnStr = getString($r('app.string.word_kind_adv'));
      else if (kindStr === "pron")    rtnStr = getString($r('app.string.word_kind_pron'));
      else if (kindStr === "prep")    rtnStr = getString($r('app.string.word_kind_prep'));
      else if (kindStr === "aux")     rtnStr = getString($r('app.string.word_kind_aux'));
      else if (kindStr === "abbr")    rtnStr = getString($r('app.string.word_kind_abbr'));
      else if (kindStr === "conj")    rtnStr = getString($r('app.string.word_kind_conj'));
      else if (kindStr === "art")     rtnStr = getString($r('app.string.word_kind_art'));
      else if (kindStr === "int")     rtnStr = getString($r('app.string.word_kind_int'));
      else if (kindStr === "interj")  rtnStr = getString($r('app.string.word_kind_interj'));
      else if (kindStr === "det")     rtnStr = getString($r('app.string.word_kind_det'));
      else if (kindStr === "num")     rtnStr = getString($r('app.string.word_kind_num'));
      else if (kindStr === "phr")     rtnStr = getString($r('app.string.word_kind_phr'));
    }
    return rtnStr;
  }

}