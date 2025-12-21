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
    
    
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core-ktx:1.15.0")
            force("androidx.core:core:1.15.0")
            force("androidx.browser:browser:1.8.0")
        }
    }

    defaultConfig {
        applicationId = "com.classified.ecommerce_shop"
        minSdkVersion(24)
        targetSdkVersion(36)
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
