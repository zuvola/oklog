import 'http_error_exporter.dart';
import 'slack_payload_formatter.dart';

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
/// Use [extraPayload] to merge additional top-level fields into the Slack
/// webhook payload before delivery. This is useful when routing through a
/// proxy that requires extra keys (e.g. `channel`, `username`, a routing
/// token, etc.):
///
/// ```dart
/// final exporter = SlackErrorExporter(
///   'https://proxy.example.com/slack',
///   extraPayload: {
///     'channel': '#alerts',
///     'username': 'ErrorBot',
///     'x-routing-key': 'my-service',
///   },
/// );
/// ```
class SlackErrorExporter extends HttpErrorExporter {
  /// Creates a [SlackErrorExporter] that posts to the given [webhookUrl].
  ///
  /// [extraPayload] — optional map of additional top-level fields merged into
  /// the Slack Block Kit payload before each send. Intended for proxy setups
  /// that require routing or authentication fields alongside `blocks`.
  SlackErrorExporter(String webhookUrl, {Map<String, dynamic>? extraPayload})
    : super(
        webhookUrl,
        SlackPayloadFormatter(),
        payloadTransformer: extraPayload != null
            ? (payload) => {...payload, ...extraPayload}
            : null,
      );
}
