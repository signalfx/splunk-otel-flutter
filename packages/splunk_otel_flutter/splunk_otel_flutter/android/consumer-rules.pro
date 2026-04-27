# Rules shipped with the splunk_otel_flutter plugin and automatically applied
# to any consumer app (via `consumerProguardFiles` in build.gradle).
#
# The OpenTelemetry Java SDK (pulled in transitively by the Splunk RUM Android
# SDK) references compile-time only annotations that are not present on the
# runtime classpath. Without these rules R8 fails consumer release builds with
# "Missing class" errors.

# Google AutoValue -- compile-time annotations used by OpenTelemetry.
-dontwarn com.google.auto.value.AutoValue
-dontwarn com.google.auto.value.AutoValue$Builder
-dontwarn com.google.auto.value.AutoValue$CopyAnnotations
-dontwarn com.google.auto.value.extension.memoized.Memoized
-dontwarn com.google.auto.value.**

# Error Prone annotations -- compile-time only.
-dontwarn com.google.errorprone.annotations.**

# Jackson core is an optional compile-time dependency of io.opentelemetry.exporter.
-dontwarn com.fasterxml.jackson.core.JsonGenerator
-dontwarn com.fasterxml.jackson.core.JsonFactory
-dontwarn com.fasterxml.jackson.core.**

# JSR-305 / javax.annotation placeholders referenced by several Google libs.
-dontwarn javax.annotation.**
