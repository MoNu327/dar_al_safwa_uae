import 'package:majan/presentation/view/dashboard/controller/property_interests_controller.dart';
import 'package:majan/presentation/view/inbox/controller/inbox_controller.dart';
import 'package:majan/presentation/widgets/loader_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:majan/data/model/agent_chat_response.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';

class PropertyInteractionPage extends StatefulWidget {
  const PropertyInteractionPage({Key? key}) : super(key: key);

  @override
  _PropertyInteractionPageState createState() =>
      _PropertyInteractionPageState();
}

class _PropertyInteractionPageState extends State<PropertyInteractionPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedEntries = 10;
  String _searchQuery = '';

  final PropertyInterestController _controller =
      Get.put(PropertyInterestController());
  final ChatController chatController = Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
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
            (interest.propertyTitle ?? "")
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (interest.agentName ?? "")
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (interest.userName ?? "")
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (interest.unitTitle ?? "")
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
          return _buildErrorState();
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
                _buildPropertyInterestCounts(chatData.data.propertyCounts ?? []),
                kHeight(0.03),
                _buildAllPropertyInterests(chatData.data.interests ?? []),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.redColor),
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

  Widget _buildPropertyInterestCounts(List<PropertyCount> propertyCounts) {
    return Container(
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerTile(
            title: "Property Interest Counts",
            icon: Icons.bar_chart,
            bgColor: AppColors.primaryColor,
            textColor: AppColors.secondaryColor,
          ),
          if (propertyCounts.isEmpty)
            _emptyState("No property counts available")
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: propertyCounts.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.lightGrey2),
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
                          item.propertyTitle ?? "N/A",
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
                          child: _pill(item.count),
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
                            if (item.soldCount != "0")
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
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerTile(
            title: "All Property Interests (${interests.length})",
            icon: Icons.list_alt,
            bgColor: AppColors.secondaryColor,
            textColor: AppColors.white,
            unrepliedCount: _controller.chatData.value?.data.unrepliedCount ?? 0,
          ),
          kHeight(0.02),
          _buildSearchAndEntries(),
          kHeight(0.02),
          _buildInterestsTable(),
        ],
      ),
    );
  }

  Widget _buildInterestsTable() {
    final filteredInterests = _filteredInterests;

    if (filteredInterests.isEmpty) {
      return _emptyState("No interests found");
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredInterests.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: AppColors.lightGrey2),
      itemBuilder: (context, index) {
        final interest = filteredInterests[index];
        final userName = interest.userName ?? "Unknown";
        final unitTitle = interest.unitTitle ?? "";
        final propertyTitle = interest.propertyTitle ?? "N/A";

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
                      propertyTitle,
                      style: TextStyle(
                        fontSize: detailContentTitle,
                        color: AppColors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (unitTitle.isNotEmpty)
                      Text(
                        unitTitle,
                        style: TextStyle(
                          fontSize: detailContentTitle - 1,
                          color: AppColors.black600,
                        ),
                      ),
                  ],
                ),
              ),
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
                                errorBuilder: (_, __, ___) =>
                                    _avatarText(userName),
                              ),
                            )
                          : _avatarText(userName),
                    ),
                    kWidth(0.02),
                    Expanded(
                      child: Text(
                        userName,
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
                  unitTitle.isNotEmpty ? unitTitle : 'N/A',
                  style: TextStyle(
                    fontSize: detailContentTitle,
                    color: AppColors.black600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _pill(
                  interest.unreplied ? "Unreplied" : "Replied",
                  color: interest.unreplied
                      ? AppColors.redColor
                      : AppColors.onlineGreen,
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: Icon(Icons.remove_red_eye,
                      color: AppColors.secondaryColor, size: smallIconSize),
                  onPressed: () {
                    final agentEmail =
                        FirebaseAuth.instance.currentUser?.email ?? "";
                    debugPrint('Chat ID: ${interest.firebaseChatId}');
                    debugPrint('Agent Email: $agentEmail');
                    debugPrint('Property ID: ${interest.propertyId}');
                    debugPrint('Unit ID: ${interest.unitId}');
                    debugPrint('Property Name: ${interest.propertyTitle}');
                    debugPrint('User Name: ${interest.userName}');
                    chatController.navigateToAgentChat(
    agentEmail,
    propertyId: interest.propertyId,
    chatId: interest.firebaseChatId ?? '',
    unitId: interest.unitId,
    propertyName: interest.propertyTitle,
    userName: interest.userName, // Pass the user name
  );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Helpers ----------

  BoxDecoration _boxDecoration() => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  Widget _headerTile({
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    int? unrepliedCount,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: iconSize),
          kWidth(0.02),
          Text(
            title,
            style: TextStyle(
              fontSize: H18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Spacer(),
          if (unrepliedCount != null && unrepliedCount > 0)
            _pill("Unreplied: $unrepliedCount", color: AppColors.redColor),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) => Container(
        padding: EdgeInsets.all(screenWidth5),
        child: Center(
          child: Text(
            msg,
            style: TextStyle(
              fontSize: detailContentTitle,
              color: AppColors.black600,
            ),
          ),
        ),
      );

  Widget _pill(String text, {Color color = AppColors.secondaryColor}) =>
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth2,
          vertical: screenHeight05,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: tagTitle,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      );

  Widget _avatarText(String name) {
    final initial =
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "?";
    return Text(
      initial,
      style: TextStyle(
        fontSize: detailContentTitle,
        color: AppColors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSearchAndEntries() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth4),
      child: Row(
        children: [
          Text("Show",
              style: TextStyle(
                fontSize: detailContentTitle,
                color: AppColors.black600,
              )),
          kWidth(0.02),
          DropdownButton<int>(
            value: _selectedEntries,
            underline: SizedBox(),
            items: [10, 25, 50, 100].map((v) {
              return DropdownMenuItem<int>(
                value: v,
                child: Text(v.toString()),
              );
            }).toList(),
            onChanged: (v) {
              setState(() {
                _selectedEntries = v!;
              });
            },
          ),
          kWidth(0.02),
          Text("entries",
              style: TextStyle(
                fontSize: detailContentTitle,
                color: AppColors.black600,
              )),
          Spacer(),
          SizedBox(
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
