
import { AboutView, AboutViewConfig } from '../views/setting/AboutView';
import { ReclaimView, ReclaimViewConfig } from '../views/setting/ReclaimView';
import { AdviceView, AdviceViewConfig } from '../views/setting/AdviceView';
import { LogOffView, LogOffViewConfig } from '../views/login/LogOffView';
import { LinkView, LinkViewConfig } from '../app/views/LinkView';
import { QuickLearnView, QuickLearnViewConfig } from '../views/quicklearn/QuickLearnView';
import { QuickLearnWordsView, QuickLearnWordsViewConfig } from '../views/quicklearn/QuickLearnWordsView';
import { WordCardsView, WordCardsViewConfig } from '../views/card/wordcard/WordCardsView';
import { ComposeMemoView, ComposeMemoViewConfig } from '../views/card/wordcard/memo/ComposeMemoView';
import { SetView, SetViewConfig } from '../views/main/under/SetView';
import { DeletedWordsView, DeletedWordsViewConfig } from '../views/setting/DeletedWordsView';
import { QuizScopeUnitView, QuizScopeUnitViewConfig } from '../views/quiz/scope/QuizScopeUnitView';
import { QuizScopeAllView, QuizScopeAllViewConfig } from '../views/quiz/scope/QuizScopeAllView';
import { QuizScopeCategoryView, QuizScopeCategoryViewConfig } from '../views/quiz/scope/QuizScopeCategoryView';
import { QuizScopeFavoriteView, QuizScopeFavoriteViewConfig } from '../views/quiz/scope/QuizScopeFavoriteView';
import { QuizScopeMistakeView, QuizScopeMistakeViewConfig } from '../views/quiz/scope/QuizScopeMistakeView';
import { QuizStartViewConfig, QuizStartView } from '../views/quiz/start/QuizStartView';
import { QuizRunningView, QuizRunningViewConfig } from '../views/quiz/running/QuizRunningView';
import { QuizResultView, QuizResultViewConfig } from '../views/quiz/result/QuizResultView';
import { QuizChallengeView, QuizChallengeViewConfig } from '../views/quiz/running/QuizChallengeView';
import { SpellRunningView, SpellRunningViewConfig } from '../views/quiz/spell/SpellRunningView';
import { BookListView, BookListViewConfig } from '../views/books/BookListView';
import { BooksOnlineView, BooksOnlineViewConfig } from '../views/books/BooksOnlineView';
import { TestTopView, TestTopViewConfig } from '../views/test/TestTopView';
import { ChallengeTopView, ChallengeTopViewConfig } from '../views/test/ChallengeTopView';
import { UnitWordsView, UnitWordsViewConfig } from '../views/learn/UnitWordsView';
import { UnitsView, UnitsViewConfig } from '../views/learn/UnitsView';
import { DetailCardsView, DetailCardsViewConfig } from '../views/card/detail/DetailCardsView';
import { CigenWordsView, CigenWordsViewConfig } from '../views/card/cigen/CigenWordsView';


@Builder
export function navigationTo<T>(name: string, param: T){

  if (name === LinkViewConfig.NavKey)                     { LinkView({title: (param as LinkViewConfig.Param).title, url: (param as LinkViewConfig.Param).url})
  }else if (name === UnitsViewConfig.NavKey)              { UnitsView()
  }else if (name === UnitWordsViewConfig.NavKey)          { UnitWordsView({unitId: (param as UnitWordsViewConfig.Param).unitId})
  }else if (name === QuickLearnViewConfig.NavKey)         { QuickLearnView()
  }else if (name === QuickLearnWordsViewConfig.NavKey)    { QuickLearnWordsView({unitId: (param as QuickLearnWordsViewConfig.Param).unitId})
  }else if (name === DetailCardsViewConfig.NavKey)        { DetailCardsView({words: (param as DetailCardsViewConfig.Param).words, initIndex: (param as DetailCardsViewConfig.Param).initIndex})
  }else if (name === WordCardsViewConfig.NavKey)          { WordCardsView({words: (param as WordCardsViewConfig.Param).words, initIndex: (param as WordCardsViewConfig.Param).initIndex})
  }else if (name === ComposeMemoViewConfig.NavKey)        { ComposeMemoView({word: (param as ComposeMemoViewConfig.Param).word})
  }else if (name === BookListViewConfig.NavKey)           { BookListView()
  }else if (name === BooksOnlineViewConfig.NavKey)        { BooksOnlineView({category: (param as BooksOnlineViewConfig.Param).category})
  }else if (name === CigenWordsViewConfig.NavKey)         { CigenWordsView({words: (param as CigenWordsViewConfig.Param).words, navTitle:  (param as CigenWordsViewConfig.Param).navTitle})
  }else if (name === DeletedWordsViewConfig.NavKey)       { DeletedWordsView()
  }else if (name === TestTopViewConfig.NavKey)            { TestTopView()
  }else if (name === ChallengeTopViewConfig.NavKey)       { ChallengeTopView()
  }else if (name === QuizScopeUnitViewConfig.NavKey)      { QuizScopeUnitView()
  }else if (name === QuizScopeAllViewConfig.NavKey)       { QuizScopeAllView()
  }else if (name === QuizScopeCategoryViewConfig.NavKey)  { QuizScopeCategoryView()
  }else if (name === QuizScopeFavoriteViewConfig.NavKey)  { QuizScopeFavoriteView()
  }else if (name === QuizScopeMistakeViewConfig.NavKey)   { QuizScopeMistakeView()
  }else if (name === QuizStartViewConfig.NavKey)          { QuizStartView()
  }else if (name === QuizRunningViewConfig.NavKey)        { QuizRunningView()
  }else if (name === QuizChallengeViewConfig.NavKey)      { QuizChallengeView()
  }else if (name === SpellRunningViewConfig.NavKey)       { SpellRunningView()
  }else if (name === QuizResultViewConfig.NavKey)         { QuizResultView()
  }else if (name === AdviceViewConfig.NavKey)             { AdviceView()
  }else if (name === ReclaimViewConfig.NavKey)            { ReclaimView()
  }else if (name === LogOffViewConfig.NavKey)             { LogOffView()
  }else if (name === SetViewConfig.NavKey)                { SetView()
  }else if (name === AboutViewConfig.NavKey)              { AboutView()
  }else{ NavDestination(){Text(`<Index.ets>未配置navigationTo: ${name}`)}
  }
}