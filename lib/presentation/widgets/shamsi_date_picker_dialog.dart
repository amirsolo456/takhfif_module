import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../shared/utils/iran_format.dart';

class ShamsiDatePickerDialog extends StatefulWidget {
  final Jalali initialDate;
  final Jalali? minDate;
  final Jalali? maxDate;

  const ShamsiDatePickerDialog({
    super.key,
    required this.initialDate,
    this.minDate,
    this.maxDate,
  });

  static Future<Jalali?> show({
    required BuildContext context,
    Jalali? initialDate,
    Jalali? minDate,
    Jalali? maxDate,
  }) async {
    return showDialog<Jalali>(
      context: context,
      builder: (context) => ShamsiDatePickerDialog(
        initialDate: initialDate ?? Jalali.now(),
        minDate: minDate ?? Jalali(1380, 1, 1),
        maxDate: maxDate ?? Jalali(1420, 12, 29),
      ),
    );
  }

  @override
  State<ShamsiDatePickerDialog> createState() => _ShamsiDatePickerDialogState();
}

class _ShamsiDatePickerDialogState extends State<ShamsiDatePickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  static const List<String> _months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
  }

  int get _maxDaysInMonth {
    final j = Jalali(_selectedYear, _selectedMonth, 1);
    return j.monthLength;
  }

  void _clampDay() {
    final maxDays = _maxDaysInMonth;
    if (_selectedDay > maxDays) {
      _selectedDay = maxDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minYear = widget.minDate?.year ?? 1380;
    final maxYear = widget.maxDate?.year ?? 1420;
    final years = List<int>.generate(maxYear - minYear + 1, (i) => minYear + i);

    _clampDay();

    final currentJalali = Jalali(_selectedYear, _selectedMonth, _selectedDay);
    final formattedDate =
        '${IranFormat.digits(_selectedYear)}/${IranFormat.digits(_selectedMonth.toString().padLeft(2, '0'))}/${IranFormat.digits(_selectedDay.toString().padLeft(2, '0'))}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'انتخاب تاریخ شمسی',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontFamily: 'BYekan',
                        fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Year & Month Selection Row
              Row(
                children: [
                  // Year Dropdown
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('سال', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedYear,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: years.map((y) {
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text(
                                IranFormat.digits(y),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedYear = val;
                                _clampDay();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Month Dropdown
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ماه', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedMonth,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: List.generate(12, (i) {
                            final monthNum = i + 1;
                            return DropdownMenuItem<int>(
                              value: monthNum,
                              child: Text(
                                '${IranFormat.digits(monthNum)}. ${_months[i]}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedMonth = val;
                                _clampDay();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Day Grid Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('روز', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _maxDaysInMonth,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final isSelected = day == _selectedDay;
                        return InkWell(
                          onTap: () => setState(() => _selectedDay = day),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              IranFormat.digits(day),
                              style: TextStyle(
                                fontFamily: 'BYekan',
                                fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                fontSize: 14,
                                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, currentJalali),
                        child: const Text('تایید تاریخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text('انصراف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
