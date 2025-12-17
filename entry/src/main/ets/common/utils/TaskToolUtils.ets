
import { lang, taskpool } from '@kit.ArkTS';  // 引入ISendable


/**
 * 全局TaskPool执行函数（类型安全版）
 * @param func 用@Concurrent装饰的全局函数
 * @param args 可序列化的参数（需符合TaskPool序列化支持类型）
 * @returns Promise<T | null> 执行结果或null（失败时）
 */
export async function executeInTaskPool<T, P extends Array<lang.ISendable>>(func: (...args: P) => T, ...args: P): Promise<T | null> {
  try {
    const task = new taskpool.Task(func, ...args);
    return await taskpool.execute(task) as T;
  } catch (error) {
    console.error("TaskPool执行失败:", error);
    return null;
  }
}


