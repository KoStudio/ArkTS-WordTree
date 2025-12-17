import { getString } from "../../../common/utils/ResourceUtils"

export enum Mistake {
  mistake_0       = 1 << 0 ,//1
  mistake_1_Only  = 1 << 1 ,//2,
  mistake_1_3     = 1 << 2 ,//4,
  mistake_3_5     = 1 << 3 ,//8,
  mistake_5_10    = 1 << 4 ,//16,
  mistake_10_Over = 1 << 5 ,//32,
  mistake_All     = (1 << 6) -1,//63,
}

// MARK: - Helper Classes
export class MistakeHelper {
  static fromWrongTimes(wrongTimes: number): Mistake {
    switch (true) {
      case wrongTimes === 0                 : return Mistake.mistake_0
      case wrongTimes === 1                 : return Mistake.mistake_1_Only
      case wrongTimes >= 2 && wrongTimes <= 3 : return Mistake.mistake_1_3
      case wrongTimes >= 4 && wrongTimes <= 5 : return Mistake.mistake_3_5
      case wrongTimes >= 6 && wrongTimes <= 10: return Mistake.mistake_5_10
      default                                : return Mistake.mistake_10_Over
    }
  }

  static localizedName(m: Mistake): string {
    switch (m) {
      case Mistake.mistake_1_Only  : return getString($r("app.string.wrang_times_1_only"))
      case Mistake.mistake_1_3     : return getString($r("app.string.wrang_times_1_3"))
      case Mistake.mistake_3_5     : return getString($r("app.string.wrang_times_3_5"))
      case Mistake.mistake_5_10    : return getString($r("app.string.wrang_times_5_10"))
      case Mistake.mistake_10_Over : return getString($r("app.string.wrang_times_10_over"))
      default                        : return "--"
    }
  }
}
