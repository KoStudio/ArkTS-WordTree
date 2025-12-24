// MARK: - Plan的Info
/// 该结构体用于表示一个学习计划的基本信息
export class DBPlan {
  planId      : number | null  = null;  // 计划ID
  planName    : string | null  = null;  // 计划名称
  bookId      : number | null  = null;  // 书籍ID
  countPerDay : number | null  = null;  // 每日学习的字数
  startDate   : Date   | null  = null;  // 计划开始日期
  distances   : string | null  = null;  // 距离信息，以逗号分隔
  process     : number | null  = null;  // 学习进度
}

// MARK: - Plan的Piece的text
/// 该结构体表示一个学习计划中的单个Piece（学习单元）的文本信息
export class DBPiece {
  planId  : number | null  = null;  // 计划ID
  pieceNo : number | null  = null;  // Piece的编号
  text    : string | null  = null;  // 该Piece的学习文本内容，未加密
}

// MARK: - Plan的Day的Box
/// 该结构体表示一个学习计划中某个Piece的盒子（Box）信息
export class DBBox {
  planId   : number | null  = null;  // 计划ID
  num      : number | null  = null;  // Box编号
  distance : number | null  = null;  // 距离值
  pieceNo  : number | null  = null;  // 该Box所属的Piece编号
}

// MARK: - Plan Learn
/// 该结构体表示一个学习记录（Learn），记录了某个Piece的学习情况
export class DBLearn {
  planId    : number | null  = null;  // 计划ID
  bookId    : number | null  = null;  // 书籍ID
  num       : number | null  = null;  // 学习次数
  distance  : number | null  = null;  // 学习的距离
  pieceNo   : number | null  = null;  // 学习的Piece编号
  wordId    : wordId | null  = null;  // 学习的文本内容，未加密
  learnDate : Date   | null  = null;  // 学习日期
}