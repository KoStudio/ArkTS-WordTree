import { relationalStore } from "@kit.ArkData";
import { dMyDataFolderPath } from "../../../../app/constants/AppDefines";
import { createFolderIfNeeds } from "../../../../app/constants/AppFunctions";
import { BookManager } from "../../../../models/datas/book/BookManager";
import { UserDbSuperAccess } from "../../../../models/datas/myData/UserDbSuperAccess";
import { DBAccessor, ParamType } from "../../../../models/dbUtils/DBAccessor";
import { DB } from "../../../../models/dbUtils/DBConstants";
import { ResultSetTool } from "../../../../models/dbUtils/ResultSetTool";
import { StringEncoder } from "../../../utils/strings/StringEncrypt";

// MARK: - 表结构定义
namespace Tables {
  export namespace Record {
    export const name = "wcRecord";  // 表名

    export namespace Col {
      export const text  = "text";   // 文本列
      export const sound = "sound";  // 声音数据列
    }
  }
}

// MARK: - 录音数据结构
export class RecordSound {
  name     : string     | null = null
  pronData : Uint8Array | null = null
}

// MARK: - 录音数据库访问类
export class SpeechRecordDbAccessor extends UserDbSuperAccess {
  // 单例实例
  private static instance: SpeechRecordDbAccessor;

  // 数据库访问器
  // private db: DBAccessor | null = null;

  private constructor(){ super();}

  public static get shared(): SpeechRecordDbAccessor {
    if (!SpeechRecordDbAccessor.instance) {
      SpeechRecordDbAccessor.instance = new SpeechRecordDbAccessor();
    }
    return SpeechRecordDbAccessor.instance;
  }

  // // 私有构造函数
  // private constructor() {
  //   //createFolderIfNeeds(this.getDbFolder());
  //   this.db = new DBAccessor(this.getDbPath(), null, false);
  //   this.createDbIfNeeds();
  // }
  //
  //
  // getDbFolder():string {
  //   return BookManager.getCurrentDirectoryOfUserData()
  // }
  //
  // getDbPath(): string {
  //   return BookManager.getCurrentPathOfUserData()
  // }
  //
  // refreshDb(): void {
  //   this.db = new DBAccessor(this.getDbPath(), null, false);
  //   this.createDbIfNeeds();
  // }

  // 获取单例实例


  // MARK: - 数据库初始化
  createDbIfNeeds() {
    if (!this.db) return;

    // 创建录音表
    const sql = `CREATE TABLE IF NOT EXISTS "${Tables.Record.name}" (
            "${Tables.Record.Col.text}" TEXT PRIMARY KEY NOT NULL,
            "${Tables.Record.Col.sound}" BLOB
        )`;

    // 执行创建表语句
    this.db.updateDb(sql);
  }

  // 用于恢复数据时检查是否有新表
  refreshDbs(): void {
    this.createDbIfNeeds();
  }

  // MARK: - 插入/更新操作
  /**
   * 插入或更新录音记录
   * @param text - 录音文本
   * @param data - 录音数据（Uint8Array格式）
   */
  async insertOrUpdateRecord(text: string, data: Uint8Array): Promise<void> {
    if (!this.db || !text.trim()) return;

    // 1. 删除现有记录（如果存在）
    const sqlDelete = `DELETE FROM ${Tables.Record.name}
            WHERE SUBSTR(${Tables.Record.Col.text}, ${DB.salt} + 1,
            LENGTH(${Tables.Record.Col.text}) - ${DB.salt}) = ?`;

    const textEncoded = StringEncoder.encodedToBase64(text.trim());
    const paramsDelete: ParamType[] = [textEncoded];

    // 2. 插入新记录
    const sqlInsert = `INSERT INTO ${Tables.Record.name} (
            ${Tables.Record.Col.text},
            ${Tables.Record.Col.sound}
        ) VALUES(?, ?)`;

    const textEncodeAndSalted = StringEncoder.encodeAndAddSalt(text.trim());
    const paramsInsert: ParamType[] = [textEncodeAndSalted, data];

    // 批量执行删除和插入操作
    await this.db.updateDbBatch([sqlDelete, sqlInsert], [paramsDelete, paramsInsert]);
  }

  // MARK: - 查询操作
  /**
   * 根据文本获取录音数据
   * @param text - 查询的文本
   * @returns RecordSound 对象或 null
   */
  async getRecordSound(text: string): Promise<RecordSound | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${Tables.Record.name}
            WHERE SUBSTR(${Tables.Record.Col.text}, ${DB.salt} + 1,
            LENGTH(${Tables.Record.Col.text}) - ${DB.salt}) = ?`;

    const textEncoded = StringEncoder.encodedToBase64(text.trim());

    return await this.db.getData(sql, [textEncoded],
      rs => this.createRecordSoundFromRs(rs));
  }

  /**
   * 获取所有录音记录
   * @returns RecordSound 数组或 null
   */
  async getAllRecordSounds(): Promise<RecordSound[] | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${Tables.Record.name}`;

    return await this.db.getDatas(sql, [],
      rs => this.createRecordSoundFromRs(rs));
  }

  // MARK: - 删除操作
  /**
   * 根据文本删除录音
   * @param text - 要删除的录音文本
   */
  async removeRecordSound(text: string): Promise<void> {
    if (!this.db) return;

    const sql = `DELETE FROM ${Tables.Record.name}
            WHERE SUBSTR(${Tables.Record.Col.text}, ${DB.salt} + 1,
            LENGTH(${Tables.Record.Col.text}) - ${DB.salt}) = ?`;

    const textEncoded = StringEncoder.encodedToBase64(text.trim());

    await this.db.updateDb(sql, [textEncoded]);
  }

  /**
   * 删除所有录音记录
   */
  async removeAllRecordSounds(): Promise<void> {
    if (!this.db) return;

    const sql = `DELETE FROM ${Tables.Record.name}`;
    await this.db.updateDb(sql);
  }

  // MARK: - 结果集转换
  /**
   * 从结果集创建 RecordSound 对象
   * @param rs - 关系型数据库结果集
   * @returns RecordSound 对象
   */
  private createRecordSoundFromRs(rs: relationalStore.ResultSet): RecordSound {
    const sound = new RecordSound();

    // 获取文本列（解密）
    sound.name       = ResultSetTool.decodeString(rs, Tables.Record.Col.text);

    // 获取声音数据
    const soundIndex = rs.getColumnIndex(Tables.Record.Col.sound);
    sound.pronData   = rs.getBlob(soundIndex);


    return sound;
  }
}