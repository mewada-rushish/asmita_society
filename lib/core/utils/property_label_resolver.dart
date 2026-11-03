import '../../features/visitor_management/data/models/property_config.dart';

class PropertyLabelResolver {
  static String tower(PropertyConfig config) {
    return config.towerLabel;
  }

  static String wing(PropertyConfig config) {
    return config.wingLabel;
  }

  static String unit(PropertyConfig config) {
    return config.flatLabel;
  }

  static String memberLabel(PropertyConfig config) {
    if (config.isIndustrial) return 'Employee';
    if (config.isCommercial) return 'Staff';
    return 'Resident';
  }

  static String householdLabel(PropertyConfig config) {
    if (config.isIndustrial) return 'My Team / Desk';
    if (config.isCommercial) return 'My Office';
    return 'My Household';
  }

  static String propertyInfoLabel(PropertyConfig config) {
    if (config.isIndustrial) return 'Company Info & SOPs';
    if (config.isCommercial) return 'Building Management';
    return 'Society Info';
  }

  static List<String> visitorCategories(PropertyConfig config) {
    if (config.visitorCategories.isNotEmpty) {
      return config.visitorCategories;
    }
    if (config.isIndustrial) {
      return const ['Guest', 'Vendor', 'Contractor', 'Delivery', 'Interview'];
    }
    if (config.isCommercial) {
      return const ['Client', 'Vendor', 'Delivery', 'Cab', 'Interview'];
    }
    return const ['Guest', 'Delivery', 'Cab', 'Service'];
  }
}
