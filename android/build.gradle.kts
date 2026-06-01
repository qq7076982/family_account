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

val knownNamespaces = mapOf(
    "cloudbase_ce" to "com.cloudbase.cloudbase_ce",
    "jni" to "com.github.dart_lang.jni"
)

gradle.buildStarted { _ ->
    val pubCache = System.getenv("PUB_CACHE")
        ?: (System.getProperty("user.home") + "/.pub-cache")
    val cacheDir = file(pubCache).resolve("hosted/pub.dev")

    for ((pkg, ns) in knownNamespaces) {
        val pkgDir = cacheDir.listFiles()?.find {
            it.isDirectory && it.name.startsWith("${pkg}-")
        } ?: continue

        val buildFile = pkgDir.resolve("android/build.gradle")
        if (!buildFile.exists()) continue

        var content = buildFile.readText()
        var modified = false

        if (!content.contains("namespace")) {
            content = content.replaceFirst("android {", "android {\n    namespace '$ns'")
            modified = true
        }

        val sdkMatcher = Regex("""compileSdkVersion\s+(\d+)""").find(content)
        if (sdkMatcher != null) {
            val currentSdk = sdkMatcher.groupValues[1].toIntOrNull() ?: 0
            if (currentSdk < 30) {
                content = content.replace("compileSdkVersion $currentSdk", "compileSdkVersion 30")
                modified = true
            }
        }

        if (modified) {
            buildFile.writeText(content)
            println("[family_account] Patched ${pkg}: namespace='$ns', compileSdk=30")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}