class NICData {
  final String? fullName;
  final String? nicNumber;
  final DateTime? dateOfBirth;
  final String? address;
  final String extractedText;
  final double confidence;
  final String nicFormat;
  final bool isValidNIC;
  final bool isValidDOB;
  final FieldsExtracted fieldsExtracted;
  final List<ValidationError> errors;

  NICData({
    this.fullName,
    this.nicNumber,
    this.dateOfBirth,
    this.address,
    required this.extractedText,
    required this.confidence,
    required this.nicFormat,
    required this.isValidNIC,
    required this.isValidDOB,
    required this.fieldsExtracted,
    required this.errors,
  });

  factory NICData.fromJson(Map<String, dynamic> json) {
    return NICData(
      fullName: json['fullName'],
      nicNumber: json['nicNumber'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      address: json['address'],
      extractedText: json['extractedText'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      nicFormat: json['nicFormat'] ?? 'unknown',
      isValidNIC: json['isValidNIC'] ?? false,
      isValidDOB: json['isValidDOB'] ?? false,
      fieldsExtracted: FieldsExtracted.fromJson(json['fieldsExtracted'] ?? {}),
      errors: (json['errors'] as List?)
          ?.map((e) => ValidationError.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'nicNumber': nicNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'extractedText': extractedText,
      'confidence': confidence,
      'nicFormat': nicFormat,
      'isValidNIC': isValidNIC,
      'isValidDOB': isValidDOB,
      'fieldsExtracted': fieldsExtracted.toJson(),
      'errors': errors.map((e) => e.toJson()).toList(),
    };
  }

  bool get hasValidData => isValidNIC && fullName != null;

  bool get hasErrors => errors.any((e) => e.severity == 'error');

  bool get hasWarnings => errors.any((e) => e.severity == 'warning');

  int get extractionScore {
    int score = 0;
    if (fieldsExtracted.name) score += 25;
    if (fieldsExtracted.nic) score += 25;
    if (fieldsExtracted.dob) score += 25;
    if (fieldsExtracted.address) score += 25;
    return score;
  }
}

class FieldsExtracted {
  final bool name;
  final bool nic;
  final bool dob;
  final bool address;

  FieldsExtracted({
    required this.name,
    required this.nic,
    required this.dob,
    required this.address,
  });

  factory FieldsExtracted.fromJson(Map<String, dynamic> json) {
    return FieldsExtracted(
      name: json['name'] ?? false,
      nic: json['nic'] ?? false,
      dob: json['dob'] ?? false,
      address: json['address'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nic': nic,
      'dob': dob,
      'address': address,
    };
  }
}

class ValidationError {
  final String field;
  final String message;
  final String severity;

  ValidationError({
    required this.field,
    required this.message,
    required this.severity,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'warning',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
      'severity': severity,
    };
  }

  bool get isError => severity == 'error';
  bool get isWarning => severity == 'warning';
}

class NICDetection {
  final String imageUrl;
  final NICData nicData;

  NICDetection({
    required this.imageUrl,
    required this.nicData,
  });

  factory NICDetection.fromJson(Map<String, dynamic> json) {
    return NICDetection(
      imageUrl: json['imageUrl'] ?? '',
      nicData: NICData.fromJson(json['nicData']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'nicData': nicData.toJson(),
    };
  }
}