import 'package:firebasetesting/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io';

void main() => GoogleSigninPlugin();

// ignore: non_constant_identifier_names
void GoogleSigninPlugin() async {
  //initialize the Firebase Setting
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  //If already signed in, route to HomePage directly
  //If not, route to Authentication Page
  runApp(
    MaterialApp(
      title: "Flutter",
      home: StreamBuilder<User?>(
        stream: AuthenticationService.instance.authStateChange(),
        builder: (_, snapshot) {
          final isSignedIn = snapshot.data != null;
          return isSignedIn ? HomePage() : GoogleSigninPage();
        },
      ),
    ),
  );
}

class GoogleSigninPage extends StatefulWidget {
  const GoogleSigninPage({Key? key}) : super(key: key);

  @override
  _GoogleSigninPageState createState() => _GoogleSigninPageState();
}

class _GoogleSigninPageState extends State<GoogleSigninPage> {
  bool isSigningIn = false;
  final googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Sign Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () async {
                  //function for sign in with Apple
                  isSigningIn = true;
                  final credential = await SignInWithApple.getAppleIDCredential(
                    scopes: [
                      AppleIDAuthorizationScopes.email,
                      AppleIDAuthorizationScopes.fullName,
                    ],
                    // Optional parameters for web-based authentication flows on non-Apple platforms
                    webAuthenticationOptions: WebAuthenticationOptions(
                      clientId: '',
                      redirectUri: Uri.parse(
                        'https://iostesting-b52e5.firebaseapp.com/__/auth/handler',
                      ),
                    ),

                    nonce: 'example-nonce',
                    state: 'example-state',
                  );

                  print(credential);

                  // This is the endpoint that will convert an authorization code obtained
                  // via Sign in with Apple into a session in your system
                  final signInWithAppleEndpoint = Uri(
                    scheme: 'https',
                    host: 'flutter-sign-in-with-apple-example.glitch.me',
                    path: '/sign_in_with_apple',
                    queryParameters: <String, String>{
                      'code': credential.authorizationCode,
                      if (credential.givenName != null)
                        'firstName': credential.givenName!,
                      if (credential.familyName != null)
                        'lastName': credential.familyName!,
                      'useBundleId':
                          Platform.isIOS || Platform.isMacOS ? 'true' : 'false',
                      if (credential.state != null) 'state': credential.state!,
                    },
                  );

                  final session = await http.Client().post(
                    signInWithAppleEndpoint,
                  );

                  // If we got this far, a session based on the Apple ID credential has been created in your system,
                  // and you can now set this as the app's session
                  print(session);
                },
                child: Text("Apple"))
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final googleSignIn = GoogleSignIn();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HomePage')),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          //Content of Home Page
          Text("Logged In Sucessfully!"),

          //Button for Signning Out
          ElevatedButton(
            onPressed: () async {
              try {
                await googleSignIn.disconnect();
                FirebaseAuth.instance.signOut();
              } catch (e) {
                debugPrint("Sign out failed");
              }
            },
            child: Text('Sign out Google Account'),
          ),
        ],
      )),
    );
  }
}
