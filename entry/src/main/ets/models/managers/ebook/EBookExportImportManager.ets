import fs from '@ohos.file.fs'
import { Want } from '@kit.AbilityKit'
import { dAppCachefolder } from '../../../app/constants/AppDefines'
import { createFolderIfNeeds } from '../../../app/constants/AppFunctions'
import { FileUtility } from '../../../common/utils/FileUtility'
import { ZipTool } from '../../../common/utils/ZipTool'
import { PathUtility } from '../../../common/utils/PathUtility'
import { getString, getStringF } from '../../../common/utils/ResourceUtils'
import { Toast } from '../../../common/utils/Toast'
import { Book } from '../../datas/book/Book'
import { BookManager, BookManagerNotification } from '../../datas/book/BookManager'
import { EBookManager } from './EBookManager'
import { MemberManager } from '../member/MemberManager'
import { DebugLog } from '../../../app/debug/DebugLog'
import { WordUserDbAccess } from '../../datas/myData/WordUserDbAccess'
import { SearchManager } from '../../datas/model/SearchManager'
import { SimpleEventBus } from '../../../common/components/eventbus/SimpleEventBus'

// 与 iOS `EBookExportImportManager` 对齐：本地 EBook 导出 / 导入 .wte（实为 zip）、他应用打开 .wte 确认导入
export class EBookExportImportManager {

  private static instance: EBookExportImportManager = new EBookExportImportManager()

  private static pendingWteOpenPath: string | null = null

  static get shared(): EBookExportImportManager {
    return EBookExportImportManager.instance
  }

  static readonly fileExtension: string = 'wte'

  /**
   * EntryAbility 收到 Want 时调用：路径为 .wte 且文件存在则记入待导入队列。
   * @param want 启动或 onNewWant 传入的 Want
   */
  static offerWantForWteOpenIfNeed(want: Want | undefined): void {

    // 分支：Want 不存在时直接返回
    if (want === undefined) {
      return
    }

    let uriRaw: string | undefined = want.uri

    // 分支：uri 为空时，尝试从 parameters.path 兜底
    if ((uriRaw === undefined || uriRaw.length < 1) && want.parameters) {

      const p = want.parameters['path'] as string | undefined

      // 分支：兜底路径可用时覆盖 uriRaw
      if (p !== undefined && p.length > 0) {
        uriRaw = p
      }
    }

    // 分支：仍无可用路径时返回
    if (uriRaw === undefined || uriRaw.length < 1) {
      return
    }

    let path = uriRaw

    // 分支：file:// 前缀需要裁剪成真实文件路径
    if (path.indexOf('file://') === 0) {
      path = path.substring('file://'.length)
    }

    const lower = path.toLowerCase()

    // 分支：非 .wte 文件不处理
    if (!lower.endsWith(`.${EBookExportImportManager.fileExtension}`)) {
      return
    }

    // 分支：文件不存在时不入队
    if (!FileUtility.isFileExistAt(path)) {
      return
    }

    // 调用：缓存待导入路径，等待隐私同意后弹窗
    EBookExportImportManager.pendingWteOpenPath = path
  }

  /**
   * 隐私已同意且主界面可用时调用：若有待导入 .wte 则弹出确认框（与 iOS `checkToImportEBookIfNeed` 对齐）。
   */
  static tryPresentPendingWteImportIfReady(): void {

    const path = EBookExportImportManager.pendingWteOpenPath

    // 分支：无待导入路径时返回
    if (path === null || path === undefined || path.length < 1) {
      return
    }

    // 调用：先消费队列，避免重复弹窗
    EBookExportImportManager.pendingWteOpenPath = null

    // 调用：展示导入确认弹窗
    EBookExportImportManager.presentOpenWteImportConfirm(path)
  }

  /**
   * 导入成功后切换当前书并刷新用户词表、搜索（与 `EBookImportView` 内联逻辑一致）。
   * @param newBook 导入得到的本地 EBook
   */
  static applyImportSuccess(newBook: Book): void {

    // 调用：切换当前教材
    BookManager.shared.setCurrentBook(newBook)

    // 调用：每书独立 learnDb，切换后仅重连
    WordUserDbAccess.shared.refreshDb()

    // 调用：刷新全局搜索索引
    void SearchManager.shared.refreshData()

    // 调用：广播当前教材更新
    SimpleEventBus.emit(BookManagerNotification.currentBookUpdated)

    // 调用：广播教材列表更新
    SimpleEventBus.emit(BookManagerNotification.bookListUpdated)
  }

  /**
   * 弹出“检测到 .wte 文件”确认框，确认后执行导入。
   * @param filePath 外部打开的 .wte 路径
   */
  private static presentOpenWteImportConfirm(filePath: string): void {

    const fileName = PathUtility.getLastComponentName(filePath)

    // 调用：展示确认弹窗
    Toast.showAlert({
      title           : $r('app.string.ebook_import_detect_title'),
      message         : fileName,
      secondaryButton : {
        value     : $r('app.string.cfm_btn_cancel'),
        fontColor : Color.Gray,
        action    : () => {

          // 调用：取消时删除临时导入文件
          FileUtility.deleteFileAt(filePath)
        }
      },
      primaryButton   : {
        value  : $r('app.string.confirm_btn_import'),
        action : () => {

          // 调用：确认后执行导入
          void EBookExportImportManager.shared.importEBookAtPath(filePath,
            (ok: boolean, errMsg: string | null, newBook: Book | null) => {

              // 调用：导入流程结束后删除临时导入文件
              FileUtility.deleteFileAt(filePath)

              // 分支：导入失败时提示错误
              if (!ok) {

                // 调用：展示失败文案
                Toast.showMessage(errMsg ?? getString($r('app.string.ebook_import_failed_msg')))
                return
              }

              // 分支：导入成功并返回 book 时，执行后续刷新
              if (newBook !== null) {

                // 调用：应用导入成功后的统一刷新逻辑
                EBookExportImportManager.applyImportSuccess(newBook)

                const raw     = (newBook.bookName ?? '').trim()
                const display = raw.length < 1 ? getString($r('app.string.ebook_default_book_name')) : raw

                // 调用：展示导入成功提示
                Toast.showMessage(getStringF($r('app.string.ebook_import_success_fmt'), display))
              }
            })
        }
      }
    })
  }

  /**
   * 将单个 sqlite 包一层目录后打 zip（与 `CUserDataManager.createZipForSingleFileAtPath` / iOS `ZipUtility.createZip` 对齐）
   * @param srcPath 教材 sqlite 绝对路径
   * @returns zip 沙箱路径；失败则 null
   */
  private static async createWteForSingleSqliteAtPath(srcPath: string): Promise<string | null> {

    const base       = PathUtility.getLastComponentName(srcPath)
    const jobId      = `${Date.now()}`
    const exportRoot = FileUtility.appendPathComponent(dAppCachefolder, 'EBookExport')
    const wrapDir    = FileUtility.appendPathComponent(exportRoot, `_ebook_exp_${jobId}`)
    const innerDir   = FileUtility.appendPathComponent(wrapDir, 'inner')

    // 调用：确保导出根目录存在（与 iOS temporaryDirectory/EBookExport 对齐）
    createFolderIfNeeds(exportRoot)

    // 调用：确保中间目录存在
    createFolderIfNeeds(innerDir)

    const innerFile = FileUtility.appendPathComponent(innerDir, base)

    // 分支：复制 sqlite 失败时清理并返回
    if (!FileUtility.copyFile(srcPath, innerFile)) {

      // 调用：清理临时目录
      FileUtility.deleteDirectoryAt(wrapDir)
      return null
    }

    // 调用：打包 inner 目录为压缩包（ZipTool 当前输出为 .zip）
    const zipPathInWrapDir = await ZipTool.createOneZip(innerDir)

    // 分支：打包失败时清理并返回
    if (zipPathInWrapDir === null || !FileUtility.isFileExistAt(zipPathInWrapDir)) {

      // 调用：清理临时目录
      FileUtility.deleteDirectoryAt(wrapDir)
      return null
    }

    // 目标：在清理 wrapDir 前先把压缩包移动并统一改名为 .wte，避免被一并删除导致导出失败
    const exportedWtePath = FileUtility.appendPathComponent(exportRoot, `_ebook_exp_${jobId}.${EBookExportImportManager.fileExtension}`)

    // 调用：同名旧文件先删，避免 move 失败
    FileUtility.deleteFileAt(exportedWtePath)

    // 分支：移动压缩包并改名为 .wte 失败时清理并返回
    if (!FileUtility.moveFile(zipPathInWrapDir, exportedWtePath)) {

      // 调用：清理临时目录
      FileUtility.deleteDirectoryAt(wrapDir)
      return null
    }

    // 调用：打包完成后清理临时目录（此时 zip 已移出，不会被删除）
    FileUtility.deleteDirectoryAt(wrapDir)

    return exportedWtePath
  }

  /**
   * 导出 EBook 为 .wte；参数 book 须为 EBook 且本地 textDb 存在。
   * @param book        要导出的书
   * @param completion  (是否成功, 错误信息, 导出文件的沙箱路径)
   */
  exportEBook(book: Book,
    completion: (ok: boolean, errMsg: string | null, exportPath: string | null) => void): void {

    // 分支：仅允许导出 EBook 且 textDb 非空
    if (!book.isEBook || book.textDb === null || book.textDb === undefined) {
      completion(false, 'not an EBook', null)
      return
    }

    const textDbPath = EBookManager.textDbPath(book.textDb)

    // 分支：源 sqlite 不存在时返回
    if (!FileUtility.isFileExistAt(textDbPath)) {
      completion(false, 'EBook textDb missing', null)
      return
    }

    // 调用：创建单文件 .wte（内部仍为 zip 内容）
    void EBookExportImportManager.createWteForSingleSqliteAtPath(textDbPath).then((wtePath: string | null) => {

      // 分支：打包失败时返回错误
      if (wtePath === null || !FileUtility.isFileExistAt(wtePath)) {
        completion(false, getString($r('app.string.ebook_export_failed_msg')), null)
        return
      }

      const defName     = getString($r('app.string.ebook_default_book_name'))
      const rawName     = (book.bookName ?? defName).trim()
      const safeName    = EBookExportImportManager.safeFileName(rawName.length < 1 ? defName : rawName)
      const exportDir   = FileUtility.appendPathComponent(dAppCachefolder, 'EBookExport')

      // 调用：确保导出目录存在
      createFolderIfNeeds(exportDir)

      const exportPath  = FileUtility.appendPathComponent(exportDir, `${safeName}.${EBookExportImportManager.fileExtension}`)

      // 调用：清理同名旧导出文件
      FileUtility.deleteFileAt(exportPath)

      // 分支：移动导出文件失败时清理临时 .wte 并返回
      if (!FileUtility.moveFile(wtePath, exportPath)) {

        // 调用：删除未移动成功的临时 .wte
        FileUtility.deleteFileAt(wtePath)

        completion(false, getString($r('app.string.ebook_export_failed_msg')), null)
        return
      }

      completion(true, null, exportPath)
    })
  }

  /**
   * 从沙箱内 .wte 路径导入为本地 EBook。
   * @param filePath   源 .wte 绝对路径
   * @param completion (是否成功, 错误信息, 新建的书)
   */
  async importEBookAtPath(filePath: string,
    completion: (ok: boolean, errMsg: string | null, newBook: Book | null) => void): Promise<void> {

    // 与 iOS `MemberManager.checkEBookCreatable` 默认一致：弹会员 Sheet；提示文案由 completion 统一展示，避免与 MemberManager Toast 重复
    // 分支：会员上限校验不通过时返回
    if (!MemberManager.shared.checkEBookCreatable(false, true)) {
      completion(false, getString($r('app.string.member_manager_msg_limit_add_ebook')), null)
      return
    }

    // 分支：源文件不存在时返回
    if (!FileUtility.isFileExistAt(filePath)) {
      completion(false, 'file not exists', null)
      return
    }

    const ext = PathUtility.getLastComponentName(filePath).toLowerCase().split('.').pop()

    // 分支：扩展名不是 .wte 时返回
    if (ext !== EBookExportImportManager.fileExtension) {
      completion(false, 'not a wte file', null)
      return
    }

    const jobId      = `${Date.now()}`
    const tempRoot   = FileUtility.appendPathComponent(dAppCachefolder, `EBookImport_${jobId}`)

    // 调用：创建导入工作目录
    createFolderIfNeeds(tempRoot)

    const tempWte    = FileUtility.appendPathComponent(tempRoot, `pack.${EBookExportImportManager.fileExtension}`)

    // 分支：复制 .wte 到临时 .wte 失败时清理并返回
    if (!FileUtility.copyFile(filePath, tempWte)) {

      // 调用：清理导入工作目录
      FileUtility.deleteDirectoryAt(tempRoot)
      completion(false, 'copy file failed', null)
      return
    }

    const unzipDir   = FileUtility.appendPathComponent(tempRoot, 'unz')

    // 调用：解压临时 .wte（内容为 zip）
    const unzipped   = await ZipTool.unzipTo(tempWte, unzipDir)

    // 调用：解压后删除临时 .wte
    FileUtility.deleteFileAt(tempWte)

    // 分支：解压失败时清理并返回
    if (unzipped === null) {

      // 调用：清理解压工作目录
      FileUtility.deleteDirectoryAt(tempRoot)
      completion(false, 'unzip failed', null)
      return
    }

    const sqlitePath = EBookExportImportManager.firstSQLitePathInDirectory(unzipped)

    // 分支：未找到 sqlite 时清理并返回
    if (sqlitePath === null) {

      // 调用：清理解压工作目录
      FileUtility.deleteDirectoryAt(tempRoot)
      completion(false, 'no sqlite in package', null)
      return
    }

    const defName    = getString($r('app.string.ebook_default_book_name'))
    const rawTitle   = PathUtility.getLastComponentName(filePath).replace(/\.wte$/i, '').trim()
    const bookName   = rawTitle.length < 1 ? defName : rawTitle
    const newBook    = await EBookManager.shared.createLocalEBook(bookName, null)

    // 分支：创建本地 EBook 失败时清理并返回
    if (newBook === null || newBook.textDb === null || newBook.textDb === undefined) {

      // 调用：清理解压工作目录
      FileUtility.deleteDirectoryAt(tempRoot)
      completion(false, 'create local EBook failed', null)
      return
    }

    const targetPath = EBookManager.textDbPath(newBook.textDb)

    try {

      // 分支：目标库已存在时先删除
      if (FileUtility.isFileExistAt(targetPath)) {

        // 调用：删除旧库
        FileUtility.deleteFileAt(targetPath)
      }

      // 分支：移动导入 sqlite 到目标失败时返回
      if (!FileUtility.moveFile(sqlitePath, targetPath)) {
        completion(false, 'replace textDb failed', null)
        return
      }
    } catch (e) {

      // 调用：记录异常日志
      DebugLog.e(`[EBookExportImportManager] import move: ${e}`)

      // 调用：异常时清理临时目录
      FileUtility.deleteDirectoryAt(tempRoot)
      completion(false, 'replace textDb failed', null)
      return
    }

    // 调用：导入完成后清理临时目录
    FileUtility.deleteDirectoryAt(tempRoot)

    // 调用：刷新词本统计
    await BookManager.shared.refreshBookCounts(targetPath)

    completion(true, null, newBook)
  }

  /**
   * 规整导出文件名：替换非法字符并限制长度。
   * @param name 原始名称
   * @returns 规整后的文件名
   */
  private static safeFileName(name: string): string {

    const invalid = /[/\\:?%*|"<>]/g
    let cleaned   = name.replace(invalid, '_')

    // 分支：空文件名回退默认词汇本名
    if (cleaned.length < 1) {
      cleaned = getString($r('app.string.ebook_default_book_name'))
    }

    // 分支：文件名超长时截断
    if (cleaned.length > 40) {
      cleaned = cleaned.substring(0, 40)
    }

    return cleaned
  }

  /**
   * 递归查找目录中的首个 sqlite 文件路径。
   * @param folder 起始目录
   * @returns sqlite 完整路径；找不到时为 null
   */
  private static firstSQLitePathInDirectory(folder: string): string | null {

    try {

      // 分支：目录不可访问时返回
      if (!fs.accessSync(folder)) {
        return null
      }

      const names = fs.listFileSync(folder)

      for (let i = 0; i < names.length; i++) {
        const n         = names[i]
        const full      = FileUtility.appendPathComponent(folder, n)
        const st        = fs.statSync(full)

        // 分支：当前项为目录时递归查找
        if (st.isDirectory()) {
          const found = EBookExportImportManager.firstSQLitePathInDirectory(full)

          // 分支：子目录已找到 sqlite 时直接返回
          if (found !== null) {
            return found
          }
        } else {

          // 分支：命中 sqlite 文件时返回
          if (n.toLowerCase().endsWith('.sqlite')) {
            return full
          }
        }
      }
    } catch (e) {

      // 调用：记录扫描异常
      DebugLog.e(`[EBookExportImportManager] scan sqlite: ${e}`)
    }

    return null
  }
}
