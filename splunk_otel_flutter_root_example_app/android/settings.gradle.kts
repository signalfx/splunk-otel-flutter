/*
 * Copyright 2026 Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

buildscript {
    // Netty reaches this classpath only transitively, through the gRPC client used by AGP's
    // test and device tooling. AGP 8.13.1 resolves 4.1.110.Final, which predates the fixes in
    // 4.1.138.Final. Nothing here ends up in the application.
    // Patch Guava here as well because example builds load AGP from the settings classpath.
    configurations.classpath {
        resolutionStrategy.eachDependency {
            if (requested.group == "io.netty") {
                useVersion("4.1.138.Final")
            }
            if (requested.group == "com.google.guava" && requested.name == "guava") {
                useVersion("33.7.2-jre")
                because("CVE-2026-102554")
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
