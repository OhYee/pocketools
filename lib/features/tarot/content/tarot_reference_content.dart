import '../domain/tarot_models.dart';

/// Concise reference summaries based on A. E. Waite's public-domain
/// companion text for the Rider-Waite-Smith deck. These are Chinese
/// paraphrases, not a verbatim translation and not the only RWS school.
final class TarotReferenceContent {
  const TarotReferenceContent({
    required this.uprightKeywords,
    required this.reversedKeywords,
    required this.uprightMeaning,
    required this.reversedMeaning,
  });

  final List<String> uprightKeywords;
  final List<String> reversedKeywords;
  final String uprightMeaning;
  final String reversedMeaning;
}

abstract final class TarotReferenceContentCatalog {
  static const sourceLabel = 'RWS/Waite 传统参考（中文摘要）';
  static const sourceUrl =
      'https://en.wikisource.org/wiki/The_Pictorial_Key_to_the_Tarot/Part_3';

  static TarotReferenceContent forCard(TarotCard card) {
    if (card.arcana == TarotArcana.major) {
      final reference = _major[card.deckIndex];
      if (reference != null) return reference;
    } else {
      final reference = _minor[card.suit]?[card.rank];
      if (reference != null) return reference;
    }
    throw StateError('Missing traditional tarot reference for ${card.id}.');
  }

  static const Map<int, TarotReferenceContent> _major =
      <int, TarotReferenceContent>{
        0: TarotReferenceContent(
          uprightKeywords: <String>['新开始', '自由', '自发'],
          reversedKeywords: <String>['鲁莽', '幼稚', '判断失误'],
          uprightMeaning: '象征新的旅程、开放的可能性和对未知的信任。',
          reversedMeaning: '提示冲动、准备不足，或没有看清行动的代价。',
        ),
        1: TarotReferenceContent(
          uprightKeywords: <String>['显化', '技巧', '意志'],
          reversedKeywords: <String>['操纵', '技巧未用', '欺骗'],
          uprightMeaning: '象征把意图、知识和手边资源转化为实际行动。',
          reversedMeaning: '提示能力与真实意图不一致，或资源被用于操控。',
        ),
        2: TarotReferenceContent(
          uprightKeywords: <String>['直觉', '秘密', '内在知识'],
          reversedKeywords: <String>['压抑直觉', '表面知识', '混乱'],
          uprightMeaning: '象征尚未揭开的知识、沉默和需要被倾听的直觉。',
          reversedMeaning: '提示信息被遮蔽，或把表面印象误当成深层理解。',
        ),
        3: TarotReferenceContent(
          uprightKeywords: <String>['丰饶', '创造', '滋养'],
          reversedKeywords: <String>['创造受阻', '依赖', '过度照料'],
          uprightMeaning: '象征生长、创造力、感官经验和持续的滋养。',
          reversedMeaning: '提示创造力受阻，或付出与自我照料之间失去平衡。',
        ),
        4: TarotReferenceContent(
          uprightKeywords: <String>['权威', '结构', '稳定'],
          reversedKeywords: <String>['支配', '僵化', '失控'],
          uprightMeaning: '象征秩序、权威、保护和把计划落实为现实。',
          reversedMeaning: '提示控制欲过强、规则僵化，或权力边界失衡。',
        ),
        5: TarotReferenceContent(
          uprightKeywords: <String>['传统', '教导', '共同信念'],
          reversedKeywords: <String>['反叛', '教条', '非常规'],
          uprightMeaning: '象征传统知识、制度、师承和群体认可的道路。',
          reversedMeaning: '提示既有教条不再适用，或正在寻找个人化的道路。',
        ),
        6: TarotReferenceContent(
          uprightKeywords: <String>['爱情', '结合', '选择'],
          reversedKeywords: <String>['失衡', '分离', '价值冲突'],
          uprightMeaning: '象征关系、吸引力以及按照重要价值作出选择。',
          reversedMeaning: '提示关系或选择中出现不一致、犹豫和价值冲突。',
        ),
        7: TarotReferenceContent(
          uprightKeywords: <String>['意志', '胜利', '自律'],
          reversedKeywords: <String>['失去方向', '攻击性', '失控'],
          uprightMeaning: '象征以清晰目标驾驭相反力量，并凭意志向前推进。',
          reversedMeaning: '提示目标分裂、方向失控，或把推进变成强行压迫。',
        ),
        8: TarotReferenceContent(
          uprightKeywords: <String>['勇气', '慈悲', '内在力量'],
          reversedKeywords: <String>['自我怀疑', '软弱', '滥用力量'],
          uprightMeaning: '象征以耐心、勇气和温和的力量面对本能与困难。',
          reversedMeaning: '提示信心耗损，或强硬掩盖了内在的不安。',
        ),
        9: TarotReferenceContent(
          uprightKeywords: <String>['内省', '独处', '指引'],
          reversedKeywords: <String>['孤立', '退缩', '迷失'],
          uprightMeaning: '象征暂时远离喧扰，在独处和反思中寻找方向。',
          reversedMeaning: '提示独处变成隔绝，或谨慎已经变成逃避连接。',
        ),
        10: TarotReferenceContent(
          uprightKeywords: <String>['命运', '周期', '转机'],
          reversedKeywords: <String>['抗拒变化', '失去控制', '延误'],
          uprightMeaning: '象征周期变化、命运转折和新的机会窗口。',
          reversedMeaning: '提示重复旧模式，或在无法控制的变化中感到受阻。',
        ),
        11: TarotReferenceContent(
          uprightKeywords: <String>['公平', '真相', '责任'],
          reversedKeywords: <String>['不公', '偏见', '逃避责任'],
          uprightMeaning: '象征事实、因果、法律和对自身选择负责。',
          reversedMeaning: '提示信息不全、标准不一，或试图回避行为后果。',
        ),
        12: TarotReferenceContent(
          uprightKeywords: <String>['暂停', '牺牲', '新视角'],
          reversedKeywords: <String>['拖延', '抗拒', '无效牺牲'],
          uprightMeaning: '象征主动暂停惯性，从倒置的视角重新理解局面。',
          reversedMeaning: '提示停滞失去意义，或付出已经超出合理边界。',
        ),
        13: TarotReferenceContent(
          uprightKeywords: <String>['结束', '转化', '更新'],
          reversedKeywords: <String>['抗拒改变', '停滞', '恐惧结束'],
          uprightMeaning: '象征一个阶段结束，并为新的形态腾出空间。',
          reversedMeaning: '提示执着于旧形态，使必要的转变迟迟无法完成。',
        ),
        14: TarotReferenceContent(
          uprightKeywords: <String>['节制', '平衡', '调和'],
          reversedKeywords: <String>['失衡', '过度', '不协调'],
          uprightMeaning: '象征节制、耐心和不同力量之间可持续的调和。',
          reversedMeaning: '提示资源或情绪分配过度，难以维持稳定节奏。',
        ),
        15: TarotReferenceContent(
          uprightKeywords: <String>['束缚', '欲望', '物质执着'],
          reversedKeywords: <String>['释放', '脱离', '重获选择'],
          uprightMeaning: '象征依附、成瘾、物质欲望以及看不见的自我限制。',
          reversedMeaning: '提示束缚开始松动，正在重新取回选择和行动能力。',
        ),
        16: TarotReferenceContent(
          uprightKeywords: <String>['剧变', '揭露', '崩塌'],
          reversedKeywords: <String>['延迟崩塌', '回避', '余震'],
          uprightMeaning: '象征旧结构突然破裂，隐藏事实被迫显露。',
          reversedMeaning: '提示变化被压后发生，或正在回避已经明显的裂缝。',
        ),
        17: TarotReferenceContent(
          uprightKeywords: <String>['希望', '信念', '复原'],
          reversedKeywords: <String>['失望', '缺乏信心', '灰心'],
          uprightMeaning: '象征希望、灵感、疗愈和对长期方向的信任。',
          reversedMeaning: '提示暂时看不到方向，或期待与现实之间出现落差。',
        ),
        18: TarotReferenceContent(
          uprightKeywords: <String>['幻象', '恐惧', '不确定'],
          reversedKeywords: <String>['迷雾散去', '误判', '焦虑'],
          uprightMeaning: '象征不完整信息、梦境、恐惧和直觉交织的阶段。',
          reversedMeaning: '提示真相开始显现，也要防止焦虑制造新的误读。',
        ),
        19: TarotReferenceContent(
          uprightKeywords: <String>['喜悦', '成功', '清晰'],
          reversedKeywords: <String>['快乐受阻', '过度乐观', '延迟'],
          uprightMeaning: '象征活力、公开的成功、清晰和真诚的喜悦。',
          reversedMeaning: '提示成果被期待遮蔽，或快乐暂时无法充分表达。',
        ),
        20: TarotReferenceContent(
          uprightKeywords: <String>['觉醒', '召唤', '复生'],
          reversedKeywords: <String>['自我怀疑', '拒绝回应', '苛责'],
          uprightMeaning: '象征回顾经验、听见召唤，并对新的阶段作出回应。',
          reversedMeaning: '提示被自我评判困住，或不愿面对已经清楚的选择。',
        ),
        21: TarotReferenceContent(
          uprightKeywords: <String>['完成', '整合', '成就'],
          reversedKeywords: <String>['未完成', '停滞', '缺乏收束'],
          uprightMeaning: '象征一个循环完成、经验整合以及进入更广阔的阶段。',
          reversedMeaning: '提示仍有遗漏的收尾工作，成果尚未真正整合。',
        ),
      };

  static const Map<TarotSuit, Map<TarotRank, TarotReferenceContent>> _minor =
      <TarotSuit, Map<TarotRank, TarotReferenceContent>>{
        TarotSuit.wands: <TarotRank, TarotReferenceContent>{
          TarotRank.ace: TarotReferenceContent(
            uprightKeywords: <String>['灵感', '创造', '新行动'],
            reversedKeywords: <String>['延迟', '缺乏动力', '方向不明'],
            uprightMeaning: '象征行动、创意或事业的新起点。',
            reversedMeaning: '提示热情被阻，计划暂未找到合适的落点。',
          ),
          TarotRank.two: TarotReferenceContent(
            uprightKeywords: <String>['规划', '选择', '远景'],
            reversedKeywords: <String>['糟糕规划', '恐惧未知', '停滞'],
            uprightMeaning: '象征评估选项、规划未来并准备离开舒适区。',
            reversedMeaning: '提示计划不完整，或因为害怕未知而迟迟不行动。',
          ),
          TarotRank.three: TarotReferenceContent(
            uprightKeywords: <String>['扩展', '远见', '进展'],
            reversedKeywords: <String>['障碍', '延误', '缺乏远见'],
            uprightMeaning: '象征已有基础上的扩展、贸易、探索和等待成果。',
            reversedMeaning: '提示进展受到阻碍，未来规划需要重新校准。',
          ),
          TarotRank.four: TarotReferenceContent(
            uprightKeywords: <String>['庆祝', '家庭', '稳定'],
            reversedKeywords: <String>['不稳定', '冲突', '缺乏归属'],
            uprightMeaning: '象征庆典、家庭、归属和阶段性稳定。',
            reversedMeaning: '提示表面的庆祝下仍有不安，或家庭关系缺少协调。',
          ),
          TarotRank.five: TarotReferenceContent(
            uprightKeywords: <String>['竞争', '冲突', '挑战'],
            reversedKeywords: <String>['和解', '妥协', '冲突缓解'],
            uprightMeaning: '象征竞争、争论和通过摩擦检验力量。',
            reversedMeaning: '提示冲突正在缓和，或对抗已经消耗过多资源。',
          ),
          TarotRank.six: TarotReferenceContent(
            uprightKeywords: <String>['胜利', '认可', '荣誉'],
            reversedKeywords: <String>['失败', '缺乏认可', '延误'],
            uprightMeaning: '象征公开的胜利、好消息和努力得到认可。',
            reversedMeaning: '提示成果没有被看见，或胜利带来的信心尚不稳定。',
          ),
          TarotRank.seven: TarotReferenceContent(
            uprightKeywords: <String>['勇气', '坚持', '守护立场'],
            reversedKeywords: <String>['不堪重负', '退让', '防御过度'],
            uprightMeaning: '象征站稳有利位置，为立场和边界持续应对挑战。',
            reversedMeaning: '提示压力超过承受范围，或防御已经变成孤立。',
          ),
          TarotRank.eight: TarotReferenceContent(
            uprightKeywords: <String>['速度', '行动', '消息'],
            reversedKeywords: <String>['延误', '挫败', '阻力'],
            uprightMeaning: '象征快速进展、移动、沟通和事情接近结果。',
            reversedMeaning: '提示消息或行动受阻，节奏快慢出现失配。',
          ),
          TarotRank.nine: TarotReferenceContent(
            uprightKeywords: <String>['韧性', '坚持', '警戒'],
            reversedKeywords: <String>['疲惫', '偏执', '防御'],
            uprightMeaning: '象征经历考验后仍保持警觉和继续坚持的力量。',
            reversedMeaning: '提示长期戒备造成疲惫，或把所有接近都视为威胁。',
          ),
          TarotRank.ten: TarotReferenceContent(
            uprightKeywords: <String>['负担', '责任', '压力'],
            reversedKeywords: <String>['放下', '委派', '崩溃'],
            uprightMeaning: '象征承担过多责任、压力和接近终点的沉重过程。',
            reversedMeaning: '提示需要分担责任；继续独自承受可能导致崩溃。',
          ),
          TarotRank.page: TarotReferenceContent(
            uprightKeywords: <String>['热情', '探索', '消息'],
            reversedKeywords: <String>['急躁', '方向不明', '坏消息'],
            uprightMeaning: '象征新鲜热情、探索机会和带来消息的年轻能量。',
            reversedMeaning: '提示热情缺少方向，消息可能不成熟或来得太急。',
          ),
          TarotRank.knight: TarotReferenceContent(
            uprightKeywords: <String>['行动', '冒险', '热情'],
            reversedKeywords: <String>['鲁莽', '愤怒', '仓促'],
            uprightMeaning: '象征带着热情快速投入行动、旅行或冒险。',
            reversedMeaning: '提示行动过快，冲动和怒气可能破坏原本的推进。',
          ),
          TarotRank.queen: TarotReferenceContent(
            uprightKeywords: <String>['自信', '热情', '独立'],
            reversedKeywords: <String>['嫉妒', '不安全', '自私'],
            uprightMeaning: '象征温暖、自信、创造力和对自身方向的掌握。',
            reversedMeaning: '提示不安全感以嫉妒或控制的方式表现出来。',
          ),
          TarotRank.king: TarotReferenceContent(
            uprightKeywords: <String>['领导', '远见', '企业精神'],
            reversedKeywords: <String>['专横', '冲动', '缺乏方向'],
            uprightMeaning: '象征有远见的领导、创业精神和鼓舞他人的行动力。',
            reversedMeaning: '提示领导变成专断，或宏大目标缺少可执行方向。',
          ),
        },
        TarotSuit.cups: <TarotRank, TarotReferenceContent>{
          TarotRank.ace: TarotReferenceContent(
            uprightKeywords: <String>['情感开始', '爱', '直觉'],
            reversedKeywords: <String>['情感阻塞', '空虚', '压抑'],
            uprightMeaning: '象征新的情感、爱、直觉和心灵开放。',
            reversedMeaning: '提示情感难以流动，或内在需要被长期压抑。',
          ),
          TarotRank.two: TarotReferenceContent(
            uprightKeywords: <String>['结合', '伙伴', '相互吸引'],
            reversedKeywords: <String>['失衡', '分离', '冲突'],
            uprightMeaning: '象征平等关系、互相吸引、合作和情感联结。',
            reversedMeaning: '提示关系中缺少对等，或双方正在走向分离。',
          ),
          TarotRank.three: TarotReferenceContent(
            uprightKeywords: <String>['庆祝', '友谊', '社群'],
            reversedKeywords: <String>['过度', '孤立', '流言'],
            uprightMeaning: '象征友谊、社群、庆祝和共同分享的喜悦。',
            reversedMeaning: '提示享乐过度、关系表面化，或社群中出现流言。',
          ),
          TarotRank.four: TarotReferenceContent(
            uprightKeywords: <String>['倦怠', '沉思', '不满'],
            reversedKeywords: <String>['觉察', '接受', '重新投入'],
            uprightMeaning: '象征对现状感到厌倦，暂时无法看见眼前的机会。',
            reversedMeaning: '提示重新意识到自己的需要，并准备恢复行动。',
          ),
          TarotRank.five: TarotReferenceContent(
            uprightKeywords: <String>['失落', '悲伤', '失望'],
            reversedKeywords: <String>['接受', '宽恕', '向前看'],
            uprightMeaning: '象征失去、悲伤和沉浸于已经倾倒的部分。',
            reversedMeaning: '提示逐渐接受损失，开始看见仍然保留下来的关系或资源。',
          ),
          TarotRank.six: TarotReferenceContent(
            uprightKeywords: <String>['怀旧', '童年', '重逢'],
            reversedKeywords: <String>['困于过去', '不现实', '不成熟'],
            uprightMeaning: '象征过去的记忆、善意、重逢和熟悉的情感。',
            reversedMeaning: '提示过度理想化过去，或没有把经验带回现在。',
          ),
          TarotRank.seven: TarotReferenceContent(
            uprightKeywords: <String>['选择', '想象', '幻象'],
            reversedKeywords: <String>['清晰', '承诺', '现实感'],
            uprightMeaning: '象征许多诱人的选择、幻想和尚未落地的愿望。',
            reversedMeaning: '提示需要减少幻想，辨别真正愿意投入的选择。',
          ),
          TarotRank.eight: TarotReferenceContent(
            uprightKeywords: <String>['离开', '寻找意义', '转身'],
            reversedKeywords: <String>['逃避', '停滞', '害怕改变'],
            uprightMeaning: '象征离开已经无法满足内在需要的事物，寻找更深意义。',
            reversedMeaning: '提示明知需要改变却不愿离开，或用逃避代替选择。',
          ),
          TarotRank.nine: TarotReferenceContent(
            uprightKeywords: <String>['满足', '愿望', '享受'],
            reversedKeywords: <String>['不满足', '物质执着', '过度'],
            uprightMeaning: '象征愿望实现、满足感和享受已有成果。',
            reversedMeaning: '提示外在拥有没有带来真正满足，或享受已经变成过度。',
          ),
          TarotRank.ten: TarotReferenceContent(
            uprightKeywords: <String>['家庭幸福', '和谐', '情感圆满'],
            reversedKeywords: <String>['家庭冲突', '失和', '期待落差'],
            uprightMeaning: '象征家庭、归属、长期关系和共享的幸福。',
            reversedMeaning: '提示家庭表面和谐下有冲突，或共同愿景出现落差。',
          ),
          TarotRank.page: TarotReferenceContent(
            uprightKeywords: <String>['敏感', '创意', '情感消息'],
            reversedKeywords: <String>['情绪不成熟', '不安全', '受阻'],
            uprightMeaning: '象征温柔的情感消息、创意和直觉的初次萌发。',
            reversedMeaning: '提示情绪表达不稳定，或敏感变成了不安全感。',
          ),
          TarotRank.knight: TarotReferenceContent(
            uprightKeywords: <String>['浪漫', '邀请', '想象'],
            reversedKeywords: <String>['不现实', '情绪化', '嫉妒'],
            uprightMeaning: '象征浪漫提议、情感靠近和理想主义的追求。',
            reversedMeaning: '提示承诺停留在想象中，或情绪波动影响判断。',
          ),
          TarotRank.queen: TarotReferenceContent(
            uprightKeywords: <String>['慈悲', '直觉', '情感成熟'],
            reversedKeywords: <String>['依赖', '牺牲过度', '不安全'],
            uprightMeaning: '象征同理心、直觉、接纳和稳定的情感支持。',
            reversedMeaning: '提示照顾他人超过照顾自己，或情感边界变得模糊。',
          ),
          TarotRank.king: TarotReferenceContent(
            uprightKeywords: <String>['情绪平衡', '智慧', '外交'],
            reversedKeywords: <String>['情绪操控', '波动', '压抑'],
            uprightMeaning: '象征成熟的情绪管理、理解力和温和而有分寸的影响力。',
            reversedMeaning: '提示情绪被压抑，或成熟外表下存在操控和不稳定。',
          ),
        },
        TarotSuit.swords: <TarotRank, TarotReferenceContent>{
          TarotRank.ace: TarotReferenceContent(
            uprightKeywords: <String>['真相', '清晰', '突破'],
            reversedKeywords: <String>['混乱', '错误信息', '缺乏清晰'],
            uprightMeaning: '象征新的认知、真相、清晰判断和思想突破。',
            reversedMeaning: '提示信息混乱，判断可能被偏见或错误说法影响。',
          ),
          TarotRank.two: TarotReferenceContent(
            uprightKeywords: <String>['僵局', '选择', '回避'],
            reversedKeywords: <String>['犹豫', '信息过载', '冲突升级'],
            uprightMeaning: '象征在两个选择之间暂停，尚未准备好面对事实。',
            reversedMeaning: '提示回避已经难以维持，过多信息正在迫使决定出现。',
          ),
          TarotRank.three: TarotReferenceContent(
            uprightKeywords: <String>['心痛', '悲伤', '分离'],
            reversedKeywords: <String>['疗愈', '宽恕', '释放'],
            uprightMeaning: '象征心痛、失望、分离以及必须承认的伤口。',
            reversedMeaning: '提示伤口正在得到理解，旧痛开始被释放。',
          ),
          TarotRank.four: TarotReferenceContent(
            uprightKeywords: <String>['休息', '恢复', '退隐'],
            reversedKeywords: <String>['疲惫', '焦躁', '停滞'],
            uprightMeaning: '象征暂停冲突、休养和让思绪恢复秩序。',
            reversedMeaning: '提示表面休息不足以恢复，内在仍在持续紧张。',
          ),
          TarotRank.five: TarotReferenceContent(
            uprightKeywords: <String>['冲突', '失败', '代价'],
            reversedKeywords: <String>['和解', '怨恨', '未解决'],
            uprightMeaning: '象征争斗后的胜负、损失和并不令人满足的胜利。',
            reversedMeaning: '提示冲突表面结束，但怨恨或代价仍需要处理。',
          ),
          TarotRank.six: TarotReferenceContent(
            uprightKeywords: <String>['过渡', '离开', '疗愈'],
            reversedKeywords: <String>['抗拒改变', '负担', '回头'],
            uprightMeaning: '象征离开动荡环境，带着经验向较平静的地方过渡。',
            reversedMeaning: '提示仍被旧问题牵制，或者不断回到已经离开的模式。',
          ),
          TarotRank.seven: TarotReferenceContent(
            uprightKeywords: <String>['策略', '独立', '隐秘行动'],
            reversedKeywords: <String>['欺骗曝光', '坦白', '计划失效'],
            uprightMeaning: '象征策略、独立行动和不公开全部意图的处理方式。',
            reversedMeaning: '提示隐藏的行为可能被揭露，或原有策略无法继续。',
          ),
          TarotRank.eight: TarotReferenceContent(
            uprightKeywords: <String>['限制', '恐惧', '无力感'],
            reversedKeywords: <String>['释放', '自主', '突破信念'],
            uprightMeaning: '象征被恐惧、观念或环境限制，暂时看不见可行出口。',
            reversedMeaning: '提示开始识别自我限制，并逐步恢复行动自由。',
          ),
          TarotRank.nine: TarotReferenceContent(
            uprightKeywords: <String>['焦虑', '忧虑', '失眠'],
            reversedKeywords: <String>['恢复', '绝望减轻', '面对恐惧'],
            uprightMeaning: '象征夜间忧虑、内疚和被想象放大的恐惧。',
            reversedMeaning: '提示最严重的焦虑正在松动，但仍需正视真实压力。',
          ),
          TarotRank.ten: TarotReferenceContent(
            uprightKeywords: <String>['结束', '背叛', '最低点'],
            reversedKeywords: <String>['恢复', '重生', '拒绝结束'],
            uprightMeaning: '象征痛苦循环到达终点，某种旧方式已经无法继续。',
            reversedMeaning: '提示从创伤中恢复，或仍在抗拒必须完成的结束。',
          ),
          TarotRank.page: TarotReferenceContent(
            uprightKeywords: <String>['警觉', '好奇', '信息'],
            reversedKeywords: <String>['散乱', '急躁', '准备不足'],
            uprightMeaning: '象征敏锐观察、求知、消息和保持警觉的思维。',
            reversedMeaning: '提示信息传播过快，或警觉变成了散乱和猜疑。',
          ),
          TarotRank.knight: TarotReferenceContent(
            uprightKeywords: <String>['行动', '决断', '速度'],
            reversedKeywords: <String>['鲁莽', '攻击', '缺乏方向'],
            uprightMeaning: '象征快速的思想、直接行动和为目标奋力推进。',
            reversedMeaning: '提示速度超过判断，言语或行动可能带有攻击性。',
          ),
          TarotRank.queen: TarotReferenceContent(
            uprightKeywords: <String>['清晰', '独立', '真相'],
            reversedKeywords: <String>['冷酷', '怨恨', '偏见'],
            uprightMeaning: '象征以清醒、诚实和独立判断面对事实。',
            reversedMeaning: '提示痛苦使判断变得尖锐，诚实可能滑向冷酷或偏见。',
          ),
          TarotRank.king: TarotReferenceContent(
            uprightKeywords: <String>['理性', '权威', '判断'],
            reversedKeywords: <String>['操控', '暴政', '滥用权力'],
            uprightMeaning: '象征理性、专业判断、权威和清楚的决策。',
            reversedMeaning: '提示理性被用于操控，或权威失去伦理约束。',
          ),
        },
        TarotSuit.pentacles: <TarotRank, TarotReferenceContent>{
          TarotRank.ace: TarotReferenceContent(
            uprightKeywords: <String>['机会', '繁荣', '落实'],
            reversedKeywords: <String>['错失机会', '资源不足', '计划不周'],
            uprightMeaning: '象征工作、金钱、身体或现实生活中的新机会。',
            reversedMeaning: '提示机会尚未落地，或现实准备不足以承接它。',
          ),
          TarotRank.two: TarotReferenceContent(
            uprightKeywords: <String>['平衡', '适应', '时间管理'],
            reversedKeywords: <String>['失衡', '混乱', '不堪重负'],
            uprightMeaning: '象征在多项现实责任之间保持灵活和平衡。',
            reversedMeaning: '提示事务过多，时间、金钱或精力分配已经失衡。',
          ),
          TarotRank.three: TarotReferenceContent(
            uprightKeywords: <String>['合作', '技能', '工艺'],
            reversedKeywords: <String>['缺乏合作', '低质量', '失序'],
            uprightMeaning: '象征团队协作、专业技能和认真完成工作的成果。',
            reversedMeaning: '提示合作缺少共识，或投入的质量没有达到要求。',
          ),
          TarotRank.four: TarotReferenceContent(
            uprightKeywords: <String>['安全', '保存', '控制'],
            reversedKeywords: <String>['贪婪', '占有', '害怕失去'],
            uprightMeaning: '象征守住已有资源、寻求安全和建立现实边界。',
            reversedMeaning: '提示对安全的追求变成占有、吝啬或对失去的恐惧。',
          ),
          TarotRank.five: TarotReferenceContent(
            uprightKeywords: <String>['困难', '贫乏', '孤立'],
            reversedKeywords: <String>['复原', '支持', '困难结束'],
            uprightMeaning: '象征物质困难、被排斥以及在逆境中寻求帮助。',
            reversedMeaning: '提示支持开始出现，最严重的匮乏正在缓解。',
          ),
          TarotRank.six: TarotReferenceContent(
            uprightKeywords: <String>['给予', '帮助', '互惠'],
            reversedKeywords: <String>['附带条件', '债务', '失衡'],
            uprightMeaning: '象征慷慨、资源交换、援助和相对平衡的互惠。',
            reversedMeaning: '提示帮助带有控制条件，或给予与接受之间不再平等。',
          ),
          TarotRank.seven: TarotReferenceContent(
            uprightKeywords: <String>['耐心', '评估', '长期收获'],
            reversedKeywords: <String>['急躁', '成果不佳', '缺乏远见'],
            uprightMeaning: '象征耐心等待投入成长，并评估长期成果是否值得。',
            reversedMeaning: '提示投入回报不如预期，或过早放弃了长期计划。',
          ),
          TarotRank.eight: TarotReferenceContent(
            uprightKeywords: <String>['练习', '勤勉', '精进'],
            reversedKeywords: <String>['敷衍', '完美主义', '缺乏动力'],
            uprightMeaning: '象征学徒训练、重复练习和通过专注形成技能。',
            reversedMeaning: '提示工作缺少投入，或完美主义阻止真正完成。',
          ),
          TarotRank.nine: TarotReferenceContent(
            uprightKeywords: <String>['丰盛', '独立', '自足'],
            reversedKeywords: <String>['过度消费', '不安全', '挫折'],
            uprightMeaning: '象征独立、舒适、劳动成果和能够享受自己的收获。',
            reversedMeaning: '提示外在丰盛不稳定，或消费无法填补内在不安全。',
          ),
          TarotRank.ten: TarotReferenceContent(
            uprightKeywords: <String>['财富', '传承', '家庭'],
            reversedKeywords: <String>['损失', '不稳定', '家庭争端'],
            uprightMeaning: '象征长期财富、家族传承、稳定基础和共同资源。',
            reversedMeaning: '提示资源或家庭结构出现不稳定，传承关系需要重新协商。',
          ),
          TarotRank.page: TarotReferenceContent(
            uprightKeywords: <String>['学习', '机会', '实际计划'],
            reversedKeywords: <String>['拖延', '不切实际', '进展停滞'],
            uprightMeaning: '象征学习、工作或财务上的实际机会和认真起步。',
            reversedMeaning: '提示计划停留在想法，缺少稳定投入或现实可行性。',
          ),
          TarotRank.knight: TarotReferenceContent(
            uprightKeywords: <String>['责任', '效率', '稳定推进'],
            reversedKeywords: <String>['停滞', '懒散', '不负责任'],
            uprightMeaning: '象征可靠、勤勉、按步骤完成现实责任。',
            reversedMeaning: '提示进展过慢或缺乏投入，承诺没有被落实。',
          ),
          TarotRank.queen: TarotReferenceContent(
            uprightKeywords: <String>['实用', '照料', '丰盛'],
            reversedKeywords: <String>['忽视自己', '嫉妒', '不安全'],
            uprightMeaning: '象征实际照料、资源管理、舒适和稳定的成长环境。',
            reversedMeaning: '提示过度照顾外界而忽视自己，安全感因此下降。',
          ),
          TarotRank.king: TarotReferenceContent(
            uprightKeywords: <String>['繁荣', '可靠', '事业'],
            reversedKeywords: <String>['贪婪', '腐败', '不稳定'],
            uprightMeaning: '象征现实成就、商业能力、可靠管理和长期繁荣。',
            reversedMeaning: '提示财富或权力缺少节制，稳定表象下存在腐败风险。',
          ),
        },
      };
}
