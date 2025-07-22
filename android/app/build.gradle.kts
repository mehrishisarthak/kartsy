plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Firebase
    id("dev.flutter.flutter-gradle-plugin") // Flutter
}

android {
    namespace = "com.classified.ecommerce_shop"
    compileSdk = 35

    ndkVersion = "27.0.12077973" // ✅ Required by Firebase plugins

    defaultConfig {
        applicationId = "com.classified.ecommerce_shop"
        minSdk = 23 // ✅ Required for firebase-auth >= 23.2.0
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug") // ⚠️ For development only
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
