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

// Downgrade AGP to 8.x for compatibility with older plugins
gradle.settingsEvaluated {
    // Override android.gradle.plugin.version via command line or extra properties
}

// Apply namespace/compileSdk patches to pub-cache plugin build files
gradle.projectsLoaded {
    val pubCache = System.getenv("PUB_CACHE")
        ?: (System.getProperty("user.home") + "/.pub-cache")
    val cacheDir = file(pubCache).resolve("hosted/pub.dev")

    // Packages needing namespace + compileSdk patches
    val patches = listOf("cloudbase_ce", "jni")
    for (pkg in patches) {
        val pkgDir = cacheDir.listFiles()?.find {
            it.isDirectory && it.name.startsWith("${pkg}-")
        } ?: continue

        val buildFile = pkgDir.resolve("android/build.gradle")
        if (!buildFile.exists()) continue

        var content = buildFile.readText()
        var modified = false

        // 1) Add namespace if missing
        if (!content.contains("namespace")) {
            // Read package from AndroidManifest.xml
            val manifest = pkgDir.resolve("android/src/main/AndroidManifest.xml")
            if (manifest.exists()) {
                val manifestContent = manifest.readText()
                val matcher = Regex("""package="([^"]+)"""").find(manifestContent)
                val pkgName = matcher?.groupValues?.get(1)
                if (!pkgName.isNullOrEmpty()) {
                    content = content.replaceAfterLast(
                        "android {",
                        "android {\n    namespace '$pkgName'"
                    )
                    modified = true
                }
            }
        }

        // 2) Upgrade compileSdkVersion if too low
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
            println("[family_account] Patched ${pkg} build.gradle in pub-cache")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}