int? multiplicaQtd(String s, String t) {
  int? result;
  final val1 = int.parse(s);
  final val2 = int.parse(t);
  if (val2 > 0) {
    result = val1 * val2;
  } else {
    result = val1;
  }
  return result;
}
