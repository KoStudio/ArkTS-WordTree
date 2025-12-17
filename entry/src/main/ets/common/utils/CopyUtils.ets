import { pasteboard } from "@kit.BasicServicesKit";



export class CopyUtils {

  /**
   * 实现文本复制功能
   * @param text 要复制的文本
   */
  public static copyText(text: string): void {
    // 创建剪贴板条目
    const pasteboardData   = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    const systemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(pasteboardData); // Put data into clipboard
  }


  // public static pasteText(): string | null {
  //   // 获取系统剪贴板
  //   const systemPasteboard = pasteboard.getSystemPasteboard();
  //
  //   // 获取剪贴板的数据（普通文本）
  //   const pasteboardData = systemPasteboard.getDataSync()
  //
  //   /////在应用级输入法中，直接调用getPrimaryText()违反应用内输入法的安全限制
  //   return pasteboardData.getPrimaryText()
  //
  // }
}