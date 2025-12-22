import { BookDbAccess } from "./BookDbAccess";

// MARK: -
export class Category {
  categoryName: string | null = null;

  constructor(categoryName: string | null) {
    this.categoryName = categoryName;
  }

  // 实现 Equatable 接口（以名称判断）
  static equals(lhs: Category, rhs: Category): boolean {
    return lhs.categoryName === rhs.categoryName;
  }
}

// 分类数据模型
export class CategoryManager {
  private static instance: CategoryManager;
  private categories: Category[] = [];

  private constructor() {}

  public static get shared(): CategoryManager {
    if (!CategoryManager.instance) {
      CategoryManager.instance = new CategoryManager();
    }
    return CategoryManager.instance;
  }

  /**
   * 获取所有分类
   */
  getCategories(): Category[] {
    return [...this.categories];
  }

  /// 重新获取类别
  async reload() {
    this.categories = [];
    await this.loadCategories();
  }

  /**
   * 初始化分类数据
   */
  async loadCategories(): Promise<Category[]> {
    // 已有缓存直接返回
    if (this.categories.length !== 0) {
      return this.categories;
    }

    try {
      const books = await BookDbAccess.shared.getAllBooks();
      if (books) {
        const uniqueCategories = new Map<string, Category>();

        books.forEach(book => {
          const name = book.categoryName;
          if (!name) {
            return;
          }

          if (!uniqueCategories.has(name)) {
            uniqueCategories.set(
              name,
              new Category(name)
            );
          }
        });

        this.categories = Array.from(uniqueCategories.values());
        return this.categories;
      }
    } catch (e) {
      console.error("加载分类数据出错:", e);
    }

    return [];
  }

  /**
   * 向后兼容的回调方式
   */
  loadCategoriesWithCallback(
    callback?: (categories: Category[]) => void
  ): void {
    this.loadCategories()
      .then(categories => callback?.(categories))
      .catch((error: Error | string) => {
        console.error("加载分类数据时出错:", error);
        callback?.([]);
      });
  }
}