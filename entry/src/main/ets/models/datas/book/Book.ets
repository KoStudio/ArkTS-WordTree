

// MARK: -
export class Book {
  // bookId      : number | null = null;   // bookId
  // categoryId  : number | null = null;   // categoryId
  // categoryName: string | null = null;   // cagegotyName
  // bookName    : string | null = null;   // bookName
  // bookIcon    : string | null = null;   // bookIcon
  // textDb      : string | null = null;   // textDb
  // description : string | null = null;   // description

  bookId        : number  | null = null
  bookName      : string  | null = null
  categoryName  : string  | null = null
  textDb        : string  | null = null
  golds         : number  | null = null
  unitsCount    : number  | null = null
  wordsCount    : number  | null = null
  visible       : boolean | null = null


  // 等价于 Swift extension Book: Equatable
  static equals(lhs: Book, rhs: Book): boolean {
    return lhs.bookId === rhs.bookId;
  }

  // // ====== 状态属性 ======
  // /**
  //  * 判断是否为当前正在学习的书籍
  //  * - 返回: boolean 是否为当前学习书籍
  //  */
  // get isStuding(): boolean {
  //   return this.bookId === SettingManager.shared.currentBookId;
  // }
  //
  // /**
  //  * 判断是否为用户添加的书籍
  //  * - 返回: boolean 是否为用户添加
  //  */
  // get isAddedBook(): boolean {
  //   //return (this.bookId ?? 0) >= EBookConstant.Add_BookIdFirst;
  //   return this.categoryId == EBookConstant.CategoryId
  // }
  //
  // // ====== 关联数据获取 ======
  // /**
  //  * 获取所有部分
  //  * - 返回: Part[] 部分数组
  //  */
  // async parts(): Promise<Part[]> {
  //   await SearchManager.shared.setBook(this)
  //   return SearchManager.shared.getAllParts();
  // }
  //
  // /**
  //  * 获取所有单元
  //  * - 返回: Unit[] 单元数组
  //  */
  // async units(): Promise<Unit[]> {
  //   await SearchManager.shared.setBook(this)
  //   return SearchManager.shared.getAllUnits();
  // }
  //
  // /**
  //  * 获取所有课程
  //  * - 返回: Lesson[] | null 课程数组或null
  //  */
  // async lessons(): Promise<Lesson[] | null> {
  //   await SearchManager.shared.setBook(this)
  //   return SearchManager.shared.getAllLessons();
  // }
  //
  // // ====== 图标处理 ======
  // /**
  //  * 获取书籍图标
  //  * - 返回: string | null 图标路径或数据URL
  //  */
  //  icon(): image.PixelMap | null | string {
  //   const imgName = this.bookIcon;
  //   if (imgName) {
  //
  //     // 检查是否启用了CBook功能
  //     if (AppCfgManager.shared.isCBook_Useable_is_ON()) {
  //
  //       // 尝试从CBook路径加载图片
  //       const path = new CBookIconPath(imgName).path;
  //       if (path) {
  //         if (FileUtility.isFileExistAt(path)) {
  //           return `file://${path}`
  //         }
  //
  //         ///或者 创建PixelMap 内存图片 都可以
  //
  //         // const img = PixelMapUtil.createPixelMapFromFile(path);
  //         // if (img) {
  //         //   return img;
  //         // }
  //       }
  //     }
  //
  //     /// 本地Bundle中的图片
  //     const path = ResImg.allImages.find(p => p.name === imgName)?.filePath
  //     if (path) {
  //
  //       ///直接使用路径方式
  //       if (FileUtility.isFileExistAt(path)) {
  //         return `file://${path}`
  //       }
  //
  //       ///或者 创建PixelMap 内存图片 都可以
  //       // const img = PixelMapUtil.createPixelMapFromFile(path);
  //       // if (img) {
  //       //   return img;
  //       // }
  //     }
  //   }
  //
  //   let text: string      = '📔'
  //   let width: number     = 68
  //   let height: number    = 86
  //   let inCenter: boolean = true // 是否在正中间
  //   let fontSize: number  = 16
  //   let textColor: string = '#787878'
  //   let bgColor: string   = '#333333' //透明
  //
  //    ///文本生成图片不成功，暂时不使用
  //    return null
  //    /*
  //   /// 我的课本
  //   if (this.isAddedBook) {
  //     /// ///✨🌟⭐️☀️💥📖📋🔅📕📗📘📙📚📔📓📒
  //     //📔
  //     text  = '📔'
  //     return PixelMapUtil.createImageFromTextSync(text, width, height, inCenter, fontSize, textColor, bgColor)
  //   }
  //
  //   /// 记忆曲线
  //   if ((this.bookId ?? 0) > PlanManager.planBookIdPref) { /// 记忆曲线
  //
  //     text  = dFlashFlag
  //     let rtn = PixelMapUtil.createImageFromTextSync(text, width, height, inCenter, fontSize, textColor, bgColor)
  //     return rtn
  //   }
  //
  //   /// 其它未找到 bookIcon 时用 bookName
  //   text    = this.bookName ?? "📚"
  //   bgColor = "33333333" //gray
  //   return PixelMapUtil.createImageFromTextSync(text, width, height, inCenter, fontSize, textColor, bgColor)
  //
  //    */
  // }
  //
  // iconText(): string {
  //   /// 我的课本
  //   if (this.isAddedBook) {
  //     /// ///✨🌟⭐️☀️💥📖📋🔅📕📗📘📙📚📔📓📒
  //     //📔
  //     return  '📔'
  //   }
  //
  //   /// 记忆曲线
  //   if ((this.bookId ?? 0) > PlanManager.planBookIdPref) { /// 记忆曲线
  //     return dFlashFlag
  //   }
  //
  //   return this.bookName ?? "📚"
  // }
}

