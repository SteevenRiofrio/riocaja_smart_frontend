plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.riocaja_smart"
    compileSdk = 34  // ✅ CAMBIO DE 36 A 34 - MÁS COMPATIBLE
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.riocaja_smart"
        minSdk = 21  // ✅ FORZAMOS minSdk 21 EN LUGAR DE flutter.minSdkVersion
        targetSdk = 34  // ✅ CAMBIO DE 36 A 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ✅ DESHABILITAMOS MINIFY PARA EVITAR ERRORES ML KIT
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}