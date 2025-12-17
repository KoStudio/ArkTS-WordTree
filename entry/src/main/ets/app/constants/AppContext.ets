// =====================================================================
// AppContext.ts
// 全局应用上下文管理工具
// 用于在 ArkTS 应用中保存和访问 ApplicationContext 与 UIContext。
// =====================================================================

import common from '@ohos.app.ability.common'

/**
 * AppContext：静态类
 * 负责保存与提供全局 ApplicationContext / UIContext。
 *
 * 使用步骤：
 * 1. 在应用启动时调用 `initAppContext(context)` 初始化。
 * 2. 可在任意模块中通过 `getAppContext()` 获取全局 ApplicationContext。
 * 3. 可在 UI 层组件中通过 `getUIContext()` 获取 UIContext。
 */
class AppContext {
  // 静态属性：应用级上下文（整个应用生命周期存在）
  private static _appContext?: common.UIAbilityContext

  // 静态属性：UI 上下文（页面级别上下文）
  private static _uiContext?: UIContext

  /**
   * 初始化应用上下文。
   * 通常在 EntryAbility 的 onCreate() 中调用一次。
   */
  static initAppContext(context: common.UIAbilityContext): void {
    if (AppContext._appContext) {
      console.warn('[AppContext] ApplicationContext 已初始化，无需重复设置。')
      return
    }
    AppContext._appContext = context
  }

  /**
   * 初始化 UI 上下文。
   * 通常在页面或组件的 aboutToAppear() 生命周期中调用。
   */
  static initUIContext(context: UIContext): void {
    AppContext._uiContext = context
  }

  /**
   * 获取全局 ApplicationContext。
   * 若未初始化则抛出错误。
   */
  static get appContext(): common.UIAbilityContext {
    if (!AppContext._appContext) {
      throw new Error('[AppContext] ApplicationContext 尚未初始化，请先调用 initAppContext()。')
    }
    return AppContext._appContext
  }

  /**
   * 获取当前 UIContext。
   * 若未初始化则抛出错误。
   */
  static get uiContext(): UIContext {
    if (!AppContext._uiContext) {
      throw new Error('[AppContext] UIContext 尚未初始化，请先调用 initUIContext()。')
    }
    return AppContext._uiContext
  }
}

// ---------------------------------------------------------------------
// 导出函数式封装（更方便使用）
// ---------------------------------------------------------------------

/** 获取 ApplicationContext（推荐方式） */
export function getAppContext(): common.UIAbilityContext {
  return AppContext.appContext
}

/** 获取 UIContext（推荐方式） */
export function getUIContext(): UIContext {
  return AppContext.uiContext
}

/** 初始化 ApplicationContext（在应用入口调用） */
export function initAppContext(context: common.UIAbilityContext): void {
  AppContext.initAppContext(context)
}

/** 初始化 UIContext（在页面入口调用） */
export function initUIContext(context: UIContext): void {
  AppContext.initUIContext(context)
}

// =====================================================================
// 使用示例：
// =====================================================================
//
// // 在 EntryAbility 中：
// onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
//   initAppContext(this.context)
// }
//
// // 在页面组件中：
// aboutToAppear() {
//   initUIContext(this.getUIContext())
// }
//
// // 在任意模块中：
// const appCtx = getAppContext()
// const uiCtx = getUIContext()
// =====================================================================