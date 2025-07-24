import 'dart:html' as html;

void showWebNotification(String title, String body) {
  print('Attempting to show web notification: $title - $body');
  if (html.Notification.supported) {
    html.Notification.requestPermission().then((permission) {
      print('Notification permission: $permission');
      if (permission == 'granted') {
        html.Notification(title, body: body);
      }
    });
  }
}
