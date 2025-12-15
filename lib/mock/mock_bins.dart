import 'package:smart_recycle/models/smart_bin.dart';

final List<SmartBin> mockBins = [
  SmartBin(
    id: 'bin_1',
    name: 'Poubelle 1',
    region: 'Port Louis',
    latitude: -20.1609,
    longitude: 57.5012,
    category: [BinCategory.plastic, BinCategory.bottle],
  ),
  SmartBin(
    id: 'bin_2',
    name: 'Poubelle 2',
    region: 'Curepipe',
    latitude: -20.1655,
    longitude: 57.4978,
    category: [BinCategory.paper, BinCategory.bag],
  ),
  SmartBin(
    id: 'bin_3',
    name: 'Poubelle 2',
    region: 'Quatre Bornes',
    latitude: -20.1620,
    longitude: 57.5050,
    category: [BinCategory.organic, BinCategory.electronic],
  ),
];
