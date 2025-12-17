// 字符串工具类
export class StringPyHelper {

  //// 复合字符编码(拼音) 统一转换为复合形式
  /// 若用拼音保存为文件名时，这时Mac上文件(路径)名的编码形式，码点形式也会被自动转换为复合码形式
  /// 因为腾讯云Cos上的文件是直接从Mac上传的，所以必须要采用相同的字符形式，才能在Cos的SDK下载时URLEncode地址也一样
  static convertUnicodeForPinyin(str: string): string {
    if (!str || str.length === 0) return str;

    ///////////////////////////////////////////////////////////////
    //通过URL可将码点表示 ---转换成---> 复合码表示，
    //   "t\u{00f3}u n\u{01ce}o"   // 码点直接表示:tóu nǎ
    //       ↓↓↓↓↓↓↓↓↓↓↓↓
    //   "to\u{0301}u na\u{030c}o" // 复合码表示: tóu nǎo
    ///////////////////////////////////////////////////////////////

    ///可直接使用此方法将预设置码点字符转换为标准的分解字符
    // by ko 2020.12.22
    return str.normalize('NFD'); // NFD: 标准分解
  }

  /// 检测是否为字母
  static isAlphabet(str: string): boolean {
    return Array.from(str).every(c => /[a-zA-Z]/.test(c));
  }

  /// 检测是否为汉字
  static isChinese(text: string): boolean {
    // return Array.from(text).every(c => {
    //   const code = c.charCodeAt(0);
    //   return code >= 0x4E00 && code <= 0x9FFF;
    // });
    // 实现你的中文判断逻辑
    return /[\u4e00-\u9fa5]/.test(text);
  }

  /// 检测是否包含拼音（不能区分英文）
  static isPinyin(str: string): boolean {
    // 拼音字符集，包括大小写字母和声调符号
    const pinyinLetters = new Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZüÜáàǎāéèěēíìǐíóòǒōúùǔūǖǘǚǜ");

    // 遍历当前字符串中的每个字符
    for (const char of str) {
      // 如果当前字符是拼音字符，返回true
      if (pinyinLetters.has(char)) {
        return true;
      }
    }
    // 如果没有找到任何拼音字符，返回false
    return false;
  }

  ///返回当前字符串中含有的声调的个数，用于Debug时检查sentencePy数据
  static pinyinToneCount(str: string): number {
    // 去除前后空白并转换为拼音形式
    const s = StringPyHelper.convertUnicodeForPinyin(str.trim());
    if (!s) return 0; // 空字符串视为没有声调

    // 初始化一个声调计数器
    let toneCount = 0;

    // 声调符号对应的Unicode值
    const toneMarks = new Set([0x0304, 0x0301, 0x030c, 0x0300]); // 对应声调符号1,2,3,4

    // 遍历字符的unicodeScalars，统计声调符号出现的次数
    for (let i = 0; i < s.length; i++) {
      const code = s.charCodeAt(i);
      if (toneMarks.has(code)) {
        toneCount++;
      }
    }

    return toneCount;
  }

  //检查当前拼音是否含有声调 qíng/qing
  static isPinyinContainsPyTone(str: string): boolean {
    // 去除前后空白
    const s = StringPyHelper.convertUnicodeForPinyin(str.trim());
    if (!s) return false; // 空字符串视为忽略

    // 检查组合字符
    for (let i = 0; i < s.length; i++) {
      const code = s.charCodeAt(i);
      if (code === 0x0304 || // "\u{0304}" 1声
        code === 0x0301 || // \u{0301} 2声
        code === 0x030c || // \u{030c} 3声
        code === 0x0300) { // \u{0300} 4声
        return true;
      }
    }

    return false;
  }

  ///检查是否所有拼音都不包含声调 qíng bù zì yǐ
  static isPinyinContainsPyToneWithAll(str: string): boolean {
    const a = str.trim()
      .replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g, '') // 移除标点
      .split(' ') // 空格区分
      .filter(s => s.length > 0); // 过滤空字符串

    // 如果全部都是空字符串
    if (a.length === 0) return false;

    for (const s of a) {
      // 只要有一个不包含声调，就返回false
      if (s && !StringPyHelper.isPinyinContainsPyTone(s)) {
        return false;
      }
    }

    return true;
  }
}
