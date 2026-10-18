import 'dart:math';

abstract final class SortByMacth {
  static String normalize(String s) => s
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');

  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = min(min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
      }
      final t = prev;
      prev = curr;
      curr = t;
    }
    return prev[b.length];
  }

  static List<T> sortByMatch<T>(
    Iterable<T> x,
    String w,
    String Function(T xi) xString,
  ) {
    final nw = normalize(w);

    // Precompute sort keys once per word
    final scored = x.map((word) {
      final n = normalize(xString(word));

      final tier = n == nw
          ? 0
          : n.startsWith(nw)
          ? 1
          : n.contains(nw)
          ? 2
          : 3;
      return (word: word, tier: tier, dist: levenshtein(n, nw), len: n.length);
    }).toList();

    scored.sort((a, b) {
      var c = a.tier.compareTo(b.tier);
      if (c != 0) return c;
      c = a.dist.compareTo(b.dist);
      if (c != 0) return c;
      return a.len.compareTo(b.len);
    });

    return scored.map((e) => e.word).toList();
  }
}
