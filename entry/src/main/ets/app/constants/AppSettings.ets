import { getString } from "../../common/utils/ResourceUtils"
import { StringEncoder } from "../../common/utils/strings/StringEncrypt"
import { LanguageManager } from "../../common/components/Language/LanguageManager"

// AppSettings.ets
export namespace AppSettings {

  export class App {

    static readonly projectName     = "WordTree" // 用于标识 project
    static readonly appName         = "WordTree"     // 用于标识 app
    static readonly appDisplayName  = getString($r('app.string.app_name'))
    static readonly deviceType      = "Harmony"
    static readonly minDisk         = 100 //mb
  }

  export class ICP {
    static readonly code    = "蜀ICP备19021466号-3A"           // 备案号：单词树
    static readonly title   = "ICP/IP地址/域名信息备案管理系统"    // 备案网址标题
    static readonly addr    = "https://beian.miit.gov.cn/"     // 备案网址
  }

  export class Address {
    //static readonly addressQQWxz       = "https://a.app.qq.com/o/simple.jsp?pkgname=com.ko.tools.zhika.huawei"
    static readonly terms              = "http://www.dancishu.com/terms.html"
    static readonly terms_subscription = "http://www.dancishu.com/terms_subscription.html"
    static readonly privacy            = "http://www.dancishu.com/privacy.html"
    static readonly privacy_kid        = "http://www.dancishu.com/privacy_kid.html"
    static readonly contact            = "http://www.dancishu.com/contact.html"
    static get share_app(): string {
      if (LanguageManager.isTraditionalChinese()) {
        return "https://www.dancishu.com/dcshtml/wordtree/shareapp/share_wtt.html"
      }
      return "https://www.dancishu.com/dcshtml/index.html"
    }

  }

  export class CfgWeixin {
    static readonly AppId:string         = StringEncoder.decodeAfterRemoveSalt('23d3gzYzgzMTQ0YWFkNmUyODUy')||''                    // 已加密 WordTree
    static readonly AppSecret:string     = StringEncoder.decodeAfterRemoveSalt('35Nzc4NWEzODhmMzIzMTgxODYwM2VhNjA1MzQzNmZkYjc=')||''  // 已加密
    static readonly Url                  = "https://www.dancishu.com"

  }

  //MARK: - QQ config
  export class CfgQQ {
    static readonly AppId              = "1105391403"        //QQ: WordTree
    static readonly AppKey             = "loNT3AlvXvEbSmb0"
    static readonly Url                = "https://www.dancishu.com"

  }

  export class TEConfigs {

    // 华为订阅商品 SKU：自动续费会员
    static readonly SKU_Member1: string = "com.ou.wordtree.member1";  // 连续包月
    static readonly SKU_Member2: string = "com.ou.wordtree.member2";  // 连续包季（3个月）
    static readonly SKU_Member3: string = "com.ou.wordtree.member3";  // 连续包年（12个月）

    // 华为一次性购买商品 SKU：固定时长会员，不自动续费
    static readonly SKU_Member7: string = "com.ou.wordtree.member6";  // 12个月会员　本来应该用　com.ou.wordtree.member7，但Android那边创建时搞错了，member7不能再用了，只能用6，这边和安卓统一。
    static readonly SKU_Member8: string = "com.ou.wordtree.member8";  // 24个月会员
    static readonly SKU_Member9: string = "com.ou.wordtree.member9";  // 36个月会员
    static readonly SKU_Member10: string = "com.ou.wordtree.member10"; // 60个月会员
  }
}
