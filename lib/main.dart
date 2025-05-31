import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/skt_tracking_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/inventory_count_screen.dart';
import 'screens/inventory_sales_screen.dart';
import 'screens/home_screen.dart';
import 'providers/auth_provider.dart' as app;
import 'util.dart';
import 'theme.dart';
import 'package:firebase_core/firebase_core.dart';

String? firestoreTestResult;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('tr_TR', null);

  final authProvider = app.AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app.AuthProvider>(context);
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, "Roboto", "Roboto");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'A101 Mağaza Yönetim Uygulaması',
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr'),
      home: Consumer<app.AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoggedIn) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
      onGenerateRoute: generateRoute,
      routes: {
        '/inventory-count': (context) => const InventoryCountScreen(),
        '/inventory-sales': (context) => const InventorySalesScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/admin-panel': (context) => const AdminPanelScreen(),
        '/chat': (context) => const ChatScreen(),
        '/skt-tracking': (context) => const SktTrackingScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

// Route tanımlamaları
MaterialPageRoute<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const InventorySalesScreen());
    default:
      return null;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
