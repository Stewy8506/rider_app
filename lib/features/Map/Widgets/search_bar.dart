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
            Stack(
              children: [
                // Expanded blur background
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: const SizedBox(),
                    ),
                  ),
                ),
                // Foreground content
                Container(
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
              ],
            ),

            if (vm.results.isNotEmpty || vm.isLoading) ...[
              const SizedBox(height: 4),
              const Divider(
                height: 10,
                thickness: 0.5,
                color: Colors.black12,
              ),
            ],

            // Results Dropdown
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: (vm.results.isNotEmpty || vm.isLoading) ? 1 : 0,
                child: (vm.results.isNotEmpty || vm.isLoading)
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: const SizedBox(),
                              ),
                            ),
                          ),
                          Container(
                            key: const ValueKey("dropdown"),
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.65),
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
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        leading: Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: const Icon(
                                            Icons.location_on_outlined,
                                            size: 20,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        title: Text(
                                          place.name.split(',').first,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        subtitle: Text(
                                          place.name.split(',').skip(1).join(',').trim(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        onTap: () async {
                                          final navController = context.read<NavigationController>();
                                          final mapVM = context.read<MapViewModel>();

                                          final fullPlace = await vm.selectPlace(place);

                                          final current = mapVM.currentPosition;

                                          if (fullPlace != null && current != null) {
                                            navController.setDestination(
                                              startLat: current.latitude,
                                              startLng: current.longitude,
                                              endLat: fullPlace.latLng.latitude,
                                              endLng: fullPlace.latLng.longitude,
                                            );

                                            FocusScope.of(context).unfocus();
                                            vm.clearSearch();
                                          }
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
