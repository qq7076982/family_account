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

// Use a separate init script approach via gradle.buildFinished
// Since subprojects{} can't run Groovy scripts, we apply patches via gradle.projectEvaluation hook
val pubCache = System.getenv("PUB_CACHE")
    ?: (System.getProperty("user.home") + "/.pub-cache")
val cacheDir = file(pubCache).resolve("hosted/pub.dev")

// Patch cloudbase_ce build.gradle directly in pub-cache before configuration
val cloudbaseDir = cacheDir.listFiles()?.find {
    it.isDirectory && it.name.startsWith("cloudbase_ce-")
}
if (cloudbaseDir != null) {
    val buildFile = cloudbaseDir.resolve("android/build.gradle")
    if (buildFile.exists()) {
        var content = buildFile.readText()
        if (!content.contains("namespace")) {
            content = content.replaceFirst(
                "android {",
                "android {\n    namespace 'com.cloudbase.cloudbase_ce'"
            )
        }
        val sdkMatch = Regex("""compileSdkVersion\s+(\d+)""").find(content)
        if (sdkMatch != null) {
            val sdk = sdkMatch.groupValues[1].toIntOrNull() ?: 0
            if (sdk < 30) {
                content = content.replace("compileSdkVersion $sdk", "compileSdkVersion 30")
            }
        }
        buildFile.writeText(content)
        println("[family_account] Patched cloudbase_ce build.gradle: namespace + compileSdkVersion")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}