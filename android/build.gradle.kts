import java.io.File

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
    beforeEvaluate { proj ->
        if (proj.name == "app") return@beforeEvaluate

        val androidDir = proj.projectDir.resolve("android")
        val buildFile = androidDir.resolve("build.gradle")
        val manifestFile = androidDir.resolve("src/main/AndroidManifest.xml")

        if (!buildFile.exists()) return@beforeEvaluate

        val buildContent = buildFile.readText()

        // 1) Inject namespace if missing
        if (!buildContent.contains("namespace") && manifestFile.exists()) {
            val manifest = manifestFile.readText()
            val packageMatcher = Regex("""package="([^"]+)"""").find(manifest)
            val packageName = packageMatcher?.groupValues?.get(1)
            if (!packageName.isNullOrEmpty()) {
                val patched = buildContent.replaceAfterLast(
                    "android {",
                    "android {\n    namespace '$packageName'"
                )
                buildFile.writeText(patched)
                println("[family_account] Injected namespace '$packageName' into ${proj.name}")
            }
        }

        // 2) Upgrade compileSdkVersion if too low
        val sdkMatcher = Regex("""compileSdkVersion\s+(\d+)""").find(buildContent)
        if (sdkMatcher != null) {
            val currentSdk = sdkMatcher.groupValues[1].toIntOrNull() ?: 0
            if (currentSdk < 30) {
                val patched = buildContent.replace(
                    "compileSdkVersion $currentSdk",
                    "compileSdkVersion 30"
                )
                buildFile.writeText(patched)
                println("[family_account] Upgraded compileSdkVersion $currentSdk→30 in ${proj.name}")
            }
        }
    }

    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.property("android")
            if (android is com.android.build.gradle.LibraryExtension) {
                if (android.namespace.isNullOrEmpty()) {
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