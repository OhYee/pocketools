import '../../liuyao/presentation/liuyao_labels.dart';
import '../domain/multi_divination_models.dart';

String multiDivinationModeLabel(MultiDivinationMode mode) => switch (mode) {
  MultiDivinationMode.standard => '标准融合',
};

String multiDivinationGroupLabel(int index) => 'A${index + 1}';

String multiDivinationProgressLabel(MultiDivinationReading reading) =>
    '已完成 ${reading.groups.length}/${MultiDivinationReading.groupCapacity} 组 · '
    '记录顺序：自下而上';

String multiDivinationLineLabel(MultiDivinationGroup group) =>
    '${multiDivinationGroupLabel(group.index)} · 和值 ${group.lineValue} · '
    '${liuyaoLineKindLabel(group.lineKind)} · ${group.isMoving ? '动爻' : '静爻'}';
