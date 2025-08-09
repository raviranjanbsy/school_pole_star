# Flutter-specific rules.
-dontwarn io.flutter.embedding.**
# Add your application-specific rules here.

# Firebase SDK
-keep class com.google.firebase.** { *; }
-keepnames class com.google.android.gms.measurement.AppMeasurement.Event { *; }
-keepnames class com.google.android.gms.measurement.AppMeasurement.UserProperty { *; }


# Rules for react-native-stripe-sdk which is a dependency of flutter_stripe
-keep class com.reactnativestripesdk.** { *; }
-keep class com.facebook.react.** { *; }

# Stripe Android SDK
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.core.** { *; }
-keep class com.stripe.android.model.** { *; }
-keep class com.stripe.android.view.** { *; }
-keep class com.stripe.android.networking.** { *; }
-keep class com.stripe.android.payments.** { *; }
-keep class com.stripe.android.paymentsheet.** { *; }
-keep class com.stripe.android.link.** { *; }
-keep class com.stripe.android.financialconnections.** { *; }
-keep class com.stripe.android.uicore.** { *; }
-keep class com.stripe.android.ui.core.** { *; }
-keep class com.stripe.android.cards.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }

# Required for Google Pay
-keep class com.google.android.gms.wallet.** { *; }

# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.stripe.android.pushProvisioning.EphemeralKeyUpdateListener
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider