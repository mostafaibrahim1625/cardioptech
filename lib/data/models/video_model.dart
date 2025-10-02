class VideoModel {
  final int id;
  final String title;
  final String miniDescription;
  final String? description;
  final String? link;

  VideoModel({
    required this.id,
    required this.title,
    required this.miniDescription,
    this.description,
    this.link,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      miniDescription: json['mini_description'] ?? '',
      description: json['description'],
      link: json['link'],
    );
  }

  // Factory for video details response (without id)
  factory VideoModel.fromDetailsJson(Map<String, dynamic> json, int id) {
    return VideoModel(
      id: id,
      title: json['title'] ?? '',
      miniDescription: json['mini_description'] ?? '',
      description: json['description'],
      link: json['link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'mini_description': miniDescription,
      'description': description,
      'link': link,
    };
  }

  VideoModel copyWith({
    int? id,
    String? title,
    String? miniDescription,
    String? description,
    String? link,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      miniDescription: miniDescription ?? this.miniDescription,
      description: description ?? this.description,
      link: link ?? this.link,
    );
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, title: $title, miniDescription: $miniDescription, description: $description, link: $link)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoModel &&
        other.id == id &&
        other.title == title &&
        other.miniDescription == miniDescription &&
        other.description == description &&
        other.link == link;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        miniDescription.hashCode ^
        description.hashCode ^
        link.hashCode;
  }
}
