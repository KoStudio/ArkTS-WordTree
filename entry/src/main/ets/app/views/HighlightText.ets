import { dFontNameKaiti } from "../constants/AppDefines";

/**
 * 基础文本样式配置接口
 */
interface TextStyleConfig {
  fontFamily?: Resource | string;
  textAlign?: TextAlign;
  maxLines?: number;
  fontSize?: number;
  maxFontSize?: number;
  minFontSize?: number;
}

/**
 * 高亮文本片段类型
 */
interface TextSegment {
  text: string;
  isHighlight: boolean;
}

// ==================== 组件实现 ====================
@ComponentV2
export struct HighlightText {
  // ---------- 输入参数 ----------
  @Param content: string = '';
  @Param keyword: string = '';
  @Param highlightColor: ResourceColor = Color.Red;
  @Param normalColor: ResourceColor = Color.Black;

  // ---------- 样式配置 ----------
  @Param textStyle: TextStyleConfig = {
    textAlign: TextAlign.Center,
    maxLines: 0,             // 0 表示不限制行数
    maxFontSize: 18,
    minFontSize: 1
  };

  // ---------- 私有方法：分割文本 ----------
  private getHighlightParts(): TextSegment[] {
    if (!this.keyword) {
      // 没有关键词，按行拆分
      return this.content.split('\n').flatMap((line, index, arr) => {
        const segments: TextSegment[] = [{ text: line, isHighlight: false }];
        if (index < arr.length - 1) segments.push({ text: '\n', isHighlight: false });
        return segments;
      });
    }

    // 有关键词，按行拆分并高亮
    const segments: TextSegment[] = [];
    const lines = this.content.split('\n');

    lines.forEach((line, lineIndex) => {
      let lastIndex = 0;
      const lowerText = line.toLowerCase();
      const lowerKeyword = this.keyword.toLowerCase();

      while (true) {
        const matchIndex = lowerText.indexOf(lowerKeyword, lastIndex);
        if (matchIndex === -1) break;

        if (matchIndex > lastIndex) {
          segments.push({
            text: line.substring(lastIndex, matchIndex),
            isHighlight: false
          });
        }

        segments.push({
          text: line.substring(matchIndex, matchIndex + this.keyword.length),
          isHighlight: true
        });

        lastIndex = matchIndex + this.keyword.length;
      }

      if (lastIndex < line.length) {
        segments.push({
          text: line.substring(lastIndex),
          isHighlight: false
        });
      }

      // 添加换行符
      if (lineIndex < lines.length - 1) {
        segments.push({ text: '\n', isHighlight: false });
      }
    });

    return segments;
  }

  // ---------- 构建组件 ----------
  build() {
    Text() {
      ForEach(this.getHighlightParts(), (item: TextSegment) => {
        Span(item.text)
          .fontColor(item.isHighlight ? this.highlightColor : this.normalColor)
      })
    }
    .width('100%')
    .textAlign(this.textStyle.textAlign)
    .maxLines(this.textStyle.maxLines || 0)
    .fontSize(this.textStyle.fontSize)
    .maxFontSize(this.textStyle.maxFontSize)
    .minFontSize(this.textStyle.minFontSize)
    .fontFamily(this.textStyle.fontFamily)
    //.heightAdaptivePolicy(TextHeightAdaptivePolicy.MAX_LINES_FIRST) // 高度自适应，多行显示
  }
}