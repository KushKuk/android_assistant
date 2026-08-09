class ContactCandidate {
  const ContactCandidate({
    required this.contactId,
    required this.displayName,
    required this.phoneNumbers,
    required this.isExactNameMatch,
  });

  final String contactId;
  final String displayName;
  final List<String> phoneNumbers;
  final bool isExactNameMatch;

  factory ContactCandidate.fromMap(Map<Object?, Object?> map) {
    final rawNumbers = map['phoneNumbers'] as List<Object?>? ?? const [];
    return ContactCandidate(
      contactId: map['contactId'] as String,
      displayName: map['displayName'] as String,
      phoneNumbers: rawNumbers.cast<String>(),
      isExactNameMatch: map['isExactNameMatch'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contactId': contactId,
      'displayName': displayName,
      'phoneNumbers': phoneNumbers,
      'isExactNameMatch': isExactNameMatch,
    };
  }
}

class ContactSearchResult {
  const ContactSearchResult({required this.query, required this.candidates});

  final String query;
  final List<ContactCandidate> candidates;

  bool get hasNoMatches => candidates.isEmpty;
  bool get hasMultipleMatches => candidates.length > 1;

  factory ContactSearchResult.fromMap(Map<Object?, Object?> map) {
    final rawCandidates = map['candidates'] as List<Object?>? ?? const [];
    return ContactSearchResult(
      query: map['query'] as String,
      candidates: rawCandidates
          .cast<Map<Object?, Object?>>()
          .map(ContactCandidate.fromMap)
          .toList(growable: false),
    );
  }
}
