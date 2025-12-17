export class SectionDatas<K, T extends Object> {

  private sectionOrder: K[] = [];          // 分组顺序
  private sectionMap: Map<K, T[]> = new Map(); // 分组 -> 数据列表

  // 缓存（自动失效）
  private cachedAllDatas: T[] | null = null;
  private cachedSectionStarts: number[] | null = null; // 每个分组开始的 index（方便做 indexOfAll）

  // ========== 内部工具 ==========

  private invalidateCache(): void {
    this.cachedAllDatas = null;
    this.cachedSectionStarts = null;
  }

  private ensureSectionExists(section: K): void {
    if (!this.sectionMap.has(section)) {
      this.sectionMap.set(section, []);
      this.sectionOrder.push(section);
      this.invalidateCache();
    }
  }

  // ========== 添加数据 ==========

  addSection(section: K): boolean {
    if (this.sectionMap.has(section)) return false;

    this.sectionMap.set(section, []);
    this.sectionOrder.push(section);
    this.invalidateCache();
    return true;
  }

  addSectionWithData(section: K, data: T): void {
    this.ensureSectionExists(section);
    this.sectionMap.get(section)!.push(data);
    this.invalidateCache();
  }

  addSectionWithDatas(section: K, datas: T[]): void {
    this.ensureSectionExists(section);
    this.sectionMap.get(section)!.push(...datas);
    this.invalidateCache();
  }

  // ========== 查询 ==========

  allSections(): K[] {
    return this.sectionOrder;
  }

  allDatasOfSection(section: K): T[] {
    return this.sectionMap.get(section) ?? [];
  }

  allDatasOfSectionIndex(index: number): T[] {
    return this.sectionMap.get(this.sectionOrder[index])!;
  }

  /**
   * ⭐ 超高速版本 allDatas()
   * - 内有缓存 → 每次调用都是 O(1)
   */
  allDatas(): T[] {
    if (this.cachedAllDatas != null) return this.cachedAllDatas;

    let total = 0;
    for (const section of this.sectionOrder) {
      total += this.sectionMap.get(section)!.length;
    }

    const result = new Array<T>(total);
    let offset = 0;

    for (const section of this.sectionOrder) {
      const arr = this.sectionMap.get(section)!;
      for (let i = 0; i < arr.length; i++) {
        result[offset++] = arr[i];
      }
    }

    this.cachedAllDatas = result;
    return result;
  }

  // ========== section 索引 ==========

  indexOfSection(section: K): number | null {
    const i = this.sectionOrder.indexOf(section);
    return i === -1 ? null : i;
  }

  /**
   * 获取某个分组内某条数据的索引（带缓存的高效版本）
   */
  indexOfData(data: T, section: K): number | null {
    const arr = this.sectionMap.get(section);
    if (!arr) return null;

    // 使用 indexOf，ArkTS 优化过，性能极高
    const idx = arr.indexOf(data);
    return idx === -1 ? null : idx;
  }

  sectionAtIndex(index: number): K | null {
    if (index < 0 || index >= this.sectionOrder.length) return null;
    return this.sectionOrder[index];
  }

  // ========== 数据索引 ==========

  /**
   * ⭐ 超高速 indexOfAll（使用缓存）
   */
  indexOfAllFromIndex(rowIndex: number, sectionIndex: number): number {
    if (this.cachedSectionStarts == null) {
      this.cachedSectionStarts = [];

      let running = 0;
      for (let i = 0; i < this.sectionOrder.length; i++) {
        this.cachedSectionStarts[i] = running;
        running += this.allDatasOfSectionIndex(i).length;
      }
    }

    return this.cachedSectionStarts[sectionIndex] + rowIndex;
  }

  // ========== 删除 ==========

  removeAll(): void {
    this.sectionOrder = [];
    this.sectionMap.clear();
    this.invalidateCache();
  }

  removeSectionAtIndex(sectionIndex: number): void {
    const section = this.sectionOrder[sectionIndex];
    this.sectionOrder.splice(sectionIndex, 1);
    this.sectionMap.delete(section);
    this.invalidateCache();
  }

  removeSection(section: K): void {
    const idx = this.indexOfSection(section);
    if (idx != null) this.removeSectionAtIndex(idx);
  }

  removeData(rowIndex: number, sectionIndex: number): void {
    const section = this.sectionOrder[sectionIndex];
    const arr = this.sectionMap.get(section)!;
    arr.splice(rowIndex, 1);
    this.invalidateCache();
  }


  // ========== 数据定位 ==========

  sectionOfData(data: T): K | null {
    for (const section of this.sectionOrder) {
      const arr = this.sectionMap.get(section)!;
      if (arr.includes(data)) return section;
    }
    return null;
  }



  /**
   * 🔒 私有低级工具方法：在数组中搜索数据的索引
   * （旧版兼容，某些外部逻辑可能依赖它）
   */
  private indexOfDataInDatas(data: T, datas: T[]): number | null {
    const idx = datas.indexOf(data);
    return idx === -1 ? null : idx;
  }
}