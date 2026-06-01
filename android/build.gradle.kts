import java.util.Properties

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Map of known missing-namespace packages
val knownNamespaces = mapOf(
    "cloudbase_ce" to "com.cloudbase.cloudbase_ce",
    "jni" to "com.github.dart_lang.jni",
    "flutter_local_notifications" to "com.dexterous.flutterlocalnotifications",
    "sqflite_android" to "com.tekartik.sqflite",
    "shared_preferences_android" to "io.flutter.plugins.sharedpreferences",
    "path_provider_android" to "io.flutter.plugins.pathprovider"
)

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.property("android")
            if (android is com.android.build.gradle.LibraryExtension) {
                if (android.namespace == null) {
                    android.namespace = knownNamespaces[project.name]
                        ?: project.group?.toString()
                        ?: "auto.${project.name.replace("-", "_")}"
                    println("[family_account] Set namespace '${android.namespace}' for ${project.name}")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}