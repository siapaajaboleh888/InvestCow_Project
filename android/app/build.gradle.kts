import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.investcow.app"
    compileSdk = 35  // 👈 DIUBAH: Set ke 35 untuk stabilitas plugin
    ndkVersion = "27.0.12077973"  // 👈 DIUBAH: Set ke 27 untuk plugin compatibility

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // 👈 DIUBAH: Ke 17 untuk SDK 36
        targetCompatibility = JavaVersion.VERSION_17  // 👈 DIUBAH: Ke 17 untuk SDK 36
    }

    kotlinOptions {
        jvmTarget = "17"  // 👈 DIUBAH: Ke 17 untuk SDK 36
    }

    defaultConfig {
        applicationId = "com.investcow.app"
        minSdk = flutter.minSdkVersion  // 👈 DIUBAH: Set eksplisit ke 21
        targetSdk = 35  // 👈 DIUBAH: Set ke 35 untuk stabilitas plugin
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
