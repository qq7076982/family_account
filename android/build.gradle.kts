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

gradle.buildStarted { settings ->
    val pubCache = System.getenv("PUB_CACHE")
        ?: (System.getProperty("user.home") + "/.pub-cache")
    val cacheDir = file(pubCache).resolve("hosted/pub.dev")

    // Packages needing namespace + compileSdk patches
    listOf("cloudbase_ce", "jni").forEach { pkg ->
        val pkgDir = cacheDir.listFiles()?.find {
            it.isDirectory && it.name.startsWith("${pkg}-")
        } ?: return@forEach

        val buildFile = pkgDir.resolve("android/build.gradle")
        if (!buildFile.exists()) return@forEach

        var content = buildFile.readText()
        var modified = false

        if (!content.contains("namespace")) {
            val manifest = pkgDir.resolve("android/src/main/AndroidManifest.xml")
            if (manifest.exists()) {
                val matcher = Regex("""package="([^"]+)"""").find(manifest.readText())
                val pkgName = matcher?.groupValues?.get(1)
                if (!pkgName.isNullOrEmpty()) {
                    content = content.replaceFirst(
                        "android {",
                        "android {\n    namespace '$pkgName'"
                    )
                    modified = true
                }
            }
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
            println("[family_account] buildStarted: patched ${pkg} build.gradle")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}