# App-specific R8 / ProGuard rules for release builds.
#
# Flutter's own keep rules (embedding, plugins registrant) are added
# automatically by the Flutter Gradle plugin; list only what your app or its
# plugins need on top of that. Most plugins ship consumer rules of their own.

# Keep line numbers so release stack traces (Crashlytics, Play Console) stay
# readable, while hiding the original source file name.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
