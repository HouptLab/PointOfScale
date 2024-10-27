# Description


# Hardware Required

1. iPad M1 Air or better, of just about any capacity

2. a USB-C charger with cable to charge the iPad

2. Etekcity Nutrition Scale model # ESN00 (Bluetooth kitchen scale)

3. Stand for iPad, e.g. ["AboveTEK Elegant Tablet Stand, Aluminum iPad Stand Holder"](https://www.amazon.com/dp/B01KW7LSQK)

4. Cart to hold iPad in stand, Bluetooth scale, lab notebook, and/or the cage of the animal being weighed

5. Macintosh with Xcode development to compile PointOfScale source

TODO: inset photo of ipad/scale/cart setup

# Compiling PointOfScale from Source

## Integrating Firebase into iPad project

The XCode project in GitHub includes the necessary Swift package dependency for https://github.com/firebase/firebase-ios-sdk , which should be fetched and loaded when the app is built.

## Setting up Firebase

In console -> "Project settings" -> "General" tab:

1. Under "Your Project" copy "Web Api Key" to enter in "Settings" of BarTender and PointOfScale apps.

2. create an iOS+ "Apple app" for PointOfScale, with Bundle ID com.bcybernetics.PointOfScale

3. In console -> "Authentication" -> "Sign-In Methods" tab:
    enable Email/Password

4. In console -> "Authentication" -> "Users" tab:
    add user with email and password 
   
4. enter this email and password in "Settings" of the PointOfScale app.

4. copy GoogleService-Info.plist into PointOfScale project

## Loading onto local iPad

At the moment, the easiest way distribute PointOfScale isto connect the  iPad to the Mac used for development,  and build the app with the iPad selected as the target. (The iPad may need to be registered as a development device in your Apple developer account.) This local deployment of the app should be usable for at least 90 days.

An app store version of PointOfScale should be available soon.