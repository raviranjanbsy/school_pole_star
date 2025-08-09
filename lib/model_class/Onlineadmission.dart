class Onlineadmission {
  int? reg_no;
  String? full_name;
  String? dob;
  String? email;
  String? mob;
  String? gender;
  String? fathername;
  String? mothername;
  String? class1;
  String? section;
  String? present_address;
  String? permanent_address;
  String? session;
  String? username;
  String? password;
  String? image;

  Onlineadmission({
    required this.reg_no,
    required this.full_name,
    required this.dob,
    required this.email,
    required this.mob,
    required this.gender,
    required this.fathername,
    required this.mothername,
    required this.class1,
    required this.section,
    required this.present_address,
    required this.permanent_address,
    required this.session,
    required this.username,
    required this.password,
    required this.image,
  });
  factory Onlineadmission.fromJson(Map<String, dynamic> json) => Onlineadmission(
    reg_no: json['reg_no'],
    full_name: json['full_name'],
    dob: json['dob'],
    email: json['email'],
    mob: json['mob'],
    gender: json['gender'],
    fathername: json['fathername'],
    mothername: json['mothername'],
    class1: json['class1'],
    section: json['section'],
    present_address: json['present_address'],
    permanent_address: json['permanent_address'],
    session: json['session'],
    username: json['username'],
    password: json['password'],
    image: json['image'],
  );
  Map<String, dynamic> toJson() {
    return {
      "reg_no": reg_no,
      "full_name": full_name,
      "dob": dob,
      "email": email,
      "mob": mob,
      "gender": gender,
      "fathername": fathername,
      "mothername": mothername,
      "class1": class1,
      "section": section,
      "present_address": present_address,
      "permanent_address": permanent_address,
      "session": session,
      "username": username,
      "password": password,
      "image": image,

    };
  }
}

