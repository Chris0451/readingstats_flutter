import 'package:json_annotation/json_annotation.dart';

part 'volume.g.dart';

@JsonSerializable()
class VolumeList {
  final int? totalItems;
  final List<Volume>? items;

  VolumeList({this.totalItems, this.items});

  factory VolumeList.fromJson(Map<String, dynamic> json) => _$VolumeListFromJson(json);
  Map<String, dynamic> toJson() => _$VolumeListToJson(this);
}

@JsonSerializable()
class Volume {
  final String id;
  @JsonKey(name: 'volumeInfo')
  final VolumeInfo info;

  Volume({required this.id, required this.info});

  factory Volume.fromJson(Map<String, dynamic> json) => _$VolumeFromJson(json);
  Map<String, dynamic> toJson() => _$VolumeToJson(this);
}

@JsonSerializable()
class VolumeInfo {
  final String? title;
  final List<String>? authors;
  final String? description;
  final int? pageCount;
  final List<String>? categories;
  final ImageLinks? imageLinks;
  final List<IndustryIdentifier>? industryIdentifiers;

  VolumeInfo({
    this.title,
    this.authors,
    this.description,
    this.pageCount,
    this.categories,
    this.imageLinks,
    this.industryIdentifiers,
  });

  // helper comodi
  String? get thumbnail => imageLinks?.thumbnail;
  String? get isbn13 => industryIdentifiers
      ?.firstWhere((x) => x.type == 'ISBN_13', orElse: () => const IndustryIdentifier('', ''))
      .identifier;
  String? get isbn10 => industryIdentifiers
      ?.firstWhere((x) => x.type == 'ISBN_10', orElse: () => const IndustryIdentifier('', ''))
      .identifier;

  factory VolumeInfo.fromJson(Map<String, dynamic> json) => _$VolumeInfoFromJson(json);
  Map<String, dynamic> toJson() => _$VolumeInfoToJson(this);
}

@JsonSerializable()
class ImageLinks {
  final String? smallThumbnail;
  final String? thumbnail;

  ImageLinks({this.smallThumbnail, this.thumbnail});

  factory ImageLinks.fromJson(Map<String, dynamic> json) => _$ImageLinksFromJson(json);
  Map<String, dynamic> toJson() => _$ImageLinksToJson(this);
}

@JsonSerializable()
class IndustryIdentifier {
  final String type;
  final String identifier;

  const IndustryIdentifier(this.type, this.identifier);

  factory IndustryIdentifier.fromJson(Map<String, dynamic> json) =>
      _$IndustryIdentifierFromJson(json);
  Map<String, dynamic> toJson() => _$IndustryIdentifierToJson(this);
}
