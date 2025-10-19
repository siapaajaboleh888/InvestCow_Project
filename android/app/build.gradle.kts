plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.investcow"
    compileSdk = 36  // 👈 DIUBAH: Set ke 36 untuk plugin compatibility
    ndkVersion = "27.0.12077973"  // 👈 DIUBAH: Set ke 27 untuk plugin compatibility

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // 👈 DIUBAH: Ke 17 untuk SDK 36
        targetCompatibility = JavaVersion.VERSION_17  // 👈 DIUBAH: Ke 17 untuk SDK 36
    }

    kotlinOptions {
        jvmTarget = "17"  // 👈 DIUBAH: Ke 17 untuk SDK 36
    }

    defaultConfig {
        applicationId = "com.example.investcow"
        minSdk = flutter.minSdkVersion  // 👈 DIUBAH: Set eksplisit ke 21
        targetSdk = 36  // 👈 DIUBAH: Set ke 36 untuk plugin compatibility
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
