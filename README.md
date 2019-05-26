#To run app
flutter run
# To give signup build
flutter build apk --release

####################################################
##################  Native code  ###################
#################################################### 


---->add debugShowCheckedModeBanner: false, in main Material App to remove the ribbon

to format dart code
shift+option+F

####################################################
##################  iOS          ###################
#################################################### 
#To run app
flutter run
#To build
flutter build ios --debug (or --profile or --release)
..................................
to run on particular device 
flutter run -d ZX1PC2JHXH
.................................
#To add ios platform:swift
flutter create -i swift . 
#Cocopods
pod init
pod update
pod install
#To open simulator
open -a Simulator

#Keyboard Shortcuts
to open ios keyboard in simulator=⇧(Option) + ⌘(Command) +K
                                 =⌘(Command) +K

Format code = Ctrl+I                                 

#FB plugin bug fix
edit flutter_facebook_login.podspec in .pub-cache directory , change the content to be following:
s.dependency 'FBSDKLoginKit', '4.39.1'
s.dependency 'FBSDKCoreKit', '4.39.1' #<---add this, keep the same version with loginkit
pod update FBSDKLoginKit
pod deintegrate
pod install


