# Rules shipped with the splunk_otel_flutter_session_replay plugin and
# automatically applied to any consumer app (via `consumerProguardFiles`
# in build.gradle).
#
# The session replay native SDK shares the OpenTelemetry Java stack with
# the main Splunk RUM SDK, so the same compile-time annotation warnings
# need to be silenced.

#compile-time annotation
-dontwarn com.google.auto.value.AutoValue
-dontwarn com.google.auto.value.AutoValue$Builder
-dontwarn com.google.auto.value.AutoValue$CopyAnnotations
-dontwarn com.google.auto.value.extension.memoized.Memoized

#compile-time dependency in io.opentelemetry.exporter
-dontwarn com.fasterxml.jackson.core.JsonGenerator
-dontwarn com.fasterxml.jackson.core.JsonFactory