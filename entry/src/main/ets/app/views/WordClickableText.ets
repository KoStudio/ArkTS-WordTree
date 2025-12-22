@ComponentV2
export struct WordClickableText {
  // ---------- 输入参数 ----------
  @Param text:            string         = "";                               // 原始文本
  @Param highlightWords:  string[]       = [];                               // 高亮单词列表
  @Param highlightColor:  ResourceColor  = $r('app.color.color_text_marked'); // 高亮颜色
  @Param normalColor:     ResourceColor  = $r('app.color.color_card_title');       // 普通颜色
  @Param fontSize:        number         = 20;                               // 字体大小

  // 点击单词事件回调
  @Event onWordClick?: (word: string) => void;

  // ---------- 本地状态 ----------
  @Local onTouchedColor: ResourceColor    = $r('app.color.color_text_touched'); // 按下背景颜色
  @Local activeId?: string = undefined;                                   // 当前按下的单词id

  // ---------- 私有方法 ----------

  /** 判断是否英文单词 */
  private isWord(str: string): boolean {
    return /^[A-Za-z]+$/.test(str);
  }

  /** 是否高亮单词 */
  private isHighlightWord(str: string): boolean {
    return this.isWord(str) && this.highlightWords.map(v=>v.toLowerCase()).includes(str.toLowerCase());
  }

  /** 拆分文本，英文单词分开，保留其他字符 */
  private splitText(src: string): string[] {
    if (!src) return [""];
    return src.split(/(\b[A-Za-z]+\b)/);
  }

  // ---------- 组件构建 ----------
  build() {
    // 使用 Flex 实现多行自动换行
    Flex({
      direction: FlexDirection.Row,
      wrap: FlexWrap.Wrap,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Start
    }) {
      // 遍历文本拆分的片段
      ForEach(this.splitText(this.text), (part: string, index: number) => {


        // 使用 Text 来显示每个片段
        Text(part)
          .fontSize(this.fontSize)
          .fontColor(this.isHighlightWord(part) ? this.highlightColor : this.normalColor)
          .backgroundColor(this.activeId === `${part}_${index}` ? this.onTouchedColor : Color.Transparent)
          .fontFamily("HarmonyOS Sans")
          .minFontScale(0.1)
          .onTouch((evt) => {
            if (this.isWord(part)) { // 只对英文单词生效
              if (evt.type === TouchType.Down) {
                this.activeId = `${part}_${index}`;      // 按下高亮
              } else if (evt.type === TouchType.Up || evt.type === TouchType.Cancel) {
                // 延迟恢复颜色，防止点击被遮挡
                setTimeout(() => { this.activeId = undefined; }, 50);
              }
            }
          })
          .onClick(this.isWord(part) ? () => {
            this.onWordClick?.(part);        // 点击事件
          } : undefined);
      });
    }
    .width("100%")

  }
}