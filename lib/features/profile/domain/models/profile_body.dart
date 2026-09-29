class ProfileBody {
  String? _sMethod;
  String? _fName;
  String? _lName;
  String? _bankName;
  String? _branch;
  String? _branchAddress;
  String? _accountNo;
  String? _ifscCode;
  String? _accountType;
  String? _holderName;
  String? _password;
  String? _image;

  ProfileBody(
      {String? sMethod,
        String? fName,
        String? lName,
        String? bankName,
        String? branch,
        String? branchAddress,
        String? accountNo,
        String? ifscCode,
        String? accountType,
        String? holderName,
        String? password,
        String? image}) {
    _sMethod = sMethod;
    _fName = fName;
    _lName = lName;
    _bankName = bankName;
    _branch = branch;
    _branchAddress = branchAddress;
    _accountNo = accountNo;
    _ifscCode = ifscCode;
    _accountType = accountType;
    _holderName = holderName;
    _password = password;
    _image = image;
  }

  String? get sMethod => _sMethod;
  String? get fName => _fName;
  String? get lName => _lName;
  String? get bankName => _bankName;
  String? get branch => _branch;
  String? get branchAddress => _branchAddress;
  String? get accountNo => _accountNo;
  String? get ifscCode => _ifscCode;
  String? get accountType => _accountType;
  String? get holderName => _holderName;
  String? get password => _password;
  String? get image => _image;

  ProfileBody.fromJson(Map<String, dynamic> json) {
    _sMethod = json['_method'];
    _fName = json['f_name'];
    _lName = json['l_name'];
    _bankName = json['bank_name'];
    _branch = json['branch'];
    _branchAddress = json['branch_address'];
    _accountNo = json['account_no'];
    _ifscCode = json['ifsc_code'];
    _accountType = json['account_type'];
    _holderName = json['holder_name'];
    _password = json['password'];
    _image = json['image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_method'] = _sMethod;
    data['f_name'] = _fName;
    data['l_name'] = _lName;
    data['bank_name'] = _bankName;
    data['branch'] = _branch;
    data['branch_address'] = _branchAddress;
    data['account_no'] = _accountNo;
    data['ifsc_code'] = _ifscCode;
    data['account_type'] = _accountType;
    data['holder_name'] = _holderName;
    data['password'] = _password;
    data['image'] = _image;
    return data;
  }
}
