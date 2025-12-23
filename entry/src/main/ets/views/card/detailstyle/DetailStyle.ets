export interface StylePattern {
  fontSize : number;
  font?    : string;   // 目前只需要字体大小，字体样式和颜色暂不需要配置
  color?   : number;   // 目前只需要字体大小，字体样式和颜色暂不需要配置
}


export interface StyleItem {
  wordEn   : StylePattern;
  wordCn   : StylePattern;
  wordPron : StylePattern;
  title    : StylePattern;
  subtitle : StylePattern;
  detail   : StylePattern;
  memo     : StylePattern;
}

export class DetailStyle {

  // ---------------- 常量定义 ----------------

  static readonly Style0: number = 0;
  static readonly Style1: number = 1;
  static readonly Style2: number = 2;

  // ---------------- 初始化 ----------------

  /** 根据 value 初始化 */
  static init(fromValue: number): number {
    switch (fromValue) {
      case DetailStyle.Style0: return DetailStyle.Style0;
      case DetailStyle.Style1: return DetailStyle.Style1;
      case DetailStyle.Style2: return DetailStyle.Style2;
      default: return DetailStyle.Style0;
    }
  }

  /** 所有样式 */
  static get all(): number[] {
    return [
      DetailStyle.Style0,
      DetailStyle.Style1,
      DetailStyle.Style2
    ];
  }

  // ---------------- 名称 ----------------

  static getName(style: number): ResourceStr {
    switch (style) {
      case DetailStyle.Style0:
        return $r('app.string.learn_detail_info_txt_font_style_1'); // "小"
      case DetailStyle.Style1:
        return $r('app.string.learn_detail_info_txt_font_style_2'); // "中"
      case DetailStyle.Style2:
        return $r('app.string.learn_detail_info_txt_font_style_3'); // "大"
      default:
        return '';
    }
  }

  // ---------------- 样式项 ----------------

  static getItem(style: number): StyleItem {
    switch (style) {

      case DetailStyle.Style0:
        return {
          wordEn:   { fontSize: 32 },
          wordCn:   { fontSize: 18 },
          wordPron: { fontSize: 20 },

          title:    { fontSize: 22 },
          subtitle: { fontSize: 18 },
          detail:   { fontSize: 18 },
          memo:     { fontSize: 18 }
        };

      case DetailStyle.Style1:
        return {
          wordEn:   { fontSize: 36 },
          wordCn:   { fontSize: 20 },
          wordPron: { fontSize: 22 },

          title:    { fontSize: 26 },
          subtitle: { fontSize: 22 },
          detail:   { fontSize: 22 },
          memo:     { fontSize: 22 }
        };

      case DetailStyle.Style2:
        return {
          wordEn:   { fontSize: 40 },
          wordCn:   { fontSize: 28 },
          wordPron: { fontSize: 30 },

          title:    { fontSize: 32 },
          subtitle: { fontSize: 28 },
          detail:   { fontSize: 28 },
          memo:     { fontSize: 28 }
        };

      default:
        return DetailStyle.getItem(DetailStyle.Style0);
    }
  }
}