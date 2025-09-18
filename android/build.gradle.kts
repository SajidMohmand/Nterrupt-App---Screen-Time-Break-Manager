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


// Ensure all Android modules (including transitive plugins like usage_stats)
// use a modern compileSdk to avoid AAPT errors such as android:attr/lStar not found.
subprojects {
    plugins.withId("com.android.library") {
        // Library modules
        extensions.configure<com.android.build.api.dsl.LibraryExtension>("android") {
            compileSdk = 36
        }
    }
    // Note: Application modules should configure compileSdk in their own build.gradle files
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
