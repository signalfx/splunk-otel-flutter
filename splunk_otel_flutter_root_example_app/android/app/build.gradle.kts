plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.splunk.rum-okhttp3-auto-plugin") version "2.2.2"
    id("com.splunk.rum-httpurlconnection-auto-plugin") version "2.2.2"
}

// Either jetifier has to be disabled or bytebuddy version forced for network interception to work.
configurations
    .matching { it.name.contains("ByteBuddyClasspath", ignoreCase = true) }
    .all {
        resolutionStrategy {
            force("net.bytebuddy:byte-buddy:1.14.12")
        }
    }

android {
    namespace = "com.splunk.rum.flutter.root.exampleapp.root_example_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.splunk.rum.flutter.root.exampleapp.root_example_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24  // Required by splunk_otel_flutter library
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("com.splunk:rum-integration-agent-api:2.2.2")
    implementation("com.splunk:rum-integration-customtracking:2.2.2")
    implementation("com.splunk:rum-common-otel:2.2.2")
    implementation("com.splunk:rum-integration-okhttp3-manual:2.2.2")
    implementation("com.squareup.okhttp3:okhttp:4.11.0")
    implementation("com.squareup.okio:okio:3.4.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:runner:1.3.0")
    androidTestImplementation("androidx.test:rules:1.2.0")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.3.0")
}

flutter {
    source = "../.."
}
