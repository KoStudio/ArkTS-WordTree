import { vibrate } from '../../../common/components/Vibrator/Vibrator';
import { theme } from '../../constants/AppTheme';

// ==========================
// 3. 定义按钮样式枚举
// ==========================
export enum TextStyleButtonStyle {
  DEFAULT        = 1,  // 默认样式 空心边框 primary 主题色
  LIGHT          = 2,  // 浅色样式 空心边框 white 白色
  SOLID          = 3,  // 实心样式
  SOLID_ACCENT   = 4,  // 实心强调色样式
  SOLID_OBSCURE  = 5,  // 实心暗色样式
  ACCENT         = 6   // 空心边框 Accent 红色
}

// ==========================
// 4. 定义颜色集合接口
// ==========================
interface ColorSet {
  normal   : ResourceColor;
  selected : ResourceColor;
}

// ==========================
// 5. 使用 @ComponentV2 定义按钮组件
// ==========================
@ComponentV2
export struct TextStyleButton {

  @Param text            : ResourceStr       = '';     // 按钮标题
  @Param style           : TextStyleButtonStyle       = TextStyleButtonStyle.DEFAULT; // 按钮样式
  @Event onClickCallBack : () => void        = () => {}

  @Param isSelected       : boolean          = false;  // 是否选中
  @Param isEnabled        : boolean          = true;   // 是否可用

  @Param fontSize         : number | string  = 16
  @Param buttonType       : ButtonType       = ButtonType.Normal
  @Param radius           : number | string  = 6
  @Param textPadding      : Padding | number = 6
  @Param minWidth         : number           = 88

  @Local private touchOpacity : number       = 1.0;    // 触摸透明度，用于按下效果
  @Local pressed: boolean                    = false


  // ==========================
  // 构建组件UI
  // 注意：build() 内只能写UI组件链式调用语法
  // ==========================
  build() {
    Button(){
      Text(this.text)
        .fontSize(this.fontSize)
        .textAlign(TextAlign.Center)
        .fontColor(this.isSelected ? this.getTitleColor(this.style).selected : this.getTitleColor(this.style).normal) // 根据选中状态设置标题颜色
    }
      .width('auto')  // 根据内部内容自适应宽度
      .constraintSize({ minWidth: this.minWidth })  // 指定最小宽度为 66
      .backgroundColor(this.isSelected ? this.getBackgroundColor(this.style).selected : this.getBackgroundColor(this.style).normal)     // 根据选中状态设置背景颜色
      .border({ width: 1, color: this.isSelected ? this.getBorderColor(this.style).selected : this.getBorderColor(this.style).normal }) // 设置边框
      .type(this.buttonType)
      .borderRadius(this.radius)
      .padding(this.textPadding)
      .opacity(this.pressed ? 0.3 : 1.0)// 设置透明度与是否可用
      .enabled(this.isEnabled)
      .onTouch((event) => {
        // 处理按压状态
        if (event.type === TouchType.Down) {
          this.pressed = true
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressed = false
          vibrate()//震动
        }
      })
      .onClick(() => {
        this.onClickCallBack()
      })
      .stateEffect(true)

  }

  // ==========================
  // 获取标题颜色
  // normal: 未选中颜色
  // selected: 选中颜色
  // ==========================
  private getTitleColor(style: TextStyleButtonStyle): ColorSet {
    switch (style) {
      case TextStyleButtonStyle.DEFAULT:       return { normal: theme.color.primary, selected: theme.color.light };
      case TextStyleButtonStyle.LIGHT:         return { normal: theme.color.light,   selected: theme.color.primary };
      case TextStyleButtonStyle.SOLID:         return { normal: theme.color.light,   selected: theme.color.primary };
      case TextStyleButtonStyle.SOLID_ACCENT:  return { normal: theme.color.light,   selected: theme.color.accent };
      case TextStyleButtonStyle.SOLID_OBSCURE: return { normal: theme.color.primary, selected: theme.color.secondary };
      case TextStyleButtonStyle.ACCENT:        return { normal: theme.color.accent,  selected: theme.color.accent2 };
      default:                        return { normal: theme.color.primary, selected: theme.color.light };
    }
  }

  // ==========================
  // 获取边框颜色
  // ==========================
  private getBorderColor(style: TextStyleButtonStyle): ColorSet {
    switch (style) {
      case TextStyleButtonStyle.DEFAULT:       return { normal: theme.color.primary,  selected: theme.color.primary };
      case TextStyleButtonStyle.LIGHT:         return { normal: theme.color.light,    selected: theme.color.light };
      case TextStyleButtonStyle.SOLID:         return { normal: theme.color.primary,  selected: theme.color.primary };
      case TextStyleButtonStyle.SOLID_ACCENT:  return { normal: theme.color.accent,   selected: theme.color.accent };
      case TextStyleButtonStyle.SOLID_OBSCURE: return { normal: theme.color.obscure,  selected: theme.color.obscure };
      case TextStyleButtonStyle.ACCENT:        return { normal: theme.color.accent,  selected: theme.color.accent2 };
      default:                         return { normal: theme.color.primary,  selected: theme.color.primary };
    }
  }

  // ==========================
  // 获取背景颜色
  // ==========================
  private getBackgroundColor(style: TextStyleButtonStyle): ColorSet {
    switch (style) {
      case TextStyleButtonStyle.DEFAULT:       return { normal: theme.color.clear,   selected: theme.color.primary };
      case TextStyleButtonStyle.LIGHT:         return { normal: theme.color.clear,   selected: theme.color.light };
      case TextStyleButtonStyle.SOLID:         return { normal: theme.color.primary, selected: theme.color.secondary };
      case TextStyleButtonStyle.SOLID_ACCENT:  return { normal: theme.color.accent,  selected: theme.color.accent2 };
      case TextStyleButtonStyle.SOLID_OBSCURE: return { normal: theme.color.obscure, selected: theme.color.obscure };
      case TextStyleButtonStyle.ACCENT:       return { normal: theme.color.clear,   selected: theme.color.clear };
      default:                        return { normal: theme.color.clear,   selected: theme.color.primary };
    }
  }
}