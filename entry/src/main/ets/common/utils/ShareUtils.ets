import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileUri } from '@kit.CoreFileKit';
import { AppSettings } from '../../app/constants/AppSettings';
import { getString } from './ResourceUtils';


/**
 * 分享参数接口 (增强版)
 * 类似Swift中的struct或Kotlin中的data class
 */
interface ShareParams {
  text?: string;       // 文本内容
  imagePath?: string;  // 图片路径
  url?: string;        // 链接地址
  filePath?: string;   // 文件路径（新增）
  title?: string;      // 标题
  summary?: string;    // 描述
  utdType?: string;    // 自定义UTD类型（可选）
}

/**
 * 分享工具类 (Stage模型)
 * 功能：封装文本、链接、图片、文件、PDF及混合内容分享
 * 类似Swift中的static工具类或Kotlin中的object单例
 */
export class ShareUtils {
  // 私有静态属性，存储UIAbility上下文
  private static context: common.UIAbilityContext | null = null;

  /**
   * 初始化上下文
   * @param context - UIAbility上下文
   * 类似SwiftUI中的EnvironmentObject或Kotlin中的Context注入
   */
  static init(context: common.UIAbilityContext): void {
    ShareUtils.context = context;
  }

  static shareThisAppWithLoadedLink(){
    ShareUtils.shareLink(AppSettings.Address.share_app, getString($r('app.string.app_name')), "高效的英文单词学习助手")
  }
  /**
   * 分享PDF文件
   * @param pdfPath - PDF文件路径
   * @param title - 分享标题（可选）
   * @param summary - 分享描述（可选）
   */
  static sharePdf(pdfPath: string, title?: string, summary?: string): void {
    // 转换文件路径为URI格式
    const uri = fileUri.getUriFromPath(pdfPath);

    // 创建PDF类型分享数据
    const data = new systemShare.SharedData({
      utd: utd.UniformDataType.PDF, // 明确PDF类型
      uri: uri,
      title: title || '分享PDF文件'  // 默认标题
    });

    // 添加文件记录（必须步骤）
    data.addRecord({
      utd: utd.UniformDataType.PDF,
      uri: uri
    });

    // 添加描述文本（如果存在）
    if (summary) {
      data.addRecord({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: summary
      });
    }

    // 显示分享面板
    ShareUtils.showSharePanel(data);
  }

  /**
   * 分享任意文件类型
   * @param filePath - 文件路径
   * @param title - 分享标题（可选）
   * @param summary - 分享描述（可选）
   * @param customUtd - 自定义UTD类型（可选）
   */
  static shareFile(
    filePath: string,
    title?: string,
    summary?: string,
    customUtd?: string
  ): void {
    // 转换文件路径为URI格式
    const uri = fileUri.getUriFromPath(filePath);

    // 自动检测文件类型（基于扩展名）
    const extension = filePath.split('.').pop() || '';
    const detectedUtd = utd.getUniformDataTypeByFilenameExtension(
      '.' + extension,
      utd.UniformDataType.FILE // 默认类型
    );

    // 创建分享数据
    const data = new systemShare.SharedData({
      utd: customUtd || detectedUtd, // 优先使用自定义类型
      uri: uri,
      title: title || `分享${extension.toUpperCase()}文件` // 动态标题
    });

    // 添加文件记录
    data.addRecord({
      utd: customUtd || detectedUtd,
      uri: uri
    });

    // 添加描述文本（如果存在）
    if (summary) {
      data.addRecord({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: summary
      });
    }

    // 显示分享面板
    ShareUtils.showSharePanel(data);
  }

  /**
   * 分享文本
   * @param text - 文本内容
   * @param summary - 描述（可选）
   */
  static shareText(text: string, summary?: string): void {
    const data = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: text
    });

    if (summary) {
      data.addRecord({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: summary
      });
    }

    ShareUtils.showSharePanel(data);
  }

  /**
   * 优化版链接分享（严格遵循systemShare规范）
   * @param url - 分享链接（必填）
   * @param title - 分享标题（必填）
   * @param summary - 分享描述（必填）
   */
  static shareLink(
    url: string,
    title?: string,
    summary?: string
  ): void {
    // 1. 创建主分享数据（必须设置HYPERLINK类型）
    const data = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK, // 统一类型描述符，标识为超链接类型
      content: url,                      // 链接地址作为主内容
      title: title || '网页分享',         // 标题（不传时显示默认文本）
      description: summary || ''          // 描述（不传时显示空字符串）
    });

    // 2. 添加明确的链接记录（确保微信能识别）
    data.addRecord({
      utd: utd.UniformDataType.HYPERLINK,
      content: url,
      title: title,
      description: summary,
      // 添加微信专用的元数据标识，提高兼容性
      extraData: {
        'wechat.extra': 'url',                      // 微信专用标识
        'android.intent.extra.SUBJECT': title || '', // 安卓标准标题字段
        'android.intent.extra.TEXT': (summary || '') + ' ' + url // 安卓标准文本字段
      }
    });

    // 3. 添加纯文本记录作为备用（提高跨平台兼容性）
    data.addRecord({
      utd: utd.UniformDataType.PLAIN_TEXT,          // 纯文本类型
      content: `${title || ''}\n${summary || ''}\n${url}`, // 合并所有信息
      title: title,
      description: summary
    });


    // 显示分享面板
    ShareUtils.showSharePanel(data);
  }

  /**
   * 分享图片
   * @param imagePath - 图片路径
   * @param summary - 描述（可选）
   */
  static shareImage(imagePath: string, summary?: string): void {
    const uri = fileUri.getUriFromPath(imagePath);
    const data = new systemShare.SharedData({
      utd: utd.UniformDataType.IMAGE,
      uri: uri
    });

    if (summary) {
      data.addRecord({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: summary
      });
    }

    ShareUtils.showSharePanel(data);
  }

  /**
   * 分享混合内容（增强版）
   * @param params - 分享参数对象
   * 优先级：文件 > 图片 > 链接 > 文本 > 标题 > 描述
   */
  static shareMixed(params: ShareParams): void {
    // 确定主分享内容（优先级：图片 > 链接 > 文本 > 标题 > 描述）
    const primaryContent = ShareUtils.determinePrimaryContent(params);

    if (!primaryContent) {
      console.error('ShareUtils: 至少需要提供一个分享内容参数');
      return;
    }

    // 使用主内容初始化SharedData
    const data = new systemShare.SharedData(primaryContent);

    // 添加其他内容
    ShareUtils.addSecondaryContent(data, params, primaryContent);

    // 显示分享面板
    ShareUtils.showSharePanel(data);
  }

  /**
   * 确定主分享内容（私有方法）
   * @private
   */
  private static determinePrimaryContent(
    params: ShareParams
  ): systemShare.SharedRecord | undefined {
    // 文件类型优先（最高优先级）
    if (params.filePath) {
      return {
        utd: params.utdType || utd.UniformDataType.FILE,
        uri: fileUri.getUriFromPath(params.filePath) // 路径转换
      };
    }

    // 图片类型
    if (params.imagePath) {
      return {
        utd: utd.UniformDataType.IMAGE,
        uri: params.imagePath
      };
    }

    // 链接类型
    if (params.url) {
      return {
        utd: utd.UniformDataType.HYPERLINK,
        content: params.url
      };
    }

    // 文本类型
    if (params.text) {
      return {
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: params.text
      };
    }

    // 标题作为文本
    if (params.title) {
      return {
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: params.title
      };
    }

    // 描述作为文本
    if (params.summary) {
      return {
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: params.summary
      };
    }

    return undefined;
  }

  /**
   * 添加次要分享内容（私有方法）
   * @private
   */
  private static addSecondaryContent(
    data: systemShare.SharedData,
    params: ShareParams,
    primaryContent: systemShare.SharedRecord
  ): void {
    // 添加文件（如果不是主内容）
    if (params.filePath && primaryContent.utd !== utd.UniformDataType.FILE) {
      data.addRecord({
        utd: params.utdType || utd.UniformDataType.FILE,
        uri: fileUri.getUriFromPath(params.filePath)
      });
    }

    // 添加URL（如果不是主内容）
    if (params.url && primaryContent.utd !== utd.UniformDataType.HYPERLINK) {
      data.addRecord({
        utd: utd.UniformDataType.HYPERLINK,
        content: params.url
      });
    }

    // 添加图片（如果不是主内容）
    if (params.imagePath && primaryContent.utd !== utd.UniformDataType.IMAGE) {
      data.addRecord({
        utd: utd.UniformDataType.IMAGE,
        uri: params.imagePath
      });
    }

    // 添加文本（如果不是主内容）
    if (params.text && primaryContent.utd !== utd.UniformDataType.PLAIN_TEXT) {
      data.addRecord({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: params.text
      });
    }

    // 添加标题（如果不是主内容）
    if (params.title && primaryContent.content !== params.title) {
      data.addRecord({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: params.title
      });
    }

    // 添加描述（如果不是主内容）
    if (params.summary && primaryContent.content !== params.summary) {
      data.addRecord({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: params.summary
      });
    }
  }

  /**
   * 显示分享面板（私有方法）
   * @private
   */
  private static showSharePanel(data: systemShare.SharedData): void {
    // 上下文检查
    if (!ShareUtils.context) {
      console.error('ShareUtils: 未初始化上下文！请先调用 ShareUtils.init(context)');
      return;
    }

    try {
      // 创建分享控制器
      const controller = new systemShare.ShareController(data);

      // 添加面板关闭监听
      controller.on('dismiss', () => {
        console.log('分享面板已关闭');
      });

      // 显示分享面板（带Promise处理）
      controller.show(ShareUtils.context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.SINGLE
      }).then(() => {
        console.log('分享面板显示成功');
      }).catch((error: BusinessError) => {
        console.error(`分享失败: ${error.code} ${error.message}`);
      });
    } catch (error) {
      // 错误处理
      const err = error as BusinessError;
      console.error(`ShareUtils: 分享失败 [${err.code}] - ${err.message}`);
    }
  }
}

//======================================================================

// // 分享PDF文件
// ShareUtils.sharePdf(
//   '/data/storage/files/report.pdf',
//   '季度财务报告',
//   '2025年Q3业绩分析'
// );
//
// // 分享Excel文件
// ShareUtils.shareFile(
//   '/data/storage/files/sales.xlsx',
//   '销售数据',
//   '2025年8月销售记录'
// );
//
// // 混合分享（含文件和描述）
// ShareUtils.shareMixed({
//   filePath: '/data/storage/files/presentation.pptx',
//   title: '项目方案',
//   summary: 'HarmonyOS生态整合方案',
//   url: 'https://company.com/project-details'
// });

//======================================================================