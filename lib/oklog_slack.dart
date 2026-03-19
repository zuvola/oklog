/// oklog Slack integration.
///
/// Import this library to use [SlackErrorExporter] and
/// [SlackPayloadFormatter] for sending error reports to a Slack channel
/// via an Incoming Webhook.
///
/// ```dart
/// import 'package:oklog/oklog.dart';
/// import 'package:oklog/oklog_slack.dart';
/// ```
library;

export 'src/integrations/slack/slack_payload_formatter.dart';
export 'src/integrations/slack/slack_error_exporter.dart';
