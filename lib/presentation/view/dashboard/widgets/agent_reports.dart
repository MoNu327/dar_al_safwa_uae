import 'package:dar_al_safwa/presentation/view/dashboard/controller/property_interests_controller.dart';
import 'package:dar_al_safwa/presentation/view/inbox/controller/inbox_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/loader_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dar_al_safwa/data/model/agent_chat_response.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';

class PropertyInteractionPage extends StatefulWidget {
  const PropertyInteractionPage({
    Key? key,
  }) : super(key: key);

  @override
  _PropertyInteractionPageState createState() =>
      _PropertyInteractionPageState();
}

class _PropertyInteractionPageState extends State<PropertyInteractionPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedEntries = 10;
  String _searchQuery = '';

  PropertyInterestController _controller =
      Get.put(PropertyInterestController());
  final ChatController chatController = Get.find<ChatController>();
  // AuthService _authService = Get.put(AuthService());

  @override
  void initState() {
    super.initState();
    // _controller = Get.find<PropertyInterestController>();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (FirebaseAuth.instance.currentUser?.uid != null) {
      await _controller.fetchAgentChats(FirebaseAuth.instance.currentUser!.uid);
    } else {
      Get.snackbar("Retry", "No User Found Please Login Again !",
          backgroundColor: AppColors.error);
    }
  }

  List<Interest> get _filteredInterests {
    final interests = _controller.chatData.value?.data.interests ?? [];

    if (_searchQuery.isEmpty) {
      return interests.take(_selectedEntries).toList();
    }

    return interests
        .where((interest) =>
            interest.propertyTitle
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            interest.agentName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            interest.userName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            interest.unitTitle
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .take(_selectedEntries)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Property Interests',
          style: TextStyle(
            fontSize: appBarTitles,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: iconSize),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return Center(child: CustomLoaderWidget());
        }

        if (_controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.redColor,
                ),
                SizedBox(height: 16),
                Text(
                  'Error Loading Data',
                  style: TextStyle(
                    fontSize: H18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth4),
                  child: Text(
                    _controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: detailContentTitle,
                      color: AppColors.black600,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchData,
                  child: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final chatData = _controller.chatData.value;
        if (chatData == null) {
          return Center(
            child: Text(
              'No data available',
              style: TextStyle(
                fontSize: H18,
                color: AppColors.black600,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenWidth4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Interest Counts Section
                _buildPropertyInterestCounts(chatData.data.propertyCounts),
                kHeight(0.03),
                // All Property Interests Section
                _buildAllPropertyInterests(chatData.data.interests),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPropertyInterestCounts(List<PropertyCount> propertyCounts) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth5),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: AppColors.secondaryColor,
                  size: iconSize,
                ),
                kWidth(0.02),
                Text(
                  'Property Interest Counts',
                  style: TextStyle(
                    fontSize: H18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (propertyCounts.isEmpty)
            Container(
              padding: EdgeInsets.all(screenWidth5),
              child: Center(
                child: Text(
                  'No property counts available',
                  style: TextStyle(
                    fontSize: detailContentTitle,
                    color: AppColors.black600,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: propertyCounts.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColors.lightGrey2,
              ),
              itemBuilder: (context, index) {
                final item = propertyCounts[index];
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth5,
                    vertical: screenHeight2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.propertyTitle,
                          style: TextStyle(
                            fontSize: tagTitle,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth2,
                              vertical: screenHeight05,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.count,
                              style: TextStyle(
                                fontSize: tagTitle,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total: ${item.count}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: detailContentTitle,
                                color: AppColors.black600,
                              ),
                            ),
                            if (item.soldCount != '0')
                              Text(
                                'Sold: ${item.soldCount}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: detailContentTitle,
                                  color: AppColors.onlineGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAllPropertyInterests(List<Interest> interests) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(screenWidth5),
            decoration: BoxDecoration(
              color: AppColors.secondaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: AppColors.white,
                  size: iconSize,
                ),
                kWidth(0.02),
                Text(
                  'All Property Interests (${interests.length})',
                  style: TextStyle(
                    fontSize: H18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Spacer(),
                if (_controller.chatData.value?.data.unrepliedCount != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth2,
                      vertical: screenHeight05,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.white),
                      color: AppColors.redColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Unreplied: ${_controller.chatData.value!.data.unrepliedCount}',
                      style: TextStyle(
                        fontSize: detailContentTitle,
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          kHeight(0.02),

          // Action Buttons
          // Container(
          //   padding: EdgeInsets.all(screenWidth4),
          //   child: Row(
          //     children: [
          //       _buildActionButton(
          //           'Excel', Icons.file_download, AppColors.onlineGreen),
          //       kWidth(0.02),
          //       _buildActionButton(
          //           'PDF', Icons.picture_as_pdf, AppColors.redColor),
          //       kWidth(0.02),
          //       _buildActionButton('Print', Icons.print, AppColors.blueColor),
          //     ],
          //   ),
          // ),

          // Search and Entries
          Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth4),
            child: Row(
              children: [
                Text(
                  'Show',
                  style: TextStyle(
                    fontSize: detailContentTitle,
                    color: AppColors.black600,
                  ),
                ),
                kWidth(0.02),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightGrey2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedEntries,
                    underline: SizedBox(),
                    items: [10, 25, 50, 100].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEntries = value!;
                      });
                    },
                  ),
                ),
                kWidth(0.02),
                Text(
                  'entries',
                  style: TextStyle(
                    fontSize: detailContentTitle,
                    color: AppColors.black600,
                  ),
                ),
                Spacer(),
                Container(
                  width: screenWidth35,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search interests...',
                      hintStyle: TextStyle(fontSize: detailContentTitle),
                      prefixIcon: Icon(Icons.search, size: smallIconSize),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.lightGrey2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth2,
                        vertical: screenHeight1,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          kHeight(0.02),

          // Table
          _buildInterestsTable(),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth3,
        vertical: screenHeight1,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: smallIconSize),
          kWidth(0.01),
          Text(
            text,
            style: TextStyle(
              fontSize: detailContentTitle,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsTable() {
    final filteredInterests = _filteredInterests;

    return Container(
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.all(screenWidth4),
            decoration: BoxDecoration(
              color: AppColors.lightGrey2,
              border: Border(
                bottom: BorderSide(color: AppColors.lightGrey),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: tagTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Property',
                    style: TextStyle(
                      fontSize: tagTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                // Expanded(
                //   flex: 2,
                //   child: Text(
                //     'Agent',
                //     style: TextStyle(
                //       fontSize: tagTitle,
                //       fontWeight: FontWeight.bold,
                //       color: AppColors.black,
                //     ),
                //   ),
                // ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'User',
                    style: TextStyle(
                      fontSize: tagTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Unit Type',
                    style: TextStyle(
                      fontSize: tagTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: tagTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: tagTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          if (filteredInterests.isEmpty)
            Container(
              padding: EdgeInsets.all(screenWidth5),
              child: Center(
                child: Text(
                  'No interests found',
                  style: TextStyle(
                    fontSize: detailContentTitle,
                    color: AppColors.black600,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredInterests.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColors.lightGrey2,
              ),
              itemBuilder: (context, index) {
                final interest = filteredInterests[index];
                return Container(
                  padding: EdgeInsets.all(screenWidth4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            fontSize: detailContentTitle,
                            color: AppColors.black600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              interest.propertyTitle,
                              style: TextStyle(
                                fontSize: detailContentTitle,
                                color: AppColors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (interest.unitTitle.isNotEmpty)
                              Text(
                                interest.unitTitle,
                                style: TextStyle(
                                  fontSize: detailContentTitle - 1,
                                  color: AppColors.black600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Expanded(
                      //   flex: 2,
                      //   child: Text(
                      //     interest.agentName,
                      //     style: TextStyle(
                      //       fontSize: detailContentTitle,
                      //       color: AppColors.black600,
                      //     ),
                      //   ),
                      // ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: screenWidth3,
                              backgroundColor: interest.userPhoto != null
                                  ? AppColors.primaryColor
                                  : AppColors.secondaryColor,
                              child: interest.userPhoto != null
                                  ? ClipOval(
                                      child: Image.network(
                                        interest.userPhoto!,
                                        width: screenWidth6,
                                        height: screenWidth6,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Text(
                                            interest.userName
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: detailContentTitle,
                                              color: AppColors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Text(
                                      interest.userName
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: detailContentTitle,
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            kWidth(0.02),
                            Expanded(
                              child: Text(
                                interest.userName,
                                style: TextStyle(
                                  fontSize: detailContentTitle,
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          interest.unitTitle.isNotEmpty
                              ? interest.unitTitle
                              : 'N/A',
                          style: TextStyle(
                            fontSize: detailContentTitle,
                            color: AppColors.black600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth1,
                                vertical: screenHeight05,
                              ),
                              decoration: BoxDecoration(
                                color: interest.unreplied
                                    ? AppColors.redColor
                                    : AppColors.onlineGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                interest.unreplied ? 'Unreplied' : 'Replied',
                                style: TextStyle(
                                  fontSize: detailContentTitle - 1,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(
                            Icons.remove_red_eye,
                            color: AppColors.secondaryColor,
                            size: smallIconSize,
                          ),
                          onPressed: () {
                            final agentEmail =
                                FirebaseAuth.instance.currentUser?.email ?? "";
                            ''; // Get email from otherUser data
                            // final propertyName = chat['propertyId'] ??
                            //     'Unknown Property'; // Get property name

                            debugPrint('Chat ID: ${interest.firebaseChatId}');
                            chatController.navigateToAgentChat(agentEmail,
                                propertyId: interest.propertyId,
                                chatId: interest.firebaseChatId);
                            // Navigate to chat detail page
                            // You can use interest.firebaseChatId for navigation
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
