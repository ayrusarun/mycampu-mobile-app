class AIQuery {
  final String question;
  final String? contextFilter;

  AIQuery({
    required this.question,
    this.contextFilter,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      if (contextFilter != null) 'context_filter': contextFilter,
    };
  }
}

class AIResponse {
  final String answer;
  final List<Map<String, dynamic>> sources;
  final int conversationId;

  AIResponse({
    required this.answer,
    required this.sources,
    required this.conversationId,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      answer: json['answer'] as String,
      sources: List<Map<String, dynamic>>.from(json['sources'] ?? []),
      conversationId: json['conversation_id'] as int,
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<Map<String, dynamic>>? sources;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.sources,
  });
}

class Conversation {
  final int id;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.messages,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      messages: [], // We'll manage messages locally
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class KnowledgeSearchQuery {
  final String query;
  final String? contentType;
  final int limit;

  KnowledgeSearchQuery({
    required this.query,
    this.contentType,
    this.limit = 5,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      if (contentType != null) 'content_type': contentType,
      'limit': limit,
    };
  }
}

class SearchResult {
  final String docId;
  final double similarity;
  final Map<String, dynamic> metadata;

  SearchResult({
    required this.docId,
    required this.similarity,
    required this.metadata,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      docId: json['doc_id'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }
}
