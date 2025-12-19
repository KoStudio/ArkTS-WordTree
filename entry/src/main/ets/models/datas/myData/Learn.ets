// // ============================================================
// // Learn 数据模型（对应 Java LearnTable）
// // ============================================================
//
// @ObservedV2
// export class Learn {
//   // ================== 常量 ==================
//   static readonly KShareMemo_MemoText   : string = "kMemoText"
//   static readonly KShareMemo_AuthorName : string = "kAuthorName"
//   static readonly KShareMemo_MemoId     : string = "kMemoId"
//
//   @Trace titleEn        : string  = ""
//   @Trace learnTimes     : number  = 0
//   @Trace correctedTimes : number  = 0
//   @Trace wrangTimes     : number  = 0
//   @Trace favoriteLevel  : number  = 0
//   @Trace lastResult     : number  = 0
//   @Trace wrangDate      : number  = 0
//   @Trace unitId         : number  = 0
//   @Trace partId         : number  = 0
//   @Trace memo           : string | null = null
//   @Trace shareMemos     : Array<Record<string, string>> = []
//
//   @Trace deleted        : boolean = false
//
// }