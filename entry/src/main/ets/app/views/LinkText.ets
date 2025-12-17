import { dFontNameKaiti } from "../constants/AppDefines";

/**
 * 链接文本样式配置接口
 * @property isLinkUnderline - 链接是否显示下划线（默认显示）
 * @property fontFamily - 字体资源（可选）
 * @property textAlign - 文本对齐方式（默认居中）
 * @property maxLines - 最大显示行数（默认1行）
 * @property maxFontSize - 最大字号（默认18）
 * @property minFontSize - 最小字号（默认1）
 */
interface TextStyleConfig {
  isLinkUnderline?: boolean;
  fontFamily?: Resource | string;
  textAlign?: TextAlign;
  maxLines?: number;
  maxFontSize?: number;
  minFontSize?: number;
  fontSize?: number
}

/**
 * 链接文本片段类型
 * @property text - 文本内容
 * @property isLink - 是否为可点击链接
 */
interface TextSegment {
  text: string;
  isLink: boolean;
}

// ==================== 组件实现 ====================
@ComponentV2
export struct LinkText {
  // ---------- 输入参数 ----------
  @Param content: string            = '';          // 原始文本内容
  @Param linkTexts: string[]        = [];      // 需要作为链接的文本数组
  @Param linkColor: ResourceColor   = $r('app.color.color_link'); // 链接颜色（默认蓝色）
  @Param normalColor: ResourceColor = $r('app.color.color_text2'); // 链接颜色（默认蓝色）
  @Param isLinkUnderline: boolean   = true; // 链接是否显示下划线（默认显示）
  @Param @Require onLinkTapped: (text: string) => void; // 链接点击回调

  // ---------- 样式配置参数 ----------
  @Param textStyle: TextStyleConfig = {  // 文本基础样式
    textAlign: TextAlign.Start,         // 默认居左对齐
    maxLines: 1,                        // 默认单行显示
    // maxFontSize: 18,                 // 默认最大字号
    // minFontSize: 1,                  // 默认最小字号
    fontFamily: 'HarmonyOS Sans',       // 默认系统字体
    fontSize: 15

  };

  // ---------- 私有方法：文本分割逻辑 ----------
  /**
   * 将原始文本分割为链接/普通片段
   * @returns 分割后的文本片段数组
   */
  private getLinkParts(): TextSegment[] {
    // 无链接文本时返回完整普通文本
    if (this.linkTexts.length === 0) {
      return [{ text: this.content, isLink: false }];
    }

    const segments: TextSegment[] = [];
    let remainingText = this.content;

    while (remainingText !== '') {
      let foundLink = false;

      // 按顺序检查每个链接词
      for (const linkText of this.linkTexts) {
        const index = remainingText.indexOf(linkText);

        if (index !== -1) {
          // 添加链接前的普通文本
          const prefix = remainingText.substring(0, index);
          if (prefix) {
            segments.push({ text: prefix, isLink: false });
          }

          // 添加链接文本
          segments.push({ text: linkText, isLink: true });

          // 更新剩余文本
          remainingText = remainingText.substring(index + linkText.length);
          foundLink = true;
          break;
        }
      }

      // 未找到链接则添加剩余文本
      if (!foundLink) {
        segments.push({ text: remainingText, isLink: false });
        break;
      }
    }

    return segments;
  }

  // ---------- 组件构建 ----------
  build() {
    // 使用Text作为根容器，内部嵌套Span实现多片段文本
    Text() {
      ForEach(this.getLinkParts(), (item: TextSegment) => {
        // 使用三元表达式实现条件渲染
        Span(item.text)
          .fontColor(item.isLink ? this.linkColor : this.normalColor) // 条件设置颜色
          .fontSize(this.textStyle.fontSize)
          .decoration(
            item.isLink && this.isLinkUnderline
              ? { type: TextDecorationType.Underline, color: this.linkColor }
              : null
          )
          .onClick(item.isLink ? () => {
            this.onLinkTapped(item.text); // 仅链接可点击
          } : null)
      })
    }
    .width('100%')                                      // 宽度填满父容器
    .textAlign(this.textStyle.textAlign)           // 文本对齐方式
    .maxLines(this.textStyle.maxLines)             // 最大行数限制
    // .maxFontSize(this.textStyle.maxFontSize)       // 动态字号范围
    // .minFontSize(this.textStyle.minFontSize)       // 最小字号保护
    .fontFamily(this.textStyle.fontFamily || 'HarmonyOS Sans') // 字体设置 dFontNameKaiti
  }
}

// ==================== 使用示例 ====================
@Preview
@ComponentV2
struct ExamplePage {
  build() {
    Column({ space: 10 }) {
      // 基本用法（带下划线）
      LinkText({
        content: "阅读用户协议和隐私政策,阅读用户协议和隐私政策,阅读用户协议和隐私政策",
        linkTexts: ["用户协议", "隐私政策"],
        onLinkTapped: (text) => {
          console.log(`点击了: ${text}`);
        }
      })

      // 无下划线链接
      LinkText({
        content: "服务条款与退款政策",
        linkTexts: ["服务条款", "退款政策"],
        isLinkUnderline: false,
        linkColor: Color.Green,
        onLinkTapped: (text) => {
          console.log(`点击了: ${text}`);
        }
      })

      // 完整配置示例
      LinkText({
        content: "点击查看《鸿蒙NEXT开发指南》",
        linkTexts: ["《鸿蒙NEXT开发指南》"],
        textStyle: {
          fontFamily: $r(`${dFontNameKaiti}}`),
          textAlign: TextAlign.Start,
          maxLines: 2
        }
        , onLinkTapped: (text) => {
          console.log(`点击了: ${text}`);
        }
      })
    }
    .padding(20)
  }
}