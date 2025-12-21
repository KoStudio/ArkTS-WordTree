
@ComponentV2
export struct SubLearnView {
  build() {
    Column() {
      Scroll() {
        Column({ space: 12 }) {
          InfoPanel()
          ButtonPanel()
          TodayPanel()
          CurvePanel()
        }
        .padding(10)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_background'))
    .border({width: {bottom: 1}, color: $r('app.color.color_gray_light')})
  }
}

@Builder
function InfoPanel() {
  Column({ space: 10 }) {
    InfoTitleRow()
    InfoCountRow()
    InfoLearnTestRow()
  }
  .padding(10)
}

@Builder
function InfoTitleRow() {
  Text('CET4')
    .fontSize(28)
    .fontWeight(FontWeight.Bold)
    .textAlign(TextAlign.Center)
}

@Builder
function InfoCountRow() {
  Row({ space: 20 }) {
    InfoBox('140个单元', '#66CD40')
    InfoBox('1223个单词', '#26C9FF')
  }
}

@Builder
function InfoBox(text: string, color: string) {
  Text(text)
    .width('45%')
    .padding(10)
    .textAlign(TextAlign.Center)
    .fontSize(16)
    .fontColor(color)
    .backgroundColor('#222222')
    .borderRadius(12)
}

@Builder
function InfoLearnTestRow() {
  Row({ space: 8 }) {
    LearnTestItem($r('app.media.ic_yixuexi'), '已学习', '140', '#66CD40')
    Blank().width(20)
    LearnTestItem($r('app.media.ic_yiceyan'), '已测验', '1223', '#26C9FF')
  }
}

interface LearnTestItemData {
  icon: Resource
  title: string
  value: string
  valueColor: string
}

@Builder
function LearnTestItem(icon: Resource, title: string, value: string, valueColor: string) {
  Row({ space: 4 }) {
    Image(icon).width(15).height(11)
    Text(title).fontSize(18)
    Text(value).fontSize(30).fontColor(valueColor)
  }
}

@Builder
function ButtonPanel() {
  Column({ space: 10 }) {
    ButtonRow({ title: '快速记忆', icon: 'ic_kuaisujiyi' }, { title: '学习', icon: 'ic_xuexi' })
    ButtonRow({ title: '测验', icon: 'ic_ceyan' }, { title: '挑战', icon: 'ic_tiaozhan' })
  }
}

interface BtnData {
  title: string
  icon: string
}

@Builder
function ButtonRow(left: BtnData, right: BtnData) {
  Row({ space: 10 }) {
    MainButton(left.title, left.icon)
    MainButton(right.title, right.icon)
  }
}

@Builder
function MainButton(title: string, icon: string) {
  Button() {
    Column({ space: 6 }) {
      Image($r(`app.media.${icon}`)).width(24).height(24)
      Text(title).fontSize(14)
    }
  }
  .layoutWeight(1)
  .height(100)
  .borderRadius(12)
}

@Builder
function TodayPanel() {
  Stack() {
    Image($r('app.media.bg_banner')).width('100%').height(140).objectFit(ImageFit.Cover)
    TodayTitle()
  }
}

@Builder
function TodayTitle() {
  Text('Excellent\n   English').fontSize(32).fontColor(Color.White).margin({ left: 10, top: 10 })
}

@Builder
function CurvePanel() {
  Column() {
    CurveCard()
  }
  .padding(10)
  .backgroundColor('#EEEEEE')
}

@Builder
function CurveCard() {
  Column({ space: 8 }) {
    CurveHeaderRow()
    CurveActionRow()
  }
  .padding(10)
  .backgroundColor(Color.White)
  .borderRadius(12)
}

@Builder
function CurveHeaderRow() {
  Row() {
    Text('记忆曲线').fontSize(16).fontWeight(FontWeight.Bold)
    Blank()
    Button().width(25).height(25)
  }
}

@Builder
function CurveActionRow() {
  Column({ space: 6 }) {
    Button('创建计划').width(180).height(32)
    Text('创建学习计划，开始记忆曲线').fontSize(14)
  }
  .alignItems(HorizontalAlign.Center)
}
