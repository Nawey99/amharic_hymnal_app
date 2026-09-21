# Flutter and the Android plugins publish their own consumer rules. Keep only
# attributes and native entry points that project code can access reflectively.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Preserve JNI entry points without retaining every Flutter or AndroidX class.
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
