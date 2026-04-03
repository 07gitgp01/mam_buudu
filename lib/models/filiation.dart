class Filiation {
  final String id;
  final String enfantId;
  final String unionId;
  final String typeLien; // biologique, adoptif, nourricier, beau-parent
  final int ordreNaissance;
  
  Filiation({
    required this.id,
    required this.enfantId,
    required this.unionId,
    this.typeLien = 'biologique',
    this.ordreNaissance = 1,
  });
  
  // Convertir en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enfantId': enfantId,
      'unionId': unionId,
      'typeLien': typeLien,
      'ordreNaissance': ordreNaissance,
    };
  }
  
  // Créer depuis Map
  factory Filiation.fromMap(Map<String, dynamic> map) {
    return Filiation(
      id: map['id'] ?? '',
      enfantId: map['enfantId'] ?? '',
      unionId: map['unionId'] ?? '',
      typeLien: map['typeLien'] ?? 'biologique',
      ordreNaissance: map['ordreNaissance'] ?? 1,
    );
  }
  
  @override
  String toString() {
    return 'Filiation(id: $id, enfant: $enfantId, union: $unionId, type: $typeLien)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Filiation &&
        other.id == id &&
        other.enfantId == enfantId &&
        other.unionId == unionId;
  }
  
  @override
  int get hashCode => id.hashCode ^ enfantId.hashCode ^ unionId.hashCode;
}
