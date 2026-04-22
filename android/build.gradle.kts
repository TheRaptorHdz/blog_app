import org.gradle.api.file.Directory

// 🔹 Repositorios globales
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔹 Ajuste de carpeta build (opcional pero válido)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

// 🔹 Subproyectos usan el mismo build dir
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🔹 Dependencias entre módulos (necesario para Flutter)
subprojects {
    project.evaluationDependsOn(":app")
}

// 🔹 Plugins (IMPORTANTE: solo declarar, no aplicar)
plugins {
    id("com.android.application") apply false
    id("com.google.gms.google-services") apply false
}

// 🔹 Dependencias de buildscript (Firebase)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
    }
}