class EmergencyContactModel {
  List<ContactList>? contactList;

  EmergencyContactModel({this.contactList});

  EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    if (json['contact_list'] != null) {
      contactList = <ContactList>[];
      json['contact_list'].forEach((v) {
        contactList!.add(ContactList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (contactList != null) {
      data['contact_list'] = contactList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ContactList {
  int? id;
  int? userId;
  String? name;
  String? phone;
  String? createdAt;
  String? updatedAt;
  String? countryCode;

  ContactList(
      {this.id,
        this.userId,
        this.name,
        this.phone,
        this.createdAt,
        this.updatedAt,
        this.countryCode
      });

  ContactList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    name = json['name'];
    phone = json['phone'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    countryCode = json['country_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['name'] = name;
    data['phone'] = phone;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['country_code'] = countryCode;
    return data;
  }
}
