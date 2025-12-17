import { SearchManager } from "../../../models/datas/model/SearchManager";
import { WordUser } from "../../../models/datas/myData/WordUser";

@ComponentV2
export struct FavoriteStarButton {

  @Param @Require word: WordUser;
  @Param btnWidth: number = 120;
  @Param btnHeight: number = 28;

  /** 事件：当用户在抬起时确认当前等级会触发该回调 */
  @Event onFavoriteStarButtonClick?: (val: number) => void;

  // ========== 本地状态 ==========
  @Local private nVal: number = 0;
  @Local private resNames: Resource[] = [
    $r('app.media.star_level_0'),
    $r('app.media.star_level_1'),
    $r('app.media.star_level_2'),
    $r('app.media.star_level_3'),
    $r('app.media.star_level_4'),
    $r('app.media.star_level_5')
  ];
  @Local currentImage: Resource = $r('app.media.star_level_0');

  // 添加滑动状态标记
  @Local private isSliding: boolean = false;

  // ========== 生命周期 ==========
  aboutToAppear(): void {
    this.onChangeOfWord();
  }

  @Monitor('word')
  onChangeOfWord(): void {
    if (this.word) {
      this.setVal(this.word.favoriteLevel ?? 0);
    }
  }

  @Builder
  build() {
    Image(this.currentImage)
      .width(this.btnWidth)
      .height(this.btnHeight)
      .objectFit(ImageFit.Fill)
      .gesture(
        GestureGroup(GestureMode.Parallel,
          // 点击手势 - 处理快速点击
          TapGesture()
            .onAction((event: GestureEvent) => {
              if (event.fingerList.length > 0) {
                const localX = event.fingerList[0].localX;
                this.handlePositionUpdate(localX);

                // 保存状态到SearchManager
                this.saveFavoriteLevel();
              }
            }),


          PanGesture()
          // 开始触摸：标记滑动开始
            .onActionStart((event: GestureEvent) => {
              this.isSliding = true;
              // 滑动开始时立即根据起始位置更新一次等级
              if (event.fingerList && event.fingerList.length > 0) {
                const x = event.fingerList[0].localX;
                this.handlePositionUpdate(x);
              }
            })
            // 滑动更新：实时更新等级显示
            .onActionUpdate((event: GestureEvent) => {
              if (event.fingerList && event.fingerList.length > 0) {
                const x = event.fingerList[0].localX;
                this.handlePositionUpdate(x);
              }
            })
            // 结束触摸：确认最终等级并保存
            .onActionEnd(() => {
              this.isSliding = false;

              // 保存状态到SearchManager
              this.saveFavoriteLevel();

            })
            // 取消触摸：重置状态
            .onActionCancel(() => {
              this.isSliding = false;
            })
        )
      );
  }

  // ========== 公有方法 ==========
  /** 获取当前WordUser */
  public getWord(): WordUser | undefined {
    return this.word;
  }

  /** 获取当前值 */
  public getVal(): number {
    return this.nVal;
  }

  /** 设置当前值（会更新背景） */
  public setVal(val: number): void {
    if (!this.resNames || this.resNames.length === 0) {
      this.nVal = clamp(val, 0, 5);
      return;
    }
    this.nVal = clamp(val, 0, this.resNames.length - 1);
    this.updateBg();
  }

  // ========== 私有辅助方法 ==========
  /** 更新背景图片引用 */
  private updateBg(): void {
    const idx = clamp(this.nVal, 0, this.resNames.length - 1);
    this.currentImage = this.resNames[idx] || $r('app.media.star_level_0');
  }

  /** 处理位置更新（实时调用） */
  private handlePositionUpdate(x: number): void {
    const width = this.btnWidth;

    if (!width || width <= 0) return;

    // 按照Java逻辑计算触摸区域对应的等级
    let newVal = this.nVal;

    if (x < width / 10.0) {
      newVal = 0;
    } else if (x < width * 1.0 / 5.0) {
      newVal = 1;
    } else if (x < width * 2.0 / 5.0) {
      newVal = 2;
    } else if (x < width * 3.0 / 5.0) {
      newVal = 3;
    } else if (x < width * 4.0 / 5.0) {
      newVal = 4;
    } else {
      newVal = 5;
    }

    // 只在等级变化时更新UI，避免不必要的重绘
    if (this.nVal !== newVal) {
      this.nVal = newVal;
      this.updateBg();
    }
  }

  /** 保存收藏等级到SearchManager */
  private async saveFavoriteLevel(): Promise<void> {
    try {
      if (this.word) {
        // 同步修改内存模型
        this.word.favoriteLevel = this.nVal;
        await SearchManager.shared.changeFavoriteLevelForWord(this.word, this.nVal);
      }
    } catch (e) {
      console.warn('FavoriteStarButton: save favorite level failed', e);
    }

    // 触发外部事件回调
    if (this.onFavoriteStarButtonClick) {
      this.onFavoriteStarButtonClick(this.nVal);
    }
  }
}

/** 辅助：限制数字范围 */
function clamp(v: number, lo: number, hi: number): number {
  if (isNaN(v)) return lo;
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}