
// 空格和换行字符串
const emptyStr: string[] = [
  " ",   // 空格 半角
  "　",  // 空格 全角
  "\r",
  "\n"
];

// 标点符号
const punkMarks: Set<string> = new Set([
  ",", "、", "，",
  ".", "。", "・",
  "!", "！",
  "?", "？",
  ";", "；",
  ":", "：",
  "'", "\"", "’", "”", "“", "”",
  "\\", "¥", "#", "$", "%", "&", "~", "^", "|", "_", "=", "-", "+", "*", "/",
  "…", "ー",
  "(", ")", "[", "]", "{", "}", "《", "》", "<", ">",
  "（", "）", "「", "」", "『", "』"
]);


// 字符串工具类
export class StringUtils {
  
  /**
   * 去除前后空格
   * @param str 输入字符串
   * @returns 处理后的字符串
   */
  static trimedString(str: string): string {
    return str.trim();
  }

  /**
   * 是否包含空格或换行字符
   * @param str 输入字符串
   * @returns 是否包含
   */
  static containsEmpty(str: string): boolean {
    const chars = Array.from(str);
    for (const c of chars) {
      if (emptyStr.includes(c)) {
        return true;
      }
    }
    return false;
  }

  /**
   * 是否包含标点符号
   * @param str 输入字符串
   * @returns 是否包含
   */
  static containsPunctuations(str: string): boolean {
    const chars = Array.from(str);
    for (const c of chars) {
      if (punkMarks.has(c)) {
        return true;
      }
    }
    return false;
  }

  /**
   * 是否包含重复字符（空格和换行不算重复）
   * @param str 输入字符串
   * @returns 是否包含
   */
  static containsDuplicates(str: string): boolean {
    const set = new Set<string>();
    const chars = Array.from(str);

    for (const c of chars) {
      if (!emptyStr.includes(c)) {
        if (set.has(c)) {
          return true;
        }
        set.add(c);
      }
    }
    return false;
  }

  /**
   * 去除空格和换行符
   * @param str 输入字符串
   * @returns 处理后的字符串
   */
  static removedEmpty(str: string): string {
    let result = str;
    for (const empty of emptyStr) {
      result = result.split(empty).join('');
    }
    return result;
  }

  /**
   * 去除标点符号
   * @param str 输入字符串
   * @returns 处理后的字符串
   */
  static removedPunctuations(str: string): string {
    return Array.from(str)
      .filter(c => !punkMarks.has(c))
      .join('');
  }

  /**
   * 去除重复字符（保留顺序）
   * @param str 输入字符串
   * @returns 处理后的字符串
   */
  static removedDuplicates(str: string): string {
    const set = new Set<string>();
    const result: string[] = [];
    const chars = Array.from(str);

    for (const c of chars) {
      if (emptyStr.includes(c)) {
        result.push(c);
      } else if (!set.has(c)) {
        set.add(c);
        result.push(c);
      }
    }

    return result.join('');
  }

  /**
   * 统一替换换行符为半角空格
   * @param str 输入字符串
   * @returns 处理后的字符串
   */
  static replacedToSpace(str: string): string {
    return str
      .replace(/\r\n/g, ' ')  // 优先处理Windows换行
      .replace(/\r/g, ' ')    // 处理Mac换行
      .replace(/\n/g, ' ')    // 处理Unix/Linux换行
      .replace(/　/g, ' ')    // 替换全角空格
      .replace(/\s+/g, ' ');  // 关键：将任意长度的连续空白字符压缩为一个空格
  }

  /**
   * 验证邮箱格式是否正确
   * @param email 输入的邮箱字符串
   * @returns 是否是合法的邮箱格式
   */
  static isValidEmail(email: string): boolean {
    const emailRegex: RegExp = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,64}$/i;
    return emailRegex.test(email);
  }

  /**
   * 将字符串打乱（Fisher–Yates 洗牌）
   * @param str 要打乱的字符串
   * @returns 打乱后的字符串
   */
  static randomed(str: string): string {
    // 如果为空或非字符串，直接返回原值
    if (!str) return str;

    // 将字符串拆成字符数组（支持 Unicode 较好）
    const chars: string[] = Array.from(str);

    // 从后向前遍历，随机交换当前位置与前面某个位置的字符
    // 这就是 Fisher–Yates 洗牌算法
    for (let i = chars.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1)); // 生成 0..i 的随机索引

      // ArkTS 不支持解构赋值，使用临时变量交换元素
      const tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }

    // 重新拼回字符串并返回
    return chars.join('');
  }
}
