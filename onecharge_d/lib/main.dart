import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/core/network/api_service.dart';
import 'package:onecharge_d/data/repositories/vehicle_repository.dart';
import 'package:onecharge_d/firebase_options.dart';
import 'package:onecharge_d/logic/blocs/auth/auth_bloc.dart';
import 'package:onecharge_d/logic/blocs/auth/auth_event.dart';
import 'package:onecharge_d/logic/blocs/auth/auth_state.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_bloc.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_event.dart';
import 'package:onecharge_d/logic/blocs/ticket/ticket_bloc.dart';
import 'package:onecharge_d/logic/blocs/ticket/ticket_event.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_bloc.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_event.dart';
import 'package:onecharge_d/screens/home/bootmnav.dart';
import 'package:onecharge_d/screens/login/login_screen.dart';
import 'package:onecharge_d/widgets/platform_loading.dart';
import 'package:onecharge_d/core/network/reverb_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:onecharge_d/core/services/notification_service.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register FCM background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => ApiService()),
        RepositoryProvider(
          create: (context) => VehicleRepository(context.read<ApiService>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(context.read<ApiService>())..add(AppStarted()),
          ),
          BlocProvider(
            create: (context) => DriverBloc(context.read<ApiService>()),
          ),
          BlocProvider(
            create: (context) => TicketBloc(context.read<ApiService>()),
          ),
          BlocProvider(
            create: (context) => VehicleBloc(context.read<VehicleRepository>()),
          ),
        ],
        child: MaterialApp(
          title: 'Onecharge Driver',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            fontFamily: 'Lufga',
          ),
          home: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                // Initialize FCM Push Notifications
                NotificationService().initialize();
                // Initialize Reverb real-time service
                final reverb = ReverbService();
                reverb.initialize().then((_) {
                  // Bind all ticket related events
                  reverb.bindTicketOffered((data) {
                    if (context.mounted) {
                      context.read<TicketBloc>().add(
                        RealTimeTicketUpdate('offered', data),
                      );
                    }
                  });

                  reverb.bindTicketUpdated((data) {
                    if (context.mounted) {
                      context.read<TicketBloc>().add(
                        RealTimeTicketUpdate('updated', data),
                      );
                    }
                  });

                  reverb.bindTicketCancelled((data) {
                    if (context.mounted) {
                      context.read<TicketBloc>().add(
                        RealTimeTicketUpdate('cancelled', data),
                      );
                    }
                  });

                  // ─── CRITICAL: Re-fetch tickets when socket subscribes ───
                  // This handles the user request "fetch all tickets from socket/ready state"
                  // by ensuring the API is checked exactly when the real-time pipe is ready.
                  reverb.ticketsChannelState.addListener(() {
                    if (reverb.ticketsChannelState.value ==
                            ChannelState.subscribed &&
                        context.mounted) {
                      print(
                        'Reverb: 🎯 Channel subscribed, refreshing tickets...',
                      );
                      context.read<TicketBloc>().add(FetchTickets());
                    }
                  });
                });

                // If we have user data from login/storage, initialize DriverBloc with it
                // and also fetch fresh data from /api/driver/me
                context.read<DriverBloc>().add(
                  UpdateDriverLocal(state.userData),
                );
                context.read<DriverBloc>().add(FetchDriverProfile());
                context.read<TicketBloc>().add(FetchTickets());
                context.read<VehicleBloc>()
                  ..add(const FetchVehicles())
                  ..add(const FetchCurrentVehicle());
              } else if (state is AuthUnauthenticated) {
                // Clear all internal data Blocs so a new login starts with a fresh state.
                // This prevents the "Offered Ticket" modal from flash-showing old data
                // from the previous session before the new FetchTickets call finishes.
                context.read<TicketBloc>().add(ClearTickets());
                context.read<DriverBloc>().add(ClearDriverData());
                context.read<VehicleBloc>().add(const ClearVehicles());
              }
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated || state is AuthLogoutLoading) {
                  return const Bootmnav();
                } else if (state is AuthInitial) {
                  return const Scaffold(body: Center(child: PlatformLoading()));
                }
                return const LoginScreen();
              },
            ),
          ),
        ),
      ),
    );
  }
}
