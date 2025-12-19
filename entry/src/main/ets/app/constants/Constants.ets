export namespace Constants {

  // MARK: -
  export namespace TitleTextJp {

    export const wordsSperator    : string = "；"; // 翻译分隔符  （Android版暂时只考虑全角;）
    export const wordsSubSperator : string = "，"; // 翻译子分隔符（Android版暂时只考虑全角，）
    export const linesSeperator   : string = "\n"; // 换行符
    export const wordsMaxPart     : number = 100;  // 6;  （中文版暂时不做截取）// 翻译最大部分数
    export const wordsMaxPartLong : number = 100;  // 10; （中文版暂时不做截取）// 翻译最大部分数(更长，用于BaseDict)

  }

}