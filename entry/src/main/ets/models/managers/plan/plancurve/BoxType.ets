// MARK: - DistanceFromBase
/// 每个 piece 的第一天（新字）为 base
import { util } from "@kit.ArkTS";
import { getString } from "../../../../common/utils/ResourceUtils";

/// DistanceFromBase 是相距 base 的天数： base + distance
export type DistanceFromBase = number;

// MARK: - BoxType
/// 系统暂定需要记忆的天数
export enum BoxType {
  New  = 0,    // base + 0
  Rev1 = 1,    // base + 1
  Rev2 = 2,    // base + 2
  Rev3 = 4,
  Rev4 = 7,
  Rev5 = 15,
  Rev6 = 30
}

// MARK: - Distance Helper
export class DistanceHelper {

  /**
   * 返回 distance 的 UI 表示字符串
   * @param distance 天数
   * @returns +0天, +1天, +2天...
   */
  static distanceString(distance: DistanceFromBase): string {
    // 注意：LocalizedString 可以自行实现或从资源加载
    if (distance === 1) {
      return util.format(getString($r('app.string.distance_string_day')), distance)//$r("app.string.distance_string_day", distance);
    } else {
      return util.format(getString($r('app.string.distance_string_days')), distance) //$r("app.string.distance_string_days", distance);
    }
  }

  /**
   * 返回 distance 类型字符串：学习 或 复习
   * @param distance 天数
   * @returns 学习 或 复习
   */
  static typeString(distance: DistanceFromBase): string {
    return distance === BoxType.New ? getString($r("app.string.distance_new_string")) : getString($r("app.string.distance_review_string"));
  }

  /**
   * 返回 distance + 类型字符串：学习 或 复习(+1天)
   * @param distance 天数
   * @returns 学习 或 复习(+1天)
   */
  static distanceAndTypeString(distance: DistanceFromBase): string {
    if (distance === BoxType.New) {
      return DistanceHelper.typeString(distance);
    } else {
      return `${DistanceHelper.typeString(distance)}(${DistanceHelper.distanceString(distance)})`;
    }
  }

  /**
   * 获取所有 BoxType 枚举值（模拟 Swift CaseIterable）
   */
  static allBoxTypes(): BoxType[] {
    return [
      BoxType.New,
      BoxType.Rev1,
      BoxType.Rev2,
      BoxType.Rev3,
      BoxType.Rev4,
      BoxType.Rev5,
      BoxType.Rev6
    ];
  }
}
