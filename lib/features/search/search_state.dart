part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  
  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<SearchResult> results;
  final AdvancedFilters filters;
  final bool hasReachedMax;
  final int totalResults;
  final bool isLoadingMore;
  
  const SearchLoaded({
    required this.results,
    required this.filters,
    this.hasReachedMax = false,
    required this.totalResults,
    this.isLoadingMore = false,
  });
  
  SearchLoaded copyWith({
    List<SearchResult>? results,
    AdvancedFilters? filters,
    bool? hasReachedMax,
    int? totalResults,
    bool? isLoadingMore,
  }) {
    return SearchLoaded(
      results: results ?? this.results,
      filters: filters ?? this.filters,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalResults: totalResults ?? this.totalResults,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
  
  @override
  List<Object> get props => [
    results,
    filters,
    hasReachedMax,
    totalResults,
    isLoadingMore,
  ];
}

class SearchError extends SearchState {
  final String message;
  
  const SearchError(this.message);
  
  @override
  List<Object> get props => [message];
}

class SearchSaved extends SearchState {
  final String searchName;
  
  const SearchSaved(this.searchName);
  
  @override
  List<Object> get props => [searchName];
}

class SavedSearchesLoading extends SearchState {}

class SavedSearchesLoaded extends SearchState {
  final List<SavedSearch> savedSearches;
  
  const SavedSearchesLoaded(this.savedSearches);
  
  @override
  List<Object> get props => [savedSearches];
}

class SavedSearch {
  final String id;
  final String name;
  final AdvancedFilters filters;
  final DateTime savedAt;
  final int resultCount;
  
  const SavedSearch({
    required this.id,
    required this.name,
    required this.filters,
    required this.savedAt,
    required this.resultCount,
  });
}
