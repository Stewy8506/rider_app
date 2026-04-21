import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Widgets/search_view_model.dart';
import '../map_view_model.dart';
import '../../Navigation/navigation_controller.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: vm.textController,
                    onChanged: vm.onSearchChanged,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Search destination...",
                      hintStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Results Dropdown
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: (vm.results.isNotEmpty || vm.isLoading)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          key: const ValueKey("dropdown"),
                          constraints: const BoxConstraints(maxHeight: 250),
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: vm.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: vm.results.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: Colors.black.withValues(alpha: 0.05),
                                  ),
                                  itemBuilder: (context, index) {
                                    final place = vm.results[index];

                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 2,
                                          ),
                                      title: Text(
                                        place.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      leading: const Icon(
                                        Icons.location_on_outlined,
                                        size: 20,
                                        color: Colors.black87,
                                      ),
                                      onTap: () async {
                                        final navController = context
                                            .read<NavigationController>();
                                        final mapVM = context
                                            .read<MapViewModel>();

                                        final fullPlace = await vm.selectPlace(
                                          place,
                                        );

                                        final current = mapVM.currentPosition;

                                        if (fullPlace != null &&
                                            current != null) {
                                          navController.setDestination(
                                            startLat: current.latitude,
                                            startLng: current.longitude,
                                            endLat: fullPlace.latLng.latitude,
                                            endLng: fullPlace.latLng.longitude,
                                          );

                                          // Defocus keyboard and collapse dropdown completely
                                          FocusScope.of(context).unfocus();
                                          vm.clearSearch();
                                        }
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}
