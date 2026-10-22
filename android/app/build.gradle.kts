plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.salon.salon_app_view"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.salon.salon_app_view"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Opt-in, app-scoped debug key. If `android/app/debug.keystore` exists it is
    // used for debug (and for the debug-signed release build) instead of the
    // machine-wide ~/.android/debug.keystore. This lets you register a fresh,
    // never-used SHA-1 in Google Cloud without disturbing every other Android
    // project on this machine. Create it with:
    //   bash tool/new_project_debug_keystore.sh --yes
    // The file is gitignored (*.keystore), so it never leaves this checkout.
    signingConfigs {
        val projectDebugKey = file("debug.keystore")
        if (projectDebugKey.exists()) {
            create("projectDebug") {
                storeFile = projectDebugKey
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        // When a project-local key exists, use it for debug too so the
        // installed APK, `flutter run`, and `flutter run --release` all share
        // the same registered SHA-1.
        getByName("debug") {
            signingConfigs.findByName("projectDebug")?.let { signingConfig = it }
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.findByName("projectDebug")
                ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
