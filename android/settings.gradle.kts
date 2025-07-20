pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

include(":app")

val localPropertiesFile = file("local.properties")
val properties = java.util.Properties()

if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        properties.load(reader)
    }
}

val flutterSdkPath = properties.getProperty("flutter.sdk")
if (flutterSdkPath != null) {
    val flutterProjectRoot = file(flutterSdkPath).resolve("packages").resolve("flutter_tools").resolve("gradle")
    
    gradle.getIncludedBuilds().forEach {
        if (it.name == "flutter") return@forEach
    }
    
    apply(from = flutterProjectRoot.resolve("app_plugin_loader.gradle"))
}