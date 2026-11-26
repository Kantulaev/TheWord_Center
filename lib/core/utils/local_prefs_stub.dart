final Map<String, String> _memoryPrefs = {};

String? readLocalPref(String key) => _memoryPrefs[key];

void writeLocalPref(String key, String value) {
  _memoryPrefs[key] = value;
}
