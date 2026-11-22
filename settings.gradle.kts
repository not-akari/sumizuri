rootProject.name = "Sumizuri"

pluginManagement {
    repositories {
        google {
            mavenContent {
                includeGroupAndSubgroups("androidx")
                includeGroupAndSubgroups("com.android")
                includeGroupAndSubgroups("com.google")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google {
            mavenContent {
                includeGroupAndSubgroups("androidx")
                includeGroupAndSubgroups("com.android")
                includeGroupAndSubgroups("com.google")
            }
        }
        mavenCentral()
        // The embedded browser's native bindings are published here, and only these.
        maven("https://jogamp.org/deployment/maven") {
            content { includeGroupAndSubgroups("org.jogamp") }
        }
    }
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

include(":app:android", ":app:desktop", ":app:shared", ":app:tv")
// Sync: the part shared by the app and the server, and the server itself.
include(":sync:core", ":sync:server")
