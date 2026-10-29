import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.agridigitale.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.agridigitale.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Force image_picker à utiliser le Photo Picker natif Android (exigé par Google Play)
        // Désactive l'accès large à la galerie, utilise ActivityResultContracts.PickVisualMedia
        manifestPlaceholders["useAndroidXPhotoPickerForImagePicker"] = "true"
        resValue("bool", "use_android_x_photo_picker", "true")
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Supprime les permissions interdites par Google Play AVANT compilation binaire
afterEvaluate {
    android.applicationVariants.configureEach {
        val variantName = name.replaceFirstChar { it.uppercase() }
        val mergeTask = tasks.findByName("merge${variantName}Resources")
        val manifestTask = tasks.findByName("process${variantName}MainManifest")
            ?: tasks.findByName("process${variantName}Manifest")

        manifestTask?.doLast {
            val dirs = listOf(
                "intermediates/merged_manifest/${name}/process${variantName}MainManifest",
                "intermediates/merged_manifest/${name}/process${variantName}Manifest",
                "intermediates/merged_manifest/${name}"
            )
            val permissionsToRemove = listOf(
                "android.permission.READ_MEDIA_IMAGES",
                "android.permission.READ_MEDIA_VIDEO",
                "android.permission.READ_EXTERNAL_STORAGE",
                "android.permission.WRITE_EXTERNAL_STORAGE"
            )
            dirs.forEach { dir ->
                val manifestFile = File(buildDir, "$dir/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    var content = manifestFile.readText()
                    permissionsToRemove.forEach { perm ->
                        content = content.replace(
                            Regex("[ \t]*<uses-permission[^/]*/?>?[\r\n]*".toRegex().pattern +
                                "(?=.*${Regex.escape(perm)})", RegexOption.DOT_MATCHES_ALL), ""
                        )
                        content = content.replace(
                            Regex("\\s*<uses-permission\\s+android:name=\"${Regex.escape(perm)}\"\\s*/>"), ""
                        )
                    }
                    manifestFile.writeText(content)
                    println("[AgriDigitale] Manifest nettoyé : $manifestFile")
                }
            }
        }
    }
}
