import 'package:dar_al_safwa/presentation/widgets/custom_text_formfield_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/notification_navigation_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';
import 'tenants_create_ticket_screen.dart';
import 'tenants_ticket_details_screen.dart';

class TenantsTicketsListWidget extends StatefulWidget {
  const TenantsTicketsListWidget({super.key});

  @override
  State<TenantsTicketsListWidget> createState() =>
      _TenantsTicketsListWidgetState();
}

class _TenantsTicketsListWidgetState extends State<TenantsTicketsListWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<TicketModel> tickets = [];
  List<TicketModel> filteredTickets = [];

  @override
  void initState() {
    super.initState();
    _initializeTickets();
    filteredTickets = tickets;
  }

  void _initializeTickets() {
    tickets = [
      TicketModel(
        id: 'TK-1062',
        title: 'Palm Residency - Flat B12',
        description: 'Leaking tap in kitchen',
        submittedDate: 'May 20, 2024',
        status: TicketStatus.pending,
      ),
      TicketModel(
        id: 'TK-1234',
        title: 'Green view Apartment - Unit 301',
        description: 'Broken window in living room',
        submittedDate: 'May 18, 2024',
        status: TicketStatus.rectified,
      ),
      TicketModel(
        id: 'TK-1889',
        title: 'Sunset Estate-House 19',
        description: 'Bathroom light not working',
        submittedDate: 'May 14, 2024',
        status: TicketStatus.pending,
      ),
      TicketModel(
        id: 'TK-2678',
        title: 'Maple Residency - Flat A07',
        description: 'AC not cooling properly',
        submittedDate: 'May 10, 2024',
        status: TicketStatus.rectified,
      ),
    ];
  }

  void _searchTickets(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredTickets = tickets;
      } else {
        filteredTickets = tickets.where((ticket) {
          return ticket.id.toLowerCase().contains(query.toLowerCase()) ||
              ticket.title.toLowerCase().contains(query.toLowerCase()) ||
              ticket.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomTextWidget(
          title: "Tickets",
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: [notificationNavigation()],
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth2),
        child: Stack(
          children: [
            Column(
              children: [
                // Search Bar
                CustomTextFieldWidget(
                    hintText: "Search ticket by ID or Issue...",
                    keyboardType: TextInputType.text,
                    prefixIcon: Icons.search,
                    controller: _searchController),

                // Tickets List
                Expanded(
                  child: filteredTickets.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth1,
                              vertical: screenHeight1),
                          itemCount: filteredTickets.length,
                          itemBuilder: (context, index) {
                            return _buildTicketCard(filteredTickets[index]);
                          },
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: screenHeight * 0.05,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: Get.width * 0.9, // 90% of screen width
                  child: CustomButtonWidget(
                    buttonColor: AppColors.secondaryColor,
                    buttonTitle: "Create Ticket",
                    buttonTextColor: AppColors.white,
                    onPressed: () {
                      Get.to(TenantsCreateTicketScreen(propertyName: '',));
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    return InkWell(
      onTap: () {
        Get.to(TicketDetailsScreen(
          ticket: ticket,
        ));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight1),
        padding: EdgeInsets.all(screenWidth1),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            CustomTextWidget(
              title: "#${ticket.id}",
              fontSize: Get.height * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.black800,
            ),

            SizedBox(height: screenHeight05),

            // Title
            CustomTextWidget(
              title: ticket.title,
              fontSize: Get.height * 0.018,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              maxLines: 2,
            ),

            // kHeight(0.01),

            // Description
            CustomTextWidget(
              title: ticket.description,
              fontSize: Get.height * 0.014,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
              maxLines: 2,
            ),

            SizedBox(height: screenHeight05),

            // Submitted Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTextWidget(
                  title: "Submitted on ${ticket.submittedDate}",
                  fontSize: Get.height * 0.014,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black500,
                ),
                _buildStatusChip(ticket.status),
              ],
            ),
            kHeight(0.02),
            Container(
              height: Get.height * 0.001,
              width: Get.width * 0.90,
              color: AppColors.grey.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case TicketStatus.pending:
        backgroundColor = AppColors.primaryColor;
        textColor = AppColors.secondaryColor;
        statusText = "Pending";
        break;
      case TicketStatus.rectified:
        backgroundColor = AppColors.onlineGreen.withValues(alpha: 0.1);
        textColor = AppColors.onlineGreenDark;
        statusText = "Rectified";
        break;
      case TicketStatus.inProgress:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        statusText = "In Progress";
        break;
      case TicketStatus.completed:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.010,
        vertical: screenHeight * 0.002,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomTextWidget(
        title: statusText,
        fontSize: Get.height * 0.012,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: Get.height * 0.08,
            color: AppColors.lightGrey,
          ),
          SizedBox(height: screenHeight1),
          CustomTextWidget(
            title: "No tickets found",
            fontSize: Get.height * 0.02,
            fontWeight: FontWeight.w600,
            color: AppColors.black500,
          ),
          SizedBox(height: screenHeight05),
          CustomTextWidget(
            title: "Try adjusting your search criteria",
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w400,
            color: AppColors.lightGrey,
          ),
        ],
      ),
    );
  }

  void _showCreateTicketDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: CustomTextWidget(
            title: "Create New Ticket",
            fontSize: Get.height * 0.02,
            fontWeight: FontWeight.w600,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "Ticket title",
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.lightGrey,
                    fontSize: Get.height * 0.016,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: screenHeight1),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Describe the issue",
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.lightGrey,
                    fontSize: Get.height * 0.016,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: CustomTextWidget(
                title: "Cancel",
                color: AppColors.black500,
                fontSize: Get.height * 0.016,
              ),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _createNewTicket(
                      titleController.text, descriptionController.text);
                }
              },
              child: CustomTextWidget(
                title: "Create",
                color: AppColors.primaryColor,
                fontSize: Get.height * 0.016,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  void _createNewTicket(String title, String description) {
    final newTicket = TicketModel(
      id: 'TK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      title: title,
      description: description,
      submittedDate: 'Today',
      status: TicketStatus.pending,
    );

    setState(() {
      tickets.insert(0, newTicket);
      filteredTickets = tickets;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomTextWidget(
          title: "Ticket created successfully!",
          color: AppColors.white,
          fontSize: Get.height * 0.016,
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Update your existing TicketModel and TicketStatus from the previous file
class TicketModel {
  final String id;
  final String title;
  final String description;
  final String submittedDate;
  final TicketStatus status;

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.submittedDate,
    required this.status,
  });
}

enum TicketStatus {
  pending,
  rectified,
  inProgress, completed,
}
