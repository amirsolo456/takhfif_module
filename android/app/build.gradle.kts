plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.takhfif_module"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "30.0.15729638"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.takhfif_module"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a", "x86_64"))
        }
    }

    signingConfigs {
        val ciKeystorePath = System.getenv("CI_KEYSTORE_PATH")
        val ciStorePassword = System.getenv("CI_KEYSTORE_PASSWORD")
        val ciKeyAlias = System.getenv("CI_KEY_ALIAS")
        val ciKeyPassword = System.getenv("CI_KEY_PASSWORD")

        if (!ciKeystorePath.isNullOrBlank() && !ciStorePassword.isNullOrBlank() &&
            !ciKeyAlias.isNullOrBlank() && !ciKeyPassword.isNullOrBlank()) {
            create("ciRelease") {
                storeFile = file(ciKeystorePath)
                storePassword = ciStorePassword
                keyAlias = ciKeyAlias
                keyPassword = ciKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // CI uses a temporary Linux-local signing key so the build never depends
            // on a developer's Windows C:\Users\... debug keystore path.
            signingConfig = if (!System.getenv("CI_KEYSTORE_PATH").isNullOrBlank()) {
                signingConfigs.getByName("ciRelease")
            } else {
                signingConfigs.getByName("debug")
            }
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
