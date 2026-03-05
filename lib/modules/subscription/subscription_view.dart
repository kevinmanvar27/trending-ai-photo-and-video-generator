import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'subscription_controller.dart';

class SubscriptionView extends GetView<SubscriptionController> {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        centerTitle: true,
      ),
      body: Obx(() {
        // Show loading indicator
        if (controller.isLoading.value && controller.subscriptionPlans.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Show error message
        if (controller.errorMessage.value.isNotEmpty && controller.subscriptionPlans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadSubscriptionPlans(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show plans
        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadSubscriptionPlans();
            await controller.loadMySubscription();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Current Credits Display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Balance',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Obx(() => Text(
                            '${controller.creditsService.credits.value} Credits',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Active Subscription Info
                Obx(() {
                  if (controller.mySubscription.value != null && 
                      controller.mySubscription.value!.isActive) {
                    final sub = controller.mySubscription.value!;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Active Subscription',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Plan: ${sub.plan?.name ?? "Unknown"}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Expires: ${_formatDate(sub.expiresAt)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Remaining Credits: ${sub.remainingCoins}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                
                const SizedBox(height: 24),
                
                // Info Card
                /*Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Credit Usage',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• 1 credit per image conversion\n• 5 credits per video conversion',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),*/
                
                // const SizedBox(height: 32),
                
                // Plans Title
                const Text(
                  'Choose Your Plan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subscription Plans from API
                if (controller.subscriptionPlans.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No subscription plans available',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...controller.subscriptionPlans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final plan = entry.value;
                    final isPopular = index == 1; // Mark second plan as popular
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildPlanCard(
                        context,
                        plan: plan,
                        popular: isPopular,
                        onTap: () => controller.subscribeToPlan(plan),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required dynamic plan,
    bool popular = false,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: popular
            ? LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: popular ? null : Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        border: Border.all(
          color: popular ? Colors.transparent : AppColors.primary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: popular
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (popular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🔥 MOST POPULAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          if (popular) const SizedBox(height: 16),
          
          // Plan Name
          /*Text(
            plan.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: popular ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),*/
          
          const SizedBox(height: 8),
          
          // Description
          /*if (plan.description != null && plan.description!.isNotEmpty)
            Text(
              plan.description!,
              style: TextStyle(
                fontSize: 14,
                color: popular ? Colors.white70 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          
          const SizedBox(height: 16),*/
          
          Icon(
            Icons.stars,
            size: 48,
            color: popular ? Colors.white : AppColors.primary,
          ),
          
          const SizedBox(height: 12),
          
          // Credits
          Text(
            '${plan.coins} Credits',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: popular ? Colors.white : AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Price
          Text(
            '₹${plan.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: popular ? Colors.white : AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Duration
          /*Text(
            plan.durationText,
            style: TextStyle(
              fontSize: 14,
              color: popular ? Colors.white70 : Colors.grey,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Price per credit
          Text(
            '₹${(plan.price / plan.coins).toStringAsFixed(2)} per credit',
            style: TextStyle(
              fontSize: 14,
              color: popular ? Colors.white70 : Colors.grey,
            ),
          ),
          
          // Features
          if (plan.features != null && plan.features!.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...plan.features!.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: popular ? Colors.white : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14,
                        color: popular ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
          
          const SizedBox(height: 20),*/
          
          // Buy Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isProcessing.value ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: popular ? Colors.white : AppColors.primary,
                foregroundColor: popular ? AppColors.primary : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isProcessing.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Subscribe Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            )),
          ),
        ],
      ),
    );
  }
}
