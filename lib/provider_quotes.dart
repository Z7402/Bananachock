import "dart:math";
import "dart:convert";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;

const List<Map<String, String>> _builtinQuotes = [
  {"text": "逝者如斯夫，不舍昼夜。", "author": "孔子《论语》"},
  {"text": "志士惜年，贤人惜日，圣人惜时。", "author": "魏源《默觚》"},
  {"text": "人的差异在于业余时间。", "author": "爱因斯坦"},
  {"text": "莫等闲，白了少年头，空悲切。", "author": "岳飞《满江红》"},
  {"text": "盛年不重来，一日难再晨。及时当勉励，岁月不待人。", "author": "陶渊明《杂诗》"},
  {"text": "明日复明日，明日何其多。我生待明日，万事成蹉跎。", "author": "钱福《明日歌》"},
  {"text": "天行健，君子以自强不息。", "author": "《周易》"},
  {"text": "Do not watch the clock. Do what it does. Keep going.", "author": "Sam Levenson"},
  {"text": "Time is what we want most, but what we use worst.", "author": "William Penn"},
  {"text": "生命是以时间为单位的，浪费别人的时间等于谋财害命。", "author": "鲁迅"},
  {"text": "少年易老学难成，一寸光阴不可轻。", "author": "朱熹《劝学诗》"},
  {"text": "劝君莫惜金缕衣，劝君惜取少年时。", "author": "杜秋娘《金缕衣》"},
  {"text": "每一个不曾起舞的日子，都是对生命的辜负。", "author": "尼采"},
  {"text": "十年磨一剑，霜刃未曾试。", "author": "贾岛《剑客》"},
  {"text": "粗缯大布裹生涯，腹有诗书气自华。", "author": "苏轼《和董传留别》"},
  {"text": "夫天地者，万物之逆旅也；光阴者，百代之过客也。", "author": "李白"},
  {"text": "青春须早为，岂能长少年。", "author": "孟郊《劝学》"},
  {"text": "真正的迅速是很有价值的。", "author": "培根"},
  {"text": "世间好物不坚牢，彩云易散琉璃脆。", "author": "白居易《简简吟》"},
  {"text": "活着本身就是一个奇迹。", "author": "史铁生《病隙碎笔》"},
  {"text": "The bad news is time flies. The good news is you are the pilot.", "author": "Michael Altshuler"},
];

class QuotesNotifier extends StateNotifier<QuoteState> {
  QuotesNotifier() : super(const QuoteState()) {
    _refreshQuote();
  }

  final Random _random = Random();

  void _refreshQuote() {
    final quote = _builtinQuotes[_random.nextInt(_builtinQuotes.length)];
    state = QuoteState(text: quote["text"]!, author: quote["author"]!);
  }

  Future<void> fetchRemoteQuote() async {
    try {
      final response = await http
          .get(Uri.parse("https://v1.hitokoto.cn/?c=a&c=b&c=c&c=d&c=e&c=f&c=h&c=i&c=j&c=k&c=l&encode=json"))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data["hitokoto"] as String?;
        final from = data["from"] as String?;
        if (text != null && text.isNotEmpty) {
          state = QuoteState(text: text, author: from ?? "");
          return;
        }
      }
    } catch (_) {}
    _refreshQuote();
  }

  void nextQuote() {
    if (_random.nextDouble() < 0.1) {
      fetchRemoteQuote();
    } else {
      _refreshQuote();
    }
  }
}

class QuoteState {
  final String text;
  final String author;
  const QuoteState({this.text = "", this.author = ""});
}

final quoteProvider = StateNotifierProvider<QuotesNotifier, QuoteState>((ref) {
  return QuotesNotifier();
});
