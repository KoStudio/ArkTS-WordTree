//
//  EBookConstants.ets
//  WordTree
//
//  为何单独文件（与 iOS / Android 结构不同）：
//  - iOS：`EBookMinBookId` 写在 `EBookManager` 上，`Book2.isEBook` 使用 `EBookManager.EBookMinBookId`，Swift 中无问题。
//  - 鸿蒙：`EBookManager` 已 import `Book`（创建 `new Book()`）。若 `Book` 再 import `EBookManager` 取常量，会形成
//    `EBookManager → Book → EBookManager` 的模块循环依赖，ArkTS 编译/打包易失败。
//  - 因此将数值常量放在本文件，供 `Book` 与 `EBookManager` 共同引用；语义与 iOS `EBookManager.EBookMinBookId` 完全一致。
//

/** 本地 EBook 使用的最小 bookId（避免与服务器下发的 CBook 冲突）。与 iOS `EBookManager.EBookMinBookId`、Android 一致。备份上传时，服务器上的 ServerBookId 从 10001 开始。 */
export const EBookMinBookId: number = 1001
