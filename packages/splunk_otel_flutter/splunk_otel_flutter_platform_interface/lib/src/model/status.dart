import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

enum Status {
  running,
  /// The agent has not been installed.
  notInstalled,
  /// Android only
  subProcess,
  ///  The agent is not running because of being sampled out locally.
  sampledOut,
  /// The platform is not supported by Agent.
  unsupportedPlatform,
  /// The operating system is not supported for this version.
  unsupportedOsVersion,
}

extension StatusExtension on Status {
  GeneratedStatus toGeneratedStatus() {
    switch (this) {
      case Status.running:
        return GeneratedStatus.running;
      case Status.notInstalled:
        return GeneratedStatus.notInstalled;
      case Status.subProcess:
        return GeneratedStatus.subProcess;
      case Status.sampledOut:
        return GeneratedStatus.unsupportedPlatform;
      case Status.unsupportedPlatform:
        return GeneratedStatus.unsupportedOsVersion;
      case Status.unsupportedOsVersion:
        return GeneratedStatus.unsupportedOsVersion;
    }
  }
}

extension GeneratedStatusExtension on GeneratedStatus {
  Status toStatus() {
    switch (this) {
      case GeneratedStatus.running:
        return Status.running;
      case GeneratedStatus.notInstalled:
        return Status.notInstalled;
      case GeneratedStatus.subProcess:
        return Status.subProcess;
      case GeneratedStatus.sampledOut:
        return Status.sampledOut;
      case GeneratedStatus.unsupportedPlatform:
        return Status.unsupportedPlatform;
      case GeneratedStatus.unsupportedOsVersion:
        return Status.unsupportedOsVersion;
    }
  }
}

