plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.marotoweb.cajuscan_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.marotoweb.cajuscan_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Reproduciblity
    // Remove ficheiros que variam entre builds e quebram o hash SHA-256
    packaging {
        resources {
            excludes += "assets/dexopt/*"
            excludes += "META-INF/*.kotlin_module"
        }
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    val hasKeyProperties = keystorePropertiesFile.exists()
    if (hasKeyProperties) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        // Configuração de assinatura dinâmica
        create("release") {
            if (hasKeyProperties) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            // Só tenta assinar se as propriedades existirem, caso contrário usa debug
            signingConfig = if (hasKeyProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            // Otimização e conformidade FOSS:
            // activa R8/Proguard para remover código e recursos não utilizados (como o Play Core),
            // reduzindo o tamanho do APK e garantindo que bibliotecas bloqueadas sejam expurgadas.
            isMinifyEnabled = true 
            isShrinkResources = true
            
            // Regras de Proguard:
            // Define as regras de otimização padrão da Google e regras personalizadas do projeto.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }
}

// Foss compliance
// Bloqueia dependências proprietárias transitivas da Google
configurations.all {
    resolutionStrategy {
        force("dev.flutter:empty:1.0")
        eachDependency {
            if (requested.group == "com.google.android.play") {
                useTarget("dev.flutter:empty:1.0")
            }
        }
    }
}

// Deterministic Build
// Desativa tarefas que geram perfis binários inconsistentes (corrige classes.dex)
tasks.withType<org.gradle.api.Task>().configureEach {
    if (name.contains("ArtProfile", ignoreCase = true)) {
        enabled = false
    }
}

flutter {
    source = "../.."
}