// DBAccessor.ets
import relationalStore from '@ohos.data.relationalStore';
import { getAppContext } from '../../app/constants/AppContext';
import { DebugLog } from '../../app/debug/DebugLog';
import { PathUtility } from '../../common/utils/PathUtility';
import { StringEncoder } from '../../common/utils/strings/StringEncrypt';

/**
 * 数据库操作参数类型定义
 * 支持：字符串(string)、数字(number)、布尔值(boolean)、null四种类型
 */
export type ParamType = relationalStore.ValueType// | relationalStore.UTCTime //string | number | boolean | null;

export interface SqlObj {
  sql: string
  params: ParamType[]
}

/**
 * 数据库访问工具类
 * 封装HarmonyOS relationalStore操作，提供安全易用的数据库访问接口
 * 注意：所有数据库操作完成后会自动关闭连接，无需手动管理
 */
export class DBAccessor {
  // MARK: - 成员变量

  /** 主数据库文件路径（示例：'/data/app/main.db'） */
  private dbPath: string | null;

  /** 需要附加的数据库路径列表（示例：['/data/app/user.db']） */
  private attachPaths: Array<string | null> | null;

  private isReadOnly: boolean = true

  /** 数据库连接实例（使用后会自动关闭） */
  private rdbStore: relationalStore.RdbStore | null = null;

  /** 初始化状态标志 */
  private isInitialized = false;

  // MARK: - 初始化方法

  /**
   * 构造函数
   * @param dbPath - 主数据库文件路径（必须）
   * @param attachPaths - 需要附加的其他数据库路径（可选）
   */
  constructor(dbPath: string | null, attachPaths: Array<string | null> | null = null, isReadOnly: boolean = true) {
    this.dbPath = dbPath;
    this.attachPaths = attachPaths;
    this.isReadOnly = isReadOnly
  }

  // MARK: - 私有方法

  /**
   * 初始化数据库连接
   * @returns Promise<boolean> 返回是否初始化成功
   * 注意：该方法会自动处理连接关闭，调用方无需关心资源释放
   */
  private async initDatabase(): Promise<boolean> {
    // 已初始化则直接返回
    if (this.isInitialized) return true;

    // 检查数据库路径有效性
    if (!this.dbPath) {
      console.error("DBAccessor: 数据库路径不能为空");
      return false;
    }

    const relativePath = PathUtility.getRelativeDatabasePath(this.dbPath!)
    const dbFolder     = PathUtility.getParentPathOf(relativePath)
    const dbFolderPath = PathUtility.removeLastSlashOfDirectoryIfExists(dbFolder)
    const dbName       = PathUtility.getLastComponentName(this.dbPath!)

    // 数据库配置
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: dbName,
      customDir: dbFolderPath!,///相对于../rdb/后的部分
      isReadOnly: this.isReadOnly, //只读
      securityLevel: relationalStore.SecurityLevel.S2 // S1级安全加密
    };

    try {
      // 创建数据库连接
      this.rdbStore = await relationalStore.getRdbStore(getAppContext(), STORE_CONFIG);

      // 附加其他数据库
      if (this.attachPaths) {
        for (const path of this.attachPaths) {
          if (path) await this.attachDatabase(path);
        }
      }

      this.isInitialized = true;
      return true;
    } catch (err) {
      console.error(`DBAccessor: 数据库初始化失败 - ${err}`);
      this.closeDatabase(); // 初始化失败时关闭连接
      return false;
    }
  }

  /**
   * 附加其他数据库
   * @param path - 需要附加的数据库路径
   */
  private async attachDatabase(path: string): Promise<void> {
    if (!this.rdbStore) return;

    // 从路径中提取数据库名称（去除路径和扩展名）
    const dbName = path.substring(
      path.lastIndexOf('/') + 1,  // 获取文件名
      path.lastIndexOf('.sqlite')      // 去除.db后缀
    );

    try {
      await this.rdbStore.executeSql(`ATTACH DATABASE '${path}' AS ${dbName}`);
      DebugLog.d(`ATTACH DATABASE '${path}' AS ${dbName}`)

    } catch (err) {
      console.error(`DBAccessor: 附加数据库失败 [${path}] - ${err}`);
    }
  }

  /**
   * 关闭数据库连接（私有方法）
   */
  private closeDatabase(): void {
    try {
      this.rdbStore?.close();
      this.rdbStore = null;
      this.isInitialized = false;
      DebugLog.d('DBAccessor-closeDatabased')
    } catch (err) {
      DebugLog.d("DBAccessor: 关闭数据库连接失败:" + err, );
    }
  }

  // MARK: - 数据查询接口

  /**
   * 执行查询并返回多条记录
   * @param sql - SQL查询语句（需包含WHERE等条件）
   * @param params - 查询参数数组（可选，默认空数组）
   * @param handler - 处理单行结果的回调函数
   * @returns Promise<T[] | null> 返回查询结果数组或null（出错时）
   * 注意：该方法会自动关闭结果集和数据库连接
   */
  async getDatas<T>(
    sql: string,
    params: ParamType[] = [],
    handler: (rs: relationalStore.ResultSet) => T
  ): Promise<T[] | null> {
    if (!await this.initDatabase()) return null;

    try {
      // 执行查询
      const resultSet = await this.rdbStore!.querySql(sql, params);
      DebugLog.d(sql +'  参数: ' + params)

      const results: T[] = [];

      // 遍历结果集
      while (resultSet.goToNextRow()) {
        results.push(handler(resultSet));
      }

      // 关闭结果集
      resultSet.close();
      return results.length > 0 ? results : null;
    } catch (err) {
      console.error(`DBAccessor: 查询失败 [${sql}] - ${err}`);
      return null;
    } finally {
      this.closeDatabase(); // 确保关闭连接
    }
  }

  ///同步方法，需要提前初始化isInitialized
  getDatasSync<T>(
    sql: string,
    params: ParamType[] = [],
    handler: (rs: relationalStore.ResultSet) => T
  ): T[] | null {
    if (!this.isInitialized) return null;
    try {
      const resultSet = this.rdbStore!.querySqlSync(sql, params); // 假设存在同步API
      DebugLog.d(sql +'  参数: ' + params)

      const results: T[] = [];
      while (resultSet.goToNextRow()) {
        results.push(handler(resultSet));
      }
      resultSet.close();
      return results.length > 0 ? results : null;
    } catch (err) {
      console.error(`同步查询失败: ${err}`);
      return null;
    }
  }

  /**
   * 执行查询并返回单条记录
   * @param sql - SQL查询语句
   * @param params - 查询参数数组（可选）
   * @param handler - 处理单行结果的回调函数
   * @returns Promise<T | null> 返回查询结果或null（无结果或出错时）
   * 注意：该方法会自动关闭结果集和数据库连接
   */
  async getData<T>(
    sql: string,
    params: ParamType[] = [],
    handler: (rs: relationalStore.ResultSet) => T | null
  ): Promise<T | null> {
    if (!await this.initDatabase()) return null;

    try {
      const resultSet = await this.rdbStore!.querySql(sql, params);
      DebugLog.d(sql +'  参数: ' + params)

      // 只获取第一条记录
      const result = resultSet.goToNextRow() ? handler(resultSet) : null;

      resultSet.close();
      return result;
    } catch (err) {
      console.error(`DBAccessor: 单条查询失败 [${sql}] - ${err}`);
      return null;
    } finally {
      this.closeDatabase(); // 确保关闭连接
    }
  }

  ///同步方法，需要提前初始化isInitialized
  getDataSync<T>(
    sql: string,
    params: ParamType[] = [],
    handler: (rs: relationalStore.ResultSet) => T | null
  ): T | null {
    if (! this.initDatabase()) return null;

    try {
      const resultSet = this.rdbStore!.querySqlSync(sql, params);
      DebugLog.d(sql +'  参数: ' + params)

      // 只获取第一条记录
      const result = resultSet.goToNextRow() ? handler(resultSet) : null;

      resultSet.close();
      return result;
    } catch (err) {
      console.error(`DBAccessor: 单条查询失败 [${sql}] - ${err}`);
      return null;
    } finally {
      this.closeDatabase(); // 确保关闭连接
    }
  }

  // MARK: - 实用方法

  /**
   * 获取查询结果的行数
   * @param sql - COUNT查询语句（如："SELECT COUNT(*) FROM users"）
   * @param params - 查询参数（可选）
   * @returns Promise<number> 返回记录数量（出错时返回0）
   */
  async getCount(sql: string, params: ParamType[] = []): Promise<number> {
    const count = await this.getData<number>(
      sql,
      params,
      rs => rs.getLong(0) // 获取COUNT结果的第一列
    );
    return count ?? 0; // 空值保护
  }

  /**
   * 获取指定列的最大值
   * @param column - 列名（如："age"）
   * @param table - 表名（如："users"）
   * @param where - WHERE条件语句（可选，如："status = 1"）
   * @returns Promise<number> 返回最大值（无数据时返回0）
   */
  async getMax(column: string, table: string, where?: string): Promise<number> {
    // 构建MAX查询SQL
    let sql = `SELECT MAX(${column}) FROM ${table}`;
    if (where) sql += ` WHERE ${where}`;

    const max = await this.getData<number>(sql, [], rs => rs.getLong(0));
    return max ?? 0;
  }

  /**
   * 检查表中是否存在某列
   * @param column - 需要检查的列名
   * @param table - 表名
   * @returns Promise<boolean> 返回列是否存在
   */
  async isExist(column: string, table: string): Promise<boolean> {
    // 使用PRAGMA查询表结构
    const names = await this.getDatas<string>(
      `PRAGMA table_info(${table})`,
      [],
      rs => rs.getString(1) // 获取列名字段
    );
    return names?.includes(column) ?? false;
  }

  /**
   * 检查查询结果是否存在记录
   * @param sql - 存在性查询语句（如："SELECT 1 FROM users WHERE id = ?"）
   * @param params - 查询参数（可选）
   * @returns Promise<boolean> 返回是否存在记录
   */
  async isExistWithSql(sql: string, params: ParamType[] = []): Promise<boolean> {
    if (!await this.initDatabase()) return false;

    try {
      const resultSet = await this.rdbStore!.querySql(sql, params);
      DebugLog.d(sql +'  参数: ' + params)

      // 只需检查是否有第一条记录
      const exists = resultSet.goToNextRow();
      resultSet.close();
      return exists;
    } catch (err) {
      console.error(`DBAccessor: 存在性查询失败 [${sql}] - ${err}`);
      return false;
    } finally {
      this.closeDatabase(); // 确保关闭连接
    }
  }

  // MARK: - 数据修改接口

  /**
   * 执行更新操作（INSERT/UPDATE/DELETE）
   * @param sql - 更新语句
   * @param params - 参数数组（可选）
   * @returns Promise<boolean> 返回是否执行成功
   * 注意：该方法会自动关闭数据库连接
   */
  async updateDb(sql: string, params: ParamType[] = []): Promise<boolean> {
    if (!await this.initDatabase()) return false;

    try {
      await this.rdbStore!.executeSql(sql, params);
      DebugLog.d(sql +'  参数: ' + params)

      return true;
    } catch (err) {
      console.error(`DBAccessor: 更新失败 [${sql}] - ${err}`);
      return false;
    } finally {
      this.closeDatabase(); // 确保关闭连接
    }
  }

  /**
   * 在事务中批量执行更新操作
   * @param sqls - SQL语句数组
   * @param paramsList - 参数数组的数组（与sqls一一对应）
   * @returns Promise<boolean> 返回是否全部执行成功
   * 注意：该方法会自动关闭数据库连接
   */
  async updateDbBatch(
    sqls: string[],
    paramsList: ParamType[][] = []
  ): Promise<boolean> {
    if (!await this.initDatabase()) return false;
    if (!this.isInitialized || !this.rdbStore) {
      console.error('数据库未初始化成功');
      return false;
    }
    try {
      // 使用 beginTransaction（通常不会返回 txId）
      this.rdbStore!.beginTransaction();

      for (let i = 0; i < sqls.length; i++) {
        try {
          await this.rdbStore?.executeSql(sqls[i], paramsList[i] || []);
          DebugLog.d(sqls[i] +'  参数' + paramsList[i])

        } catch (err) {
          DebugLog.e(`DBAccessor: 执行失败 [${i}] [${sqls[i]}], 参数： ${paramsList[i]}},  - ${err}`);
          this.rdbStore?.rollBack(); // 注意：rollBack 无参数
          return false;
        }
      }

      this.rdbStore?.commit();
      return true;
    } catch (err) {
      console.error(`DBAccessor: 事务执行异常 - ${err}`);
      return false;
    } finally {
      this.closeDatabase();
    }
  }

  ///安全编码字符串参数（带输入验证和类型守卫）
  static encodedParamString(param: string | null): string | null {
    if (!param?.trim()) return null; // 合并空值检查和trim
    return StringEncoder.encodedToBase64(param) ?? null; // 空值合并操作符
  }
}