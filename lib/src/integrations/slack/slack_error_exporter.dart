import '../../sinks/http_error_exporter.dart';
import 'slack_payload_formatter.dart';

/// Placeholder URL used in template code and examples.
///
/// If a [SlackErrorExporter] is constructed with this value, it is
/// automatically replaced by [HttpErrorExporter.demoUrl] so the
/// payload is printed to the console instead of making a real HTTP request.
const _slackPlaceholderUrl =
    'https://hooks.slack.com/services/YOUR/WEBHOOK/URL';

/// A convenience [ErrorExporter] that sends error reports to a Slack channel
/// via an Incoming Webhook URL.
///
/// This is a thin wrapper around [HttpErrorExporter] pre-configured with
/// [SlackPayloadFormatter]. For full control over the formatter or transport,
/// compose [HttpErrorExporter] and [SlackPayloadFormatter] directly.
///
/// To obtain a webhook URL, create an Incoming Webhook in your Slack app
/// settings: https://api.slack.com/messaging/webhooks
///
/// Use [payloadBuilder] to merge dynamic top-level fields into the Slack
/// webhook payload, or [headersBuilder] to inject dynamic HTTP headers on
/// every send. Both are useful when routing through a proxy that requires
/// extra keys or authentication:
///
/// ```dart
/// final exporter = SlackErrorExporter(
///   'https://proxy.example.com/slack',
///   payloadBuilder: () => {
///     'channel': '#alerts',
///     'username': 'ErrorBot',
///   },
///   headersBuilder: () => {
///     'Authorization': 'Bearer ${tokenProvider.current}',
///     'X-Routing-Key': 'my-service',
///   },
/// );
/// ```
class SlackErrorExporter extends HttpErrorExporter {
  /// Creates a [SlackErrorExporter] that posts to the given [webhookUrl].
  ///
  /// [payloadBuilder] — optional callback invoked on every send whose return
  /// value is merged into the Slack Block Kit payload.
  ///
  /// [headersBuilder] — optional callback invoked on every send whose return
  /// value is merged into the HTTP request headers.
  SlackErrorExporter(
    String webhookUrl, {
    Map<String, dynamic> Function()? payloadBuilder,
    Map<String, String> Function()? headersBuilder,
  }) : super(
         // Replace the template placeholder with the demo URL so users can
         // run the example code without a real Slack webhook.
         webhookUrl == _slackPlaceholderUrl
             ? HttpErrorExporter.demoUrl
             : webhookUrl,
         SlackPayloadFormatter(),
         payloadBuilder: payloadBuilder != null
             ? (payload) => {...payload, ...payloadBuilder()}
             : null,
         headersBuilder: headersBuilder,
       );
}
