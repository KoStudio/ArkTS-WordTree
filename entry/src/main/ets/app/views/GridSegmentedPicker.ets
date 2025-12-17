// 导入必要的模块
import { CellSize } from "./ListCellOnes"; // 假设从其他文件导入单元格尺寸定义
import { LayoutConstraint, window } from '@kit.ArkUI'; // 用于获取布局信息
import { dScreenWidth } from "../constants/AppDefines";
import { common } from "@kit.AbilityKit";

// 定义选项类型
export interface GridPickerItem {
  value: number;
  label: string;
}

@ComponentV2
export struct GridSegmentedPicker {
  // 必需参数：选项数组和当前选中项
  @Param @Require options: GridPickerItem[];
  @Param @Require selectedValue: number;

  // 动态UI插槽（默认使用customBuilder兜底）
  @BuilderParam builder: (option: GridPickerItem) => void = this.customBuilder;

  // 选中事件回调
  @Event onSelected: (selection: GridPickerItem) => void;

  // 组件内部状态
  @Local private gridHeight: number = 0; // 网格总高度，用于动态设置Grid高度
  @Local private readonly CELL_SIZE: CellSize = { width: 130, height: 150 }; // 每个网格项的固定尺寸
  @Local private readonly SPACING: number = 10; // 网格项之间的间距
  @Local private actualContainerWidth: number = 0; // 记录Grid容器的实际宽度
  @Local private calculatedCols: number = 0; // 根据容器宽度计算出的列数

  // 默认UI构建函数
  @LocalBuilder
  private customBuilder(option: GridPickerItem) {
    Text(option.label)
      .fontSize(16)
      .textAlign(TextAlign.Center)
  }

  build() {
    // 使用Column作为外层容器，其宽度将自适应父容器（如Sheet）
    Column() {
      Grid() {
        ForEach(this.options, (item: GridPickerItem) => {
          GridItem() {
            Column() {
              // 使用动态构建器渲染每个选项的内容
              this.builder(item)
            }
            .width('100%') // 宽度填满GridItem
            .height(this.CELL_SIZE.height) // 固定高度
            .padding(8) // 内边距
            .onClick(() => {
              // 点击选项时触发选中事件，并伴有轻微动画
              animateTo({ duration: 100 }, () => {
                if (this.onSelected) {
                  this.onSelected(item);
                }
              });
            })
            .border({
              // 根据是否选中设置边框颜色
              width: 1,
              color: this.selectedValue === item.value ? '#007DFF' : '#CCCCCC'
            })
            .backgroundColor(
              // 根据是否选中设置背景色
              this.selectedValue === item.value ? '#007DFF20' : '#FFFFFF'
            )
          }
        }, (item: GridPickerItem, index: number) => index.toString()) // ForEach的键生成函数
      }
      .columnsTemplate(this.generateColumnsTemplate()) // 动态生成列模板
      .columnsGap(this.SPACING) // 设置列间隙
      .rowsGap(this.SPACING) // 设置行间隙
      .width('100%') // Grid宽度填满父Column
      .height(this.gridHeight) // 动态设置Grid高度，确保滚动区域正确
      .onAreaChange((oldValue: Area, newValue: Area) => {

        if (typeof newValue.width === 'number') {
          // 添加有效性检查：只有当新宽度是一个有效的正数时才更新
          if (newValue.width > 0) {
            this.actualContainerWidth = newValue.width;
          }else{
            this.actualContainerWidth = dScreenWidth
          }
        }

        this.updateColumnsAndHeight();
      })
    }
    .width('100%') // Column宽度填满其父容器，以便获取准确宽度
    .onAppear(() => {

    })
    .width('100%') // 确保Column也填满Sheet
  }

  /**
   * 根据当前容器实际宽度和设定的单元格参数，动态计算列数和网格总高度
   */
  private updateColumnsAndHeight(): void {
    if (this.actualContainerWidth <= 0) {
      return;
    }

    // 计算单个网格项占据的水平空间（宽度 + 一个列间隙的份额，因为最后一列右侧没有间隙）
    // 更简单直接的方法：计算最大可容纳列数
    const singleCellWidthWithGap = this.CELL_SIZE.width + this.SPACING;
    // 最大列数                   = (容器总宽度 + 一个间隙) / (单元格宽度 + 一个间隙) 后取整
    let maxCols                  = Math.floor((this.actualContainerWidth + this.SPACING) / singleCellWidthWithGap);
    maxCols                      = Math.max(1, maxCols); // 确保至少有一列
    maxCols                      = Math.min(maxCols, this.options.length); // 列数不超过选项总数

    this.calculatedCols          = maxCols;

    // 计算所需行数
    const rowCount               = Math.ceil(this.options.length / this.calculatedCols);
    // 计算网格总高度：所有行高 + 所有行间隙
    this.gridHeight              = rowCount * this.CELL_SIZE.height + (rowCount - 1) * this.SPACING;
  }

  /**
   * 生成网格列模板字符串
   * @returns 列模板字符串，如 "1fr 1fr 1fr"
   */
  private generateColumnsTemplate(): string {
    // 如果尚未计算出列数或列数无效，返回默认一列模板
    if (this.calculatedCols <= 0) {
      return '1fr';
    }
    // 使用 repeat() 函数生成列模板，例如 repeat(3, 1fr) 表示三等分
    return `repeat(${this.calculatedCols}, 1fr)`;
  }
}