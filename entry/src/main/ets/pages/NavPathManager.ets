
export class NavPathManager {
  private static _instance: NavPathManager
  private _navPath: NavPathStack

  // === 单例初始化 ===
  private constructor() {
    this._navPath = new NavPathStack()
  }

  static get shared(): NavPathManager {
    if (!this._instance) {
      this._instance = new NavPathManager()
    }
    return this._instance
  }

  // === 访问器 ===
  get navPath(): NavPathStack {
    return this._navPath
  }

  // ======================================================================
  // MARK: - 常用导航操作封装
  // ======================================================================

  /**
   * 推入一个页面路径
   * @param alwaysNew 如果为true，总是创建新实例；如果为false，页面已存在时复用现有页面
   */
  push<T>(path: string, params?: T, animated: boolean = true, alwaysNew: boolean = true) {
    // 检查目标路径是否已存在于导航栈中[1](@ref)
    const existingIndexes: Array<number> = this._navPath.getIndexByName(path);
    const pageExists = existingIndexes.length > 0;

    if (pageExists && !alwaysNew) {
      // 页面已存在且不要求新建：回退到栈中最后一个该页面（离栈顶最近的）
      const targetIndex = existingIndexes[existingIndexes.length - 1];
      this._navPath.popToIndex(targetIndex, animated ?? true);
    } else {
      // 要求新建或页面不存在：正常推入新页面
      if (params !== undefined) {
        this._navPath.pushPathByName(path, params, animated ?? true);
      } else {
        this._navPath.pushPathByName(path, animated ?? true);
      }
    }
  }

  /** 弹出一个页面 */
  popBack(animated?: boolean) {
    this._navPath.pop(animated ?? true)
  }

  /** 返回到最顶层（首页） */
  popTop(animated?: boolean) {
    this._navPath.popToIndex(-1, animated ?? true)
  }

  /**
   * 返回到指定路径
   * @param target 目标路径字符串
   */
  popTo(index: number, animated?: boolean) {
    this._navPath.popToIndex(index, animated ?? true)
  }

  popToName(name: string, animated?: boolean){
    this._navPath.popToName(name, animated ?? true)
  }

  /** 清空所有导航路径 */
  clear(animated?: boolean) {
    this._navPath.clear(animated ?? true)
  }



  /** 打印当前导航栈（调试用） */
  debugPrint() {
    console.log('[NavPathManager] Stack:', JSON.stringify(this._navPath))
  }
}

// ======================================================================
// MARK: - 全局快速调用函数
// ======================================================================

/** 跳转页面 */
export function NavTo<T>(path: string, params?: T, animated: boolean = true, alwaysNew: boolean = true) {
  NavPathManager.shared.push(path, params, animated, alwaysNew)
}

/** 返回上一个页面 */
export function NavPop(animated?: boolean) {
  NavPathManager.shared.popBack(animated)
}

/** 返回到首页（栈顶） */
export function NavPopTop(animated?: boolean) {
  NavPathManager.shared.popTop(animated)
}

/** 返回到指定栈索引 */
export function NavPopToIndex(index: number, animated?: boolean) {
  NavPathManager.shared.popTo(index, animated)
}

/** 返回到指定页面名称 */
export function NavPopToName(name: string, animated?: boolean) {
  NavPathManager.shared.popToName(name, animated)
}

/** 清空导航栈 */
export function NavClear(animated?: boolean) {
  NavPathManager.shared.clear(animated)
}