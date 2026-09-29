class ProductTaxConfig {
  final bool productWiseTax;
  final bool taxCalculationEnabled;
  final String defaultTaxModel;
  final List<TaxModelOption> taxModelOptions;
  final List<TaxRate> taxRates;

  ProductTaxConfig({
    required this.productWiseTax,
    this.taxCalculationEnabled = true,
    this.defaultTaxModel = 'exclude',
    this.taxModelOptions = const [],
    this.taxRates = const [],
  });

  factory ProductTaxConfig.fromJson(Map<String, dynamic> json) {
    return ProductTaxConfig(
      productWiseTax: json['product_wise_tax'] == true,
      taxCalculationEnabled: json['tax_calculation_enabled'] != false,
      defaultTaxModel: json['default_tax_model']?.toString() ?? 'exclude',
      taxModelOptions: (json['tax_model_options'] as List? ?? [])
          .map((e) => TaxModelOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      taxRates: (json['tax_rates'] as List? ?? [])
          .map((e) => TaxRate.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class TaxModelOption {
  final String value;
  final String label;

  TaxModelOption({required this.value, required this.label});

  factory TaxModelOption.fromJson(Map<String, dynamic> json) {
    return TaxModelOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class TaxRate {
  final int id;
  final String name;
  final num taxRate;

  TaxRate({required this.id, required this.name, required this.taxRate});

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      taxRate: num.tryParse(json['tax_rate'].toString()) ?? 0,
    );
  }
}
