plugins {
    id("com.android.application")
    id("kotlin-android")
    // O Flutter Gradle Plugin deve ser aplicado depois dos plugins do Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.monitor_viveiro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.monitor_viveiro"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // *** A CORREÇÃO IMPORTANTE (Multidex) ***
        // Habilita o suporte para Multidex (Sintaxe KTS correta)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            
            // *** REMOVIDO ***
            // As linhas 'isMinifyEnabled' e 'isShrinkResources' foram removidas.
            // O Flutter gere isto automaticamente ao correr 'flutter build apk --release'.
            // Adicioná-las aqui estava a causar o erro de build.
        }
    }
}

flutter {
    source = "../.."
}

// *** A CORREÇÃO IMPORTANTE (Multidex) ***
// Adiciona a dependência do Multidex (Sintaxe KTS correta)
dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}