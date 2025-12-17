export class TextAnimator {

  /**
   * 给指定状态绑定的文本添加逐字显示效果，并在指定时间后逐字擦除
   * @param setText 绑定的状态更新函数，例如: (text) => this.text = text
   * @param text 要显示的完整文本
   * @param fadeOutSeconds 延迟多少秒后开始擦除
   * @param completion 完成后回调
   */
  public static setFadeInText(
    setText: (text: string) => void,
    text: string,
    fadeOutSeconds: number = 2,
    completion?: () => void
  ) {
    if (!text) return;

    setText(""); // 先清空文本

    const totalLength = text.length;
    const durationPerChar = 150; // 每个字符动画时长 ms

    let index = 0;

    const fadeInStep = () => {
      if (index > totalLength) {
        // 显示完成，延迟 fadeOutSeconds 后擦除
        setTimeout(() => {
          TextAnimator.eraseText(setText, text, completion);
        }, fadeOutSeconds * 1000);
        return;
      }

      setText(text.substring(0, index));
      index++;

      setTimeout(fadeInStep, durationPerChar);
    };

    fadeInStep();
  }

  /**
   * 逐字擦除文本
   * @param setText 绑定的状态更新函数
   * @param text 要擦除的文本
   * @param completion 完成后回调
   */
  private static eraseText(
    setText: (text: string) => void,
    text: string,
    completion?: () => void
  ) {
    if (!text) return;

    const totalLength = text.length;
    const durationPerChar = 100; // 每个字符擦除动画时长 ms

    let index = totalLength;

    const eraseStep = () => {
      if (index < 0) {
        completion?.();
        return;
      }

      setText(text.substring(0, index));
      index--;

      setTimeout(eraseStep, durationPerChar);
    };

    eraseStep();
  }
}