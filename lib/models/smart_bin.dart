enum BinCategory {
  plastic,
  bag,
  electronic,
  organic,
  paper,
  bottle,
}

class SmartBin {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<BinCategory> category;

  SmartBin({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
  });
}
