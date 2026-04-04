allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Force all subprojects (Flutter plugins) to use a compatible AGP version.
    // This guards against outdated pub-cache plugin build.gradle files that
    // reference AGP 4.x, which is incompatible with the host's AGP 8.x and
    // triggers the "Namespace not specified" error even when namespace IS set.
    buildscript {
        configurations.all {
            resolutionStrategy.eachDependency {
                if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                    useVersion("8.1.4")
                    because("Force all plugins to use AGP 8-compatible version")
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
