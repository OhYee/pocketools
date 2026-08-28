import '../domain/liuyao_models.dart';

String liuyaoModeLabel(LiuyaoMode mode) => switch (mode) {
  LiuyaoMode.automatic => '自动投币',
  LiuyaoMode.manual => '手工录入',
};

String liuyaoCoinLabel(LiuyaoCoinSide side) => switch (side) {
  LiuyaoCoinSide.heads => '正',
  LiuyaoCoinSide.tails => '反',
};

String liuyaoLineKindLabel(LiuyaoLineKind kind) => switch (kind) {
  LiuyaoLineKind.oldYin => '老阴',
  LiuyaoLineKind.youngYang => '少阳',
  LiuyaoLineKind.youngYin => '少阴',
  LiuyaoLineKind.oldYang => '老阳',
};

String liuyaoNatureLabel(LiuyaoLineNature nature) => switch (nature) {
  LiuyaoLineNature.yin => '阴爻',
  LiuyaoLineNature.yang => '阳爻',
};

String liuyaoLinePositionLabel(int index) => switch (index) {
  0 => '初爻',
  1 => '第二爻',
  2 => '第三爻',
  3 => '第四爻',
  4 => '第五爻',
  5 => '上爻',
  _ => throw RangeError.range(index, 0, 5, 'index'),
};

String liuyaoLineSemanticLabel(LiuyaoLine line) {
  final moving = line.isMoving
      ? '动爻，将变为${liuyaoNatureLabel(line.changedNature)}'
      : '静爻';
  return '${liuyaoLinePositionLabel(line.index)}，和值${line.value}，'
      '${liuyaoLineKindLabel(line.kind)}，$moving';
}
