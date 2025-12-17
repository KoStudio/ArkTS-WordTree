import json from "@ohos.util.json";


@ComponentV2
export struct ColorPickerView {
  /**
   * 选中的颜色（外部传入）
   */
  @Param selectedColor: string = '';

  @Param isUseSimpleColor: boolean = false

  /**
   * 颜色选中回调（外部传入）
   */
  @Param @Require onColorPicked: (color: string) => void;

  /**
   * 颜色矩阵，定义颜色选择面板的颜色
   * 参考你给的颜色资源，分成5行5列
   */
  private colorMatrix: string[][] = [
    ['#000000', '#41454D', '#808080', '#999999', '#ffffff'],
    ['#320318', '#511307', '#4F340A', '#213710', '#0F2E3F'],
    ['#700C31', '#BE2813', '#B97A19', '#467C23', '#246590'],
    ['#EF5932', '#EF5932', '#F5B433', '#77C344', '#3DACF7'],
    ['#E87AA4', '#F4A88B', '#F9D98C', '#B8E297', '#79D6F9']
  ];

  private colorMatrix2: string[][] = [
    ['#ce0855','#ef5931', '#f5b332', '#2ba940', '#3dacf7', '#003ff7', '#783bfe', '#808080', '#000000']
  ];

  /**
   * 组件构建函数，返回颜色选择器UI结构
   */
  build() {
    // 垂直排列颜色行，行间距8vp
    Column({ space: 8 }) {
      // 遍历每一行颜色数组
      ForEach(this.isUseSimpleColor ? this.colorMatrix2 : this.colorMatrix, (row: string[], rowIndex: number) => {
        // 每行水平排列颜色圆圈，圆圈间距8vp
        Row({ space: 8 }) {
          // 遍历行内每个颜色，渲染圆圈
          ForEach(row, (color: string, colIndex: number) => {
            Rect()
              .width(this.isUseSimpleColor ? 25 : 36)
              .height(this.isUseSimpleColor ? 25 : 36)
              .fill(color)
              .radius(5) // 圆形需设为宽高的一半
              .stroke(this.selectedColor === color ? Color.Blue : Color.Transparent) // 动态边框颜色
              .strokeWidth(this.selectedColor === color ? 3 : 1) // 动态边框宽度

              .onClick(() => {
                if (this.onColorPicked) {
                  this.onColorPicked(color);
                }
              })
          }, (color: string, colIndex: number)  => json.stringify(`${rowIndex}-${colIndex}`)) // 用行列索引组合作为唯一key
        }
      }, (row: string[], rowIndex: number)=> json.stringify(row)) // 行索引作为行的key
    }
    .padding(this.isUseSimpleColor ? 5 : 12) // 整体内边距12vp
  }
}