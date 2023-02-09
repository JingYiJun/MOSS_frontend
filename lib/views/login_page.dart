import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:openchat_frontend/model/user.dart';
import 'package:openchat_frontend/repository/repository.dart';
import 'package:openchat_frontend/utils/account_provider.dart';
import 'package:openchat_frontend/utils/dialog.dart';
import 'package:openchat_frontend/views/chat_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ignore: constant_identifier_names
enum Region { CN, Global }

bool isValidEmail(String email) {
  return RegExp(
          r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
      .hasMatch(email);
}

bool isValidCNPhoneNumber(String phone) {
  return RegExp(
          '^((13[0-9])|(15[^4])|(166)|(17[0-8])|(18[0-9])|(19[8-9])|(147,145))\\d{8}\$')
      .hasMatch(phone);
}

bool isValidVerification(String verify) {
  return RegExp(r'^[0-9]{1,6}$').hasMatch(verify);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController accountController;
  late TextEditingController verifycodeController;
  late TextEditingController passwordController;

  late Future<Region> _region;
  bool _signupMode = false;

  @override
  void initState() {
    accountController = TextEditingController();
    passwordController = TextEditingController();
    verifycodeController = TextEditingController();
    _region = Future.delayed(const Duration(seconds: 1), () => Region.Global);
    super.initState();
  }

  @override
  void dispose() {
    accountController.dispose();
    passwordController.dispose();
    verifycodeController.dispose();
    super.dispose();
  }

  Widget emailField(BuildContext context) => TextFormField(
      keyboardType: TextInputType.emailAddress,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.email,
      ),
      validator: (value) {
        return isValidEmail(value!)
            ? null
            : AppLocalizations.of(context)!.please_enter_valid_email;
      },
      controller: accountController);

  Widget phoneField(BuildContext context) => TextFormField(
      keyboardType: TextInputType.phone,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.phone_number,
      ),
      validator: (value) {
        return isValidCNPhoneNumber(value!)
            ? null
            : AppLocalizations.of(context)!.please_enter_valid_phone;
      },
      controller: accountController);

  Widget autoAccountField(BuildContext context, Region region) {
    switch (region) {
      case Region.Global:
        return emailField(context);
      case Region.CN:
        return phoneField(context);
    }
  }

  Future<JWToken?> Function(String, String) autoLoginFunc(Region region) {
    switch (region) {
      case Region.Global:
        return Repository.getInstance().loginWithEmailPassword;
      case Region.CN:
        return Repository.getInstance().loginWithPhonePassword;
    }
  }

  Future<JWToken?> Function(String, String, String) autoSignupFunc(
      Region region) {
    switch (region) {
      case Region.Global:
        return Repository.getInstance().registerWithEmailPassword;
      case Region.CN:
        return Repository.getInstance().registerWithPhonePassword;
    }
  }

  Future<void> Function(String) autoRequestVerifyFunc(Region region) {
    switch (region) {
      case Region.Global:
        return Repository.getInstance().requestEmailVerifyCode;
      case Region.CN:
        return Repository.getInstance().requestPhoneVerifyCode;
    }
  }

  Widget buildLandingPage(BuildContext context, {Object? error}) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 70),
                Image.asset('assets/images/logo.png', scale: 6.5),
                const SizedBox(height: 25),
                Text(
                  error == null
                      ? AppLocalizations.of(context)!
                          .fetching_server_configurations
                      : AppLocalizations.of(context)!.error,
                  style: TextStyle(
                      fontSize: 35,
                      color: error == null
                          ? null
                          : Theme.of(context).colorScheme.error),
                ),
                Opacity(
                  opacity: 0.7,
                  child: Text(
                    error == null
                        ? AppLocalizations.of(context)!.please_wait
                        : error.toString(),
                    style: const TextStyle(fontSize: 35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLoginPanel(BuildContext context, Region region) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 70),
            Image.asset('assets/images/logo.png', scale: 6.5),
            const SizedBox(height: 25),
            Text(
              AppLocalizations.of(context)!.welcome_comma,
              style: const TextStyle(fontSize: 35),
            ),
            Opacity(
              opacity: 0.7,
              child: Text(
                AppLocalizations.of(context)!.sign_in_to_continue,
                style: const TextStyle(fontSize: 35),
              ),
            ),
            const SizedBox(height: 30),
            Form(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    autoAccountField(context, region),
                    const SizedBox(height: 20),
                    TextFormField(
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                        ),
                        controller: passwordController),
                    const SizedBox(height: 60),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            _signupMode = !_signupMode;
                          });
                        },
                        child: Text(AppLocalizations.of(context)!.sign_up)),
                    const SizedBox(height: 20),
                    LoginButton(
                        text: AppLocalizations.of(context)!.sign_in,
                        onTap: () async {
                          if (!Form.of(context).validate()) return;
                          try {
                            await showLoadingDialogUntilFutureCompletes<
                                    JWToken?>(
                                context,
                                autoLoginFunc(region)(accountController.text,
                                    passwordController.text));
                          } catch (e) {
                            if (e is DioError && e.response != null) {
                              ErrorMessage? em = ErrorMessage.fromJson(
                                  e.response!.data as Map<String, dynamic>);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(em.message, maxLines: 3)));
                            }
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(e.toString(), maxLines: 3)));
                          }
                        })
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSignupPanel(BuildContext context, Region region) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 70),
            Image.asset('assets/images/logo.png', scale: 6.5),
            const SizedBox(height: 25),
            Text(
              AppLocalizations.of(context)!.sign_up,
              style: const TextStyle(fontSize: 35),
            ),
            Opacity(
              opacity: 0.7,
              child: Text(
                AppLocalizations.of(context)!.region(region.name),
                style: const TextStyle(fontSize: 35),
              ),
            ),
            const SizedBox(height: 30),
            Form(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    autoAccountField(context, region),
                    const SizedBox(height: 20),
                    TextFormField(
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                        ),
                        controller: passwordController),
                    const SizedBox(height: 20),
                    TextFormField(
                        textCapitalization: TextCapitalization.none,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.verificationcode,
                            suffixIcon: VerifyCodeRequestButton(
                              onTap: () {
                                return autoRequestVerifyFunc(region)(
                                    accountController.text);
                              },
                            )),
                        controller: verifycodeController,
                        validator: (value) => isValidVerification(value ?? '')
                            ? null
                            : AppLocalizations.of(context)!
                                .please_enter_verify_code),
                    const SizedBox(height: 60),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            _signupMode = !_signupMode;
                          });
                        },
                        child: Text(AppLocalizations.of(context)!.sign_in)),
                    const SizedBox(height: 20),
                    LoginButton(
                        text: AppLocalizations.of(context)!.sign_up,
                        onTap: () async {
                          if (!Form.of(context).validate()) return;
                          try {
                            await showLoadingDialogUntilFutureCompletes<
                                    JWToken?>(
                                context,
                                autoSignupFunc(region)(
                                    accountController.text,
                                    passwordController.text,
                                    verifycodeController.text));
                          } catch (e) {
                            if (e is DioError && e.response != null) {
                              ErrorMessage? em = ErrorMessage.fromJson(
                                  e.response!.data as Map<String, dynamic>);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(em.message, maxLines: 3)));
                            }
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(e.toString(), maxLines: 3)));
                          }
                        })
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    return FutureBuilder(
      future: _region,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildLandingPage(context, error: snapshot.error);
        } else if (snapshot.hasData) {
          return AnimatedCrossFade(
            firstChild: buildLoginPanel(context, snapshot.data as Region),
            secondChild: buildSignupPanel(context, snapshot.data as Region),
            crossFadeState: _signupMode
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          );
        } else {
          return buildLandingPage(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: kTabletSingleContainerWidth,
              height: 700,
              child: Card(
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)),
                clipBehavior: Clip.antiAlias,
                child: buildContent(context),
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(body: buildContent(context));
    }
  }
}

class LoginButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const LoginButton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: 0.7,
        child: Container(
          width: 230,
          height: 75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromARGB(255, 224, 227, 231),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 19),
              ),
              const SizedBox(width: 15),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.black,
                size: 26,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class VerifyCodeRequestButton extends StatefulWidget {
  final Future<void> Function() onTap;
  const VerifyCodeRequestButton({super.key, required this.onTap});

  @override
  VerifyCodeRequestButtonState createState() => VerifyCodeRequestButtonState();
}

class VerifyCodeRequestButtonState extends State<VerifyCodeRequestButton> {
  bool _isRequesting = false;
  int countdown = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: _isRequesting
            ? null
            : () async {
                setState(() {
                  _isRequesting = true;
                });
                try {
                  await widget.onTap();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString(), maxLines: 3)));
                }
                setState(() {
                  countdown = 60;
                });
                Timer.periodic(const Duration(seconds: 1), (timer) {
                  setState(() {
                    countdown--;
                  });
                  if (countdown == 0) {
                    timer.cancel();
                    setState(() {
                      _isRequesting = false;
                    });
                  }
                });
              },
        child: Text(countdown > 0
            ? AppLocalizations.of(context)!.requested(countdown)
            : AppLocalizations.of(context)!.request));
  }
}
