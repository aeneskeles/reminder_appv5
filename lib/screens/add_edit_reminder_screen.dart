import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class AddEditReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const AddEditReminderScreen({super.key, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isRecurring = false;
  String _selectedCategory = 'Genel';
  String? _recurrencePattern;

  final List<String> _categories = ['Genel', 'Okul', 'İş', 'Sağlık'];
  final List<String> _recurrenceOptions = ['Günlük', 'Haftalık', 'Aylık'];

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _descriptionController.text = widget.reminder!.description;
      _selectedDate = widget.reminder!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.reminder!.dateTime);
      _isRecurring = widget.reminder!.isRecurring;
      _selectedCategory = widget.reminder!.category;
      _recurrencePattern = widget.reminder!.recurrencePattern;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  String? _getRecurrencePatternValue(String? displayValue) {
    if (displayValue == null) return null;
    switch (displayValue) {
      case 'Günlük':
        return 'daily';
      case 'Haftalık':
        return 'weekly';
      case 'Aylık':
        return 'monthly';
      default:
        return null;
    }
  }

  String? _getRecurrencePatternDisplay(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'daily':
        return 'Günlük';
      case 'weekly':
        return 'Haftalık';
      case 'monthly':
        return 'Aylık';
      default:
        return null;
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      final reminder = Reminder(
        id: widget.reminder?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: _combinedDateTime,
        isRecurring: _isRecurring,
        category: _selectedCategory,
        recurrencePattern: _isRecurring ? _getRecurrencePatternValue(_recurrencePattern) : null,
        isCompleted: widget.reminder?.isCompleted ?? false,
      );

      if (widget.reminder == null) {
        // Yeni hatırlatıcı ekle
        final id = await _dbHelper.insertReminder(reminder);
        final savedReminder = reminder.copyWith(id: id);
        if (!savedReminder.isCompleted) {
          await _notificationService.scheduleNotification(savedReminder);
        }
      } else {
        // Hatırlatıcı güncelle
        await _dbHelper.updateReminder(reminder);
        await _notificationService.rescheduleNotification(reminder);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Yeni Hatırlatıcı' : 'Hatırlatıcıyı Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir başlık girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir açıklama girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tarih
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Tarih'),
                  subtitle: Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 8),

              // Saat
              Card(
                child: ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Saat'),
                  subtitle: Text(_selectedTime.format(context)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectTime,
                ),
              ),
              const SizedBox(height: 16),

              // Kategori
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? 'Genel';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Tekrar eden
              SwitchListTile(
                title: const Text('Tekrar Eden Hatırlatıcı'),
                subtitle: const Text('Bu hatırlatıcı belirli aralıklarla tekrarlansın mı?'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurrencePattern = null;
                    } else if (_recurrencePattern == null) {
                      _recurrencePattern = _recurrenceOptions[0];
                    }
                  });
                },
              ),

              // Tekrar deseni
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _recurrencePattern ?? _recurrenceOptions[0],
                  decoration: const InputDecoration(
                    labelText: 'Tekrar Sıklığı',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: _recurrenceOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _recurrencePattern = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Kaydet butonu
              ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kaydet',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

