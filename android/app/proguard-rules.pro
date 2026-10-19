# shared_preferences_android invoca SharedPreferencesApiRegistrar por JNI desde Dart
# (jnigen). R8 no ve esas llamadas: hay que conservar la clase, los tipos de su
# firma (kotlin.coroutines.Continuation) y las clases que el runtime de jni busca
# por nombre (p. ej. kotlin.coroutines.intrinsics.CoroutineSingletons).
# Sin esto: NoSuchMethodError / ClassNotFoundException al arrancar en release.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
