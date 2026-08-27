pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    // do not use "includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")" it breaks gradle sync
    includeBuild(file("$flutterSdkPath/packages/flutter_tools/gradle").toPath().toRealPath().toAbsolutePath().toString())

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

buildscript {
    // Netty reaches this classpath only transitively, through the gRPC client used by AGP's
    // test and device tooling. AGP 8.13.1 resolves 4.1.110.Final, which predates the fixes in
    // 4.1.118.Final. Nothing here ends up in the application.
    configurations.classpath {
        resolutionStrategy.eachDependency {
            if (requested.group == "io.netty") {
                useVersion("4.1.118.Final")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.13.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
