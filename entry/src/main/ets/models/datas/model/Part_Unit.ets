import { WordUser } from "../myData/WordUser";

// MARK: - 单元数据模型
export class Unit {
  unitId     : number     = 0;
  unitName   : string     = '';
  unitNo     : number     = 0;
  partId     : number     = 0;
  words      : WordUser[] = [];

  // 计算属性：获取活跃单词（未删除的单词）
  get aliveWords(): WordUser[] {
    return this.words.filter(word => !word.deleted);
  }

  // 计算属性：获取已学习的单词
  get learnedWords(): WordUser[] {
    return this.aliveWords.filter(word => word.learnTimes > 0);
  }

  // 计算属性：获取正确回答的单词
  get correctedWords(): WordUser[] {
    return this.aliveWords.filter(word => word.correctedTimes > 0);
  }

  // 计算属性：获取错误回答的单词
  get wrongWords(): WordUser[] {
    return this.aliveWords.filter(word =>
    word.wrangTimes > 0 && word.correctedTimes === 0
    );
  }

  // 获取下一个要学习的单词索引
  get indexOfNextLearnWord(): number {
    const aliveWords = this.aliveWords;
    for (let i = 0; i < aliveWords.length; i++) {
      if (aliveWords[i].learnTimes === 0) {
        return i;
      }
    }
    return 0;
  }
}

// MARK: - 分类数据模型
export class Part {
  partId  : number = 0;
  partName: string = '';
  units       : Unit[] = [];

  // 计算属性：获取活跃单元（包含未删除单词的单元）
  get aliveUnits(): Unit[] {
    return this.units.filter(unit => unit.aliveWords.length > 0);
  }

  // 计算属性：获取分类下的所有活跃单词
  get aliveWords(): WordUser[] {
    const aliveWords: WordUser[] = [];
    for (const unit of this.aliveUnits) {
      aliveWords.push(...unit.aliveWords);
    }
    return aliveWords;
  }

  // 计算属性：获取正确回答的单词
  get correctedWords(): WordUser[] {
    const correctedWords: WordUser[] = [];
    for (const unit of this.aliveUnits) {
      correctedWords.push(...unit.correctedWords);
    }
    return correctedWords;
  }

  // 计算属性：获取错误回答的单词
  get wrongWords(): WordUser[] {
    const wrongWords: WordUser[] = [];
    for (const unit of this.aliveUnits) {
      wrongWords.push(...unit.wrongWords);
    }
    return wrongWords;
  }
}
//
// // MARK: - 分段数据容器（类似Java的SectionedDatas）
// export class SectionedDatas<T> {
//   private sections: Map<string, T[]> = new Map();
//
//   // 添加数据到指定分段
//   addSectionData(sectionName: string, data: T): void {
//     if (!this.sections.has(sectionName)) {
//       this.sections.set(sectionName, []);
//     }
//     this.sections.get(sectionName)!.push(data);
//   }
//
//   // 添加多个数据到指定分段
//   addSectionDatas(sectionName: string, datas: T[]): void {
//     if (!this.sections.has(sectionName)) {
//       this.sections.set(sectionName, []);
//     }
//     this.sections.get(sectionName)!.push(...datas);
//   }
//
//   // 获取所有分段名称
//   get sectionNames(): string[] {
//     return Array.from(this.sections.keys());
//   }
//
//   // 获取指定分段的数据
//   getSectionData(sectionName: string): T[] {
//     return this.sections.get(sectionName) || [];
//   }
//
//   // 获取所有数据
//   get allData(): T[] {
//     const allData: T[] = [];
//     for (const dataArray of this.sections.values()) {
//       allData.push(...dataArray);
//     }
//     return allData;
//   }
//
//   // 获取分段数量
//   get sectionCount(): number {
//     return this.sections.size;
//   }
// }