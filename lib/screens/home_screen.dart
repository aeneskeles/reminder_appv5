import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/database_helper.dart';
import '../screens/add_edit_reminder_screen.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final AuthService _authService = AuthService.instance;
  List<Reminder> _reminders = [];
  List<Reminder> _filteredReminders = [];
  bool _showCompleted = false;
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final reminders = await _dbHelper.getAllReminders();
    setState(() {
      _reminders = reminders;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Reminder> filtered = _reminders;

    // Tamamlanma durumuna göre filtrele
    if (!_showCompleted) {
      filtered = filtered.where((r) => !r.isCompleted).toList();
    }

    // Kategoriye göre filtrele
    if (_selectedCategory != 'Tümü') {
      filtered = filtered.where((r) => r.category == _selectedCategory).toList();
    }

    // Arama sorgusuna göre filtrele
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) =>
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    setState(() {
      _filteredReminders = filtered;
    });
  }

  List<String> _getCategories() {
    final categories = _reminders.map((r) => r.category).toSet().toList();
    categories.sort();
    return ['Tümü', ...categories];
  }

  Future<void> _toggleCompletion(Reminder reminder) async {
    final updated = reminder.copyWith(isCompleted: !reminder.isCompleted);
    await _dbHelper.updateReminder(updated);
    if (!updated.isCompleted) {
      await _notificationService.rescheduleNotification(updated);
    } else {
      if (reminder.id != null) {
        await _notificationService.cancelNotification(reminder.id!);
      }
    }
    _loadReminders();
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hatırlatıcıyı Sil'),
        content: const Text('Bu hatırlatıcıyı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && reminder.id != null) {
      await _dbHelper.deleteReminder(reminder.id!);
      if (reminder.id != null) {
        await _notificationService.cancelNotification(reminder.id!);
      }
      _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hatırlatıcı silindi')),
        );
      }
    }
  }

  Future<void> _navigateToAddEdit(Reminder? reminder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditReminderScreen(reminder: reminder),
      ),
    );

    if (result == true) {
      _loadReminders();
    }
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Okul': Colors.blue,
      'İş': Colors.orange,
      'Sağlık': Colors.red,
      'Genel': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hatırlatıcılar'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _authService.signOut();
                // Auth state değiştiği için otomatik olarak AuthScreen'e yönlendirilecek
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Hatırlatıcı ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),

          // Filtreler
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Kategori filtresi
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _getCategories().map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value ?? 'Tümü';
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Tamamlananları göster/gizle
                FilterChip(
                  label: Text(_showCompleted ? 'Tamamlananları Gizle' : 'Tamamlananları Göster'),
                  selected: _showCompleted,
                  onSelected: (value) {
                    setState(() {
                      _showCompleted = value;
                    });
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Hatırlatıcı listesi
          Expanded(
            child: _filteredReminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _reminders.isEmpty ? 'Henüz hatırlatıcı yok' : 'Sonuç bulunamadı',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _filteredReminders[index];
                      return _buildReminderCard(reminder);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(null),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Hatırlatıcı'),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR');
    final isPast = reminder.dateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(reminder.category),
          child: Text(
            reminder.category[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(reminder.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(reminder.dateTime),
                  style: TextStyle(
                    color: isPast && !reminder.isCompleted ? Colors.red : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (reminder.isRecurring) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    reminder.recurrencePattern ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(reminder.category),
              backgroundColor: _getCategoryColor(reminder.category).withOpacity(0.2),
              labelStyle: TextStyle(
                color: _getCategoryColor(reminder.category),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                reminder.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: reminder.isCompleted ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleCompletion(reminder),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _navigateToAddEdit(reminder),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteReminder(reminder),
            ),
          ],
        ),
      ),
    );
  }
}

