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
    afterEvaluate<Project> { project ->
        project.plugins.withId("com.android.application") {
            val android = project.extensions.getByType<com.android.build.api.dsl.ApplicationExtension>()
            android.compileSdk.set(30)
        }

        project.plugins.withId("com.android.library") {
            val android = project.extensions.getByType<com.android.build.api.dsl.LibraryExtension>()
            android.compileSdk.set(30)
            if (project.name == "cloudbase_ce") {
                android.namespace = "com.cloudbase.cloudbase_ce"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}