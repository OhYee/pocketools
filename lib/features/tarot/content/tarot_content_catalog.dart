import '../domain/tarot_deck.dart';
import '../domain/tarot_models.dart';
import 'tarot_content_models.dart';

abstract final class TarotContentCatalog {
  static const contentVersion = '1.0.0';

  static final Map<String, TarotCardContent> entries = _buildEntries();

  static TarotCardContent entryFor(String cardId) {
    final entry = entries[cardId];
    if (entry == null) throw StateError('Missing tarot content for $cardId.');
    return entry;
  }

  static List<String> validate() {
    final errors = <String>[];
    if (entries.length != TarotDeck.standard.length) {
      errors.add('塔罗原创内容必须覆盖完整 78 张牌。');
    }
    for (final card in TarotDeck.standard) {
      final entry = entries[card.id];
      if (entry == null) {
        errors.add('缺少 ${card.id} 的原创解释。');
        continue;
      }
      if (entry.uprightKeywords.length < 3 ||
          entry.reversedKeywords.length < 3 ||
          entry.traditionalSymbols.isEmpty ||
          entry.uprightMeaning.trim().isEmpty ||
          entry.reversedMeaning.trim().isEmpty ||
          entry.reflectionQuestions.isEmpty) {
        errors.add('${card.id} 的解释字段不完整。');
      }
    }
    return List<String>.unmodifiable(errors);
  }

  static Map<String, TarotCardContent> _buildEntries() {
    final built = <String, TarotCardContent>{};
    for (var index = 0; index < _majorSeeds.length; index++) {
      final card = TarotDeck.standard[index];
      final seed = _majorSeeds[index];
      built[card.id] = TarotCardContent(
        cardId: card.id,
        uprightKeywords: seed.uprightKeywords,
        reversedKeywords: seed.reversedKeywords,
        traditionalSymbols: seed.symbols,
        uprightMeaning: seed.uprightMeaning,
        reversedMeaning: seed.reversedMeaning,
        reflectionQuestions: seed.reflections,
      );
    }
    for (final card in TarotDeck.standard.where(
      (card) => card.arcana == TarotArcana.minor,
    )) {
      final suit = _suitSeeds[card.suit!]!;
      final rank = _rankSeeds[card.rank!]!;
      built[card.id] = TarotCardContent(
        cardId: card.id,
        uprightKeywords: <String>[
          suit.focus,
          rank.uprightFocus,
          '${suit.shortName}${rank.motion}',
        ],
        reversedKeywords: <String>[
          suit.pause,
          rank.reversedFocus,
          '${suit.shortName}再校准',
        ],
        traditionalSymbols: <String>[
          '${tarotSuitName(card.suit!)}在传统牌组结构中关联${suit.traditionalDomain}。',
          '${tarotRankName(card.rank!)}常用于观察${rank.structuralTheme}。',
        ],
        uprightMeaning:
            '这张牌可作为观察${suit.domain}中“${rank.uprightFocus}”的提示：'
            '先辨认已有资源，再选择一个与当下节奏相称的动作。',
        reversedMeaning:
            '逆位可提示${suit.domain}里的“${rank.reversedFocus}”：'
            '不必急于下结论，可以检查阻力来自节奏、边界还是注意力分配。',
        reflectionQuestions: <String>[
          '在${suit.domain}里，什么细节最值得被重新看见？',
          '怎样的小调整能让${rank.structuralTheme}更清楚？',
        ],
      );
    }
    final errors = <String>[];
    if (built.keys.toSet().length != TarotDeck.standard.length) {
      errors.add('Tarot content IDs are incomplete or duplicated.');
    }
    if (errors.isNotEmpty) throw StateError(errors.join(' '));
    return Map<String, TarotCardContent>.unmodifiable(built);
  }

  static const List<_MajorContentSeed> _majorSeeds = <_MajorContentSeed>[
    _MajorContentSeed(
      uprightKeywords: <String>['开放', '试探', '轻装'],
      reversedKeywords: <String>['迟疑', '分心', '准备不足'],
      symbols: <String>['旅程起点', '未知边界与轻装前行'],
      uprightMeaning: '愚者可提示一次尚未定型的开始。开放不等于莽撞，先为好奇心留出安全边界。',
      reversedMeaning: '逆位可提示准备与冲动之间的落差。暂停片刻，确认代价与支持是否清楚。',
      reflections: <String>['哪里值得先做一个小规模尝试？', '什么边界会让探索更安心？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['专注', '资源', '实践'],
      reversedKeywords: <String>['散乱', '工具错配', '用力过度'],
      symbols: <String>['工具与意图的连接', '把想法落实为行动'],
      uprightMeaning: '魔术师可提示把手边资源组织成可执行的一步，并观察意图与行动是否一致。',
      reversedMeaning: '逆位可提示资源很多却缺少焦点，或表达与真实意图尚未对齐。',
      reflections: <String>['哪项现有资源还没有被善用？', '最小可执行的一步是什么？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['静观', '直觉', '留白'],
      reversedKeywords: <String>['噪声', '封闭', '误读'],
      symbols: <String>['内外信息的门槛', '沉默与尚未显露的线索'],
      uprightMeaning: '女祭司可提示先容纳不确定，让细微线索在安静观察中逐渐显现。',
      reversedMeaning: '逆位可提示内在声音被噪声覆盖，或把猜测过早当成事实。',
      reflections: <String>['哪些线索值得再观察而非立即解释？', '怎样创造一点不被打扰的留白？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['滋养', '创造', '丰盛'],
      reversedKeywords: <String>['透支', '停滞', '忽略自身'],
      symbols: <String>['生长与照料', '感官经验和创造空间'],
      uprightMeaning: '女皇可提示通过持续照料让想法或关系获得生长空间，同时接纳真实需要。',
      reversedMeaning: '逆位可提示付出失衡或创造力被耗尽，需要把照料也留给自己。',
      reflections: <String>['什么正在等待稳定的照料？', '你需要补充哪一种资源？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['结构', '责任', '边界'],
      reversedKeywords: <String>['僵化', '控制', '边界模糊'],
      symbols: <String>['秩序与承担', '规则带来的稳定'],
      uprightMeaning: '皇帝可提示用清楚的结构承接责任，让规则服务于共同目标而非压缩空间。',
      reversedMeaning: '逆位可提示结构过硬或权责不清，适合重新检查规则为何存在。',
      reflections: <String>['哪条边界需要说得更清楚？', '当前结构是否仍服务于目标？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['传承', '学习', '共同语言'],
      reversedKeywords: <String>['教条', '盲从', '重新诠释'],
      symbols: <String>['制度化知识', '群体传统与学习路径'],
      uprightMeaning: '教皇可提示借助成熟框架学习，并辨认哪些共同语言能促进理解。',
      reversedMeaning: '逆位可提示传统与当下处境不完全贴合，需要在尊重来源的同时重新提问。',
      reflections: <String>['哪个框架能帮助你更系统地理解问题？', '哪些惯例需要重新说明？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['选择', '联结', '价值一致'],
      reversedKeywords: <String>['分歧', '投射', '难以承诺'],
      symbols: <String>['关系中的相互看见', '选择与价值的对应'],
      uprightMeaning: '恋人可提示关系或选择中的价值对齐，重点是诚实沟通而非寻找唯一答案。',
      reversedMeaning: '逆位可提示期待与现实之间存在分歧，需要区分自身需要和对他人的投射。',
      reflections: <String>['这个选择反映了什么重要价值？', '哪一处期待需要被坦诚说明？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['方向', '协调', '推进'],
      reversedKeywords: <String>['拉扯', '失速', '方向冲突'],
      symbols: <String>['多股力量的协调', '意志与行进方向'],
      uprightMeaning: '战车可提示先让不同动力朝同一方向协作，再以稳定节奏推进。',
      reversedMeaning: '逆位可提示行动被相反目标拉扯，继续加速前更适合校准方向。',
      reflections: <String>['哪些力量需要被协调？', '现在真正要前往的方向是什么？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['耐心', '勇气', '柔韧'],
      reversedKeywords: <String>['自我怀疑', '压抑', '耗竭'],
      symbols: <String>['温和约束本能', '内在力量与耐性'],
      uprightMeaning: '力量可提示用耐心承接强烈感受，柔韧的回应也可以很有力量。',
      reversedMeaning: '逆位可提示勇气被消耗或情绪被过度压住，需要更温和地恢复资源。',
      reflections: <String>['怎样回应能兼顾坚定与温和？', '什么正在消耗你的内在资源？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['独处', '求索', '澄明'],
      reversedKeywords: <String>['隔绝', '回避', '迷失'],
      symbols: <String>['在有限光线中寻找方向', '主动退后与内省'],
      uprightMeaning: '隐者可提示暂时远离噪声，以自己的步速辨认真正重要的问题。',
      reversedMeaning: '逆位可提示独处变成隔绝，或持续分析却没有回到现实连接。',
      reflections: <String>['安静下来后，哪个问题最清楚？', '你需要保留独处还是重新连接？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['变化', '周期', '转折'],
      reversedKeywords: <String>['反复', '抗拒', '时机未明'],
      symbols: <String>['循环与阶段转换', '个人选择与外部变化交会'],
      uprightMeaning: '命运之轮可提示局面处在转换中，观察周期有助于选择可控制的回应。',
      reversedMeaning: '逆位可提示相似模式再次出现，适合区分无法控制的变化与可调整的习惯。',
      reflections: <String>['当前变化中什么仍由你决定？', '哪个重复模式值得被命名？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['衡量', '诚实', '责任'],
      reversedKeywords: <String>['偏差', '逃避', '标准不一'],
      symbols: <String>['权衡与因果责任', '一致标准和清晰判断'],
      uprightMeaning: '正义可提示回到事实、影响与责任，用一致标准看待自己和他人。',
      reversedMeaning: '逆位可提示信息不全、标准摇摆或不愿面对影响，需要补足依据。',
      reflections: <String>['还有哪些事实需要确认？', '怎样的标准对各方更一致？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['暂停', '换位', '松手'],
      reversedKeywords: <String>['拖延', '僵持', '无效牺牲'],
      symbols: <String>['视角倒置', '主动停顿与重新理解'],
      uprightMeaning: '倒吊人可提示暂停惯性动作，从不同角度理解局面，再决定什么可以松开。',
      reversedMeaning: '逆位可提示停顿失去目的或付出没有边界，需要重新确认等待的价值。',
      reflections: <String>['换一个角度后，什么变得不同？', '哪一种等待已经不再有帮助？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['结束', '转换', '更新'],
      reversedKeywords: <String>['留恋', '抗拒结束', '过渡受阻'],
      symbols: <String>['阶段终结与形态变化', '为新阶段腾出空间'],
      uprightMeaning: '死神可提示某个阶段正在结束，进入新的转换。',
      reversedMeaning: '逆位可提示难以放下旧形态，使过渡变得迟缓，适合辨认真正舍不得的部分。',
      reflections: <String>['什么已经完成了它的作用？', '怎样告别能保留经验而非停在原地？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['调和', '节奏', '整合'],
      reversedKeywords: <String>['失衡', '急切', '难以兼容'],
      symbols: <String>['不同成分的往返调配', '耐心形成新平衡'],
      uprightMeaning: '节制可提示在差异之间寻找可持续比例，让改变通过反复微调发生。',
      reversedMeaning: '逆位可提示节奏过快或资源分配失衡，暂时减量可能比继续叠加更有效。',
      reflections: <String>['哪两种需要可以被更好地调和？', '什么节奏更容易长期维持？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['束缚', '欲望', '看见代价'],
      reversedKeywords: <String>['松动', '否认', '重建选择'],
      symbols: <String>['依附与自我限制', '欲望背后的交换'],
      uprightMeaning: '恶魔可提示观察让人难以退出的交换或习惯，命名代价是恢复选择的开始。',
      reversedMeaning: '逆位可提示束缚开始松动，也可能仍在否认影响，需要把选择落实为边界。',
      reflections: <String>['哪种习惯正在缩小你的选择？', '一个可执行的边界会是什么？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['震动', '揭露', '重建'],
      reversedKeywords: <String>['余震', '回避事实', '缓慢松动'],
      symbols: <String>['旧结构受到冲击', '被遮蔽的信息突然显露'],
      uprightMeaning: '高塔可提示旧结构出现裂缝，先确认现实影响，再考虑哪些部分值得重建。',
      reversedMeaning: '逆位可提示变化以内在或渐进方式发生，也可能是对明显问题的回避。',
      reflections: <String>['什么事实已经无法继续忽略？', '重建时最需要保留的基础是什么？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['希望', '复原', '坦诚'],
      reversedKeywords: <String>['灰心', '期待过高', '失去连接'],
      symbols: <String>['风暴后的清澈', '恢复信任与长期方向'],
      uprightMeaning: '星星可提示在经历消耗后恢复长期视角，让希望与可持续行动相互支持。',
      reversedMeaning: '逆位可提示暂时难以感到希望，适合把宏大期待缩小成可感知的支持。',
      reflections: <String>['什么微小迹象让你愿意继续？', '哪种支持能帮助你慢慢复原？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['朦胧', '感受', '辨识'],
      reversedKeywords: <String>['迷雾渐散', '焦虑放大', '误判'],
      symbols: <String>['夜间路径与不完整信息', '直觉、恐惧和投射交织'],
      uprightMeaning: '月亮可提示信息尚不完整，感受值得被听见，但仍需与可核实事实区分。',
      reversedMeaning: '逆位可提示迷雾开始散去，也可能是焦虑让线索失真，适合逐项核对。',
      reflections: <String>['哪些是事实，哪些是担忧或想象？', '还需要等待哪项信息？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['明朗', '活力', '分享'],
      reversedKeywords: <String>['过曝', '疲惫', '快乐受阻'],
      symbols: <String>['清晰可见与生命力', '成果被共同看见'],
      uprightMeaning: '太阳可提示局面更清楚，适合承认已有进展，并把活力投入真实连接。',
      reversedMeaning: '逆位可提示成果被过高期待遮住，或需要先恢复精力才能感受进展。',
      reflections: <String>['哪项进展值得被承认？', '怎样分享能让连接更真实？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['回顾', '回应', '重新选择'],
      reversedKeywords: <String>['苛责', '迟迟不决', '拒绝回应'],
      symbols: <String>['回应召唤与整体回顾', '经验被重新理解'],
      uprightMeaning: '审判可提示从更长时间线回看经验，并对已经听见的需要作出清醒回应。',
      reversedMeaning: '逆位可提示自我评判盖过了学习，或迟迟不愿回应已清楚的问题。',
      reflections: <String>['回看这段经历，你学到了什么？', '哪个回应已经可以开始？'],
    ),
    _MajorContentSeed(
      uprightKeywords: <String>['完成', '整合', '进入新阶段'],
      reversedKeywords: <String>['未收尾', '割裂', '迟来的完成'],
      symbols: <String>['循环完成与经验整合', '阶段边界和更广视野'],
      uprightMeaning: '世界可提示一个阶段趋于完整，适合整合经验并确认下一阶段的边界。',
      reversedMeaning: '逆位可提示仍有收尾工作，或成果尚未被纳入整体理解。',
      reflections: <String>['什么已经形成一个完整循环？', '最后哪一步能帮助经验真正落地？'],
    ),
  ];

  static const Map<TarotSuit, _SuitContentSeed> _suitSeeds =
      <TarotSuit, _SuitContentSeed>{
        TarotSuit.wands: _SuitContentSeed(
          shortName: '行动',
          domain: '行动、动力与创造实践',
          traditionalDomain: '火元素式的动力、意愿与实践',
          focus: '动力',
          pause: '节奏放缓',
        ),
        TarotSuit.cups: _SuitContentSeed(
          shortName: '感受',
          domain: '感受、关系与情绪流动',
          traditionalDomain: '水元素式的感受、关系与接纳',
          focus: '感受',
          pause: '情绪回看',
        ),
        TarotSuit.swords: _SuitContentSeed(
          shortName: '思考',
          domain: '思考、沟通与判断边界',
          traditionalDomain: '风元素式的思考、语言与辨别',
          focus: '辨识',
          pause: '观点松动',
        ),
        TarotSuit.pentacles: _SuitContentSeed(
          shortName: '落实',
          domain: '资源、身体感受与现实落实',
          traditionalDomain: '土元素式的资源、劳动与稳定',
          focus: '落实',
          pause: '资源盘点',
        ),
      };

  static const Map<TarotRank, _RankContentSeed> _rankSeeds =
      <TarotRank, _RankContentSeed>{
        TarotRank.ace: _RankContentSeed('开端', '种子尚未落地', '新的可能', '萌发'),
        TarotRank.two: _RankContentSeed('权衡', '难以选择', '两种方向的比较', '对照'),
        TarotRank.three: _RankContentSeed('协作', '配合失焦', '初步扩展与协作', '联结'),
        TarotRank.four: _RankContentSeed('稳定', '停在舒适区', '建立边界与容器', '安放'),
        TarotRank.five: _RankContentSeed('摩擦', '冲突内耗', '差异与调整压力', '碰撞'),
        TarotRank.six: _RankContentSeed('过渡', '难以离开旧节奏', '重新平衡与移动', '转换'),
        TarotRank.seven: _RankContentSeed('评估', '防御过度', '检视投入与立场', '校准'),
        TarotRank.eight: _RankContentSeed('深化', '重复而无进展', '持续练习与加速', '推进'),
        TarotRank.nine: _RankContentSeed('累积', '接近耗竭', '接近完成的承受力', '沉淀'),
        TarotRank.ten: _RankContentSeed('阶段完成', '负担过重', '结果、责任与收尾', '归拢'),
        TarotRank.page: _RankContentSeed('学习', '信息不成熟', '好奇、消息与初学', '探问'),
        TarotRank.knight: _RankContentSeed('投入行动', '冲得过快', '推进方式与动力', '奔赴'),
        TarotRank.queen: _RankContentSeed('内在掌握', '照料失衡', '成熟接纳与内在领导', '涵容'),
        TarotRank.king: _RankContentSeed('外在承担', '权责僵化', '成熟决策与外在领导', '统筹'),
      };
}

final class TarotInterpretationComposer {
  const TarotInterpretationComposer();

  TarotCardInterpretation resolve(TarotDrawnCard drawnCard) {
    final content = TarotContentCatalog.entryFor(drawnCard.card.id);
    final reversed = drawnCard.orientation == TarotOrientation.reversed;
    return TarotCardInterpretation(
      drawnCard: drawnCard,
      keywords: reversed ? content.reversedKeywords : content.uprightKeywords,
      traditionalSymbols: content.traditionalSymbols,
      uprightMeaning: content.uprightMeaning,
      reversedMeaning: content.reversedMeaning,
      currentDirectionMeaning: reversed
          ? content.reversedMeaning
          : content.uprightMeaning,
      positionMeaning: _positionMeaning(drawnCard, content, reversed),
      reflectionQuestions: content.reflectionQuestions,
    );
  }

  List<TarotCardInterpretation> resolveReading(TarotReadingResult result) =>
      List<TarotCardInterpretation>.unmodifiable(result.cards.map(resolve));

  String? combinationHint(TarotReadingResult result) {
    if (result.config.spread != TarotSpreadPreset.pastPresentFuture ||
        result.cards.length < result.config.drawCount) {
      return null;
    }
    final interpretations = resolveReading(result);
    final firstThemes = interpretations
        .map((interpretation) => interpretation.keywords.first)
        .join('、');
    final reversedCount = result.cards
        .where((card) => card.orientation == TarotOrientation.reversed)
        .length;
    final directionNote = reversedCount == 0
        ? '三张牌都以正位呈现，可观察这些主题如何相互支持。'
        : '其中 $reversedCount 张为逆位，可把它们看作节奏、边界或注意力上的张力。';
    return '组合提示：过去、现在、未来依次出现“$firstThemes”。$directionNote';
  }

  String _positionMeaning(
    TarotDrawnCard drawnCard,
    TarotCardContent content,
    bool reversed,
  ) {
    final keyword =
        (reversed ? content.reversedKeywords : content.uprightKeywords).first;
    return switch (drawnCard.position) {
      TarotPosition.dailyGuidance => '在今日提示位置，“$keyword”可作为一天中的观察主题。',
      TarotPosition.coreMessage => '在核心信息位置，“$keyword”邀请你从一个新角度整理问题。',
      TarotPosition.past => '在过去位置，“$keyword”可帮助回看已经形成的背景与经验。',
      TarotPosition.present => '在现在位置，“$keyword”可帮助辨认此刻最值得留意的关系、资源或张力。',
      TarotPosition.future => '在未来位置，“$keyword”提供后续观察方向。',
    };
  }
}

final class _MajorContentSeed {
  const _MajorContentSeed({
    required this.uprightKeywords,
    required this.reversedKeywords,
    required this.symbols,
    required this.uprightMeaning,
    required this.reversedMeaning,
    required this.reflections,
  });

  final List<String> uprightKeywords;
  final List<String> reversedKeywords;
  final List<String> symbols;
  final String uprightMeaning;
  final String reversedMeaning;
  final List<String> reflections;
}

final class _SuitContentSeed {
  const _SuitContentSeed({
    required this.shortName,
    required this.domain,
    required this.traditionalDomain,
    required this.focus,
    required this.pause,
  });

  final String shortName;
  final String domain;
  final String traditionalDomain;
  final String focus;
  final String pause;
}

final class _RankContentSeed {
  const _RankContentSeed(
    this.uprightFocus,
    this.reversedFocus,
    this.structuralTheme,
    this.motion,
  );

  final String uprightFocus;
  final String reversedFocus;
  final String structuralTheme;
  final String motion;
}
