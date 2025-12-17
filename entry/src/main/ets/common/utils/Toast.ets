// ToastUtility.ets
import { LengthMetrics, LoadingDialog, LoadingDialogV2, PromptAction, promptAction } from '@kit.ArkUI';
import { isDebugMode } from '../../app/constants/AppDefines';
import { BusinessError } from '@kit.BasicServicesKit';
import { getUIContext } from '../../app/constants/AppContext';


export class Toast {


  /**
   * 显示普通提示消息
   * @param msg 消息内容
   */
  static showMessage(msg: string | Resource | null | undefined, isAlwaysTopMost: boolean = false): void {
    if (!msg) return;//检查所有 falsy 值（包括 null、undefined、0、""、false、NaN）	会拦截数字 0 和空字符串 ""

    promptAction.showToast({
      message: msg,
      showMode: isAlwaysTopMost ? promptAction.ToastShowMode.TOP_MOST : promptAction.ToastShowMode.DEFAULT,
      duration: 2000 // 2秒
    });
  }

  /**
   * 显示调试消息（仅调试模式）
   * @param msg 调试消息
   */
  static showDebugMessage(msg: string | Resource | null | undefined): void {
    if (!msg || !isDebugMode) return;

    promptAction.showToast({
      message: `[\uD83D\uDC1EDebugMessage\uD83D\uDC1E] ${msg}`,
      duration: 4000 // 4秒

    });
  }

  static showConfirm(option: ConfirmOption){
    Toast.showAlert({
      title: option.title ?? $r('app.string.alert_title_confirm'),
      message: option.msg ?? $r('app.string.alert_msg_confirm_remove'),
      secondaryButton: {value: option.btnNo ?? $r('app.string.cfm_btn_cancel'), fontColor: Color.Gray, action: () => {}},
      primaryButton: {value: option.btnYes ?? $r('app.string.confirm_btn_yes'), action: () => {
        //回调
        option.yesAction()
      }}
    })
  }

  static showAlert(value: AlertDialogParamWithConfirm | AlertDialogParamWithButtons | AlertDialogParamWithOptions){
    AlertDialog.show(value)
    //getUIContext().showAlertDialog(value) 以后可以使用这行
  }



  /**
   * 显示带确认选项的通用对话框
   * @param title - 对话框标题（支持字符串或资源引用）
   * @param message - 对话框内容（可选）
   * @param options - 按钮选项数组，每个选项包含文本、颜色和点击回调
   * @Param cancelTitle - 取消按钮 文本，undefined时有默认值，null时不添加取消按钮
   * @remarks
   * - 自动处理按钮索引越界情况
   * - 支持动态生成的按钮样式和回调
   * - 错误会通过console.error输出
   * @example
   * ```typescript
   * showConfirm("提示", "确认删除吗？", [
   *   { text: "取消", color: Color.Gray, action: () => {} },
   *   { text: "确定", color: Color.Red, action: () => deleteItem() }
   * ]);
   * ```
   */
  static showSelectOptions(title: string | ResourceStr, message?: string | ResourceStr, options?: ItemOption[], cancelTitle?: ResourceStr | null): void {
    // 转换按钮配置：提取text和color字段，适配showDialog接口
    const btns: Button[] | undefined = options?.map((it): Button => ({
      text: it.text,
      color: it.color ?? $r('app.color.colorPrimary') // 颜色默认值
    }));

    /// 取消
    if (cancelTitle === null) {
      //do nothing.. null时，不添加取消按钮
    }else if (cancelTitle === undefined){
      btns?.push({ text: $r('app.string.confirm_btn_cancel'), color: $r('app.color.color_gray') })
    }else{
      btns?.push({ text: cancelTitle, color: $r('app.color.color_gray') })
    }


    // 调用系统弹窗API
    promptAction.showDialog({
      title: title,
      message: message,
      buttons: btns
    }).then(res => {
      // 处理用户选择
      const idx = res.index;
      if (options && idx >= 0 && idx < options.length) {
        try {
          options[idx].action(); // 执行对应按钮的回调
        } catch (e) {
          console.error(`按钮回调执行失败: ${e}`);
        }
      }
    }).catch((err: BusinessError) => {
      // 处理取消或错误（如API调用失败）
      console.error(
        `对话框操作失败，错误码: ${err.code}, 错误信息: ${err.message}`
      );
    });
  }

  /**
   * 显示一个操作菜单（Action Menu），支持最多 6 个选项。
   * 超过 6 个选项时会提示用户限制，并不显示菜单。
   *
   * @param title 操作菜单的标题，可以是字符串或本地化资源字符串
   * @param options 操作项数组，每个包含文本、颜色和点击后的操作
   */
  static showActionMenu(title: string | ResourceStr, options: ItemOption[]): void {
    // 如果没有任何选项，直接返回
    if (options.length === 0) return;

    // 如果操作项数量超过 6 个，提示用户，并终止显示菜单
    if (options.length > 6) {
      promptAction.showToast({
        message: '最多只能显示 6 个操作项', // 可根据需要替换为本地化文本
        duration: 2000 // 提示持续时间（毫秒）
      });
      return;
    }

    // 将每个操作项转换为 Button 类型，仅保留 text 和 color 字段
    const buttonsTuple = [
      ...options.map(it => ({
        text: it.text,//typeof it.text === 'string' ? it.text : String(it.text), // 确保 text 是字符串
        color: it.color ?? $r('app.color.colorPrimary') //颜色默认值
      } as Button))
    ] as [Button, Button?, Button?, Button?, Button?, Button?]; // 显式声明为最多 6 个按钮的元组类型

    // 调用系统提供的 promptAction API 显示操作菜单
    promptAction.showActionMenu({
      title: title,         // 菜单标题
      buttons: buttonsTuple // 按钮列表（最多 6 个）
    }).then(res => {
      const idx = res.index; // 用户点击的按钮索引

      // 安全范围判断，确保索引有效后执行对应的 action 回调
      if (idx >= 0 && idx < options.length) {
        options[idx].action(); // 执行点击对应按钮后的操作
      }
    }).catch((err: Error) => {
      // 用户取消或出现错误，可选择记录日志或忽略
      console.warn('用户取消或发生错误:', err);
    });
  }
  /**
   * 显示自定义底部弹窗
   * @param builder - 自定义弹窗内容构建器，需使用`@Builder`修饰的函数
   * @param autoCancel: true 允许用户点击空白处关闭Dialog
   * @remarks
   * - 弹窗默认从屏幕底部弹出
   * - 自动处理软键盘冲突（避让模式）
   * - 错误会通过console.error输出
   * @example
   * ```typescript
   * @Builder function MyDialog() {
   *   Column() { Text("自定义内容") }
   * }
   * showCustomDialog(()=>{this.MyDialog()});
   * ```
   */
  static showCustomDialog(builder: CustomBuilder, autoCancel: boolean = true, isBgTransparent: boolean = false, onDisappear?: ()=>void ): void {

    promptAction.openCustomDialog({
      builder: builder, // 传入自定义UI构建器
      isModal:true,
      autoCancel: autoCancel,
      showInSubWindow:false,
      alignment: DialogAlignment.Center, // 弹窗对齐方式：底部
      keyboardAvoidMode: KeyboardAvoidMode.DEFAULT, // 软键盘弹出时自动调整弹窗位置
      keyboardAvoidDistance: LengthMetrics.vp(10), // 弹窗与键盘间距为0虚拟像素(默认紧贴键盘上方)
      maskColor: $r('app.color.color_translucent'),// ✅ 半透明黑色遮罩 (50% 透明度)
      backgroundColor: isBgTransparent ? Color.Transparent : Color.White,
      backgroundBlurStyle: isBgTransparent ? BlurStyle.NONE : BlurStyle.Regular,
      maskRect:{ x: 0, y: 0, width: '100%', height: '100%' },
      onDidDisappear: onDisappear,

    }).then((dialogId: number) => {
      Toast.customDialogComponentId = dialogId
    }).catch((error: BusinessError) => {
        console.error(`openCustomDialog error code is ${error.code}, message is ${error.message}`)
    })


  }
   static customDialogComponentId = 0
  static closeCustomDialog(){
    getUIContext().getPromptAction().closeCustomDialog(Toast.customDialogComponentId)
    Toast.customDialogComponentId = 0
  }
}

export interface ItemOption  {
  text: string | ResourceStr;
  color?: string | Resource;
  primary?: boolean;
  action: () => void;
};
export interface Button {
  text: string | Resource;
  color: string | Resource;
  primary?: boolean;
}

export interface ConfirmOption {
  title?: ResourceStr;
  msg?:  ResourceStr;
  btnYes?:  ResourceStr;
  btnNo?: ResourceStr;
  yesAction: () => void;
}

