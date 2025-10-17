// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VolumeList _$VolumeListFromJson(Map<String, dynamic> json) => VolumeList(
  totalItems: (json['totalItems'] as num?)?.toInt(),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => Volume.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$VolumeListToJson(VolumeList instance) =>
    <String, dynamic>{
      'totalItems': instance.totalItems,
      'items': instance.items,
    };

Volume _$VolumeFromJson(Map<String, dynamic> json) => Volume(
  id: json['id'] as String,
  info: VolumeInfo.fromJson(json['volumeInfo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VolumeToJson(Volume instance) => <String, dynamic>{
  'id': instance.id,
  'volumeInfo': instance.info,
};

VolumeInfo _$VolumeInfoFromJson(Map<String, dynamic> json) => VolumeInfo(
  title: json['title'] as String?,
  authors: (json['authors'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  description: json['description'] as String?,
  pageCount: (json['pageCount'] as num?)?.toInt(),
  categories: (json['categories'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  imageLinks: json['imageLinks'] == null
      ? null
      : ImageLinks.fromJson(json['imageLinks'] as Map<String, dynamic>),
  industryIdentifiers: (json['industryIdentifiers'] as List<dynamic>?)
      ?.map((e) => IndustryIdentifier.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$VolumeInfoToJson(VolumeInfo instance) =>
    <String, dynamic>{
      'title': instance.title,
      'authors': instance.authors,
      'description': instance.description,
      'pageCount': instance.pageCount,
      'categories': instance.categories,
      'imageLinks': instance.imageLinks,
      'industryIdentifiers': instance.industryIdentifiers,
    };

ImageLinks _$ImageLinksFromJson(Map<String, dynamic> json) => ImageLinks(
  smallThumbnail: json['smallThumbnail'] as String?,
  thumbnail: json['thumbnail'] as String?,
);

Map<String, dynamic> _$ImageLinksToJson(ImageLinks instance) =>
    <String, dynamic>{
      'smallThumbnail': instance.smallThumbnail,
      'thumbnail': instance.thumbnail,
    };

IndustryIdentifier _$IndustryIdentifierFromJson(Map<String, dynamic> json) =>
    IndustryIdentifier(json['type'] as String, json['identifier'] as String);

Map<String, dynamic> _$IndustryIdentifierToJson(IndustryIdentifier instance) =>
    <String, dynamic>{'type': instance.type, 'identifier': instance.identifier};
