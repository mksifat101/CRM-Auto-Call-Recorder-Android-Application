import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin টি অবশ্যই থাকতে হবে
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // আপনার প্যাকেজ নামের সাথে এটি মিল থাকতে হবে
    namespace = "com.example.android_app" 
    
    // telephony প্যাকেজের জন্য ৩৩ বা ৩৪ ব্যবহার করা ভালো
    compileSdk = 36

    // NDK এরর এড়াতে ডাইনামিক ভার্সন ব্যবহার করুন
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // Modern Java features (java.time) ব্যবহারের জন্য এটি প্রয়োজন
        isCoreLibraryDesugaringEnabled = true 
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.android_app"
        
        // telephony প্যাকেজের জন্য ২১ বা তার বেশি হতে হয়
        minSdk = flutter.minSdkVersion 
        targetSdk = 36
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        getByName("release") {
            // প্রোডাকশনে কোড ছোট করার জন্য এটি ট্রু করা যায়, তবে এখন ফলস রাখাই নিরাপদ
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Kotlin standard library
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.22")
    
    // telephony এবং notification প্লাগইনের জন্য প্রয়োজনীয় desugaring library
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
