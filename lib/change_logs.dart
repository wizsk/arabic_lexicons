import 'package:arabic_lexicons/key_shortcuts.dart';

final releases = [
  Release(
    version: 'v3.7.0',
    changes: '''
    Fixed settings save issues (Sorry for the reset)
    Ghani sort result by closest mach to the word
    Ghani dataset fix more issues
    Add bookmark function to Direct dictionary
    Use card to show Direct dictionary results by default (to use table go to settings and Lexicon section and toggle show table)
  ''',
  ),
  Release(
    version: 'v3.6.0',
    changes: '''
    App app tour video in the help page
    Fixed many issues ghani lexicons dataset
    Add save definitions of lexicons
    Add Review Words page
    Lisanul Arab lexicon show references on click no need to scrool to the bottom
    Added ability to remove unwanted lexicons
    Directly selectable text "Direct" dictionary
    Find matching words from All the book entries. (tab and hold on the search suggestion icon)
    Adjust word Spacing in the reader
    Change highlight style for bookmarks and foreign words. Use background color highlighted words
    Add scroll to top in the lexicon page (long press to go bottom)
  ''',
  ),
  Release(
    version: 'v3.5.0',
    changes:
        '''
    Add a delete icon to the scrollable lexicon word selector
    Add keyboard Shortcuts (see help screen or ${AppShortcut.showHelp.label})
    Make the scrollable word and lexicon selectors the default on the Lexicons screen
    Store the lexicon database in the data directory instead of the cache directory
    Add Welcome screen
    Add Save/Delete options to the reader screen
    ''',
  ),
  Release(
    version: 'v3.4.1',
    changes: '''
    Minor padding issue into reader style changer page
    ''',
  ),
  Release(
    version: 'v3.4.0',
    changes: '''
    Make app launch blazingly fast
    Added the ability to adjust line height
    Add demo text to the reader-input page
    Add Aref-Ruqaa font
    Enhance direct dictionary table style
    Improve Hanswehr and Lane Lexicon search
    Fixed minor bugs & improvements
    ''',
  ),
  Release(
    version: 'v3.3.0',
    changes: '''
    Set the font size for Arabic input fields and UI elements
    Apply reader page settings immediately after changes
    Fix lexcion reordering bug + crash
    ''',
  ),
  Release(
    version: 'v3.2.0',
    changes: '''
    Added scrollable word and dictionary selectors directly to the Lexicon page, eliminating the need for a popup (toggle it by long-pressing the open-popup button or in Settings → Lexicon)
    Remove limit of number of paragraph can be shown in selection-screen
    Add page up/down to buttons reader (long press to jump to top/bottom)
    Shorten the lexicons names
    ''',
  ),
  Release(
    version: 'v3.1.0',
    changes: '''
    add export and import to foreign word list
    on large screens keep the ui width smaller (if user sets the style)
    fix on foreign undo highlight
    fix reader font-size not changing
    ''',
  ),
  Release(
    version: 'v3.0.0',
    changes: '''
    search history
    visited (foreign) word auto highlight for books
    visited (foreign) word list for individual books
    bookmarked word list for individual books
    New reader style page (font, font size, padding, width config)
    search suggestion for Direct dictionary
    while suggestions keep the top bar (Header bar)
    enhanced selection screen in reader mode
    help page changed
    add change-log on new release
    open last book if it was being read
    color matched in search suggestions
    ''',
  ),
  Release(
    version: 'v2.5.4',
    changes: '''
    better Reading progress stats
    better word search results and suggestions not found messages
    Add more English to the ui. Eg. Suggestion screen and more
    Per reader book font size
    this releases includes the changes from v2.5.3
    ''',
  ),

  Release(
    version: 'v2.5.1',
    changes: '''
    save last read position in reader mode
    book navigator chapters and ...
    add icons to root words in search suggestions
    make ui better
    add 2 new arabic fonts
    use ui favorable arabic font for arabic ui
    ''',
  ),
];

class Release {
  final String version;
  final List<String> changes;

  Release({required this.version, required String changes})
    : changes = changes
          .trim()
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
}
