import { util } from "@kit.ArkTS";
import { getAppContext } from "../../app/constants/AppContext";


export class ResourceUtils{

  static resourceToString(res: ResourceStr): string {
   if (typeof res === 'string') {
     return res
   }else{

     return getAppContext().resourceManager.getStringSync(res.id);
   }
  }

  /**
   * 将ResourceColor类型转换为#RRGGBB或#AARRGGBB格式的字符串
   * 支持Color枚举、number(HEX)、string(rgb/argb)或Resource对象[6](@ref)
   * @param color 颜色资源，ResourceColor类型
   * @param context 上下文对象（主要用于处理Resource对象的情况）[2,5](@ref)
   * @returns 颜色字符串，例如'#ff0000'或'#ffff0000'
   */
  static resourceColorToString(color: ResourceColor): string {
    // 1. 处理string类型：直接返回（可能是'#rgb'、'#argb'、'rgb()'、'rgba()'格式）
    if (typeof color === 'string') {
      return color;
    }

    ///注意：无法处理 enum Color的情况，如: Color.Red, Color.Green...


    // 3. 处理Resource对象：需要通过resourceManager获取其十进制颜色值[2,5](@ref)
    // 使用类型守卫检查是否为Resource对象
    if (color !== null && typeof color === 'object' && typeof (color as Resource).id === 'number') {
      try {
        // 获取资源的十进制颜色值
        const colorValue: number = getContext(ResourceUtils).resourceManager.getColorSync(color.id);
        // 将十进制值转换为十六进制字符串
        return ResourceUtils._decimalToHexColor(colorValue);
      } catch (error) {
        console.error(`Failed to get color from Resource: ${JSON.stringify(error)}`);
        return '#000000'; // 失败时返回默认黑色
      }
    }

    return '#000000';
  }



  /**
   * 内部方法：将十进制的颜色值转换为十六进制颜色字符串[6](@ref)
   * @param decimal 十进制的颜色值（通常是ARGB格式的32位整数）
   * @returns 十六进制颜色字符串
   */
  private static _decimalToHexColor(decimal: number): string {
    // 提取ARGB分量
    const alpha: number = (decimal >> 24) & 0xff;
    const red: number = (decimal >> 16) & 0xff;
    const green: number = (decimal >> 8) & 0xff;
    const blue: number = decimal & 0xff;

    // 格式化输出
    if (alpha === 0xff) { // 完全不透明，省略Alpha通道
      return `#${red.toString(16).padStart(2, '0')}${green.toString(16).padStart(2, '0')}${blue.toString(16).padStart(2, '0')}`;
    } else { // 包含透明度，输出#AARRGGBB
      return `#${alpha.toString(16).padStart(2, '0')}${red.toString(16).padStart(2, '0')}${green.toString(16).padStart(2, '0')}${blue.toString(16).padStart(2, '0')}`;
    }
  }

}

///获取string
export function getString(res: ResourceStr): string {
  return ResourceUtils.resourceToString(res)
}

///获取带格式化的string
export function getStringF(resFormat: ResourceStr, ...args: (number | string)[]): string {
  if (args && args.length > 0) {
    const format = getString(resFormat)
    return util.format(format, ...args)/// ✅ 注意这里加了 ...
  }
  return getString(resFormat)
}

///获取color $r('app.color.primary) --> '#FF00FF'
export function getColor(res: ResourceColor): string {
  return ResourceUtils.resourceColorToString(res)
}

