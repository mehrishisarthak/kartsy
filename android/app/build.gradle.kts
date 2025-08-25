plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Firebase
    id("dev.flutter.flutter-gradle-plugin") // Flutter
}

android {
    namespace = "com.classified.ecommerce_shop"
    compileSdk = 36 // <-- REQUIRED CHANGE: Updated from 35

    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.classified.ecommerce_shop"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // <-- BEST PRACTICE: Updated from 35 to match compileSdk
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
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}