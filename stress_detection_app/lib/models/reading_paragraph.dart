class ReadingParagraph {
  const ReadingParagraph({
    required this.instruction,
    required this.title,
    required this.body,
  });

  /// Short cue for the student (not part of the story text).
  final String instruction;

  /// Story section heading — displayed separately from body.
  final String title;

  /// Passage text only — what the student should read aloud.
  final String body;
}
