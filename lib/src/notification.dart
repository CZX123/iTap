class NotificationDetails {
  final int id;
  final int disable;
  final String title;
  final String message;
  final String yesLink;
  final String noLink;
  final String yesButton;
  final String noButton;
  final String remindButton;

  const NotificationDetails({
    this.id,
    this.disable,
    this.title,
    this.message,
    this.yesLink,
    this.noLink,
    this.yesButton,
    this.noButton,
    this.remindButton,
  });

  factory NotificationDetails.fromJson(Map<String, dynamic> parsedJson) {
    return NotificationDetails(
      id: parsedJson['id'],
      disable: parsedJson['disable'],
      title: parsedJson['title'],
      message: parsedJson['message'],
      yesLink:  parsedJson['linkforyesButton'],
      noLink: parsedJson['linkfornoButton'],
      yesButton: parsedJson['yesButton'],
      noButton: parsedJson['noButton'],
      remindButton: parsedJson['remindButton'],
    );
  }

  @override
  String toString() {
    return 'NotificationDetails(id: $id, disable: $disable, title: $title, message: $message, yesLink: $yesLink, noLink: $noLink, yesButton: $yesButton, noButton: $noButton, remindButton: $remindButton)';
  }
}
