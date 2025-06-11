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
      overview: json['overview'] == null
          ? null
          : Overview.fromJson(json['overview'] as Map<String, dynamic>),
      description: json['description'] == null
          ? null
          : Message.fromJson(json['description'] as Map<String, dynamic>),
      propertyFeatures: json['property_features'] == null
          ? null
          : PropertyFeatures.fromJson(
              json['property_features'] as Map<String, dynamic>),
      unitTypes: (json['unit_types'] as List<dynamic>?)
          ?.map((e) => UnitType.fromJson(e as Map<String, dynamic>))
          .toList(),
      agent: json['agent'] == null
          ? null
          : Agent.fromJson(json['agent'] as Map<String, dynamic>),
      regulations: json['regulations'] == null
          ? null
          : Regulations.fromJson(json['regulations'] as Map<String, dynamic>),
      reviews: json['reviews'] == null
          ? null
          : Reviews.fromJson(json['reviews'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'id': instance.id,
      'highlight_images': instance.highlightImages,
      'image_gallery': instance.imageGallery,
      'title': instance.title,
      'deal_type': instance.dealType,
      'location': instance.location,
      'price': instance.price,
      'overview': instance.overview,
      'description': instance.description,
      'property_features': instance.propertyFeatures,
      'unit_types': instance.unitTypes,
      'agent': instance.agent,
      'regulations': instance.regulations,
      'reviews': instance.reviews,
    };

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      address: json['address'] == null
          ? null
          : Address.fromJson(json['address'] as Map<String, dynamic>),
      nearby: (json['nearby'] as List<dynamic>?)
          ?.map((e) => Nearby.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'address': instance.address,
      'nearby': instance.nearby,
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
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
      'building': instance.building,
      'street': instance.street,
      'full': instance.full,
      'icon': instance.icon,
    };

Nearby _$NearbyFromJson(Map<String, dynamic> json) => Nearby(
      type: json['type'] as String?,
      name: json['name'] == null
          ? null
          : Message.fromJson(json['name'] as Map<String, dynamic>),
      distance: json['distance'] as String?,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$NearbyToJson(Nearby instance) => <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'distance': instance.distance,
      'icon': instance.icon,
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
      sectionTitle: json['section_title'] == null
          ? null
          : Message.fromJson(json['section_title'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OverviewItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OverviewToJson(Overview instance) => <String, dynamic>{
      'section_title': instance.sectionTitle,
      'items': instance.items,
    };

OverviewItem _$OverviewItemFromJson(Map<String, dynamic> json) => OverviewItem(
      title: json['title'] == null
          ? null
          : Message.fromJson(json['title'] as Map<String, dynamic>),
      value: json['value'],
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$OverviewItemToJson(OverviewItem instance) =>
    <String, dynamic>{
      'title': instance.title,
      'value': instance.value,
      'icon': instance.icon,
    };

AreaValue _$AreaValueFromJson(Map<String, dynamic> json) => AreaValue(
      number: (json['number'] as num?)?.toDouble(),
      unit: json['unit'] == null
          ? null
          : Message.fromJson(json['unit'] as Map<String, dynamic>),
      formatted: json['formatted'] == null
          ? null
          : Message.fromJson(json['formatted'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AreaValueToJson(AreaValue instance) => <String, dynamic>{
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

UnitType _$UnitTypeFromJson(Map<String, dynamic> json) => UnitType(
      type: json['type'] == null
          ? null
          : Message.fromJson(json['type'] as Map<String, dynamic>),
      totalUnits: (json['total_units'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UnitTypeToJson(UnitType instance) => <String, dynamic>{
      'type': instance.type,
      'total_units': instance.totalUnits,
    };

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
      name: json['name'] == null
          ? null
          : Message.fromJson(json['name'] as Map<String, dynamic>),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
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
      rating: (json['rating'] as num?)?.toInt(),
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
