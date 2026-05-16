enum SessionLanguage {
  english('English', 'en'),
  urdu('اردو (Urdu)', 'ur');

  const SessionLanguage(this.label, this.code);
  final String label;
  final String code;
}
