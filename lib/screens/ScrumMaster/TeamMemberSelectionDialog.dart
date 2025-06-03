import 'package:flutter/material.dart';
import '../../widgets/sm_drawer.dart';
import '../../widgets/sm_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/project_service.dart';
import 'package:provider/provider.dart';

class TeamMemberSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> currentAssignedMembers;
  final String projectId;

  const TeamMemberSelectionDialog({
    Key? key,
    required this.currentAssignedMembers,
    required this.projectId,
  }) : super(key: key);

  @override
  _TeamMemberSelectionDialogState createState() => _TeamMemberSelectionDialogState();
}

class _TeamMemberSelectionDialogState extends State<TeamMemberSelectionDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _projectMembers = [];
  List<Map<String, dynamic>> _selectedMembers = [];
  bool _createSubTeam = false;
  final TextEditingController _subTeamNameController = TextEditingController();
  List<Map<String, dynamic>> _selectedForSubTeam = [];

  @override
  void initState() {
    super.initState();
    _selectedMembers =
    List<Map<String, dynamic>>.from(widget.currentAssignedMembers);
    _loadTeamMembers();
  }

  // Modified load team members method to show ONLY Team Members
  Future<void> _loadTeamMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Dialog: Loading ONLY Team Members for project ID: ${widget
          .projectId}');

      // Check if projectId is valid
      if (widget.projectId.isEmpty) {
        print('Dialog ERROR: Invalid projectId (empty)');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Use ProjectService to get the project data
      final projectService = Provider.of<ProjectService>(
          context, listen: false);

      // Get the project
      final project = projectService.projects.firstWhere(
            (p) => p['id'] == widget.projectId,
        orElse: () => <String, dynamic>{},
      );

      print('Dialog: Project found: ${project.isNotEmpty}');
      if (project.isEmpty) {
        print('Dialog ERROR: Project not found');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Dialog: Project name: ${project['name']}');

      List<Map<String, dynamic>> teamMembersOnly = [];

      // Check for role-based structure first (new implementation)
      if (project.containsKey('roles') && project['roles'] != null) {
        final roles = project['roles'];
        print('Dialog: Project has roles structure: ${roles.keys.toList()}');

        // Get ONLY Team Members from roles.teamMembers
        if (roles.containsKey('teamMembers') && roles['teamMembers'] is List) {
          final tmIds = roles['teamMembers'] as List;
          print(
              'Dialog: Found ${tmIds.length} Team Members in roles structure');
          for (var tmId in tmIds) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(tmId)
                .get();

            if (userDoc.exists && userDoc.data() != null) {
              teamMembersOnly.add({
                'id': userDoc.id,
                ...userDoc.data()!,
                'role': 'Team Member', // Ensure role is set correctly
              });
            }
          }
        }

        print('Dialog: Loaded ${teamMembersOnly
            .length} Team Members from roles structure');
      }

      // Fall back to legacy structure if no members found in roles
      if (teamMembersOnly.isEmpty && project.containsKey('members') &&
          project['members'] is List) {
        print('Dialog: Falling back to legacy members array structure');
        final List<dynamic> legacyMemberIds = project['members'] as List;

        print('Dialog: Found ${legacyMemberIds
            .length} members in legacy structure');

        // Fetch user data for each member and filter for Team Members only
        for (String memberId in legacyMemberIds) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final userData = userDoc.data()!;
            // Only include Team Members (exclude Scrum Masters, Product Owners, and Clients)
            final userRole = userData['role'];
            if (userRole == 'Team Member') {
              teamMembersOnly.add({
                'id': userDoc.id,
                ...userData,
              });
            }
          }
        }

        print('Dialog: Loaded ${teamMembersOnly
            .length} Team Members from legacy structure');
      }

      setState(() {
        _projectMembers = teamMembersOnly;
        _isLoading = false;
      });

      print('Dialog: Final result - ${_projectMembers
          .length} Team Members available for assignment');
    } catch (e) {
      print('Dialog ERROR: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleMemberForSubTeam(Map<String, dynamic> member) {
    setState(() {
      final int index = _selectedForSubTeam.indexWhere((m) => m['id'] == member['id']);
      if (index != -1) {
        _selectedForSubTeam.removeAt(index);
        print('Removed member from sub-team: ${member['name']}');
      } else {
        _selectedForSubTeam.add(member);
        print('Added member to sub-team: ${member['name']}');
      }
    });
  }

  void _toggleMemberSelection(Map<String, dynamic> member) {
    setState(() {
      // Clear all previous selections first (radio button behavior)
      _selectedMembers.clear();

      // Always create a sub-team structure, even for individual assignments
      // This ensures consistency with how sub-teams are handled
      final individualAsSubTeam = {
        'id': 'individual_${member['id']}_${DateTime
            .now()
            .millisecondsSinceEpoch}',
        'name': '${member['name']} (Individual)',
        'members': [member],
        // Put individual in members array
        'isIndividual': true,
        // Flag to identify this as an individual assignment
      };

      _selectedMembers.add(individualAsSubTeam);
      print('Selected member as sub-team structure: ${member['name']}');
    });
  }

  // Create a sub-team from selected members
  void _confirmSubTeam() {
    if (_subTeamNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a sub-team name')),
      );
      return;
    }

    if (_selectedForSubTeam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    // Create sub-team object
    final subTeam = {
      'id': DateTime
          .now()
          .millisecondsSinceEpoch
          .toString(),
      'name': _subTeamNameController.text,
      'members': _selectedForSubTeam,
    };

    print('Creating sub-team: ${subTeam['name']} with ${_selectedForSubTeam
        .length} members');

    setState(() {
      // Add to selected members
      _selectedMembers.add(subTeam);

      // Clear sub-team creation state
      _createSubTeam = false;
      _selectedForSubTeam = [];
      _subTeamNameController.clear();
    });
  }

  // Sub-team creation content
  Widget _buildSubTeamCreationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Sub-Team',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _subTeamNameController,
                decoration: InputDecoration(
                  labelText: 'Sub-Team Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Select members:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _projectMembers.length,
            itemBuilder: (context, index) {
              final member = _projectMembers[index];
              final bool isSelected = _selectedForSubTeam.any((m) => m['id'] == member['id']);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Color(0xFF004AAD) : Colors.grey[400],
                  child: Text(
                    member['name']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  member['name'] ?? 'Member',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  member['email'] ?? 'No email',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                trailing: Checkbox(
                  value: isSelected,
                  activeColor: Color(0xFF004AAD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (bool? value) {
                    _toggleMemberForSubTeam(member);
                  },
                ),
                onTap: () {
                  _toggleMemberForSubTeam(member);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Member selection content with radio buttons
  Widget _buildMemberSelectionContent() {
    if (_projectMembers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No team members available for this project',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    // Show selected members at the top
    final List<Widget> selectedMemberChips = _selectedMembers.map((member) {
      // Check if this is a sub-team
      final bool isSubTeam = member.containsKey('members') && member['members'] is List;
      final String name = member['name'] ?? (isSubTeam ? 'Sub-Team' : 'Member');

      return Padding(
        padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
        child: Chip(
          backgroundColor: Color(0xFF004AAD).withOpacity(0.1),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSubTeam) Icon(Icons.group, size: 16, color: Color(0xFF004AAD)),
              if (isSubTeam) SizedBox(width: 4),
              Text(
                name,
                style: TextStyle(color: Color(0xFF004AAD)),
              ),
            ],
          ),
          deleteIcon: Icon(Icons.close, size: 18, color: Color(0xFF004AAD)),
          onDeleted: () {
            setState(() {
              _selectedMembers.remove(member);
            });
          },
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedMemberChips.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  children: selectedMemberChips,
                ),
              ],
            ),
          ),
          Divider(height: 1),
        ],

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Team Members (Select one):',  // Updated text to indicate single selection
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: _projectMembers.length,
            itemBuilder: (context, index) {
              final member = _projectMembers[index];
              final bool isSelected = _selectedMembers.any((selectedItem) {
                // Check if this is a direct selection
                if (selectedItem['id'] == member['id'] && !selectedItem.containsKey('members')) {
                  return true;
                }
                // Check if member is inside a sub-team structure
                if (selectedItem.containsKey('members') && selectedItem['members'] is List) {
                  final List<dynamic> members = selectedItem['members'];
                  return members.any((m) => m['id'] == member['id']);
                }
                return false;
              });

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Color(0xFF004AAD) : Colors.grey[400],
                  child: Text(
                    member['name']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  member['name'] ?? 'Member',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  member['email'] ?? 'No email',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                trailing: Radio<String>(
                  value: member['id'],
                  groupValue: isSelected ? member['id'] : null,
                  activeColor: Color(0xFF004AAD),
                  onChanged: (String? value) {
                    _toggleMemberSelection(member);
                  },
                ),
                onTap: () {
                  _toggleMemberSelection(member);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFFFDFDFD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF004AAD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.group, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assign Team Members',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(color: Color(0xFF004AAD)),
              )
                  : _createSubTeam
                  ? _buildSubTeamCreationContent()
                  : _buildMemberSelectionContent(),
            ),
            Divider(height: 1),
            // Bottom action buttons
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_createSubTeam)
                    TextButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_add, size: 18),
                          SizedBox(width: 4),
                          Text('Sub-Team'),
                        ],
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF004AAD),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                      onPressed: () {
                        setState(() {
                          _createSubTeam = true;
                          _selectedForSubTeam = [];
                        });
                      },
                    )
                  else
                    TextButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 18),
                          SizedBox(width: 4),
                          Text('Back'),
                        ],
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                      onPressed: () {
                        setState(() {
                          _createSubTeam = false;
                          _selectedForSubTeam = [];
                          _subTeamNameController.clear();
                        });
                      },
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 90, // Fixed width to ensure it fits
                        child: ElevatedButton(
                          child: Text(
                            _createSubTeam ? 'Create' : 'Confirm',
                            style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF004AAD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          ),
                          onPressed: () {
                            if (_createSubTeam) {
                              _confirmSubTeam();
                            } else {
                              Navigator.pop(context, _selectedMembers);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}