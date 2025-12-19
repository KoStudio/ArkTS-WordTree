import { getString } from "../../common/utils/ResourceUtils"
import { StringEncoder } from "../../common/utils/strings/StringEncrypt"

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
    static readonly share_app          = "http://www.dancishu.com/index.html"//'https://appgallery.huawei.com/app/detail?id=com.ou.hm.wordtree'
  }

  export class CfgWeixin {
    static readonly AppId:string         = StringEncoder.decodeAfterRemoveSalt('22d3g1MDE5Y2ZiMmQ5YjM1NjAx')||''                    // 已加密 TOEIC精选词汇
    static readonly AppSecret:string     = StringEncoder.decodeAfterRemoveSalt('31ZDUxNjg3NTk4YWY1ZjA1NGJjMWU0ZTNkODU2MmViOGU=')||''  // 已加密
    static readonly Url                  = "https://www.dancishu.com"

  }

  export class TEConfigs {

    // 商品 SKU
    static readonly SKU_Member1: string = "com.or.toeic.vocabulary.member1";
    static readonly SKU_Member2: string = "com.or.toeic.vocabulary.member2";
    static readonly SKU_Member3: string = "com.or.toeic.vocabulary.member3";
  }
}

