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

require(localPropertiesFile.exists()) { "local.properties file not found!" }
localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
    properties.load(reader)
}

val flutterSdkPath = properties.getProperty("flutter.sdk")
require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
apply(from = flutterProjectRoot.resolve("app_plugin_loader.gradle"))