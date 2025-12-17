import { getString } from "./ResourceUtils";

// MARK: - 日期工具类
export class DateUtils {

  /**
   * 计算从指定日期到另一个日期的天数差（可以是负数，表示先后顺序）
   * @param from 起始日期
   * @param to 结束日期
   * @returns 天数差（整数，可能为负数）
   */
  static daysTo(from: Date, to: Date): number {
    // 只保留年月日
    const start = new Date(from.getFullYear(), from.getMonth(), from.getDate());
    const end = new Date(to.getFullYear(), to.getMonth(), to.getDate());

    const msPerDay = 24 * 60 * 60 * 1000;
    return Math.floor((end.getTime() - start.getTime()) / msPerDay);
  }

  /**
   * 计算两个日期之间的天数差
   * @param start 开始日期
   * @param end 结束日期
   * @returns 天数差（绝对值）
   */
  static daysBetween(start: Date, end: Date): number {
    // 只保留年月日
    const s = new Date(start.getFullYear(), start.getMonth(), start.getDate());
    const e = new Date(end.getFullYear(), end.getMonth(), end.getDate());

    const msPerDay = 24 * 60 * 60 * 1000;
    return Math.abs(Math.floor((e.getTime() - s.getTime()) / msPerDay));
  }

  /**
   * 日期比较（大于）
   * @param date1 基准日期
   * @param date2 对比日期
   * @returns true 如果 date1 > date2
   */
  static isGreater(date1: Date, date2: Date): boolean {
    return date1.getTime() > date2.getTime();
  }

  /**
   * 日期比较（小于）
   * @param date1 基准日期
   * @param date2 对比日期
   * @returns true 如果 date1 < date2
   */
  static isLess(date1: Date, date2: Date): boolean {
    return date1.getTime() < date2.getTime();
  }

  /**
   * 日期相等判断
   * @param date1 日期1
   * @param date2 日期2
   * @returns true 如果时间戳相同
   */
  static equal(date1: Date, date2: Date): boolean {
    return date1.getTime() === date2.getTime();
  }

  /**
   * 增加天数
   * @param date 基准日期
   * @param daysToAdd 增加的天数
   * @returns 新日期对象
   */
  static addDays(date: Date, daysToAdd: number): Date {
    return new Date(date.getTime() + daysToAdd * 86400000); // 24 * 60 * 60 * 1000
  }

  /**
   * 增加小时
   * @param date 基准日期
   * @param hoursToAdd 增加的小时数
   * @returns 新日期对象
   */
  static addHours(date: Date, hoursToAdd: number): Date {
    return new Date(date.getTime() + hoursToAdd * 3600000); // 60 * 60 * 1000
  }

  /**
   * 增加分钟
   * @param date 基准日期
   * @param minutesToAdd 增加的分钟数
   * @returns 新日期对象
   */
  static addMinutes(date: Date, minutesToAdd: number): Date {
    return new Date(date.getTime() + minutesToAdd * 60000); // 60 * 1000
  }


  /**
   * 返回较大的日期
   * @param date1 日期1（可选）
   * @param date2 日期2（可选）
   * @returns 较大的日期或 null
   */
  static maxDate(date1: Date | null, date2: Date | null): Date | null {
    if (!date1) return date2;
    if (!date2) return date1;
    return date1.getTime() > date2.getTime() ? date1 : date2;
  }

  /**
   * 获取相对于今天的日期字符串
   * 如果是今天、昨天、明天，则返回对应本地化字符串
   * 否则返回 "YYYY-MM-DD" 格式
   * @param date 目标日期
   */
  static toDateString_YTT(date: Date): string {
    const today = new Date();

    // 只保留年月日
    const daysToNow = DateUtils.daysTo(date, today);

    if (daysToNow === 0) {
      return getString($r("app.string.common_date_str_today")); // 今天
    } else if (daysToNow === 1) {
      return getString($r("app.string.common_date_str_yesterday")); // 昨天
    } else if (daysToNow === -1) {
      return getString($r("app.string.common_date_str_tomorrow")); // 明天
    }

    return DateUtils.toDateString(date); // 默认返回 YYYY-MM-DD
  }


  /**
   * 格式化为日期字符串[YYYY-MM-DD]
   * @param date 要格式化的日期对象
   * @returns "YYYY-MM-DD"格式的日期字符串
   */
  static toDateString(date: Date): string {
    return DateUtils.formatDate(date, 'YYYY-MM-DD');
  }

  /**
   * 格式化为日期时间字符串[YYYY-MM-DD HH:mm:ss]
   * @param date 要格式化的日期对象
   * @returns "YYYY-MM-DD HH:mm:ss"格式的日期时间字符串
   */
  static toDateTimeString(date: Date): string {
    return DateUtils.formatDate(date, 'YYYY-MM-DD HH:mm:ss');
  }



  /**
   * 格式化为完整日期时间字符串[YYYY-MM-DD HH:mm:ss.SSS]
   * @param date 要格式化的日期对象
   * @returns "YYYY-MM-DD HH:mm:ss.SSS"格式的完整日期时间字符串
   */
  static toFullString(date: Date): string {
    return DateUtils.formatDate(date, 'YYYY-MM-DD HH:mm:ss.SSS');
  }

  /**
   * 核心日期格式化方法（静态方法）
   * @param date 要格式化的日期对象
   * @param format 格式字符串（支持YYYY/YY/MM/M/DD/D/HH/H/mm/m/ss/s/SSS占位符）
   * @returns 格式化后的日期字符串
   */
  static formatDate(date: Date, format: string): string {
    // 创建类型安全的日期值映射对象
    const dateValues: IDateValues = {
      year: date.getFullYear(),
      month: date.getMonth() + 1,  // 月份从0开始，需+1
      day: date.getDate(),
      hours: date.getHours(),
      minutes: date.getMinutes(),
      seconds: date.getSeconds(),
      milliseconds: date.getMilliseconds()
    };

    // 使用正则表达式替换格式字符串中的占位符
    return format.replace(/(YYYY|YY|MM|M|DD|D|HH|H|mm|m|ss|s|SSS)/g, (match) => {
      switch (match) {
        case 'YYYY': return dateValues.year.toString();
        case 'YY': return dateValues.year.toString().slice(-2);
        case 'MM': return DateUtils.padZero(dateValues.month);
        case 'M': return dateValues.month.toString();
        case 'DD': return DateUtils.padZero(dateValues.day);
        case 'D': return dateValues.day.toString();
        case 'HH': return DateUtils.padZero(dateValues.hours);
        case 'H': return dateValues.hours.toString();
        case 'mm': return DateUtils.padZero(dateValues.minutes);
        case 'm': return dateValues.minutes.toString();
        case 'ss': return DateUtils.padZero(dateValues.seconds);
        case 's': return dateValues.seconds.toString();
        case 'SSS': return DateUtils.padZero(dateValues.milliseconds, 3);
        default: return match;
      }
    });
  }


  /**
   * 解析UTC格式日期字符串
   * @param dateStr UTC格式日期字符串
   * @param format UTC格式，默认为"yyyy-MM-dd'T'HH:mm:ss.000'Z'"
   * @returns 解析成功的Date对象，失败返回null
   */
  static toDateFromUTC(dateStr: string, format: string = "yyyy-MM-dd'T'HH:mm:ss.000'Z'"): Date | null {
    return DateUtils.toDate(dateStr, format);
  }

  /**
   * 解析固定格式UTC日期字符串
   * @param dateStr UTC格式日期字符串
   * @returns 解析成功的Date对象，失败返回null
   */
  static toUTCDate(dateStr: string): Date | null {
    return DateUtils.toDate(dateStr, "yyyy-MM-dd'T'HH:mm:ss.000'Z'");
  }

  /**
   * 解析GMT格式日期字符串
   * @param dateStr GMT格式日期字符串
   * @returns 解析成功的Date对象，失败返回null
   */
  static toGMTDate(dateStr: string): Date | null {
    return DateUtils.toDate(dateStr, "EEE, dd MMM yyyy HH:mm:ss 'GMT'");
  }

  /**
   * 日期字符串解析（ArkTS 规范实现）
   * @param dateStr 日期字符串
   * @param format 格式（默认：'YYYY-MM-DD HH:mm:ss.SSS'）
   * @returns Date 对象或 null（解析失败时）
   */
  static toDate(dateStr: string, format: string = 'YYYY-MM-DD HH:mm:ss.SSS'): Date | null {
    try {
      // 处理本地时间格式 (YYYY-MM-DD HH:mm:ss.SSS)
      if (format === 'YYYY-MM-DD HH:mm:ss.SSS') {
        // 替代解构：使用临时数组存储分割结果
        const parts = dateStr.split(' ');
        if (parts.length < 2) return null;

        const datePart = parts[0]; // 日期部分
        const timePart = parts[1]; // 时间部分

        // 分割日期组件
        const dateComponents = datePart.split('-').map(Number);
        if (dateComponents.length < 3) return null;

        // 分割时间组件
        const timeComponents = timePart.split(':');
        if (timeComponents.length < 3) return null;

        // 处理秒和毫秒
        const secondsWithMs = timeComponents[2];
        const secondsParts = secondsWithMs.split('.').map(Number);
        const milliseconds = secondsParts.length > 1 ? secondsParts[1] : 0;

        return new Date(
          dateComponents[0], // 年
          dateComponents[1] - 1, // 月（0-11）
          dateComponents[2], // 日
          Number(timeComponents[0]), // 时
          Number(timeComponents[1]), // 分
          secondsParts[0], // 秒
          milliseconds // 毫秒
        );
      }

      // 处理UTC时间格式 (yyyy-MM-dd'T'HH:mm:ss.000'Z') [1,6](@ref)
      if (format === "yyyy-MM-dd'T'HH:mm:ss.000'Z'") {
        const parts = dateStr.split('T');
        if (parts.length < 2) return null;

        const datePart = parts[0];
        const timePart = parts[1].replace('Z', '');

        // 分割日期组件
        const dateComponents = datePart.split('-').map(Number);
        if (dateComponents.length < 3) return null;

        // 分割时间组件
        const timeComponents = timePart.split(':');
        if (timeComponents.length < 3) return null;

        return new Date(Date.UTC(
          dateComponents[0], // 年
          dateComponents[1] - 1, // 月（0-11）
          dateComponents[2], // 日
          Number(timeComponents[0]), // 时
          Number(timeComponents[1]), // 分
          Number(timeComponents[2]) // 秒
        ));
      }

      // 处理GMT时间格式 (EEE, dd MMM yyyy HH:mm:ss 'GMT') [4](@ref)
      if (format === "EEE, dd MMM yyyy HH:mm:ss 'GMT'") {
        const parts = dateStr.split(' ');
        if (parts.length < 6) return null;

        // 月份名称映射
        const monthsMap: Record<string, number> = {
          'Jan': 0, 'Feb': 1, 'Mar': 2, 'Apr': 3, 'May': 4, 'Jun': 5,
          'Jul': 6, 'Aug': 7, 'Sep': 8, 'Oct': 9, 'Nov': 10, 'Dec': 11
        };

        // 分割时间组件
        const timeComponents = parts[4].split(':');
        if (timeComponents.length < 3) return null;

        return new Date(
          Number(parts[3]), // 年
          monthsMap[parts[2]], // 月（0-11）
          Number(parts[1]), // 日
          Number(timeComponents[0]), // 时
          Number(timeComponents[1]), // 分
          Number(timeComponents[2]) // 秒
        );
      }

      // 默认尝试内置解析 [1,4](@ref)
      const parsedDate = new Date(dateStr);
      return isNaN(parsedDate.getTime()) ? null : parsedDate;

    } catch (e) {
      console.error('日期解析错误:', e);
      return null;
    }
  }


  /**
   * 左侧补零函数（私有静态方法）
   * @param value 需要补零的数字
   * @param len 目标长度，默认2位
   * @returns 补零后的字符串
   */
  private static padZero(value: number, len: number = 2): string {
    return value.toString().padStart(len, '0');
  }


}

// 定义日期值结构的显式接口
interface IDateValues {
  year: number;
  month: number;
  day: number;
  hours: number;
  minutes: number;
  seconds: number;
  milliseconds: number;
}
