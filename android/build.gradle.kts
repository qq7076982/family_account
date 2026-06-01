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
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.evaluationDependsOn(":app")
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.property("android")
            if (android is com.android.build.gradle.LibraryExtension) {
                if (android.namespace == null) {
                    val pkg = project.group?.toString() ?: ""
                    android.namespace = pkg.ifEmpty {
                        when (project.name) {
                            "cloudbase_ce" -> "com.cloudbase.cloudbase_ce"
                            "path_provider_android" -> "io.flutter.plugins.pathprovider"
                            "shared_preferences_android" -> "io.flutter.plugins.sharedpreferences"
                            else -> "auto.${project.name.replace("-", "_").replace(":", "_")}"
                        }
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}