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

// Map of known package name -> namespace / compileSdk upgrades needed
val knownPatches = mapOf(
    "cloudbase_ce" to listOf(
        KnownPatch("namespace", "com.cloudbase.cloudbase_ce"),
        KnownPatch("compileSdkVersion", "30")
    ),
    "jni" to listOf(
        KnownPatch("namespace", "com.github.dart_lang.jni"),
        KnownPatch("compileSdkVersion", "30")
    )
)

data class KnownPatch(val key: String, val value: String)

gradle.projectsLoaded {
    val pubCache = System.getenv("PUB_CACHE")
        ?: (System.getProperty("user.home") + "/.pub-cache")
    val cacheDir = file(pubCache).resolve("hosted/pub.dev")

    for ((pkg, patches) in knownPatches) {
        val pkgDir = cacheDir.listFiles()?.find {
            it.name.startsWith("${pkg}-")
        } ?: continue

        val buildFile = pkgDir.resolve("android/build.gradle")
        if (!buildFile.exists()) continue

        var content = buildFile.readText()
        var modified = false

        // 1) Inject namespace if missing and not already present
        val hasNamespace = content.contains("namespace")
        val hasPackageAttr = Regex("""namespace\s+['\"]([^'\"]+)['\"]""").find(content) != null
        if (!hasNamespace && !hasPackageAttr) {
            val manifestFile = pkgDir.resolve("android/src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val manifest = manifestFile.readText()
                val pkgMatcher = Regex("""package="([^"]+)"""").find(manifest)
                val pkgName = pkgMatcher?.groupValues?.get(1)
                if (!pkgName.isNullOrEmpty()) {
                    content = content.replaceAfterLast(
                        "android {",
                        "android {\n    namespace '$pkgName'"
                    )
                    modified = true
                    println("[family_account] Patched namespace '$pkgName' into ${pkg}")
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
                println("[family_account] Patched compileSdkVersion $currentSdk->30 in ${pkg}")
            }
        }

        if (modified) {
            buildFile.writeText(content)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}