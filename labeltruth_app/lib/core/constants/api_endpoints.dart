class ApiEndpoints {
  // Live Render Production Backend URL
  static const String defaultBaseUrl = "https://labeltruth-backend.onrender.com/api/v1";
  static const String productionBaseUrl = "https://labeltruth-backend.onrender.com/api/v1";
  static const String localDesktopBaseUrl = "http://127.0.0.1:8000/api/v1";
  static const String androidEmulatorBaseUrl = "http://10.0.2.2:8000/api/v1";

  // Endpoints
  static const String analyze = "/analyze";
  static const String scanUpload = "/scan/upload";
  static const String scansList = "/scans/";
  static const String scanDetail = "/scans";
  static const String products = "/products/";
  static const String barcodeLookup = "/products/barcode";
  static const String generatePdf = "/report/generate-pdf";
  static const String downloadPdf = "/report/download";
  static const String rules = "/rules/";
  static const String userProfile = "/users/me";
  static const String productChat = "/chat/product";
}
