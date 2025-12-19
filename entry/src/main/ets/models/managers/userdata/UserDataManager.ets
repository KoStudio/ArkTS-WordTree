import { HttpUtils } from "../../networks/HttpUtils";
import { Http } from "../../networks/Http";
import { dAppSoundFolderPath } from "../../../app/constants/AppDefines";
import { UserManager } from "../user/UserManager";
import { UserData, UserDataJson, UserDataKeys } from "./UserData";
import { AppSettings } from "../../../app/constants/AppSettings";
import { Route, Servers } from "../../networks/Server_Routes";
import { UserExample, UserExampleJson } from "./UserExample";
import { SearchConstants, SearchManager } from "../../datas/model/SearchManager";
import { WordUserDbAccess } from "../../datas/myData/WordUserDbAccess";
import { createFolderIfNeeds } from "../../../app/constants/AppFunctions";


export class UserDataManager {

  // 单例模式
  private static _instance: UserDataManager;
  static get shared(): UserDataManager {
    if (!UserDataManager._instance) {
      UserDataManager._instance = new UserDataManager();
    }
    return UserDataManager._instance;
  }

  private constructor() {}

  // 上传用户数据
  uploadUserData(completion: (succeed: boolean, msg: string | null) => void) {
    const userId = UserManager.shared.userId;
    if (!userId) return;

    const params: HttpUtils.HttpParams = {};
    params[UserDataKeys.userId]       = userId.toString();
    params[UserDataKeys.projectName]  = AppSettings.App.projectName;
    params[UserDataKeys.appName]      = AppSettings.App.appName;
    params[UserDataKeys.deviceType]   = AppSettings.App.deviceType;
    params[UserDataKeys.dataJson]     = this.createDataJson();

    const url = Servers.getRouteUrl(Route.user_data);
    Http.send(url, HttpUtils.Method.POST, params, completion);
  }

  // 下载用户数据
  loadUserData(completion: (succeed: boolean, msg: string | null, userDataJson: UserDataJson[] | null) => void) {
    const userId = UserManager.shared.userId;
    if (!userId) return;

    const params: HttpUtils.HttpParams = {};
    params[UserDataKeys.userId]        = userId.toString();
    params[UserDataKeys.projectName]   = AppSettings.App.projectName;
    params[UserDataKeys.appName]       = AppSettings.App.appName;
    params[UserDataKeys.deviceType]    = AppSettings.App.deviceType;

    const url = Servers.getRouteUrl(Route.user_data);
    Http.request(url, HttpUtils.Method.GET, params, completion)
  }

  // 恢复用户数据
  restoreDataJson(onProgress: (percent: number) => void, completion: (succeed: boolean, msg: string | null) => void) {
    const userId = UserManager.shared.userId;
    if (!userId) return;

    const params: HttpUtils.HttpParams = {};
    params[UserDataKeys.userId]        = userId.toString();
    params[UserDataKeys.projectName]   = AppSettings.App.projectName;
    params[UserDataKeys.appName]       = AppSettings.App.appName;
    params[UserDataKeys.deviceType]    = AppSettings.App.deviceType;

    const url = `${Servers.getRouteUrl(Route.user_data)}/data_json`;

    Http.request<UserDataJson>(url, HttpUtils.Method.GET, params, (succeed: boolean, msg: string | null, userDataJson: UserDataJson[] | null) => {
      if (!succeed || !userDataJson) {
        completion(false, msg);
        return;
      }
    const dataJson = userDataJson[0]?.data_json;
    if (dataJson) {
      const userExampleJsons = JSON.parse(dataJson) as UserExampleJson[]
      const userExamples     = UserExample.fromJsonArray(userExampleJsons)
      this.restoreAllExamples(userExamples, onProgress);
  }

  completion(succeed, msg);
});
}

// 上传本地数据压缩包
upload(completion: (succeed: boolean, msg: string | null) => void) {
  const userId = UserManager.shared.userId;
  if (!userId) return;

  const localFolder = dAppSoundFolderPath;
  const zipFile = localFolder.replace(/\/$/, "") + ".zip";

  // 删除旧压缩包
  // deleteFileAt(zipFile);
  //
  // // 压缩目录
  // ZipUtility.zipFileAtPath(localFolder, zipFile);
  //
  // const fileExists = FileUtility.exists(zipFile);
  // if (!fileExists) return;
  //
  // const url = `${Servers.getRouteUrl(Route.User_data)}/${userId}`;
  // const uploadData = { filePath: zipFile, fileName: userId.toString(), fileExt: ".zip", param: "user_data" };
  //
  // Http.upload(uploadData, url, (succeed, msg) => {
  //   completion(succeed, msg);
  //   deleteFileAt(zipFile);
  // });
}

// 下载用户数据并解压
download(userData: UserData, onProgress: (percent: number) => void, completion: (succeed: boolean, msg: string | null) => void) {
  const userDataAddr = userData.userDataAddr;
  const userId = UserManager.shared.userId;
  if (!userDataAddr || !userId) return;

  const localFolder = dAppSoundFolderPath;
  createFolderIfNeeds(localFolder);

  // const remoteUrl = `${Servers.getRouteUrl(Route.user_data)}/file?user_data_addr=${userDataAddr}`;
  // const localDownloadFolder = `${localFolder}_download`;
  // const localZip = `${localDownloadFolder}/data.zip`;
  // const unzipFolder = `${localDownloadFolder}/_unzip`;
  //
  // createFolderIfNeeds(localDownloadFolder);
  // createFolderIfNeeds(unzipFolder);
  //
  // Http.download(remoteUrl, localZip, onProgress, (succeed, msg) => {
  //   if (!succeed) {
  //     completion(false, `download failed: ${msg ?? ""}`);
  //     return;
  //   }
  //
  //   try {
  //     ZipUtility.unZipFileAtPath(localZip, unzipFolder);
  //
  //     const folderFiles = FileUtility.listFiles(unzipFolder);
  //     folderFiles.forEach(file => {
  //       if (FileUtility.isDirectory(file)) {
  //         deleteDirectoryAt(localFolder);
  //         moveFile(file, localFolder);
  //         deleteDirectoryAt(unzipFolder);
  //         deleteDirectoryAt(localDownloadFolder);
  //       }
  //     });
  //
  //     completion(true, "download finished");
  //   } catch (error) {
  //     completion(false, `download failed: ${(error as Error).message}`);
  //   }
  // });
}

// 创建用于上传的Json
private createDataJson(): string {
  const list = this.createUserExamples();
  return JSON.stringify(list);
}
  private createUserExamples(): UserExampleJson[] {
    const words = SearchManager.shared.getAllWords() ?? [];

    return words
      .filter(w =>
      w.lastResultType !== SearchConstants.TEST_RESULT_NONE ||
        w.correctedTimes > 0 ||
        w.wrangTimes > 0 ||
        w.favoriteLevel > 0 ||
        w.wrangYear !== 0 ||
        w.wrangMonth !== 0 ||
        w.wrangDay !== 0 ||
        w.learnTimes > 0 ||
        (w.memo?.length ?? 0) > 0 ||
      w.isDeleted
      )
      .map(w => {
        // 计算 last_result_type
        let lastResultTypeValue = UserExample.iOS_LastResultType.None;
        if (w.lastResultType === SearchConstants.TEST_RESULT_CORRECT) {
          lastResultTypeValue = UserExample.iOS_LastResultType.Succeed;
        } else if (w.lastResultType === SearchConstants.TEST_RESULT_WRONG) {
          lastResultTypeValue = UserExample.iOS_LastResultType.Failed;
        }

        // 返回 interface 对象（不能 new）
        const json: UserExampleJson = {
          serial_no        : w.idx,
          last_result_type : lastResultTypeValue,
          num_of_succeeded : w.correctedTimes,
          num_of_failed    : w.wrangTimes,
          check_level      : w.favoriteLevel,
          failed_year      : w.wrangYear,
          failed_month     : w.wrangMonth,
          failed_day       : w.wrangDay,
          learn_times      : w.learnTimes,
          memo             : w.memo ?? "",
          share_memos      : [],
          deleted          : w.isDeleted()  // ❗ ArkTS 属性，不是函数
        };

        return json;
      });
  }
private restoreAllExamples(userExamples: UserExample[], onProgress: (percent: number) => void) {

  // 清空原数据
  //删除 收藏夹
  SearchManager.shared.deleteFavorites()

  //删除 学習履歴
  SearchManager.shared.deleteLearnTimes()

  //删除 测验数据
  SearchManager.shared.deleteTestResults()

  //删除 复习列表
  SearchManager.shared.deleteReviewList()

  //删除 已经删除单词 DeleteWord
  SearchManager.shared.deleteDeletedWords()

  //删除 用户笔记
  SearchManager.shared.deleteMemo()

  //TODO：删除 录音

  const words = SearchManager.shared.getAllWords() ?? [];
  userExamples.forEach((ue, i) => {
    onProgress((i + 1) / userExamples.length);

    const serialNo = ue.serialNo;
    if (!serialNo) return;

    const word = words.find(w => w.idx === serialNo);
    if (!word) return;

    word.lastResultType = ue.lastResultType === UserExample.iOS_LastResultType.Succeed
      ? SearchConstants.TEST_RESULT_CORRECT
      : ue.lastResultType === UserExample.iOS_LastResultType.Failed
        ? SearchConstants.TEST_RESULT_WRONG
        : SearchConstants.TEST_RESULT_NONE;

    word.correctedTimes = ue.numOfSucceeded ?? 0;
    word.wrangTimes = ue.numOfFailed ?? 0;
    word.favoriteLevel = ue.checkLevel ?? 0;
    word.wrangYear = ue.failedYear ?? 0;
    word.wrangMonth = ue.failedMonth ?? 0;
    word.wrangDay = ue.failedDay ?? 0;
    word.learnTimes = ue.learnTimes ?? 0;

    // 合并用户笔记
    let memoText = ue.memo?.trim() ?? "";
    const shareMemos = ue.shareMemos?.map(m => m["UserData_Word_ShareMemos_Key_MemoText"]);
    if (shareMemos) {
      memoText = memoText.length > 0 ? memoText + "\n" + shareMemos.join("\n") : shareMemos.join("\n");
    }
    word.memo    = memoText;
    word.deleted = ue.deleted ?? false;

    WordUserDbAccess.shared.saveWordUser(word)

    if (word.idx && word.isDeleted()) {
      WordUserDbAccess.shared.setWordDeletedStatus(word.idx, word.isDeleted())
    }
  });
}
}