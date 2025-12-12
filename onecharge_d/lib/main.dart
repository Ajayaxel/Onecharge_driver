import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/core/repository/auth_repository.dart';
import 'package:onecharge_d/core/repository/ticket_repository.dart';
import 'package:onecharge_d/presentation/login/bloc/login_bloc.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_bloc.dart';
import 'package:onecharge_d/presentation/splash/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(
            authRepository: AuthRepository(),
          ),
        ),
        BlocProvider<TicketBloc>(
          create: (context) => TicketBloc(
            ticketRepository: TicketRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Onecharge Driver',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
        
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          fontFamily: 'Lufga',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
