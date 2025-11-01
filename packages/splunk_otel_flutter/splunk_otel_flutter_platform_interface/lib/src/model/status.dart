import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';

enum Status {
  running,
  notInstalled,
  subProcess,
  sampledOut,
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
        return GeneratedStatus.sampledOut;
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
      case GeneratedStatus.unsupportedOsVersion:
        return Status.unsupportedOsVersion;
    }
  }
}

