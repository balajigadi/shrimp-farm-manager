import 'package:flutter/material.dart';

/// Root navigator for the app — used by [FcmService] to pop back to home
/// before switching to the Market tab.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
