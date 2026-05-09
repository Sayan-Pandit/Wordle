// Root build file for the Wordle Flutter project.
// The actual Android build logic is located in the /android directory.

plugins {
    // These versions match the ones in android/settings.gradle.kts
    id("com.android.application") version "8.6.0" apply false
    id("com.android.library") version "8.6.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
