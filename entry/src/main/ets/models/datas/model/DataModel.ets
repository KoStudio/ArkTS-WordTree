import { UserSettings } from '../../settings/UserSettings'
import { PersistenceV2 } from '@kit.ArkUI'
import { GlobalKey } from '../../../app/constants/GlobalKey'



// 数据模型
@ObservedV2
export class DataModel {
  // @Trace myUnits     : UserUnit[] | null = null
  @Trace currentBookId : number  = -1

  @Trace settings    : UserSettings = PersistenceV2.connect(UserSettings, GlobalKey.kUserSettings, () => new UserSettings()) !       // 当前选中图书ID

  constructor() {
    this.initData()
  }


  async initData(): Promise<void> {

    // 模拟异步初始化
    this.updateCurrentBook()
    // await this.updateMyUnits()

  }

  updateCurrentBook() {
   // this.currentBookId = SettingManager.shared.currentBookId

  }

  updateAll(){
    this.updateCurrentBook()

  }


}
