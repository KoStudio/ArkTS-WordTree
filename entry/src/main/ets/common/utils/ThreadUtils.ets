import { process } from "@kit.ArkTS";
import { DebugLog } from "../../app/debug/DebugLog";

// 主线程检查工具类
export class ThreadUtils {
  /**
   * 判断当前是否为主线程
   */
  static isMainThread(): boolean {
    return process.tid === process.pid; // 主线程时两者相等
  }

  /**
   * 打印完整线程信息
   */
  /**
   * 获取当前线程诊断信息
   */
  static dumpThreadInfo(): string {
    const pm = new process.ProcessManager();
    const str =  `
      Process ID: ${process.pid}
      Thread ID: ${process.tid}
      Is Main: ${process.tid === process.pid}
      Is 64Bit: ${process.is64Bit()}
      Thread Priority: ${pm.getThreadPriority(process.tid)}
      Uptime: ${process.uptime()}ms
    `;

    DebugLog.d(str)
    return str
  }

}
