/// Model for job search filters
class JobSearchFilters {
  String was = '';
  String wo = '';
  String berufsfeld = '';
  String arbeitgeber = '';
  String veroeffentlichtseit = '0';
  bool zeitarbeit = false;
  String angebotsart = '1';
  String befristung = '2';
  List<String> arbeitszeit = ['vz']; // Changed to List for multiple selection
  List<String> angebotsartList = ['1']; // Changed to List for multiple selection
  double umkreis = 30.0;

  Map<String, String> toParams({required int page, required int size}) {
    final params = <String, String>{
      'was': was,
      'wo': wo,
      'berufsfeld': berufsfeld,
      'page': page.toString(),
      'size': size.toString(),
      'arbeitgeber': arbeitgeber,
      'veroeffentlichtseit': veroeffentlichtseit,
      'zeitarbeit': zeitarbeit.toString(),
      'angebotsart': angebotsartList.join(';'),
      'befristung': befristung,
      'arbeitszeit': arbeitszeit.join(';'),
      'umkreis': umkreis.toInt().toString(),
    };

    params.removeWhere((_, value) => value.isEmpty);
    return params;
  }

  void clear() {
    was = '';
    wo = '';
    berufsfeld = '';
    arbeitgeber = '';
    veroeffentlichtseit = '0';
    zeitarbeit = false;
    angebotsart = '1';
    befristung = '2';
    arbeitszeit = ['vz'];
    angebotsartList = ['1'];
    umkreis = 30.0;
  }
}
