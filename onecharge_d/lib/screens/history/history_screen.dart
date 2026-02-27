import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:onecharge_d/data/models/ticket_model.dart';
import 'package:onecharge_d/logic/blocs/ticket/ticket_bloc.dart';
import 'package:onecharge_d/logic/blocs/ticket/ticket_event.dart';
import 'package:onecharge_d/logic/blocs/ticket/ticket_state.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_bloc.dart';
import 'package:onecharge_d/logic/blocs/driver/driver_state.dart';
import '../../widgets/home_header_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _activeTab = 0; // 0 for Completed, 1 for Rejected
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 5. State Management Optimization: Fetch only if necessary
    final ticketState = context.read<TicketBloc>().state;
    if (ticketState is! TicketHistoryLoaded) {
      context.read<TicketBloc>().add(const FetchHistory());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      // 4. Lazy Loading / Pagination: Load more when scrolling to bottom
      // In this setup, FetchHistory currently fetches all, but we can call it
      // with a refresh: false to simulate pagination if the BLOC supports it.
      // For now, let's keep it ready for future page-based pagination.
      // context.read<TicketBloc>().add(const FetchHistory(isRefresh: false));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.black,
          onRefresh: () async {
            // 7. User Experience: Pull-to-refresh resets history
            context.read<TicketBloc>().add(const FetchHistory(isRefresh: true));
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeHeader(),
                    const HomeSearchBar(hintText: 'Search by ticket no ....'),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lufga',
                        ),
                      ),
                    ),
                    _buildTabs(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              // 6. Performance & Memory Optimization: Using SliverList for efficient rendering
              BlocBuilder<TicketBloc, TicketState>(
                buildWhen: (previous, current) =>
                    current is TicketHistoryLoading ||
                    current is TicketHistoryLoaded ||
                    current is TicketHistoryError,
                builder: (context, state) {
                  if (state is TicketHistoryLoading && state.isFirstFetch) {
                    // 2. Shimmer Loading: Initial load shimmer
                    // If we have an idea of the total count from a previous state, we can use it,
                    // else default to 5.
                    int shimmerCount = 5;
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const HistoryShimmerCard(),
                        childCount: shimmerCount,
                      ),
                    );
                  } else if (state is TicketHistoryLoaded ||
                      (state is TicketHistoryLoading && !state.isFirstFetch)) {
                    final List<TicketModel> allTickets =
                        (state is TicketHistoryLoaded)
                        ? state.tickets
                        : (state as TicketHistoryLoading).oldTickets;

                    final filteredTickets = allTickets.where((ticket) {
                      final s = ticket.status.toLowerCase();
                      if (_activeTab == 0) {
                        return s.contains('complete') ||
                            s.contains('done') ||
                            s.contains('finish');
                      } else {
                        return s.contains('reject') ||
                            s.contains('declin') ||
                            s.contains('cancel');
                      }
                    }).toList();

                    if (filteredTickets.isEmpty &&
                        state is TicketHistoryLoaded) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'No ${_activeTab == 0 ? 'completed' : 'rejected'} tickets found',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontFamily: 'Lufga',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= filteredTickets.length) {
                            // Show loading indicator at the bottom for pagination
                            return state is TicketHistoryLoading
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 100);
                          }
                          return HistoryCard(
                            key: ValueKey(filteredTickets[index].ticketId),
                            ticket: filteredTickets[index],
                            isRejected: _activeTab == 1,
                          );
                        },
                        childCount:
                            filteredTickets.length +
                            (state is TicketHistoryLoading ? 1 : 1),
                      ),
                    );
                  } else if (state is TicketHistoryError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(state.message)),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            _buildTabItem('Completed', 0),
            _buildTabItem('Rejected', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              color: isActive ? Colors.black : const Color(0xFF666666),
              fontFamily: 'Lufga',
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  final TicketModel ticket;
  final bool isRejected;

  const HistoryCard({super.key, required this.ticket, this.isRejected = false});

  @override
  Widget build(BuildContext context) {
    final statusColor = isRejected
        ? const Color(0xFFFF5252)
        : const Color(0xFF4CAF50);

    return BlocBuilder<DriverBloc, DriverState>(
      // 6. Performance Optimization: Only rebuild if driver data changes
      buildWhen: (previous, current) => current is DriverLoaded,
      builder: (context, state) {
        String profileImageUrl =
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop';
        if (state is DriverLoaded) {
          profileImageUrl =
              state.driverData['profile_image'] ?? profileImageUrl;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipOval(
                    child: Image.network(
                      profileImageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 44,
                            height: 44,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.customer.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Lufga',
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${DateTime.now().difference(ticket.createdAt).inMinutes.abs()} Min ago',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontFamily: 'Lufga',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Lufga',
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFE0E0E0)),
              ),
              GridView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 45,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 8,
                ),
                children: [
                  _buildDetailItem(
                    Icons.handyman_outlined,
                    'Issue',
                    ticket.issueCategory.name,
                  ),
                  _buildDetailItem(
                    Icons.directions_car_outlined,
                    'Vehicle',
                    '${ticket.brand.name} ${ticket.model.name}',
                  ),
                  _buildDetailItem(
                    Icons.credit_card_outlined,
                    'Plate',
                    ticket.numberPlate,
                  ),
                  _buildDetailItem(
                    Icons.confirmation_number_outlined,
                    'Ticket ID',
                    ticket.ticketId,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Work Time: ${isRejected ? '0m' : '1m'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Lufga',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF757575),
                  fontFamily: 'Lufga',
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lufga',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HistoryShimmerCard extends StatelessWidget {
  const HistoryShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 100, height: 16, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(width: 60, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.white),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 45,
                crossAxisSpacing: 10,
                mainAxisSpacing: 8,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => Row(
                children: [
                  Container(width: 18, height: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 30, height: 8, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(width: 50, height: 10, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
