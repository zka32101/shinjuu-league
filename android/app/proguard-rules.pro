# Firebase SDKs rely on reflection to instantiate their component
# registrars (ComponentDiscoveryService reads <meta-data> from the merged
# manifest, then does Class.forName(...).newInstance() on each one). With
# R8 full mode the no-arg constructors get stripped/renamed, which throws
# NoSuchMethodException at startup and makes Crashlytics/Installations
# "not present" — the app then hangs on the Flutter splash screen because
# the unhandled PlatformException blocks Firebase init.
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
-keep class * implements com.google.firebase.components.ComponentRegistrar
-keep class com.google.firebase.provider.FirebaseInitProvider

# WorkManager (pulled in transitively by Firebase) uses Room, which loads
# its generated *_Impl database classes by name via reflection at runtime.
# Same class of bug as above: R8 renaming/stripping them causes "Failed to
# create an instance of androidx.work.impl.WorkDatabase" at startup.
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Database class * { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase {
    <init>();
}
-keep class androidx.work.impl.WorkDatabase
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-dontwarn androidx.room.**
