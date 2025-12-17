import { AppSettings } from './AppSettings'
import { FileUtility } from '../../common/utils/FileUtility';
import { ItemOption, Toast } from '../../common/utils/Toast';
import { TintImage } from '../views/TintImage';



// 创建目录（如果需要）
export function createFolderIfNeeds(folderPath: string): void {
  FileUtility.createFolderIfNeeds(folderPath)
}


// 检查磁盘空间是否足够（带Toast提示）
export function checkDiskSpace(needMegas: number = AppSettings.App.minDisk): boolean {
  return FileUtility.checkDiskSpace(needMegas);
}

// 判断磁盘空间是否足够（纯计算）
export function isDiskSpaceEnough(needMegas: number = AppSettings.App.minDisk): boolean {
  return FileUtility.isDiskSpaceEnough(needMegas)
}

///延迟 毫秒
export async function awaitDelay(milliSeconds: number = 100) {
  await new Promise<void>((resolve, reject) => setTimeout(resolve, milliSeconds));
}


export interface PopmenuParam{
  texts: string
  index?: number
  title?: ResourceStr | null
  otherActions?: ItemOption[] | null
  navPath?: NavPathStack
}




export interface CustomNavigationMenuItem extends  NavigationMenuItem {
  isSvg?:boolean
}

///自定义导航按钮
@Builder
export function buildStandardMenu(items: (NavigationMenuItem)[]) {
  Row({ space: 2 }) {
    ForEach(items, (item: NavigationMenuItem) => {
      if (item.icon) {
        if ((item as CustomNavigationMenuItem).isSvg === true) {
          // 普通位图 svg图标
          Image(item.icon)
            .width(26)
            .height(26)
            .backgroundColor(Color.Transparent)
            .fillColor(Color.White)
            .onClick(() => item.action?.())
            .margin(10);

        } else {
          // 使用 TintImage 绘制 png图标
          TintImage({ src: item.icon, isSvg: false, colorStr: '#FFFFFFFF' })
            .width(26)
            .height(26)
            .backgroundColor(Color.Transparent)
            .onClick(() => item.action?.())
            .margin(10);
        }
      } else {
        // 没有图标，使用文字按钮
        Button() {
          Text(item.value)
            .fontSize(18)
            .fontColor(Color.White);
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => item.action?.())
        .margin(10);
      }
    });
  }
  .padding(5);
}



/**
 * 明确定义一个 ResourceLike 接口（显式类型，避免 any/unknown）
 * 列出常见可能存在的字段，按需可扩展。
 */
interface ResourceLike {
  name?: string;       // 例如资源名
  fileName?: string;   // 例如文件名
  uri?: string;        // 例如资源 URI
  path?: string;       // 本地路径
  src?: string;        // 资源源字段
  mimeType?: string;   // mime 类型（若有则最可靠）
}

/**
 * not using, 没有效果，why by ko 2025.10.31
 *
 * 判断 icon 是否为 SVG（兼容 string 或 Resource）
 *
 * 说明：
 * - 不使用 `any` / `unknown`。
 * - 不使用 `in` 操作符。
 * - 先判断 mimeType（若存在且表明 svg 则直接返回），否则按常见字段后缀判断。
 */
export function isSvgIcon(icon?: string | Resource): boolean {
  if (!icon) return false;

  // 如果是字符串，直接根据后缀判断
  if (typeof icon === 'string') {
    return icon.trim().toLowerCase().endsWith('.svg');
  }

  // 显式地把 Resource 视为 ResourceLike（明确类型断言）
  const res = icon as ResourceLike;

  // 优先使用 mimeType（如果资源提供了该字段）
  if (typeof res.mimeType === 'string' && res.mimeType.length > 0) {
    const mt = res.mimeType.trim().toLowerCase();
    if (mt === 'image/svg+xml' || mt.includes('svg')) {
      return true;
    }
  }

  // 按常见字段顺序检查，遇到第一个字符串字段就用它判断后缀
  const candidates: (string | undefined)[] = [
    res.name,
    res.fileName,
    res.uri,
    res.path,
    res.src
  ];

  for (let i = 0; i < candidates.length; i++) {
    const v = candidates[i];
    if (typeof v === 'string' && v.trim().length > 0) {
      return v.trim().toLowerCase().endsWith('.svg');
    }
  }

  // 无法判断为 svg
  return false;
}
