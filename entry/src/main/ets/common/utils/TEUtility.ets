import { SearchConstants } from "../../models/datas/model/SearchManager";
import { getString } from "./ResourceUtils";

export class TEUtility {

  static readonly WordKind_noun: string      = "noun";
  static readonly WordKind_verb: string      = "verb";
  static readonly WordKind_adjective: string = "adjective";
  static readonly WordKind_adverb: string    = "adverb";
  static readonly WordKind_kudou: string     = "kudou";
  static readonly WordKind_other: string     = "other";


  // 获取收藏星级字符串
  static getFavoriteStarTextString(favoriteLevel: number): string {
    return "★".repeat(favoriteLevel);
  }


  static getQuizTopIconResIds(): Resource[] {
    return [
      $r('app.media.quiz_top_icon_0'),
      $r('app.media.quiz_top_icon_1'),
      $r('app.media.quiz_top_icon_2'),
      $r('app.media.quiz_top_icon_3'),
      $r('app.media.quiz_top_icon_4')
    ];
  }

  static getQuizTopTextStrings(): ResourceStr[] {
    return [
      $r('app.string.quiz_top_txt_unit'),
      $r('app.string.quiz_top_txt_all'),
      $r('app.string.quiz_top_txt_category'),
      $r('app.string.quiz_top_txt_mistake'),
      $r('app.string.quiz_top_txt_favorite')
    ];
  }


  // /**
  //  * 获取错误次数的文本资源ID
  //  * @param context 上下文对象
  //  * @param wrangTimes 错误次数
  //  * @returns 资源ID
  //  */
  // public static getWrangTimesText(wrangTimes: number): ResourceStr {
  //   if (wrangTimes === 1) {
  //     return getString($r('app.string.wrang_times_1_only')))
  //   } else if (wrangTimes > 1 && wrangTimes <= 3) {
  //     return getString($r('app.string.wrang_times_1_3'))
  //   } else if (wrangTimes > 3 && wrangTimes <= 5) {
  //     return getString($r('app.string.wrang_times_3_5'))
  //   } else if (wrangTimes > 5 && wrangTimes <= 10) {
  //     return getString($r('app.string.wrang_times_5_10'))
  //   } else if (wrangTimes > 10) {
  //     return getString($r('app.string.wrang_times_10_over'))
  //   }
  //   return getString($r('app.string.wrang_times_1_only'))
  // }
  //
  // /**
  //  * 根据枚举的错误次数获取文本字符串
  //  * @param context 上下文对象
  //  * @param enumWrangTimes 枚举的错误次数
  //  * @returns 对应的文本描述
  //  */
  // public static getWrangTimesTextStringFromEnumWrangTimes(enumWrangTimes: number): ResourceStr {
  //   if (enumWrangTimes === SearchConstants.WRANG_TIMES_1_ONLY) {
  //     return $r('app.string.wrang_times_1_only')
  //   } else if (enumWrangTimes === SearchConstants.WRANG_TIMES_1_3) {
  //     return $r('app.string.wrang_times_1_3')
  //   } else if (enumWrangTimes === SearchConstants.WRANG_TIMES_3_5) {
  //     return $r('app.string.wrang_times_3_5')
  //   } else if (enumWrangTimes === SearchConstants.WRANG_TIMES_5_10) {
  //     return $r('app.string.wrang_times_5_10')
  //   } else if (enumWrangTimes === SearchConstants.WRANG_TIMES_10_OVER) {
  //     return $r('app.string.wrang_times_10_over')
  //   }
  //   return $r('app.string.wrang_times_1_only')
  // }

  public static getCategorySectionIcon(sectionIndex: number): Resource {
    switch (sectionIndex){
      case 0 : return $r('app.media.section_icon_cate_1')
      case 1 : return $r('app.media.section_icon_cate_2')
      case 2 : return $r('app.media.section_icon_cate_3')
      default:  return $r('app.media.section_icon_cate_1')
    }
  }

  public static getCategorySectionBgColor(section: string): ResourceColor {
    switch (section){
      case getString($r('app.string.cat_txt_level_1')) : return $r('app.color.color_list_section_bg_cate_1')
      case getString($r('app.string.cat_txt_level_2')) : return $r('app.color.color_list_section_bg_cate_2')
      case getString($r('app.string.cat_txt_level_3')) : return $r('app.color.color_list_section_bg_cate_3')
      default:  return $r('app.color.color_list_section_bg_cate_1')
    }
  }

  public static getCategoryScopeButtonIcon(sectionIndex: number): Resource {
    switch (sectionIndex){
      case 0 : return $r('app.media.quiz_cat1_1')
      case 1 : return $r('app.media.quiz_cat2_1')
      case 2 : return $r('app.media.quiz_cat3_1')
      default:  return $r('app.media.quiz_cat1_1')
    }
  }


  public static getCategoryIcon(categoryId?: number | null):Resource {
    //db 中的categoryId是从1开始的
    switch (categoryId){
      case 1 : return $r('app.media.icon_c_1')
      case 2 : return $r('app.media.icon_c_2')
      case 3 : return $r('app.media.icon_c_3')
      default:  return $r('app.media.icon_c_1')
    }
  }

  public static getWordKindIcon(kind?: string | null):Resource {
    switch (kind){
      case TEUtility.WordKind_noun      : return $r('app.media.icon_t_noun')
      case TEUtility.WordKind_verb      : return $r('app.media.icon_t_verb')
      case TEUtility.WordKind_adjective : return $r('app.media.icon_t_adjective')
      case TEUtility.WordKind_adverb    : return $r('app.media.icon_t_adverb')
      case TEUtility.WordKind_kudou     : return $r('app.media.icon_t_kudou')
      case TEUtility.WordKind_other     : return $r('app.media.icon_t_other')
      default                           : return $r('app.media.icon_t_other')
    }
  }

  public static getSectionTextColor(sectionIndex: number): ResourceColor{
    const colors = [
      $r('app.color.color_list_sep_txt_1'),
      $r('app.color.color_list_sep_txt_2'),
      $r('app.color.color_list_sep_txt_3'),
    ]
    return colors[sectionIndex % colors.length]
  }

  public static getSectionReviewIcon(sectionIndex: number): Resource{
    const ress = [
      $r('app.media.reivew_icon_0'),
      $r('app.media.reivew_icon_1'),
      $r('app.media.reivew_icon_2'),
    ]
    return ress[sectionIndex % ress.length]
  }

  /**
   * 根据 YMD 生成 Date
   */
  static convertDateFromYMD(year: number, month: number, day: number): Date {
    // ArkTS/JS 的 Date 构造方法：month 从 0 开始
    return new Date(year, month - 1, day);
  }

  /**
   * 根据 YMD 生成 "yyyy/MM/dd" 字符串
   */
  static convertDateStringFromYMD(year: number, month: number, day: number): string {
    const date = new Date(year, month - 1, day);

    // ArkTS 没有 Java SimpleDateFormat，需要手动格式化
    const yyyy = date.getFullYear();
    const mm = (date.getMonth() + 1).toString().padStart(2, '0');
    const dd = date.getDate().toString().padStart(2, '0');

    return `${yyyy}/${mm}/${dd}`;
  }

  // ---------- 常量 ----------
  private static readonly STR_COMMA_HALF: string = ";";   // ① 半角分号(;)
  private static readonly STR_COMMA_FULL: string = "；";   // ② 全角分号(；)


  // ---------- 对外方法：clipString(srcString) ----------
  static clipString(srcString: string | undefined | null): string {
    if (srcString) {
      return TEUtility.clipStringWithLength(srcString, 10);
    }
    return ''
  }

  // ---------- 核心方法：clipString(srcText, maxLength) ----------
  static clipStringWithLength(srcText: string, maxLength: number): string {
    const strComma:  string = TEUtility.STR_COMMA_HALF;  // ① 半角分号(;)
    const strComma2: string = TEUtility.STR_COMMA_FULL;  // ② 全角分号(；)
    let   str:       string = srcText;
    const indexNoFound: number = -1;

    // ----------------------------------------------------
    // (1) 首先按换行符分割出第一行
    // ----------------------------------------------------
    let index: number = str.indexOf("\n");
    if (index !== indexNoFound) {
      str = str.substring(0, index);
    }

    // ----------------------------------------------------
    // (2) 查找第二个间隔符之前的部分
    //     先用①半角分号，再用②全角分号
    // ----------------------------------------------------
    index = str.indexOf(strComma, str.indexOf(strComma) + 1);
    if (index !== indexNoFound) {
      str = str.substring(0, index);
    } else {
      index = str.indexOf(strComma2, str.indexOf(strComma2) + 1);
      if (index !== indexNoFound) {
        str = str.substring(0, index);
      }
    }

    // ----------------------------------------------------
    // (3) 若太长了，则只查找第一个间隔符之前的部分
    //     优先半角分号，再用全角分号
    // ----------------------------------------------------
    const strLength: number = str.length;
    if (strLength > (maxLength + 1)) {
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

    return str;
  }


}