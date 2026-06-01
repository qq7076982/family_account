import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/bill_provider.dart';
import 'services/firestore_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FamilyAccountApp());
}

class FamilyAccountApp extends StatelessWidget {
  const FamilyAccountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<FirestoreService, BillProvider>(
          create: (ctx) => BillProvider(FirestoreService.getInstance() as FirestoreService),
          update: (ctx, fs, previous) => previous ?? BillProvider(fs),
        ),
      ],
      child: MaterialApp(
        title: '家账小记',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6679EE),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF333333),
            elevation: 0,
          ),
        ),
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().init();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, auth, _) {
      if (auth.loading) {
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF6679EE)),
                SizedBox(height: 16),
                Text('加载中...', style: TextStyle(color: Color(0xFF999999))),
              ],
            ),
          ),
        );
      }

      if (!auth.hasFamily) {
        return const WelcomeScreen();
      }

      return const MainNavigator();
    });
  }
}