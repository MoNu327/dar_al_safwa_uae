// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyResponse _$PropertyResponseFromJson(Map<String, dynamic> json) =>
    PropertyResponse(
      success: json['success'] as bool?,
      message: json['message'] == null
          ? null
          : Message.fromJson(json['message'] as Map<String, dynamic>),
      data: json['data'] == null
          ? null
          : PropertyData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyResponseToJson(PropertyResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

PropertyData _$PropertyDataFromJson(Map<String, dynamic> json) => PropertyData(
      property: json['property'] == null
          ? null
          : Property.fromJson(json['property'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyDataToJson(PropertyData instance) =>
    <String, dynamic>{
      'property': instance.property,
    };

Property _$PropertyFromJson(Map<String, dynamic> json) => Property(
      id: (json['id'] as num?)?.toInt(),
      highlightImages: (json['highlight_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imageGallery: (json['image_gallery'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      youtubeVideo: json['youtube_video'] == null
          ? null
          : YoutubeVideo.fromJson(
              json['youtube_video'] as Map<String, dynamic>),
      title: json['title'] == null
          ? null
          : Message.fromJson(json['title'] as Map<String, dynamic>),
      dealType: json['deal_type'] == null
          ? null
          : Message.fromJson(json['deal_type'] as Map<String, dynamic>),
      location: json['location'] == null
          ? null
          : Location.fromJson(json['location'] as Map<String, dynamic>),
      price: json['price'] == null
          ? null
          : Price.fromJson(json['price'] as Map<String, dynamic>),
      description: json['description'] == null
          ? null
          : Message.fromJson(json['description'] as Map<String, dynamic>),
      overview: json['overview'] == null
          ? null
          : Overview.fromJson(json['overview'] as Map<String, dynamic>),
      propertyFeatures: json['property_features'] == null
          ? null
          : PropertyFeatures.fromJson(
              json['property_features'] as Map<String, dynamic>),
      unitTypes: json['unit_types'] == null
          ? null
          : UnitTypes.fromJson(json['unit_types'] as Map<String, dynamic>),
      agent: json['agent'] == null
          ? null
          : Agent.fromJson(json['agent'] as Map<String, dynamic>),
      regulations: json['regulations'] == null
          ? null
          : Regulations.fromJson(json['regulations'] as Map<String, dynamic>),
      nearbyTypes: (json['nearbytype'] as List<dynamic>?)
          ?.map((e) => NearbyType.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: json['reviews'] == null
          ? null
          : Reviews.fromJson(json['reviews'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'id': instance.id,
      'highlight_images': instance.highlightImages,
      'image_gallery': instance.imageGallery,
      'youtube_video': instance.youtubeVideo,
      'title': instance.title,
      'deal_type': instance.dealType,
      'location': instance.location,
      'price': instance.price,
      'description': instance.description,
      'overview': instance.overview,
      'property_features': instance.propertyFeatures,
      'unit_types': instance.unitTypes,
      'agent': instance.agent,
      'regulations': instance.regulations,
      'nearbytype': instance.nearbyTypes,
      'reviews': instance.reviews,
    };

YoutubeVideo _$YoutubeVideoFromJson(Map<String, dynamic> json) => YoutubeVideo(
      url: json['url'] as String?,
      thumbnail: json['thumbnail'] as String?,
    );

Map<String, dynamic> _$YoutubeVideoToJson(YoutubeVideo instance) =>
    <String, dynamic>{
      'url': instance.url,
      'thumbnail': instance.thumbnail,
    };

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      address: json['address'] == null
          ? null
          : Address.fromJson(json['address'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'address': instance.address,
    };

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
      building: json['building'] == null
          ? null
          : Message.fromJson(json['building'] as Map<String, dynamic>),
      street: json['street'] == null
          ? null
          : Message.fromJson(json['street'] as Map<String, dynamic>),
      full: json['full'] == null
          ? null
          : Message.fromJson(json['full'] as Map<String, dynamic>),
      coordinates: json['coordinates'] == null
          ? null
          : Coordinates.fromJson(json['coordinates'] as Map<String, dynamic>),
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
      'building': instance.building,
      'street': instance.street,
      'full': instance.full,
      'coordinates': instance.coordinates,
      'icon': instance.icon,
    };

Coordinates _$CoordinatesFromJson(Map<String, dynamic> json) => Coordinates(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CoordinatesToJson(Coordinates instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

Price _$PriceFromJson(Map<String, dynamic> json) => Price(
      raw: (json['raw'] as num?)?.toDouble(),
      formatted: json['formatted'] == null
          ? null
          : Message.fromJson(json['formatted'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PriceToJson(Price instance) => <String, dynamic>{
      'raw': instance.raw,
      'formatted': instance.formatted,
    };

Overview _$OverviewFromJson(Map<String, dynamic> json) => Overview(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OverviewItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OverviewToJson(Overview instance) => <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
      'items': instance.items,
    };

OverviewItem _$OverviewItemFromJson(Map<String, dynamic> json) => OverviewItem(
      title: json['title'] == null
          ? null
          : Message.fromJson(json['title'] as Map<String, dynamic>),
      value: overviewValueFromJson(json['value']),
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$OverviewItemToJson(OverviewItem instance) =>
    <String, dynamic>{
      'title': instance.title,
      'value': overviewValueToJson(instance.value),
      'icon': instance.icon,
    };

OverviewValue _$OverviewValueFromJson(Map<String, dynamic> json) =>
    OverviewValue(
      number: (json['number'] as num?)?.toInt(),
      unit: json['unit'] == null
          ? null
          : Message.fromJson(json['unit'] as Map<String, dynamic>),
      formatted: json['formatted'] == null
          ? null
          : Message.fromJson(json['formatted'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OverviewValueToJson(OverviewValue instance) =>
    <String, dynamic>{
      'number': instance.number,
      'unit': instance.unit,
      'formatted': instance.formatted,
    };

PropertyFeatures _$PropertyFeaturesFromJson(Map<String, dynamic> json) =>
    PropertyFeatures(
      sectionTitle: json['section_title'] == null
          ? null
          : Message.fromJson(json['section_title'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PropertyFeaturesToJson(PropertyFeatures instance) =>
    <String, dynamic>{
      'section_title': instance.sectionTitle,
      'items': instance.items,
    };

UnitTypes _$UnitTypesFromJson(Map<String, dynamic> json) => UnitTypes(
      mainTitle: json['main_title'] == null
          ? null
          : Message.fromJson(json['main_title'] as Map<String, dynamic>),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => UnitTypeData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UnitTypesToJson(UnitTypes instance) => <String, dynamic>{
      'main_title': instance.mainTitle,
      'data': instance.data,
    };

UnitTypeData _$UnitTypeDataFromJson(Map<String, dynamic> json) => UnitTypeData(
      id: (json['id'] as num?)?.toInt(),
      beds: (json['beds'] as num?)?.toInt(),
      baths: (json['baths'] as num?)?.toInt(),
      area: json['area'] == null
          ? null
          : Message.fromJson(json['area'] as Map<String, dynamic>),
      baseRentAmount: json['base_rent_amount'] == null
          ? null
          : BaseRentAmount.fromJson(
              json['base_rent_amount'] as Map<String, dynamic>),
      unitType: json['unit_type'] == null
          ? null
          : UnitType.fromJson(json['unit_type'] as Map<String, dynamic>),
      youtubeUrl: json['youtube_url'] as String?,
    );

Map<String, dynamic> _$UnitTypeDataToJson(UnitTypeData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'beds': instance.beds,
      'baths': instance.baths,
      'area': instance.area,
      'base_rent_amount': instance.baseRentAmount,
      'unit_type': instance.unitType,
      'youtube_url': instance.youtubeUrl,
    };

BaseRentAmount _$BaseRentAmountFromJson(Map<String, dynamic> json) =>
    BaseRentAmount(
      raw: (json['raw'] as num?)?.toDouble(),
      formatted: json['formatted'] == null
          ? null
          : Message.fromJson(json['formatted'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BaseRentAmountToJson(BaseRentAmount instance) =>
    <String, dynamic>{
      'raw': instance.raw,
      'formatted': instance.formatted,
    };

UnitType _$UnitTypeFromJson(Map<String, dynamic> json) => UnitType(
      id: (json['id'] as num?)?.toInt(),
      code: json['code'] as String?,
      name: json['name'] == null
          ? null
          : Message.fromJson(json['name'] as Map<String, dynamic>),
      description: json['description'] == null
          ? null
          : Message.fromJson(json['description'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UnitTypeToJson(UnitType instance) => <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
    };

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
      uid: json['uid'] as String?,
      name: json['name'] == null
          ? null
          : Message.fromJson(json['name'] as Map<String, dynamic>),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'image': instance.image,
    };

Regulations _$RegulationsFromJson(Map<String, dynamic> json) => Regulations(
      mainTitle: json['main_title'] == null
          ? null
          : Message.fromJson(json['main_title'] as Map<String, dynamic>),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => RegulationData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RegulationsToJson(Regulations instance) =>
    <String, dynamic>{
      'main_title': instance.mainTitle,
      'data': instance.data,
    };

RegulationData _$RegulationDataFromJson(Map<String, dynamic> json) =>
    RegulationData(
      title: json['title'] == null
          ? null
          : Message.fromJson(json['title'] as Map<String, dynamic>),
      value: json['value'] as String?,
    );

Map<String, dynamic> _$RegulationDataToJson(RegulationData instance) =>
    <String, dynamic>{
      'title': instance.title,
      'value': instance.value,
    };

NearbyType _$NearbyTypeFromJson(Map<String, dynamic> json) => NearbyType(
      type: json['type'] == null
          ? null
          : Message.fromJson(json['type'] as Map<String, dynamic>),
      name: json['name'] == null
          ? null
          : Message.fromJson(json['name'] as Map<String, dynamic>),
      distance: json['distance'] as String?,
    );

Map<String, dynamic> _$NearbyTypeToJson(NearbyType instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'distance': instance.distance,
    };

Reviews _$ReviewsFromJson(Map<String, dynamic> json) => Reviews(
      overall: json['overall'] == null
          ? null
          : OverallRating.fromJson(json['overall'] as Map<String, dynamic>),
      recentReviews: (json['recent_reviews'] as List<dynamic>?)
          ?.map((e) => RecentReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReviewsToJson(Reviews instance) => <String, dynamic>{
      'overall': instance.overall,
      'recent_reviews': instance.recentReviews,
    };

OverallRating _$OverallRatingFromJson(Map<String, dynamic> json) =>
    OverallRating(
      rating: (json['rating'] as num?)?.toDouble(),
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$OverallRatingToJson(OverallRating instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      'count': instance.count,
    };

RecentReview _$RecentReviewFromJson(Map<String, dynamic> json) => RecentReview(
      user: json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
      rating: (json['rating'] as num?)?.toDouble(),
      comment: json['comment'] as String?,
      date: json['date'] as String?,
    );

Map<String, dynamic> _$RecentReviewToJson(RecentReview instance) =>
    <String, dynamic>{
      'user': instance.user,
      'rating': instance.rating,
      'comment': instance.comment,
      'date': instance.date,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'name': instance.name,
      'avatar': instance.avatar,
    };
