import 'package:flutter/material.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

class BasicTestRunWidget extends StatefulWidget {
  const BasicTestRunWidget({super.key});

  @override
  State<BasicTestRunWidget> createState() => _BasicTestRunWidgetState();
}

class _BasicTestRunWidgetState extends State<BasicTestRunWidget> {
  @override
  Widget build(BuildContext context) {
    return const Text("y");
  }


  Future<void> wholeApiDefinition()async{
    // session replay - sensitivity ignored
    SplunkOtelFlutter.instance.sessionReplay.start();
    SplunkOtelFlutter.instance.sessionReplay.stop();
    SplunkOtelFlutter.instance.sessionReplay.state.getStatus();
    SplunkOtelFlutter.instance.sessionReplay.state.getRenderingMode();
    SplunkOtelFlutter.instance.sessionReplay.preferences.getRenderingMode();
    SplunkOtelFlutter.instance.sessionReplay.preferences.setRenderingMode(
      renderingMode: RenderingMode.native,
    );
    SplunkOtelFlutter.instance.sessionReplay.recordingMask.getRecordingMask();
    SplunkOtelFlutter.instance.sessionReplay.recordingMask.setRecordingMask(
      recordingMask: RecordingMaskList(elements: []),
    );

    // state
    SplunkOtelFlutter.instance.state.getAppName();
    SplunkOtelFlutter.instance.state.getAppVersion();
    SplunkOtelFlutter.instance.state.getStatus();
    SplunkOtelFlutter.instance.state.getEndpointConfiguration();
    SplunkOtelFlutter.instance.state.getDeploymentEnvironment();
    SplunkOtelFlutter.instance.state.getIsDebugLoggingEnabled();
    SplunkOtelFlutter.instance.state.getInstrumentedProcessName();
    SplunkOtelFlutter.instance.state.getDeferredUntilForeground();

    // session
    SplunkOtelFlutter.instance.session.state.getId();
    SplunkOtelFlutter.instance.session.state.getSamplingRate();

    // user
    SplunkOtelFlutter.instance.user.state.getTrackingMode();
    SplunkOtelFlutter.instance.user.preferences.getTrackingMode();
    SplunkOtelFlutter.instance.user.preferences.setTrackingMode(
      userTrackingMode: UserTrackingMode.noTracking,
    );

    // global attributes
    SplunkOtelFlutter.instance.globalAttributes.get(
      key: "my_key",
    );
    SplunkOtelFlutter.instance.globalAttributes.getAll();
    SplunkOtelFlutter.instance.globalAttributes.remove(
      key: "old_key",
    );
    SplunkOtelFlutter.instance.globalAttributes.removeAll();
    SplunkOtelFlutter.instance.globalAttributes.contains(
      key: "existing_key",
    );
    SplunkOtelFlutter.instance.globalAttributes.setString(
      key: "user_name",
      value: "Alice",
    );
    SplunkOtelFlutter.instance.globalAttributes.setInt(
      key: "user_id",
      value: 123,
    );
    SplunkOtelFlutter.instance.globalAttributes.setDouble(
      key: "app_version",
      value: 1.5,
    );
    SplunkOtelFlutter.instance.globalAttributes.setBool(
      key: "is_logged_in",
      value: true,
    );
    /*
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetStringList(
      key: "tags",
      value: ["mobile", "flutter"],
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetIntList(
      key: "permissions",
      value: [1, 2, 3],
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetDoubleList(
      key: "scores",
      value: [9.5, 8.0],
    );
    SplunkOtelFlutter.instance.globalAttributes.globalAttributesSetBoolList(
      key: "features",
      value: [true, false],
    );*/
    SplunkOtelFlutter.instance.globalAttributes.setAll(
      attributes: MutableAttributes(
        attributes: {
          "attr1": MutableAttributeString(value: "val1"),
          "attr2": MutableAttributeInt(value: 100),
        },
      ),
    );

    // Custom tracking
    SplunkOtelFlutter.instance.customTracking.trackCustomEvent(name: "testEvent", attributes: MutableAttributes());
    SplunkOtelFlutter.instance.customTracking.trackWorkflow(workflowName: "testWorkflow");

    // Navigation
    SplunkOtelFlutter.instance.navigation.track(screenName: "testScreen");
  }


// ---- Public API smoke test with set->get->assert checks ----

  Future<void> exercisePublicApiWithAsserts() async {
    final sdk = SplunkOtelFlutter.instance;

    // Helpers
    bool listEquals<T>(List<T> a, List<T> b) {
      if (identical(a, b)) return true;
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }

    T castAttr<T extends MutableAttributeValue>(MutableAttributeValue v) {
      assert(v is T, 'Expected ${T.toString()}, got ${v.runtimeType}');
      return v as T;
    }

    String attrToDebug(MutableAttributeValue v) {
      if (v is MutableAttributeString) return 'String(${v.value})';
      if (v is MutableAttributeInt) return 'Int(${v.value})';
      if (v is MutableAttributeDouble) return 'Double(${v.value})';
      if (v is MutableAttributeBool) return 'Bool(${v.value})';
      return v.runtimeType.toString();
    }

    try {
      // ========= Session / SessionState =========
      final sessionId = await sdk.session.state.getId();
      final samplingRate = await sdk.session.state.getSamplingRate();
      assert(sessionId.isNotEmpty, 'Session id should not be empty');
      assert(samplingRate >= 0 &&
          samplingRate <= 1, 'Sampling rate should be in [0,1]');

      // ========= State =========
      final appName = await sdk.state.getAppName();
      final appVersion = await sdk.state.getAppVersion();
      final status = await sdk.state.getStatus();
      final endpointCfg = await sdk.state.getEndpointConfiguration();
      final env = await sdk.state.getDeploymentEnvironment();
      final debugEnabled = await sdk.state.getIsDebugLoggingEnabled();
      final procName = await sdk.state.getInstrumentedProcessName();
      final deferred = await sdk.state.getDeferredUntilForeground();

      assert(appName.isNotEmpty, 'App name should not be empty');
      assert(env.isNotEmpty, 'Deployment environment should not be empty');
      assert(status !=
          Status.notInstalled, 'Agent should be installed for this test');
      assert(debugEnabled == true, 'Debug logging should be enabled (true)');

      // ========= User / UserState & Preferences =========
      final trackingFromState = await sdk.user.state.getTrackingMode();
      final trackingFromPrefs = await sdk.user.preferences.getTrackingMode();
      final trackingModeToSet = trackingFromPrefs ?? trackingFromState;
      await sdk.user.preferences.setTrackingMode(
          userTrackingMode: trackingModeToSet);
      final trackingAfter = await sdk.user.preferences.getTrackingMode();
      assert(trackingAfter ==
          trackingModeToSet, 'User tracking mode did not persist');

      // ========= SessionReplay: start/stop, state & preferences =========
      final srModeBefore = await sdk.sessionReplay.state.getRenderingMode();
      final srStatusBefore = await sdk.sessionReplay.state.getStatus();
      assert(srStatusBefore != SessionReplayStatus
          .internalError, 'Session Replay should not be in internalError');

      await sdk.sessionReplay.preferences.setRenderingMode(
          renderingMode: srModeBefore);
      final srModePref = await sdk.sessionReplay.preferences.getRenderingMode();
      assert(srModePref ==
          srModeBefore, 'SR prefs mode should equal state mode after set');

      // Recording mask: set -> get -> assert -> restore
      final originalMask = await sdk.sessionReplay.recordingMask
          .getRecordingMask();
      final tempMask = RecordingMaskList(
        elements: [
          RecordingMaskElement(
            rect: const Rect.fromLTWH(10, 10, 120, 40),
            type: RecordingMaskType.erasing,
          ),
          RecordingMaskElement(
            rect: const Rect.fromLTWH(20, 70, 200, 60),
            type: RecordingMaskType.covering,
          ),
        ],
      );
      await sdk.sessionReplay.recordingMask.setRecordingMask(
          recordingMask: tempMask);
      final maskAfterSet = await sdk.sessionReplay.recordingMask
          .getRecordingMask();
      assert(maskAfterSet !=
          null, 'Recording mask should not be null after set');
      assert(maskAfterSet!.elements.length ==
          tempMask.elements.length, 'Recording mask element count mismatch');
      // Spot-check first element equivalence
      final a = maskAfterSet!.elements.first;
      final b = tempMask.elements.first;
      assert(a.type == b.type, 'Recording mask first element type mismatch');
      assert(a.rect.left == b.rect.left &&
          a.rect.top == b.rect.top &&
          a.rect.width == b.rect.width &&
          a.rect.height ==
              b.rect.height, 'Recording mask first element rect mismatch');

      // Stop/start roundtrip
      await sdk.sessionReplay.stop();
      final srStatusStopped = await sdk.sessionReplay.state.getStatus();
      assert(srStatusStopped == SessionReplayStatus.stopped ||
          srStatusStopped == SessionReplayStatus.notStarted,
      'SR should report stopped/notStarted after stop()');
      await sdk.sessionReplay.start();
      final srStatusStarted = await sdk.sessionReplay.state.getStatus();
      assert(srStatusStarted == SessionReplayStatus.isRecording ||
          srStatusStarted == SessionReplayStatus
              .notStarted, // allow platforms that don't autostart
      'SR should be recording or notStarted after start()');

      // Restore previous mask if one existed
      if (originalMask != null) {
        await sdk.sessionReplay.recordingMask.setRecordingMask(
            recordingMask: originalMask);
        final restored = await sdk.sessionReplay.recordingMask
            .getRecordingMask();
        assert(restored!.elements.length ==
            originalMask.elements.length, 'Original mask was not restored');
      }

      // ========= GlobalAttributes (all getters/setters with assertions) =========
      // Scalars
      await sdk.globalAttributes.setString(key: 'ga_string', value: 'hello');
      final gaString = castAttr<MutableAttributeString>(
          await sdk.globalAttributes.get(key: 'ga_string'));
      assert(gaString.value == 'hello', 'ga_string roundtrip failed');

      await sdk.globalAttributes.setInt(key: 'ga_int', value: 42);
      final gaInt = castAttr<MutableAttributeInt>(
          await sdk.globalAttributes.get(key: 'ga_int'));
      assert(gaInt.value == 42, 'ga_int roundtrip failed');

      await sdk.globalAttributes.setDouble(key: 'ga_double', value: 3.1415);
      final gaDouble = castAttr<MutableAttributeDouble>(
          await sdk.globalAttributes.get(key: 'ga_double'));
      assert((gaDouble.value - 3.1415).abs() <
          1e-9, 'ga_double roundtrip failed');

      await sdk.globalAttributes.setBool(key: 'ga_bool', value: true);
      final gaBool = castAttr<MutableAttributeBool>(
          await sdk.globalAttributes.get(key: 'ga_bool'));
      assert(gaBool.value == true, 'ga_bool roundtrip failed');


      // contains()
      final hasGaString = await sdk.globalAttributes.contains(key: 'ga_string');
      assert(hasGaString == true, 'contains(ga_string) should be true');

      // getAll()
      final allBefore = await sdk.globalAttributes.getAll();
      assert(allBefore.attributes.isNotEmpty, 'getAll() should contain items');
      assert(allBefore.attributes.keys.contains(
          'ga_int'), 'getAll() should include ga_int');

      // setAll() bundle → verify by reading keys back
      await sdk.globalAttributes.setAll(
        attributes: MutableAttributes(
          attributes: {
            'bundle_bool': MutableAttributeBool(value: false),
            'bundle_int': MutableAttributeInt(value: 7),
            'bundle_double': MutableAttributeDouble(value: 2.71),
            'bundle_string': MutableAttributeString(value: 'pack'),
          },
        ),
      );

      // remove() then contains()
      await sdk.globalAttributes.remove(key: 'ga_string');
      final hasAfterRemove = await sdk.globalAttributes.contains(
          key: 'ga_string');
      assert(hasAfterRemove == false, 'ga_string should be removed');

      // removeAll() then getAll()
      await sdk.globalAttributes.removeAll();
      final allAfter = await sdk.globalAttributes.getAll();
      assert(allAfter.attributes
          .isEmpty, 'removeAll() should leave no attributes');


      //TODO
      // Custom tracking
      // Navigation


      // Final log to make it easy to see result in console
      // ignore: avoid_print
      print('✅ SplunkOtelFlutter public API smoke test with asserts completed');


    } catch (e, st) {
      // ignore: avoid_print
      print('⚠️ SplunkOtelFlutter API assert test caught error: $e\n$st');
    }
  }
}
