import { dAppCloudSoundFolderPath } from "../../../../../app/constants/AppDefines";
import { createFolderIfNeeds } from "../../../../../app/constants/AppFunctions";
import { DBAccessor } from "../../../../../models/dbUtils/DBAccessor";
import { ResultSetTool } from "../../../../../models/dbUtils/ResultSetTool";
import { StringEncoder } from "../../../../utils/strings/StringEncrypt";
import { CDBSound } from "./CDBSound";
import { relationalStore } from "@kit.ArkData";
import { DB } from "../../../../../models/dbUtils/DBConstants";
import { CDBName, CDbPath } from "../Manager/CDbPath";

// MARK: - 数据库表结构定义
namespace Tables {
  // MARK: - 声音表
  export namespace CSound {
    export const name = "CSounds";
    export namespace Col {
      export const idxx = "wcitem0";
      export const lang = "wcitem1";
      export const text = "wcitem2";
      export const data = "wcitem3";
    }
  }
}

// MARK: - 声音数据库访问类
export class CSoundDbAccessor {
  // 单例实例
  private static instance: CSoundDbAccessor;

  // 数据库访问器
  private db: DBAccessor | null = null;

  // 私有构造函数
  private constructor() {
    // 创建目录（假设dMyDataFolderPath已定义）
    createFolderIfNeeds(dAppCloudSoundFolderPath);

    // 初始化数据库访问器
    const sqlitePath = new CDbPath(CDBName.sounds).sqlite
    this.db = new DBAccessor(sqlitePath, null, false);
    this.createDbsIfNeeds();
  }

  // 获取单例实例
  public static get shared(): CSoundDbAccessor {
    if (!CSoundDbAccessor.instance) {
      CSoundDbAccessor.instance = new CSoundDbAccessor();
    }
    return CSoundDbAccessor.instance;
  }

  // MARK: - 数据库初始化
  private createDbsIfNeeds(): void {
    if (!this.db) return;

    // 创建声音表
    const sql = `CREATE TABLE IF NOT EXISTS "${Tables.CSound.name}" (
      "${Tables.CSound.Col.idxx}" INTEGER PRIMARY KEY AUTOINCREMENT,
      "${Tables.CSound.Col.lang}" TEXT,
      "${Tables.CSound.Col.text}" TEXT,
      "${Tables.CSound.Col.data}" BLOB
    )`;

    // 执行创建表语句
    this.db.updateDb(sql);
  }

  // MARK: - 插入操作
  async insertSound(sound: CDBSound): Promise<void> {
    if (!this.db || !sound.lang || !sound.text || !sound.data) return;

    const sql = `INSERT INTO ${Tables.CSound.name} (
      ${Tables.CSound.Col.lang},
      ${Tables.CSound.Col.text},
      ${Tables.CSound.Col.data}
    ) VALUES(?, ?, ?)`;

    // 假设StringEncoder.encodeAndAddSalt已经实现
    const encodedLang = StringEncoder.encodeAndAddSalt(sound.lang);
    const encodedText = StringEncoder.encodeAndAddSalt(sound.text);

    await this.db.updateDb(sql, [encodedLang, encodedText, sound.data]);
  }

  // MARK: - 查询操作
  async getById(idxx: number): Promise<CDBSound | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${Tables.CSound.name}
      WHERE ${Tables.CSound.Col.idxx} = ?`;

    return await this.db.getData(sql, [idxx], rs => this.createCSoundFromRs(rs));
  }

  async getByLangAndText(lang: string, text: string): Promise<CDBSound | null> {
    if (!this.db) return null;

    const sql = `SELECT * FROM ${Tables.CSound.name}
      WHERE SUBSTR(${Tables.CSound.Col.lang}, ${DB.salt} + 1, LENGTH(${Tables.CSound.Col.lang}) - ${DB.salt}) = ?
      AND SUBSTR(${Tables.CSound.Col.text}, ${DB.salt} + 1, LENGTH(${Tables.CSound.Col.text}) - ${DB.salt}) = ?`;

    const langBase64 = StringEncoder.encodedToBase64(lang);
    const textBase64 = StringEncoder.encodedToBase64(text);

    return await this.db.getData(sql, [langBase64, textBase64], rs => this.createCSoundFromRs(rs));
  }

  // MARK: - 删除操作
  async deleteById(idxx: number): Promise<void> {
    if (!this.db) return;

    const sql = `DELETE FROM ${Tables.CSound.name}
      WHERE ${Tables.CSound.Col.idxx} = ?`;

    await this.db.updateDb(sql, [idxx]);
  }

  async deleteByLangAndText(lang: string, text: string): Promise<void> {
    if (!this.db) return;

    const sql = `DELETE FROM ${Tables.CSound.name}
      WHERE SUBSTR(${Tables.CSound.Col.lang}, ${DB.salt} + 1, LENGTH(${Tables.CSound.Col.lang}) - ${DB.salt}) = ?
      AND SUBSTR(${Tables.CSound.Col.text}, ${DB.salt} + 1, LENGTH(${Tables.CSound.Col.text}) - ${DB.salt}) = ?`;

    const langBase64 = StringEncoder.encodedToBase64(lang);
    const textBase64 = StringEncoder.encodedToBase64(text);

    await this.db.updateDb(sql, [langBase64, textBase64]);
  }

  async deleteAll(): Promise<void> {
    if (!this.db) return;

    const sql = `DELETE FROM ${Tables.CSound.name}`;
    await this.db.updateDb(sql);
  }

  // MARK: - 结果集转换
  private createCSoundFromRs(rs: relationalStore.ResultSet): CDBSound {
    const sound = new CDBSound();
    sound.idxx = rs.getLong(rs.getColumnIndex(Tables.CSound.Col.idxx));
    sound.lang = ResultSetTool.decodeString(rs, Tables.CSound.Col.lang);
    sound.text = ResultSetTool.decodeString(rs, Tables.CSound.Col.text);
    sound.data = rs.getBlob(rs.getColumnIndex(Tables.CSound.Col.data));
    return sound;
  }
}

