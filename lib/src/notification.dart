class NotificationDetails {
  final int id;
  final String title;
  final String message;
  final String yesLink;
  final String noLink;
  final String yesButton;
  final String noButton;

  const NotificationDetails({
    this.id,
    this.title,
    this.message,
    this.yesLink,
    this.noLink,
    this.yesButton,
    this.noButton,
  });

  factory NotificationDetails.fromJson(Map<String, dynamic> parsedJson) {
    return NotificationDetails(
      id: parsedJson['id'],
      title: parsedJson['title'],
      message: parsedJson['message'],
      yesLink:  parsedJson['linkforyesButton'],
      noLink: parsedJson['linkfornoButton'],
      yesButton: parsedJson['yesButton'],
      noButton: parsedJson['noButton'],
    );
  }

  @override
  String toString() {
    return 'NotificationDetails(id: $id, title: $title, message: $message, yesLink: $yesLink, noLink: $noLink, yesButton: $yesButton, noButton: $noButton)';
  }
}
