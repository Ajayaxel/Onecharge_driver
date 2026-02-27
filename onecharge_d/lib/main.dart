import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/core/network/api_service.dart';
import 'package:onecharge_d/data/repositories/vehicle_repository.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
                });

                // If we have user data from login/storage, initialize DriverBloc with it
                // and also fetch fresh data from /api/driver/me
                context.read<DriverBloc>().add(
                  UpdateDriverLocal(state.userData),
                );
                context.read<DriverBloc>().add(FetchDriverProfile());
                // context.read<TicketBloc>().add(FetchTickets()); // STOPPED TEMPORARILY FOR SOCKET TEST
                context.read<VehicleBloc>()
                  ..add(const FetchVehicles())
                  ..add(const FetchCurrentVehicle());
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
