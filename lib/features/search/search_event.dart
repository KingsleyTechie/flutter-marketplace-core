part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();
  
  @override
  List<Object> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  final AdvancedFilters? filters;
  
  const SearchQueryChanged({
    required this.query,
    this.filters,
  });
  
  @override
  List<Object> get props => [query, filters ?? AdvancedFilters()];
}

class ApplyFilters extends SearchEvent {
  final String query;
  final AdvancedFilters filters;
  
  const ApplyFilters({
    required this.query,
    required this.filters,
  });
  
  @override
  List<Object> get props => [query, filters];
}

class ClearFilters extends SearchEvent {}

class LoadMoreResults extends SearchEvent {}

class SaveSearch extends SearchEvent {
  final String name;
  final AdvancedFilters filters;
  
  const SaveSearch({
    required this.name,
    required this.filters,
  });
  
  @override
  List<Object> get props => [name, filters];
}

class LoadSavedSearches extends SearchEvent {}

class SearchCompleted extends SearchEvent {
  final List<SearchResult> results;
  final AdvancedFilters filters;
  final int totalResults;
  
  const SearchCompleted({
    required this.results,
    required this.filters,
    required this.totalResults,
  });
  
  @override
  List<Object> get props => [results, filters, totalResults];
}
