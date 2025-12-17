/**
 * 轻量级类型安全事件总线（静态方法版）
 * 功能：事件订阅(on)、取消订阅(off)、一次性订阅(once)、事件触发(emit)
 */
export class SimpleEventBus {
  // 存储常规事件监听器（事件名 => 处理器数组）
  private static listeners: Map<string, Function[]> = new Map();
  // 存储一次性事件监听器（事件名 => 处理器数组）
  private static onceListeners: Map<string, Function[]> = new Map();

  /**
   * 触发事件
   * @param event 事件名称
   * @param data 事件数据（泛型T，默认为void）
   */
  static emit<T = void>(event: string, data?: T): void {
    // 处理常规监听器
    const handlers = SimpleEventBus.listeners.get(event);
    handlers?.forEach(handler => {
      try {
        handler(data);
      } catch (err) {
        console.error(`[事件处理错误] ${event}:`, err);
      }
    });

    // 处理一次性监听器（执行后自动移除）
    const onceHandlers = SimpleEventBus.onceListeners.get(event);
    if (onceHandlers) {
      onceHandlers.forEach(handler => {
        try {
          handler(data);
        } catch (err) {
          console.error(`[一次性事件处理错误] ${event}:`, err);
        }
      });
      SimpleEventBus.onceListeners.delete(event); // 执行后清除
    }

    // 无订阅者警告
    if (!handlers && !onceHandlers) {
      console.warn(`[无订阅者] 事件 "${event}" 未被监听`);
    }
  }

  /**
   * 订阅事件（持续监听）
   * @param event 事件名称
   * @param handler 处理函数（自动推断参数类型）
   * @returns 取消订阅的函数
   */
  static on<T = void>(event: string, handler: (data?: T) => void): () => void {
    if (typeof handler !== 'function') {
      throw new Error('处理器必须为函数');
    }

    // 初始化事件队列
    if (!SimpleEventBus.listeners.has(event)) {
      SimpleEventBus.listeners.set(event, []);
    }

    // 添加处理器
    SimpleEventBus.listeners.get(event)!.push(handler);

    // 返回取消订阅函数
    return () => SimpleEventBus.off(event, handler);
  }

  /**
   * 一次性订阅（触发后自动取消）
   * @param event 事件名称
   * @param handler 处理函数
   */
  static once<T = void>(event: string, handler: (data?: T) => void): void {
    if (typeof handler !== 'function') {
      throw new Error('处理器必须为函数');
    }

    // 初始化一次性事件队列
    if (!SimpleEventBus.onceListeners.has(event)) {
      SimpleEventBus.onceListeners.set(event, []);
    }

    // 添加处理器
    SimpleEventBus.onceListeners.get(event)!.push(handler);
  }

  /**
   * 取消订阅
   * @param event 事件名称
   * @param handler 要移除的处理器（不传则移除该事件所有处理器）
   */
  static off(event: string, handler?: Function): void {
    // 从常规监听器移除
    if (SimpleEventBus.listeners.has(event)) {
      if (!handler) {
        SimpleEventBus.listeners.delete(event);
      } else {
        const handlers = SimpleEventBus.listeners.get(event)!;
        const newHandlers = handlers.filter(h => h !== handler);
        newHandlers.length > 0
          ? SimpleEventBus.listeners.set(event, newHandlers)
          : SimpleEventBus.listeners.delete(event);
      }
    }

    // 从一次性监听器移除（可选）
    if (handler && SimpleEventBus.onceListeners.has(event)) {
      const onceHandlers = SimpleEventBus.onceListeners.get(event)!;
      const newOnceHandlers = onceHandlers.filter(h => h !== handler);
      newOnceHandlers.length > 0
        ? SimpleEventBus.onceListeners.set(event, newOnceHandlers)
        : SimpleEventBus.onceListeners.delete(event);
    }
  }
}