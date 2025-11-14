class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String? image;
  final String publishedAt;
  final String source;
  final String content;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    this.image,
    required this.publishedAt,
    required this.source,
    required this.content,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      image: json['image'],
      publishedAt: json['publishedAt'] ?? '',
      source: json['source'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'image': image,
      'publishedAt': publishedAt,
      'source': source,
      'content': content,
    };
  }
}

class NewsResponse {
  final bool success;
  final List<NewsArticle> articles;
  final int totalArticles;
  final CacheInfo cacheInfo;
  final String message;

  NewsResponse({
    required this.success,
    required this.articles,
    required this.totalArticles,
    required this.cacheInfo,
    required this.message,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      success: json['success'] ?? false,
      articles: (json['articles'] as List?)
              ?.map((article) => NewsArticle.fromJson(article))
              .toList() ??
          [],
      totalArticles: json['total_articles'] ?? 0,
      cacheInfo: CacheInfo.fromJson(json['cache_info'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

class CacheInfo {
  final bool isCached;
  final String lastUpdated;
  final String nextRefresh;

  CacheInfo({
    required this.isCached,
    required this.lastUpdated,
    required this.nextRefresh,
  });

  factory CacheInfo.fromJson(Map<String, dynamic> json) {
    return CacheInfo(
      isCached: json['is_cached'] ?? false,
      lastUpdated: json['last_updated'] ?? '',
      nextRefresh: json['next_refresh'] ?? '',
    );
  }
}
