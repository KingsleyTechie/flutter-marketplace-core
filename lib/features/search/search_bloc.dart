import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'advanced_filters.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  Timer? _debounceTimer;
  final Duration debounceDuration = const Duration(milliseconds: 500);
  
  SearchBloc() : super(SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ApplyFilters>(_onApplyFilters);
    on<ClearFilters>(_onClearFilters);
    on<LoadMoreResults>(_onLoadMoreResults);
    on<SaveSearch>(_onSaveSearch);
    on<LoadSavedSearches>(_onLoadSavedSearches);
  }
  
  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // If query is empty, show initial state
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }
    
    // Show loading state
    emit(SearchLoading());
    
    // Debounce the search
    _debounceTimer = Timer(debounceDuration, () async {
      try {
        // In real implementation, this would call your API
        await _performSearch(event.query, event.filters);
      } catch (e) {
        emit(SearchError('Search failed: ${e.toString()}'));
      }
    });
  }
  
  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    
    try {
      // Apply filters and search
      await _performSearch(event.query, event.filters);
    } catch (e) {
      emit(SearchError('Failed to apply filters: ${e.toString()}'));
    }
  }
  
  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchInitial());
  }
  
  Future<void> _onLoadMoreResults(
    LoadMoreResults event,
    Emitter<SearchState> emit,
  ) async {
    if (state is SearchLoaded) {
      final currentState = state as SearchLoaded;
      
      // Don't load more if we've reached the end
      if (currentState.hasReachedMax) {
        return;
      }
      
      // Show loading more state
      emit(currentState.copyWith(isLoadingMore: true));
      
      try {
        // Load more results
        final nextPage = currentState.filters.page + 1;
        final updatedFilters = currentState.filters.copyWith(page: nextPage);
        
        // Simulate API call - replace with actual implementation
        await Future.delayed(const Duration(seconds: 1));
        
        // In real app, you would fetch new results and append them
        final newResults = []; // Fetch from API
        
        // Check if we've reached the end
        final hasReachedMax = newResults.length < currentState.filters.limit!;
        
        emit(SearchLoaded(
          results: currentState.results, // Append new results in real app
          filters: updatedFilters,
          hasReachedMax: hasReachedMax,
          totalResults: currentState.totalResults,
        ));
      } catch (e) {
        emit(SearchError('Failed to load more results: ${e.toString()}'));
      }
    }
  }
  
  Future<void> _onSaveSearch(
    SaveSearch event,
    Emitter<SearchState> emit,
  ) async {
    try {
      // Save search to local storage or backend
      // Implementation depends on your storage strategy
      emit(SearchSaved(event.name));
    } catch (e) {
      emit(SearchError('Failed to save search: ${e.toString()}'));
    }
  }
  
  Future<void> _onLoadSavedSearches(
    LoadSavedSearches event,
    Emitter<SearchState> emit,
  ) async {
    emit(SavedSearchesLoading());
    
    try {
      // Load saved searches from storage
      // Implementation depends on your storage strategy
      await Future.delayed(const Duration(milliseconds: 500));
      
      final savedSearches = []; // Load from storage
      emit(SavedSearchesLoaded(savedSearches));
    } catch (e) {
      emit(SearchError('Failed to load saved searches: ${e.toString()}'));
    }
  }
  
  Future<void> _performSearch(String query, AdvancedFilters? filters) async {
    // Simulate API call - replace with actual implementation
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate search results
    final results = List.generate(
      10,
      (index) => SearchResult(
        id: 'result_$index',
        title: '$query result $index',
        description: 'Description for $query result $index',
        price: 100.0 * (index + 1),
        imageUrl: 'https://picsum.photos/200/300?random=$index',
        location: 'Location $index',
        category: 'Category $index',
      ),
    );
    
    // In real implementation, you would get total count from API
    final totalResults = 100;
    
    final effectiveFilters = filters?.copyWith(query: query) ??
        AdvancedFilters(query: query);
    
    add(SearchCompleted(
      results: results,
      filters: effectiveFilters,
      totalResults: totalResults,
    ));
  }
  
  // Public method to trigger search completion
  void completeSearch({
    required List<SearchResult> results,
    required AdvancedFilters filters,
    required int totalResults,
  }) {
    add(SearchCompleted(
      results: results,
      filters: filters,
      totalResults: totalResults,
    ));
  }
  
  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

class SearchResult {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String location;
  final String category;
  final double? rating;
  final int? reviewCount;
  
  const SearchResult({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.location,
    required this.category,
    this.rating,
    this.reviewCount,
  });
}
