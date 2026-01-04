buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}

// ✅ 'telephony' এবং অন্যান্য প্লাগইনের Namespace এরর ফিক্স করার নতুন পদ্ধতি
subprojects {
    // afterEvaluate এর বদলে সরাসরি কনফিগারেশন চেক
    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.BasePlugin) {
            project.extensions.getByType(com.android.build.gradle.BaseExtension::class.java).apply {
                if (namespace == null) {
                    namespace = project.group.toString()
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}