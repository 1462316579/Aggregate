group = "com.aaassseee.screen_brightness_android"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "1.9.20"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.aaassseee.screen_brightness_android"
    compileSdk = 33
    defaultConfig {
        minSdk = 21
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
}
