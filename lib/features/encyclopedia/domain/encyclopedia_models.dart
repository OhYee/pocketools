enum EncyclopediaSection { tarot, liuyao }

String encyclopediaSectionLabel(EncyclopediaSection section) =>
    switch (section) {
      EncyclopediaSection.tarot => '塔罗牌图鉴',
      EncyclopediaSection.liuyao => '周易图鉴',
    };
