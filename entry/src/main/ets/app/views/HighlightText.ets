import { dFontNameKaiti } from "../constants/AppDefines";


/**
 * 基础文本样式配置接口
 * @property font - 字体资源（可选）
 * @property textAlign - 文本对齐方式（默认居中）
 * @property maxLines - 最大显示行数（默认1行）
 * @property maxFontSize - 最大字号（默认18）
 * @property minFontSize - 最小字号（默认1）
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
 * @property text - 文本内容
 * @property isHighlight - 是否为高亮部分
 */
interface TextSegment {
  text: string;
  isHighlight: boolean;
}

// ==================== 组件实现 ====================
@ComponentV2
export struct HighlightText {
  // ---------- 输入参数 ----------
  @Param content: string = '';          // 原始文本内容
  @Param keyword: string = '';          // 需要高亮的关键词
  @Param highlightColor: ResourceColor = Color.Red; // 高亮颜色（默认红色）
  @Param normalColor: ResourceColor = Color.Black //普通文本

  // ---------- 样式配置参数 ----------
  @Param textStyle: TextStyleConfig = {  // 文本基础样式
    textAlign: TextAlign.Center,        // 默认居中对齐
    maxLines: 1,                        // 默认单行显示
    maxFontSize: 18,                    // 默认最大字号
    minFontSize: 1                      // 默认最小字号
  };

  // @Param highlightStyle: {              // 高亮部分特殊样式
  //   fontWeight?: FontWeight;            // 字体粗细（可选）
  //   backgroundColor?: ResourceColor;     // 背景色（可选）
  // } = { fontWeight: FontWeight.Bold };  // 默认加粗

  // ---------- 私有方法：文本分割逻辑 ----------
  /**
   * 将原始文本分割为高亮/非高亮片段
   * @returns 分割后的文本片段数组
   */
  private getHighlightParts(): TextSegment[] {
    // 无关键词时返回完整文本
    if (!this.keyword) {
      return [{ text: this.content, isHighlight: false }];
    }

    const segments: TextSegment[] = [];
    const lowerText = this.content.toLowerCase();
    const lowerKeyword = this.keyword.toLowerCase();
    let lastIndex = 0;

    // 循环查找所有匹配项
    while (true) {
      const matchIndex = lowerText.indexOf(lowerKeyword, lastIndex);
      if (matchIndex === -1) break;

      // 添加非高亮片段
      if (matchIndex > lastIndex) {
        segments.push({
          text: this.content.substring(lastIndex, matchIndex),
          isHighlight: false
        });
      }

      // 添加高亮片段
      segments.push({
        text: this.content.substring(matchIndex, matchIndex + this.keyword.length),
        isHighlight: true
      });

      lastIndex = matchIndex + this.keyword.length;
    }

    // 添加剩余文本
    if (lastIndex < this.content.length) {
      segments.push({
        text: this.content.substring(lastIndex),
        isHighlight: false
      });
    }

    return segments;
  }

  // ---------- 组件构建 ----------
  build() {
    // 使用Text作为根容器，内部嵌套Span实现多片段文本
    Text() {
      ForEach(this.getHighlightParts(), (item: TextSegment) => {
        Span(item.text)
          .fontColor(item.isHighlight ? this.highlightColor : this.normalColor)           // 高亮颜色切换

      })

    }
    // .backgroundColor(Color.Gray)
    .width('100%')                                      // 宽度填满父容器
    .textAlign(this.textStyle.textAlign)           // 文本对齐方式[6](@ref)
    .maxLines(this.textStyle.maxLines || 1)             // 最大行数限制[6](@ref)
    .maxFontSize(this.textStyle.maxFontSize)       // 动态字号范围[3](@ref)
    .minFontSize(this.textStyle.minFontSize)       // 最小字号保护[3](@ref)
    .fontSize(this.textStyle.fontSize)             // 字体资源（支持外部传入）
    .fontFamily(this.textStyle.fontFamily)
    // .heightAdaptivePolicy(TextHeightAdaptivePolicy.MAX_LINES_FIRST) // 优先保证行数

  }
}

// ==================== 使用示例 ====================
@Preview
@ComponentV2
struct ExamplePage {
  // @Local customFont: Resource = $r('app.font.HarmonyOS_Sans'); // 自定义字体

  build() {
    Column({ space: 10 }) {
      // 基本用法
      HighlightText({
        content: "欢迎使用ArkTS高亮组ArkTS件",
        keyword: "ArkTS"
      })

      // 完整配置示例
      HighlightText({
        content: "鸿蒙NEXT开发实战指南",
        keyword: "NEXT",

      })
    }
    .padding(20)
  }
}