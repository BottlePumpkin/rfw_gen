import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_playground/remote/screen_registry.dart';

void main() {
  test('Manifest parses JSON', () {
    final manifest = Manifest.fromJson({
      'version': 1,
      'baseUrl': 'https://example.com/remote',
      'categories': [
        {'id': 'overview', 'title': 'Overview'},
      ],
      'screens': [
        {
          'id': 'home',
          'title': 'Home',
          'category': 'overview',
          'rfwtxt': 'screens/home.rfwtxt',
          'data': 'data/home.json',
          'keywords': ['introduction', 'overview'],
        },
      ],
    });
    expect(manifest.version, 1);
    expect(manifest.screens.length, 1);
    expect(manifest.screens.first.id, 'home');
    expect(manifest.screens.first.dataPath, 'data/home.json');
    expect(manifest.categories.first.title, 'Overview');
  });

  test('Manifest.screensForCategory filters correctly', () {
    final manifest = Manifest.fromJson({
      'version': 1,
      'baseUrl': '',
      'categories': [
        {'id': 'a', 'title': 'A'},
        {'id': 'b', 'title': 'B'},
      ],
      'screens': [
        {'id': 's1', 'title': 'S1', 'category': 'a', 'rfwtxt': 'x.rfwtxt'},
        {'id': 's2', 'title': 'S2', 'category': 'b', 'rfwtxt': 'y.rfwtxt'},
      ],
    });
    expect(manifest.screensForCategory('a').length, 1);
    expect(manifest.screensForCategory('a').first.id, 's1');
  });

  test('Manifest.search matches title and keywords', () {
    final manifest = Manifest.fromJson({
      'version': 1,
      'baseUrl': '',
      'categories': [],
      'screens': [
        {
          'id': 'home',
          'title': 'Home Page',
          'category': 'overview',
          'rfwtxt': 'x.rfwtxt',
          'keywords': ['introduction'],
        },
        {
          'id': 'guide',
          'title': 'Getting Started',
          'category': 'guides',
          'rfwtxt': 'y.rfwtxt',
          'keywords': ['setup', 'install'],
        },
      ],
    });
    expect(manifest.search('home').length, 1);
    expect(manifest.search('install').length, 1);
    expect(manifest.search('xyz').length, 0);
  });
}
