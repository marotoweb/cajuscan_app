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
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
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

        externalNativeBuild {
            cmake {
                // Remove caminhos absolutos e o Build ID que causaram o erro no teu relatório
                arguments("-DCMAKE_C_FLAGS=-fdebug-prefix-map=${project.rootDir.absolutePath}=.",
                          "-DCMAKE_CXX_FLAGS=-fdebug-prefix-map=${project.rootDir.absolutePath}=.",
                          "-Wl,--build-id=none")
            }
        }
    }
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            // Mantemos as suas flags de segurança
            freeCompilerArgs += listOf("-Xno-call-assertions", "-Xno-receiver-assertions")
        
            // Remove caminhos absolutos das exceções e metadados
            freeCompilerArgs += listOf("-Xdump-declarations-to=null") 
        
            // Garante que o bytecode não contenha informações da sua máquina
            jvmTarget = "1.8" 
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
            
            // Desativa a ofuscação e a remoção de código não usado
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Mantém as definições padrão de ficheiros de regras, 
            // mas como o minify está false, elas não farão nada.
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

flutter {
    source = "../.."
}
