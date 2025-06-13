import 'dart:ui';

import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class CustomerEnquiryScreen extends StatefulWidget {
  const CustomerEnquiryScreen({Key? key}) : super(key: key);

  @override
  State<CustomerEnquiryScreen> createState() => _CustomerEnquiryScreenState();
}

class _CustomerEnquiryScreenState extends State<CustomerEnquiryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back,
            size: iconSize,
            color: AppColors.black,
          ),
        ),
        title: CustomTextWidget(
          title: 'Customer Enquiry',
          fontSize: appBarTitles,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: [
          SizedBox(
            height: screenHeight * 0.03,
            child: Image.asset('assets/images/Notifications.png'),
          ),
          kWidth(0.04)
        ],
      ),
      body: Column(
        children: [
          kHeight(0.01),
          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: screenWidth4),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              tabAlignment: TabAlignment.fill,
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.secondaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.black600,
              labelStyle: TextStyle(
                color: AppColors.white,
                fontSize: H18,
                fontWeight: FontWeight.w600,
              ),
              labelPadding: EdgeInsets.symmetric(horizontal: 8),
              dividerColor: Colors.transparent,
              unselectedLabelStyle: TextStyle(
                // backgroundColor: AppColors.redColor,
                fontSize: H18,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 30), // adjust here
                    child: Text('Total'),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10), // adjust here
                    child: Text('Pending'),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10), // adjust here
                    child: Text('In-Progress'),
                  ),
                ),
              ],
            ),
          ),
          kHeight(0.03),
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCustomerList(),
                _buildCustomerList(),
                _buildCustomerList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    final customers = [
      CustomerData(
        name: 'Rajesh Kumar',
        apartment: '201-B, Apartment, Kochi',
        status: 'Recent Visit',
        phone: '+91 (123) 456 7890',
        statusColor: AppColors.redColor,
        statusBgColor: AppColors.redColor,
      ),
      CustomerData(
        name: 'Amit Sharma',
        apartment: '301-A, Apartment, Kochi',
        status: 'In Progress',
        phone: '+91 (123) 456 7890',
        statusColor: AppColors.warning,
        statusBgColor: AppColors.warning,
      ),
      CustomerData(
        name: 'Divya Menon',
        apartment: '101-B, Apartment, Aluka',
        status: 'Closed',
        phone: '+91 (123) 456 7890',
        statusColor: AppColors.onlineGreen,
        statusBgColor: AppColors.onlineGreen,
      ),
      CustomerData(
        name: 'Kavya Martin',
        apartment: '201-B, Apartment, Ernakulam',
        status: 'Pending',
        phone: '+91 (123) 456 7890',
        statusColor: AppColors.warning,
        statusBgColor: AppColors.warning,
      ),
    ];

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: screenWidth4),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        return _buildCustomerCard(customers[index]);
      },
    );
  }

  Widget _buildCustomerCard(CustomerData customer) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight2),
      padding: EdgeInsets.all(screenWidth4),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        border: Border.all(
            width: 1, color: AppColors.darkGrey.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: CustomTextWidget(
                  title: customer.name,
                  fontSize: H18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth3,
                  vertical: screenHeight05,
                ),
                decoration: BoxDecoration(
                  color: customer.statusBgColor,
                  borderRadius: BorderRadius.circular(screenWidth2),
                ),
                child: CustomTextWidget(
                  title: customer.status,
                  fontSize: detailContentTitle,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          kHeight(0.005),

          CustomTextWidget(
            title: 'May 15,2023',
            fontSize: detailContentTitle,
            color: AppColors.darkGrey,
          ),
          kHeight(0.008),
          // Apartment Info
          CustomTextWidget(
            title: customer.apartment,
            fontWeight: FontWeight.w600,
            fontSize: detailContentTitle,
            color: AppColors.black,
          ),
          kHeight(0.008),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomTextWidget(
                  title: "Recent Deal",
                  fontWeight: FontWeight.w600,
                  fontSize: detailContentTitle,
                  color: AppColors.darkGrey,
                ),
              ),
              CustomTextWidget(
                title: customer.phone,
                fontWeight: FontWeight.w600,
                fontSize: detailContentTitle,
                color: AppColors.black,
              ),
            ],
          ),

          kHeight(0.015),
          // Phone and Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                'Call',
                Icons.call,
                AppColors.blueColor,
              ),
              kWidth(0.03),
              _buildActionButton(
                'WhatsApp',
                Icons.chat,
                AppColors.onlineGreen,
              ),
              kWidth(0.03),
              _buildActionButton(
                'Message',
                Icons.message,
                AppColors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(screenWidth2),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth6,
          vertical: screenHeight1,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.darkGrey.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextWidget(
              title: text,
              fontSize: 16,
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class CustomerData {
  final String name;
  final String apartment;
  final String status;
  final String phone;
  final Color statusColor;
  final Color statusBgColor;

  CustomerData({
    required this.name,
    required this.apartment,
    required this.status,
    required this.phone,
    required this.statusColor,
    required this.statusBgColor,
  });
}
