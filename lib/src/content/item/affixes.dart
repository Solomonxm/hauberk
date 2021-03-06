import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../elements.dart';
import 'builder.dart';
import 'items.dart';

class Affixes {
  static final prefixes = ResourceSet<Affix>();
  static final suffixes = ResourceSet<Affix>();

  /// Creates a new [Item] of [itemType] and chooses affixes for it.
  static Item createItem(ItemType itemType, int droppedDepth) {
    // Untagged items don't have any affixes.
    if (Items.types.getTags(itemType.name).isEmpty) {
      return Item(itemType, 1);
    }

    // The deeper we go, the greater chance of an affix. However, finding a
    // deeper item at a shallower depth reduces its chance of an affix (since
    // the item is already better than expected). Conversely, a weaker item
    // found deeper in the dungeon has a greater chance of an affix to
    // compensate for its weakness.
    var outOfDepth = itemType.depth - droppedDepth;
    var depth = math.max(1, droppedDepth - outOfDepth ~/ 3);

    // This generates a curve that starts out at 1% and slowly ramps upwards.
    var chance = 1 + 0.006 * depth * depth + 0.2 * depth;

    if (!rng.percent(chance.ceil())) return Item(itemType, 1);

    // Give items a chance to boost their effective level when choosing a
    // affixes.
    var affixDepth = math.max(droppedDepth, itemType.depth) + rng.taper(0, 2);

    var prefix = _chooseAffix(prefixes, itemType, affixDepth);
    var suffix = _chooseAffix(suffixes, itemType, affixDepth);

    // Decide if the item may have just a prefix, just a suffix, or (rarely)
    // both. This is mainly to make dual-affix items less common since they
    // look a bit funny.
    switch (rng.range(5)) {
      case 0:
      case 1:
        return Item(itemType, 1, prefix, null);
      case 2:
      case 3:
        return Item(itemType, 1, null, suffix);
      default:
        return Item(itemType, 1, prefix, suffix);
    }
  }

  static Affix find(String name) {
    var type = prefixes.tryFind(name);
    if (type != null) return type;

    return suffixes.find(name);
  }

  static Affix _chooseAffix(
      ResourceSet<Affix> affixes, ItemType itemType, int depth) {
    return affixes.tryChooseMatching(depth, Items.types.getTags(itemType.name));
  }

  static void initialize() {
    _resists();
    _extraDamage();
    _brands();
    // TODO: "of Accuracy" increases range of bows.

    finishAffix();
  }

  static void _resists() {
    // TODO: Don't apply to all armor types?
    affixCategory("armor");

    // TODO: Different ones for each kind of armor with different bonuses?
    // TODO: Commented out for now because it causes a name collision. Should
    // we allow different prefixes with the same name for different kinds of
    // equipment?
//    affix("Elven _", 40, 1.0)
//      ..weight(-2)
//      ..armor(2)
//      ..resist(Elements.light);
//
//    affix("Dwarven _", 30, 1.0)
//      ..weight(2)
//      ..armor(4)
//      ..resist(Elements.earth)
//      ..resist(Elements.dark);

    affix("_ of Resist Air", 10, 0.5)..resist(Elements.air);
    affix("_ of Resist Earth", 11, 0.5)..resist(Elements.earth);
    affix("_ of Resist Fire", 12, 0.5)..resist(Elements.fire);
    affix("_ of Resist Water", 13, 0.5)..resist(Elements.water);
    affix("_ of Resist Acid", 14, 0.3)..resist(Elements.acid);
    affix("_ of Resist Cold", 15, 0.5)..resist(Elements.cold);
    affix("_ of Resist Lightning", 16, 0.3)..resist(Elements.lightning);
    affix("_ of Resist Poison", 17, 0.25)..resist(Elements.poison);
    affix("_ of Resist Dark", 18, 0.25)..resist(Elements.dark);
    affix("_ of Resist Light", 19, 0.25)..resist(Elements.light);
    affix("_ of Resist Spirit", 20, 0.4)..resist(Elements.spirit);

    affix("_ of Resist Nature", 40, 0.3)
      ..resist(Elements.air)
      ..resist(Elements.earth)
      ..resist(Elements.fire)
      ..resist(Elements.water)
      ..resist(Elements.cold)
      ..resist(Elements.lightning);

    affix("_ of Resist Destruction", 40, 0.3)
      ..resist(Elements.acid)
      ..resist(Elements.fire)
      ..resist(Elements.lightning)
      ..resist(Elements.poison);

    affix("_ of Resist Evil", 60, 0.3)
      ..resist(Elements.acid)
      ..resist(Elements.poison)
      ..resist(Elements.dark)
      ..resist(Elements.spirit);

    affix("_ of Resistance", 70, 0.3)
      ..resist(Elements.air)
      ..resist(Elements.earth)
      ..resist(Elements.fire)
      ..resist(Elements.water)
      ..resist(Elements.acid)
      ..resist(Elements.cold)
      ..resist(Elements.lightning)
      ..resist(Elements.poison)
      ..resist(Elements.dark)
      ..resist(Elements.light)
      ..resist(Elements.spirit);

    affix("_ of Protection from Air", 16, 0.25)..resist(Elements.air, 2);
    affix("_ of Protection from Earth", 17, 0.25)..resist(Elements.earth, 2);
    affix("_ of Protection from Fire", 18, 0.25)..resist(Elements.fire, 2);
    affix("_ of Protection from Water", 19, 0.25)..resist(Elements.water, 2);
    affix("_ of Protection from Acid", 20, 0.2)..resist(Elements.acid, 2);
    affix("_ of Protection from Cold", 21, 0.25)..resist(Elements.cold, 2);
    affix("_ of Protection from Lightning", 22, 0.16)
      ..resist(Elements.lightning, 2);
    affix("_ of Protection from Poison", 23, 0.14)..resist(Elements.poison, 2);
    affix("_ of Protection from Dark", 24, 0.14)..resist(Elements.dark, 2);
    affix("_ of Protection from Light", 25, 0.14)..resist(Elements.light, 2);
    affix("_ of Protection from Spirit", 26, 0.13)..resist(Elements.spirit, 2);
  }

  static void _extraDamage() {
    // TODO: Exclude bows?
    affixCategory("weapon");
    affix("_ of Harming", 1, 1.0)
      ..heft(1.05)
      ..damage(bonus: 1);
    affix("_ of Wounding", 10, 1.0)
      ..heft(1.07)
      ..damage(bonus: 3);
    affix("_ of Maiming", 25, 1.0)
      ..heft(1.09)
      ..damage(scale: 1.2, bonus: 3);
    affix("_ of Slaying", 45, 1.0)
      ..heft(1.11)
      ..damage(scale: 1.4, bonus: 5);

    affix("Elven _", 40, 1.0)
      ..heft(0.7)
      ..damage(scale: 1.3)
      ..resist(Elements.light);

    affix("Dwarven _", 40, 1.0)
      ..heft(1.2)
      ..damage(scale: 1.5, bonus: 4)
      ..resist(Elements.earth)
      ..resist(Elements.dark);

    affixCategory("bow");
    affix("Ash _", 10, 1.0)
      ..heft(0.8)
      ..damage(bonus: 3);
    affix("Yew _", 20, 1.0)
      ..heft(0.8)
      ..damage(bonus: 5);
  }

  static void _brands() {
    affixCategory("weapon");

    affix("Glimmering _", 20, 0.3)
      ..damage(scale: 1.2)
      ..brand(Elements.light);
    affix("Shining _", 32, 0.25)
      ..damage(scale: 1.4)
      ..brand(Elements.light);
    affix("Radiant _", 48, 0.2)
      ..damage(scale: 1.6)
      ..brand(Elements.light, resist: 2);

    affix("Dim _", 16, 0.3)
      ..damage(scale: 1.2)
      ..brand(Elements.dark);
    affix("Dark _", 32, 0.25)
      ..damage(scale: 1.4)
      ..brand(Elements.dark);
    affix("Black _", 56, 0.2)
      ..damage(scale: 1.6)
      ..brand(Elements.dark, resist: 2);

    affix("Chilling _", 20, 0.3)
      ..damage(scale: 1.4)
      ..brand(Elements.cold);
    affix("Freezing _", 40, 0.25)
      ..damage(scale: 1.6)
      ..brand(Elements.cold, resist: 2);

    affix("Burning _", 20, 0.3)
      ..damage(scale: 1.3)
      ..brand(Elements.fire);
    affix("Flaming _", 40, 0.25)
      ..damage(scale: 1.6)
      ..brand(Elements.fire);
    affix("Searing _", 60, 0.2)
      ..damage(scale: 1.8)
      ..brand(Elements.fire, resist: 2);

    affix("Electric _", 50, 0.2)
      ..damage(scale: 1.4)
      ..brand(Elements.lightning);
    affix("Shocking _", 70, 0.2)
      ..damage(scale: 1.8)
      ..brand(Elements.lightning, resist: 2);

    affix("Poisonous _", 35, 0.2)
      ..damage(scale: 1.1)
      ..brand(Elements.poison);
    affix("Venomous _", 70, 0.2)
      ..damage(scale: 1.3)
      ..brand(Elements.poison, resist: 2);

    affix("Ghostly _", 45, 0.2)
      ..heft(0.7)
      ..damage(scale: 1.4)
      ..brand(Elements.spirit);
    affix("Spiritual _", 80, 0.15)
      ..heft(0.7)
      ..damage(scale: 1.7)
      ..brand(Elements.spirit, resist: 2);
  }

  static void defineItemTag(String tag) {
    prefixes.defineTags(tag);
    suffixes.defineTags(tag);
  }
}
