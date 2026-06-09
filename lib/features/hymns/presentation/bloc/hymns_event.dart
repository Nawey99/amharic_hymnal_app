// lib/features/hymns/presentation/bloc/hymns_event.dart
part of 'hymns_bloc.dart';

abstract class HymnsEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadHymns extends HymnsEvent {
  final String languageCode;
  final String version;
  final String sortType;

  LoadHymns(this.languageCode, this.version, this.sortType);

  @override
  List<Object> get props => [languageCode, version, sortType];
}

class SearchHymnsEvent extends HymnsEvent {
  final String languageCode;
  final String version;
  final String query;

  SearchHymnsEvent(this.languageCode, this.version, this.query);

  @override
  List<Object> get props => [languageCode, version, query];
}

class ChangeLanguage extends HymnsEvent {
  final String languageCode;
  final String version;
  final String sortType;

  ChangeLanguage(this.languageCode, this.version, this.sortType);

  @override
  List<Object> get props => [languageCode, version, sortType];
}

class ChangeVersion extends HymnsEvent {
  final String languageCode;
  final String version;
  final String sortType;

  ChangeVersion(this.languageCode, this.version, this.sortType);

  @override
  List<Object> get props => [languageCode, version, sortType];
}

class ChangeSort extends HymnsEvent {
  final String languageCode;
  final String version;
  final String sortType;

  ChangeSort(this.languageCode, this.version, this.sortType);

  @override
  List<Object> get props => [languageCode, version, sortType];
}

class ToggleFavorite extends HymnsEvent {
  final int hymnNumber;

  ToggleFavorite(this.hymnNumber);

  @override
  List<Object> get props => [hymnNumber];
}

class GetHymnByNumberEvent extends HymnsEvent {
  final String languageCode;
  final String version;
  final int number;

  GetHymnByNumberEvent(this.languageCode, this.version, this.number);

  @override
  List<Object> get props => [languageCode, version, number];
}

class LoadHymnsByCategoryEvent extends HymnsEvent {
  final String languageCode;
  final String version;
  final String category;

  LoadHymnsByCategoryEvent(this.languageCode, this.version, this.category);

  @override
  List<Object> get props => [languageCode, version, category];
}
