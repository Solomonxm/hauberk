import 'dart:html' as html;

import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/monster/monsters.dart';
import 'package:hauberk/src/engine.dart';

import 'histogram.dart';

final allBreeds = List<Histogram<String>>.generate(101, (_) => Histogram());

final allSpawns = List<Histogram<String>>.generate(101, (_) => Histogram());

final allItems = List<Histogram<String>>.generate(101, (_) => Histogram());

final allAffixes = List<Histogram<String>>.generate(101, (_) => Histogram());

final validator = html.NodeValidatorBuilder.common()..allowInlineStyles();

Game game;

main() {
  var content = createContent();
  game = Game(content, content.createHero("temp"), 1);

  spawnStuff();
  generateTable();

  html.querySelector('table').onClick.listen((_) {
    spawnStuff();
    generateTable();
  });
}

int pickDepth(int depth, int numLevels) {
  while (rng.oneIn(4) && depth > 0) depth--;
  while (rng.oneIn(6) && depth < numLevels - 1) depth++;

  return depth;
}

void spawnStuff() {
  for (var depth = 1; depth <= 100; depth++) {
    var breeds = allBreeds[depth];
    var spawns = allSpawns[depth];
    var items = allItems[depth];
    var affixes = allAffixes[depth];

    var numSpawns = 30 + depth;
    for (var i = 0; i < numSpawns; i++) {
      var breed = Monsters.breeds.tryChoose(depth, "monster");
      breeds.add(breed.name);
      for (var spawn in breed.spawnAll()) {
        spawns.add(spawn.name);
      }
    }

    var numCorpses = 5 + (depth ~/ 2);
    for (var i = 0; i < numCorpses; i++) {
      var breed = Monsters.breeds.tryChoose(depth, "monster");
      if (breed == null) continue;

      for (var spawn in breed.spawnAll()) {
        spawn.drop.spawnDrop((item) {
          items.add(item.type.name);

          if (item.prefix != null) affixes.add("${item.prefix.name} ___");
          if (item.suffix != null) affixes.add("___ ${item.suffix.name}");
        });
      }
    }
  }
}

void generateTable() {
  var text = StringBuffer();

  text.write('''<thead>
    <tr>
      <td>Depth</td>
      <td>Breeds</td>
      <td>Monsters</td>
      <td>Items</td>
      <td>Affixes</td>
    </tr>
  </thead>''');

  for (var depth = 1; depth <= 100; depth++) {
    text.write('<tr><td>$depth</td>');

    renderColumn(Histogram<String> histogram) {
      text.write('<td width="25%">');
      var more = 0;
      for (var name in histogram.descending()) {
        var width = histogram.count(name);
        if (width < 1) {
          more++;
          continue;
        }
        if (width > 100) {
          width = 100;
        }

        text.write('<div class="bar" style="width: ${width}px;"></div>');
        text.write(" $name");
        text.write("<br>");
      }

      if (more > 0) {
        text.write("<em>$more more&hellip;</em>");
      }

      text.write('</td>');
    }

    renderColumn(allBreeds[depth]);
    renderColumn(allSpawns[depth]);
    renderColumn(allItems[depth]);
    renderColumn(allAffixes[depth]);

    text.write('</tr>');
  }

  html
      .querySelector('table')
      .setInnerHtml(text.toString(), validator: validator);
}
