@ComponentV2
export struct WordClickableText {
  // ---------- 输入参数 ----------
  @Param text:            string         = "";                               // 原始文本
  @Param highlightWords:  string[]       = [];                               // 高亮单词列表
  @Param highlightColor:  ResourceColor  = $r('app.color.color_text_marked'); // 高亮颜色
  @Param normalColor:     ResourceColor  = $r('app.color.color_card_title');  // 普通颜色
  @Param fontSize:        number         = 20;                               // 字体大小

  // 点击单词事件回调
  @Event onWordClick?: (word: string) => void;

  // ---------- 本地状态 ----------
  @Local onTouchedColor: ResourceColor    = $r('app.color.color_text_touched'); // 按下背景颜色
  @Local activeId?:      string           = undefined;                           // 当前按下的单词id

  // ---------- 私有方法 ----------
  // 判断是否英文单词
  private isWord(str: string): boolean {
    return /^[A-Za-z]+$/.test(str);
  }

  // 是否高亮单词
  private isHighlightWord(str: string): boolean {
    return this.isWord(str) && this.highlightWords.map(v => v.toLowerCase()).includes(str.toLowerCase());
  }

  // 按 \n 拆成行，保留空行（与 Android / iOS 多段空白行一致）；无内容时不占位
  private textLines(src: string): string[] {

    if (src.length < 1) {
      return []
    }

    return src.split('\n')
  }

  // 单行内按英文单词边界拆分（不含换行）
  private splitLineParts(line: string): string[] {
    return line.split(/(\b[A-Za-z]+\b)/)
  }

  // 空行占位高度，接近一行正文
  private blankLineHeight(): number {
    return this.fontSize * 1.25
  }

  // ---------- 组件构建 ----------
  build() {
    Flex({
      direction:      FlexDirection.Row,
      wrap:           FlexWrap.Wrap,
      justifyContent: FlexAlign.Start,
      alignItems:     ItemAlign.Start
    }) {
      ForEach(this.textLines(this.text), (line: string, lineIndex: number) => {

        // 行与行之间：软换行（首行前不插入）
        if (lineIndex > 0) {
          Blank()
            .width('100%')
        }

        // 空行：占一行高度（原先用 \n 整体 split 时会产生 ""，走 Text("") 高度为 0，空白行被吃掉）
        if (line.length < 1) {
          Blank()
            .width('100%')
            .height(this.blankLineHeight())
        } else {
          ForEach(this.splitLineParts(line), (part: string, partIndex: number) => {

            Text(part)
              .fontSize(this.fontSize)
              .fontColor(this.isHighlightWord(part) ? this.highlightColor : this.normalColor)
              .backgroundColor(this.activeId === `${part}_${lineIndex}_${partIndex}` ? this.onTouchedColor : Color.Transparent)
              .fontFamily("HarmonyOS Sans")
              .minFontScale(0.1)
              .onTouch((evt) => {
                if (this.isWord(part)) {
                  if (evt.type === TouchType.Down) {
                    this.activeId = `${part}_${lineIndex}_${partIndex}`;
                  } else if (evt.type === TouchType.Up || evt.type === TouchType.Cancel) {
                    setTimeout(() => { this.activeId = undefined; }, 50);
                  }
                }
              })
              .onClick(this.isWord(part) ? () => { this.onWordClick?.(part); } : undefined);
          }, (part: string, partIndex: number) => `L${lineIndex}_P${partIndex}`)
        }
      }, (line: string, lineIndex: number) => `L${lineIndex}`)
    }
    .width("100%");
  }
}
