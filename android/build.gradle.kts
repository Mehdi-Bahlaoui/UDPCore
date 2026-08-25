allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // Patch flutter_bluetooth_serial, which is unmaintained and predates AGP 8.
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            if (android != null) {
                // It declares no namespace, which AGP 8+ requires.
                if (android.namespace == null) {
                    android.namespace = "io.github.edufolly.flutterbluetoothserial"
                }
                // It pins compileSdkVersion 30, older than its own AndroidX
                // dependencies need. Resource linking then fails with
                // "resource android:attr/lStar not found" on release builds.
                val level = android.compileSdkVersion?.removePrefix("android-")?.toIntOrNull()
                if (level == null || level < 35) {
                    android.compileSdkVersion(36)
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
