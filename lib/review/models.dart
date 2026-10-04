import 'dart:convert';

import 'package:arabic_lexicons/data.dart';
import 'package:flutter/material.dart';

enum RevOrder {
  old(
    'Old to new',
    'Shows the oldest due word first. If no due words remain, shows the oldest added word from bookmarks or foreign words.',
    Icons.arrow_upward_rounded,
  ),
  newest(
    'New to old',
    'Shows the newest due word first. If no due words remain, shows the newest added word from bookmarks or foreign words',
    Icons.arrow_downward_rounded,
  ),
  rand(
    'Random',
    'Shows due words in random order. If no due words remain, shows a random word from bookmarks or foreign words.',
    Icons.shuffle_rounded,
  );

  const RevOrder(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

class RevOrdData {
  final RevOrder ord;
  final bool onlyNew;
  final bool bookMarksFirst;

  const RevOrdData({
    required this.ord,
    required this.onlyNew,
    required this.bookMarksFirst,
  });

  static RevOrdData get def => RevOrdData(
    ord: RevOrder.old,
    onlyNew: false,
    bookMarksFirst: appConf.reviewBookmarksFirst,
  );

  Future<void> save() async {
    if (bookMarksFirst == appConf.reviewBookmarksFirst) return;
    await appConf.saveReviewBookmarksFirst(bookMarksFirst);
  }

  String get label => '${ord.label}${onlyNew ? ' • New' : ''}';
  String get name => ord.name;

  RevOrdData copyWith({RevOrder? ord, bool? onlyNew, bool? bookMarksFirst}) {
    return RevOrdData(
      ord: ord ?? this.ord,
      onlyNew: onlyNew ?? this.onlyNew,
      bookMarksFirst: bookMarksFirst ?? this.bookMarksFirst,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RevOrdData &&
            ord == other.ord &&
            onlyNew == other.onlyNew &&
            bookMarksFirst == other.bookMarksFirst;
  }

  @override
  int get hashCode => Object.hash(ord, onlyNew, bookMarksFirst);
}

class RevItem {
  final String word;
  final int due; // epoch ms
  final int lastInterval; // days
  final bool hidden;

  RevItem(this.word, this.due, this.lastInterval, this.hidden);

  factory RevItem.fromMap(Map<String, Object?> m) => RevItem(
    m['word'] as String,
    m['due'] as int,
    m['last_interval'] as int,
    (m['hidden'] as int) == 1,
  );

  Map<String, Object?> toMap() => {
    'word': word,
    'due': due,
    'last_interval': lastInterval,
    'hidden': hidden ? 1 : 0,
  };

  // Single item: JSON string
  factory RevItem.fromJsonString(String text) =>
      RevItem.fromMap(jsonDecode(text) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toMap());

  // List: JSON
  static List<RevItem> listFromJson(List<dynamic> json) =>
      json.map((e) => RevItem.fromMap(e as Map<String, dynamic>)).toList();

  static List<Map<String, dynamic>> listToJson(List<RevItem> items) =>
      items.map((e) => e.toMap()).toList();

  // List: JSON string
  static List<RevItem> listFromJsonString(String text) =>
      listFromJson(jsonDecode(text) as List<dynamic>);

  static String listToJsonString(List<RevItem> items) =>
      jsonEncode(listToJson(items));

  @override
  String toString() {
    return 'RevItem(${toMap().entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
  }
}
