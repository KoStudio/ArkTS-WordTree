
// 主题接口
export interface Theme {
  color: ColorPalette
}

// ==========================
// 具体主题实现
// ==========================


// ==========================
// 颜色调色板接口
// ==========================
export interface ColorPalette {
  primary    : ResourceColor   // 导航
  secondary  : ResourceColor   // 主色接近的区别色
  accent     : ResourceColor   // 强调色，如：突出按钮
  accent2    : ResourceColor
  obscure    : ResourceColor   // 不显眼的颜色，如灰色按钮、线框
  background : ResourceColor   // 页面背景
  light      : ResourceColor   // 白色（导航按钮 tint）
  clear      : ResourceColor   // 透明
  link       : ResourceColor   // 链接颜色
  line       : ResourceColor   // 线条颜色（如 footer 的分隔线）

  dark       : ResourceColor   // 黑色
  text       : ResourceColor   // 主要文字
  text2      : ResourceColor   // 次要文字
}

// ==========================
// 绿色配色实现
// ==========================
export class ColorGreen implements ColorPalette {
  primary    : ResourceColor = $r('app.color.colorPrimary')      // '#2AA940'
  secondary  : ResourceColor = $r('app.color.colorPrimaryDark')  // '#37633F'
  accent     : ResourceColor = $r('app.color.colorAccent')       // '#DD4236'
  accent2    : ResourceColor = $r('app.color.colorAccent2')      // '#F9948C'
  obscure    : ResourceColor = $r('app.color.color_obscure')     // '#EFEFF4'
  background : ResourceColor = $r('app.color.color_background')  // '#EFEFF4'
  light      : ResourceColor = $r('app.color.color_light')       // '#FFFFFF'
  clear      : ResourceColor = $r('app.color.color_clear')       // '#00000000'
  link       : ResourceColor = $r('app.color.color_link')        // '#5C8AC0'
  line       : ResourceColor = $r('app.color.color_line')        // '#D3D4D7'

  dark       : ResourceColor = $r('app.color.color_dark')        // '#000000'
  text       : ResourceColor = $r('app.color.color_text')        // '#000000'
  text2      : ResourceColor = $r('app.color.color_text2')       // '#A9A9A9' 替代 lightGray
}




// 绿色主题
export class ThemeGreen implements Theme {
  color: ColorPalette = new ColorGreen()
}


// ==========================
// 项目主题定义
// ==========================

// 当前主题（默认绿色主题）
export let theme: Theme = new ThemeGreen()

