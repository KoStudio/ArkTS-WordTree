

// 创建卡片背景形状
@ComponentV2
export struct BgCardShape {


  // @Local settings: UserSettings = PersistenceV2.connect(UserSettings, GlobalKey.kUserSettings)!

  build() {

    // if (this.settings.isListOneCircle) {
    //   // 圆形卡片
    //   Circle()
    //     .width('100%')
    //     .height('100%')
    //     .fill(Color.White)
    //     .borderRadius('100%')
    //     .shadow({
    //       radius: 10,
    //       color: Color.Gray,
    //       offsetX: 10,
    //       offsetY: 10
    //     })
    // } else {

    //   方形卡片
    Stack(){


      Rect()
        .width('100%')
        .height('100%')
        .fill(Color.White)
        .borderRadius(16)
        .radius(16)
        .shadow({
          radius: 10,
          color: Color.Gray,
          offsetX: 10,
          offsetY: 10
        })

      // CardBorderView({hasPinyin: false})
      //   .margin(20)
    }


    // }



  }
}