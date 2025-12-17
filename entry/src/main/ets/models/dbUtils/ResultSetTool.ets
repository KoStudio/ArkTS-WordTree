import relationalStore from '@ohos.data.relationalStore';
import { StringEncoder } from '../../common/utils/strings/StringEncrypt';

export class ResultSetTool {

  ///解码String
  static decodeString(rs: relationalStore.ResultSet, colName: string): string | null {
    return StringEncoder.decodeAfterRemoveSalt(rs.getString(rs.getColumnIndex(colName)))
  }

  ///ToeicVocabulary的Word.sqlite没有加盐
  static decodeStringOnlyBase64(rs: relationalStore.ResultSet, colName: string): string | null {
    return StringEncoder.decodedFromBase64(rs.getString(rs.getColumnIndex(colName)))
  }

  ///获得日期
  static getDate(rs: relationalStore.ResultSet, colName: string): Date | null {
    return new Date(rs.getString(rs.getColumnIndex(colName)));
  }
}