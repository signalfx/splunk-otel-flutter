import 'package:flutter_test/flutter_test.dart';
import 'package:splunk_otel_flutter_platform_interface/src/implementation/splunk_otel_flutter_platform_implementation.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/agent_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/model/module_configuration.dart';
import 'package:splunk_otel_flutter_platform_interface/src/pigeon/messages.pigeon.dart';
import '../mock_splunk_otel_flutter_platform_interface_host_api.dart';
import '../pigeon/test_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Splunk OpenTelemetry Flutter Integration Tests', () {
    late SplunkOtelFlutterPlatformImplementation implementation;
    late MockSplunkOtelFlutterPlatformInterfaceHostApi mockApi;

    setUp(() {
      mockApi = MockSplunkOtelFlutterPlatformInterfaceHostApi();
      TestSplunkOtelFlutterHostApi.setUp(mockApi);
      implementation = SplunkOtelFlutterPlatformImplementation.instance;
    });

    tearDown(() {
      TestSplunkOtelFlutterHostApi.setUp(null);
    });

    group('Full Installation Flow', () {
      test('should complete full installation with all configurations', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'test-token-abc123',
          ),
          appName: 'IntegrationTestApp',
          deploymentEnvironment: 'production',
          appVersion: '1.0.0',
          enableDebugLogging: true,
          //TODO global attributes
          user: const UserConfiguration(
            trackingMode: UserTrackingMode.anonymousTracking,
          ),
          session: SessionConfiguration(samplingRate: 0.75),
          instrumentedProcessName: 'com.example.integration.test',
          deferredUntilForeground: true,
        );

        final navConfig = NavigationModuleConfiguration(
          isEnabled: true,
          isAutomatedTrackingEnabled: true,
        );

        final slowRenderingConfig = SlowRenderingModuleConfiguration(
          isEnabled: true,
          interval: const Duration(milliseconds: 1500),
        );

        bool installCalled = false;
        mockApi.installHandler = (genAgent, genNav, genSlow) async {
          installCalled = true;

          // Verify agent configuration
          expect(genAgent.appName, 'IntegrationTestApp');
          expect(genAgent.deploymentEnvironment, 'production');
          expect(genAgent.endpoint.realm, 'us0');
          expect(genAgent.endpoint.rumAccessToken, 'test-token-abc123');
          expect(genAgent.appVersion, '1.0.0');
          expect(genAgent.enableDebugLogging, true);
          expect(genAgent.user?.trackingMode,
              GeneratedUserTrackingMode.anonymousTracking);
          expect(genAgent.session?.samplingRate, 0.75);
          expect(genAgent.instrumentedProcessName, 'com.example.integration.test');
          expect(genAgent.deferredUntilForeground, true);

          // Verify navigation configuration
          expect(genNav.isEnabled, true);
          expect(genNav.isAutomatedTrackingEnabled, true);

          // Verify slow rendering configuration
          expect(genSlow.isEnabled, true);
          expect(genSlow.intervalMillis, 1500);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [navConfig, slowRenderingConfig],
        );

        // Assert
        expect(installCalled, true);
      });

      test('should handle minimal configuration installation', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'eu0',
            rumAccessToken: 'minimal-token',
          ),
          appName: 'MinimalApp',
          deploymentEnvironment: 'development',
        );

        bool installCalled = false;
        mockApi.installHandler = (genAgent, genNav, genSlow) async {
          installCalled = true;

          // Verify minimal agent config
          expect(genAgent.appName, 'MinimalApp');
          expect(genAgent.appVersion, isNull);
          expect(genAgent.enableDebugLogging, false);

          // Verify default module configs are used
          expect(genNav.isEnabled, true);
          expect(genNav.isAutomatedTrackingEnabled, false);
          expect(genSlow.isEnabled, true);
          expect(genSlow.intervalMillis, 1000);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [],
        );

        // Assert
        expect(installCalled, true);
      });

      test('should handle installation with only navigation module', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'NavOnlyApp',
          deploymentEnvironment: 'staging',
        );

        final navConfig = NavigationModuleConfiguration(
          isEnabled: false,
          isAutomatedTrackingEnabled: false,
        );

        mockApi.installHandler = (_, genNav, genSlow) async {
          expect(genNav.isEnabled, false);
          expect(genNav.isAutomatedTrackingEnabled, false);
          // Default slow rendering should still be used
          expect(genSlow.isEnabled, true);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [navConfig],
        );
      });

      test('should handle installation with only slow rendering module', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'SlowRenderApp',
          deploymentEnvironment: 'production',
        );

        final slowConfig = SlowRenderingModuleConfiguration(
          isEnabled: false,
          interval: const Duration(milliseconds: 250),
        );

        mockApi.installHandler = (_, genNav, genSlow) async {
          // Default navigation should be used
          expect(genNav.isEnabled, true);
          expect(genSlow.isEnabled, false);
          expect(genSlow.intervalMillis, 250);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [slowConfig],
        );
      });
    });

    group('Session Management Flow', () {
      test('should install then start session replay', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'SessionApp',
          deploymentEnvironment: 'production',
        );

        bool installCalled = false;
        bool sessionReplayCalled = false;

        mockApi.installHandler = (_, __, ___) async {
          installCalled = true;
        };

        mockApi.sessionReplayStartHandler = () async {
          sessionReplayCalled = true;
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [],
        );
        await implementation.sessionReplayStart();

        // Assert
        expect(installCalled, true);
        expect(sessionReplayCalled, true);
      });

      test('should install then retrieve session ID', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'SessionIdApp',
          deploymentEnvironment: 'production',
        );

        const expectedSessionId = 'session-integration-test-123';
        bool installCalled = false;

        mockApi.installHandler = (_, __, ___) async {
          installCalled = true;
        };

        mockApi.getSessionIdHandler = () async => expectedSessionId;

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [],
        );
        final sessionId = await implementation.sessionStateGetId();

        // Assert
        expect(installCalled, true);
        expect(sessionId, expectedSessionId);
      });

      test('should handle complete session workflow', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'workflow-token',
          ),
          appName: 'WorkflowApp',
          deploymentEnvironment: 'production',
          session: SessionConfiguration(samplingRate: 1.0),
        );

        const sessionId = 'workflow-session-abc';
        final callOrder = <String>[];

        mockApi.installHandler = (_, __, ___) async {
          callOrder.add('install');
        };

        mockApi.sessionReplayStartHandler = () async {
          callOrder.add('sessionReplay');
        };

        mockApi.getSessionIdHandler = () async {
          callOrder.add('getSessionId');
          return sessionId;
        };

        // Act - Complete workflow
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [],
        );
        await implementation.sessionReplayStart();
        final retrievedSessionId = await implementation.sessionStateGetId();

        // Assert
        expect(callOrder, ['install', 'sessionReplay', 'getSessionId']);
        expect(retrievedSessionId, sessionId);
      });
    });

    group('Configuration Validation Integration', () {
      test('should reject invalid sampling rate during installation', () async {
        // Arrange & Assert
        expect(
              () => AgentConfiguration(
            endpoint: EndpointConfiguration.forRum(
              realm: 'us0',
              rumAccessToken: 'token',
            ),
            appName: 'InvalidApp',
            deploymentEnvironment: 'test',
            session: SessionConfiguration(samplingRate: 1.5),
          ),
          throwsArgumentError,
        );
      });

      test('should handle edge case sampling rates correctly', () async {
        // Test 0.0
        final config0 = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'App',
          deploymentEnvironment: 'test',
          session: SessionConfiguration(samplingRate: 0.0),
        );

        mockApi.installHandler = (genAgent, _, __) async {
          expect(genAgent.session?.samplingRate, 0.0);
        };

        await implementation.install(
          agentConfiguration: config0,
          moduleConfigurations: [],
        );

        // Test 1.0
        final config1 = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'App',
          deploymentEnvironment: 'test',
          session: SessionConfiguration(samplingRate: 1.0),
        );

        mockApi.installHandler = (genAgent, _, __) async {
          expect(genAgent.session?.samplingRate, 1.0);
        };

        await implementation.install(
          agentConfiguration: config1,
          moduleConfigurations: [],
        );
      });
    });

    group('User Tracking Mode Integration', () {
      test('should handle user tracking mode transitions', () async {
        // Test noTracking
        final configNoTracking = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'TrackingApp',
          deploymentEnvironment: 'test',
          user: const UserConfiguration(
            trackingMode: UserTrackingMode.noTracking,
          ),
        );

        mockApi.installHandler = (genAgent, _, __) async {
          expect(genAgent.user?.trackingMode,
              GeneratedUserTrackingMode.noTracking);
        };

        await implementation.install(
          agentConfiguration: configNoTracking,
          moduleConfigurations: [],
        );

        // Test anonymousTracking
        final configAnonymous = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'TrackingApp',
          deploymentEnvironment: 'test',
          user: const UserConfiguration(
            trackingMode: UserTrackingMode.anonymousTracking,
          ),
        );

        mockApi.installHandler = (genAgent, _, __) async {
          expect(genAgent.user?.trackingMode,
              GeneratedUserTrackingMode.anonymousTracking);
        };

        await implementation.install(
          agentConfiguration: configAnonymous,
          moduleConfigurations: [],
        );

        // Test defaultTracking
        final configDefault = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'TrackingApp',
          deploymentEnvironment: 'test',
        );

        mockApi.installHandler = (genAgent, _, __) async {
          expect(genAgent.user?.trackingMode,
              GeneratedUserTrackingMode.noTracking);
        };

        await implementation.install(
          agentConfiguration: configDefault,
          moduleConfigurations: [],
        );
      });
    });


    group('Module Configuration Priority', () {
      test('should use first module configuration when duplicates exist', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'DuplicateModulesApp',
          deploymentEnvironment: 'test',
        );

        final navConfig1 = NavigationModuleConfiguration(
          isEnabled: true,
          isAutomatedTrackingEnabled: true,
        );

        final navConfig2 = NavigationModuleConfiguration(
          isEnabled: false,
          isAutomatedTrackingEnabled: false,
        );

        mockApi.installHandler = (_, genNav, __) async {
          // Should use first one (navConfig1)
          expect(genNav.isEnabled, true);
          expect(genNav.isAutomatedTrackingEnabled, true);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [navConfig1, navConfig2],
        );
      });
    });

    group('Android-Specific Configuration', () {
      test('should handle Android-specific options correctly', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'android-token',
          ),
          appName: 'AndroidApp',
          deploymentEnvironment: 'production',
          instrumentedProcessName: 'com.example.android.app',
          deferredUntilForeground: true,
        );

        mockApi.installHandler = (genAgent, _, __) async {
          expect(genAgent.instrumentedProcessName, 'com.example.android.app');
          expect(genAgent.deferredUntilForeground, true);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [],
        );
      });

      test('should handle null Android-specific options', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'CrossPlatformApp',
          deploymentEnvironment: 'production',
          instrumentedProcessName: null,
          deferredUntilForeground: false,
        );

        mockApi.installHandler = (genAgent, _, __) async {
          expect(genAgent.instrumentedProcessName, isNull);
          expect(genAgent.deferredUntilForeground, false);
        };

        // Act
        await implementation.install(
          agentConfiguration: agentConfig,
          moduleConfigurations: [],
        );
      });
    });

    group('Duration Conversion Integration', () {
      test('should correctly convert various duration formats', () async {
        // Arrange
        final testCases = [
          (Duration.zero, 0),
          (const Duration(milliseconds: 100), 100),
          (const Duration(seconds: 1), 1000),
          (const Duration(seconds: 1, milliseconds: 500), 1500),
          (const Duration(minutes: 1), 60000),
        ];

        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'DurationApp',
          deploymentEnvironment: 'test',
        );

        for (final (duration, expectedMillis) in testCases) {
          final slowConfig = SlowRenderingModuleConfiguration(
            interval: duration,
          );

          mockApi.installHandler = (_, __, genSlow) async {
            expect(genSlow.intervalMillis, expectedMillis);
          };

          await implementation.install(
            agentConfiguration: agentConfig,
            moduleConfigurations: [slowConfig],
          );
        }
      });
    });

    group('Error Handling', () {
      test('should propagate platform errors during installation', () async {
        // Arrange
        final agentConfig = AgentConfiguration(
          endpoint: EndpointConfiguration.forRum(
            realm: 'us0',
            rumAccessToken: 'token',
          ),
          appName: 'ErrorApp',
          deploymentEnvironment: 'test',
        );

        mockApi.installHandler = (_, __, ___) async {
          throw Exception('Platform installation failed');
        };

        // Act & Assert
        expect(
              () => implementation.install(
            agentConfiguration: agentConfig,
            moduleConfigurations: [],
          ),
          throwsException,
        );
      });

      test('should propagate errors during session replay start', () async {
        // Arrange
        mockApi.sessionReplayStartHandler = () async {
          throw Exception('Session replay failed');
        };

        // Act & Assert
        expect(
              () => implementation.sessionReplayStart(),
          throwsException,
        );
      });

      test('should propagate errors during getSessionId', () async {
        // Arrange
        mockApi.getSessionIdHandler = () async {
          throw Exception('Failed to get session ID');
        };

        // Act & Assert
        expect(
              () => implementation.sessionStateGetId(),
          throwsException,
        );
      });
    });
  });
}

