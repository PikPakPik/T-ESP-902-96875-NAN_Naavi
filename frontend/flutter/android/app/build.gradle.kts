import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.eloi.naavitrails"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    flavorDimensions += "app"

    productFlavors {
        create("dev") {
            dimension = "app"
            resValue("string", "app_name", "Naavi [DEV]")
            // Pas de suffix : même package name pour dev et prod
        }

        create("prod") {
            dimension = "app"
            resValue("string", "app_name", "Naavi")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.eloi.naavitrails"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Configuration de signature pour les builds release
    signingConfigs {
        create("release") {
            var keystoreConfigured = false
            
            // Priorité 1: Vérifier si key.properties existe (pour build local)
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                
                val storeFileProp = keystoreProperties["storeFile"] as String?
                if (storeFileProp != null) {
                    // Résoudre le chemin depuis la racine du projet Android
                    val keystoreFile = rootProject.file(storeFileProp)
                    if (keystoreFile.exists()) {
                        keyAlias = keystoreProperties["keyAlias"] as String
                        keyPassword = keystoreProperties["keyPassword"] as String
                        storeFile = keystoreFile
                        storePassword = keystoreProperties["storePassword"] as String
                        keystoreConfigured = true
                    } else {
                        println("⚠️  Keystore file not found: ${keystoreFile.absolutePath}")
                    }
                }
            }
            
            // Priorité 2: Utiliser les variables d'environnement (pour CI/CD)
            if (!keystoreConfigured) {
                val keystorePath = System.getenv("KEYSTORE_PATH") ?: System.getenv("ANDROID_KEYSTORE_PATH")
                val keystorePassword = System.getenv("KEYSTORE_PASSWORD") ?: System.getenv("ANDROID_KEYSTORE_PASSWORD")
                val keyAliasEnv = System.getenv("KEY_ALIAS") ?: System.getenv("ANDROID_KEY_ALIAS")
                val keyPasswordEnv = System.getenv("KEY_PASSWORD") ?: System.getenv("ANDROID_KEY_PASSWORD")
                
                if (keystorePath != null && keystorePassword != null && keyAliasEnv != null && keyPasswordEnv != null) {
                    val keystoreFile = file(keystorePath)
                    if (keystoreFile.exists()) {
                        storeFile = keystoreFile
                        storePassword = keystorePassword
                        keyAlias = keyAliasEnv
                        keyPassword = keyPasswordEnv
                        keystoreConfigured = true
                    }
                }
            }
            
            // Si aucune configuration n'est trouvée, ne pas configurer de signature
            // Cela permettra à Gradle d'utiliser la configuration par défaut ou d'afficher une erreur claire
            if (!keystoreConfigured) {
                // Ne pas configurer de signature - Gradle utilisera la config par défaut
                // ou l'utilisateur devra configurer manuellement
            }
        }
    }

    buildTypes {
        release {
            // Utiliser la configuration de signature release seulement si elle est configurée
            val releaseSigningConfig = signingConfigs.findByName("release")
            if (releaseSigningConfig != null && releaseSigningConfig.storeFile != null) {
                signingConfig = releaseSigningConfig
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            // Enables debug mode for the debug build type.
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}
