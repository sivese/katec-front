import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

// 시간 포맷터 클래스 추가
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 숫자와 콜론만 허용
    final text = newValue.text.replaceAll(RegExp(r'[^0-9:]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 콜론이 없으면 자동으로 추가
    String formattedText = text;
    if (!text.contains(':')) {
      if (text.length <= 2) {
        formattedText = text;
      } else if (text.length <= 4) {
        formattedText = '${text.substring(0, 2)}:${text.substring(2)}';
      } else {
        formattedText = '${text.substring(0, 2)}:${text.substring(2, 4)}';
      }
    }

    // 시간 유효성 검사
    if (formattedText.contains(':')) {
      final parts = formattedText.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;

        // 시간 범위 제한 (00-23)
        if (hour > 23) {
          formattedText = '23:${parts[1]}';
        }

        // 분 범위 제한 (00-59)
        if (minute > 59) {
          formattedText = '${parts[0]}:59';
        }
      }
    }

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

enum ScheduleType { accommodation, transportation, other, dining }

class AddScheduleScreen extends StatefulWidget {
  final Trip trip;
  final Activity? accommodation; // null이면 추가, 있으면 수정
  final Activity? transportation; // null이면 추가, 있으면 수정
  final Activity? other; // null이면 추가, 있으면 수정
  final Activity? dining; // null이면 추가, 있으면 수정
  final Recommendation? recommendation; // 추천 데이터로부터 일정 추가 시 사용

  const AddScheduleScreen({
    super.key,
    required this.trip,
    this.accommodation,
    this.transportation,
    this.other,
    this.dining,
    this.recommendation,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _bookingReferenceController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // 교통 입력용 컨트롤러
  final _transportTypeController = TextEditingController();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _departureTimeController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  DateTime? _transportDepartureDate;
  DateTime? _transportArrivalDate;

  ScheduleType _selectedType = ScheduleType.accommodation;

  // 교통수단 선택 인덱스 (0: Flight, 1: Train, 2: Bus, 3: Car, 4: Taxi, 5: Other)
  int _selectedTransportType = 0;

  @override
  void initState() {
    super.initState();
    if (widget.accommodation != null) {
      // 수정 모드: 기존 값 세팅
      final acc = widget.accommodation!;
      _titleController.text = acc.title;
      _descriptionController.text = acc.description;
      _locationController.text = acc.location;
      _bookingReferenceController.text = acc.bookingReference ?? '';
      _startDate = acc.startTime;
      _endDate = acc.endTime;
      _selectedType = acc.type == ActivityType.accommodation
          ? ScheduleType.accommodation
          : ScheduleType.transportation;
    } else if (widget.transportation != null) {
      // 교통 수정 모드: 기존 값 세팅
      final transport = widget.transportation!;
      _transportDepartureDate = transport.startTime;
      _transportArrivalDate = transport.endTime;
      _selectedType = ScheduleType.transportation;
      _selectedTransportType = transport.transportationType ?? 0;
      _transportTypeController.text = _transportTypeString(
        _selectedTransportType,
      );
      _departureController.text = transport.departure ?? '';
      _arrivalController.text = transport.destination ?? '';
      _bookingReferenceController.text = transport.bookingReference ?? '';
    } else if (widget.other != null) {
      // 기타 수정 모드: 기존 값 세팅
      final other = widget.other!;
      _titleController.text = other.title;
      _descriptionController.text = other.description;
      _locationController.text = other.location;
      _startDate = other.startTime;
      _endDate = other.endTime; // 기타 스케줄은 시작/종료 날짜가 같을 수 있으므로 종료일도 설정
      _selectedType = ScheduleType.other;
      _departureTimeController.text =
          '${other.startTime.hour.toString().padLeft(2, '0')}:${other.startTime.minute.toString().padLeft(2, '0')}';
      _arrivalTimeController.text =
          '${other.endTime.hour.toString().padLeft(2, '0')}:${other.endTime.minute.toString().padLeft(2, '0')}';
    } else if (widget.dining != null) {
      // 식당 수정 모드: 기존 값 세팅
      final dining = widget.dining!;
      _titleController.text = dining.title;
      _descriptionController.text = dining.description;
      _locationController.text = dining.location;
      _startDate = dining.startTime;
      _endDate = dining.endTime;
      _selectedType = ScheduleType.dining;
      _departureTimeController.text =
          '${dining.startTime.hour.toString().padLeft(2, '0')}:${dining.startTime.minute.toString().padLeft(2, '0')}';
      _arrivalTimeController.text =
          '${dining.endTime.hour.toString().padLeft(2, '0')}:${dining.endTime.minute.toString().padLeft(2, '0')}';
    } else if (widget.recommendation != null) {
      // 추천 데이터로부터 일정 추가 모드
      final rec = widget.recommendation!;
      _titleController.text = rec.title;
      _descriptionController.text = rec.description;
      _locationController.text = rec.address ?? rec.location;

      // 추천 시간이 있으면 해당 시간으로 설정 (initState에서는 context 사용 불가)
      if (rec.recommendedStartTime != null && rec.recommendedEndTime != null) {
        // 시간을 문자열로 직접 변환하여 저장
        _departureTimeController.text =
            '${rec.recommendedStartTime!.hour.toString().padLeft(2, '0')}:${rec.recommendedStartTime!.minute.toString().padLeft(2, '0')}';
        _arrivalTimeController.text =
            '${rec.recommendedEndTime!.hour.toString().padLeft(2, '0')}:${rec.recommendedEndTime!.minute.toString().padLeft(2, '0')}';
      }

      // 카테고리에 따라 기본 타입 설정
      switch (rec.category.toLowerCase()) {
        case 'dining':
        case 'food':
          _selectedType = ScheduleType.dining;
          break;
        case 'nature':
        case 'culture':
        case 'shopping':
        case 'entertainment':
          _selectedType = ScheduleType.other;
          break;
        default:
          _selectedType = ScheduleType.other;
      }

      // 추천 데이터가 있을 때는 오늘 날짜를 기본으로 설정 (즉시 추가 가능하도록)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // trip 기간 내에서 오늘 날짜가 유효한지 확인
      if (today.isAfter(
            widget.trip.startDate.subtract(const Duration(days: 1)),
          ) &&
          today.isBefore(widget.trip.endDate.add(const Duration(days: 1)))) {
        _startDate = today;
        _endDate = today;
      } else {
        // trip 기간 밖이면 trip 시작일 사용
        _startDate = widget.trip.startDate;
        _endDate = widget.trip.startDate;
      }
    } else {
      // 추가 모드: Trip의 시작/종료일
      _startDate = widget.trip.startDate;
      _endDate = widget.trip.endDate;
      _selectedType = ScheduleType.accommodation;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _bookingReferenceController.dispose();
    _transportTypeController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _departureTimeController.dispose();
    _arrivalTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? widget.trip.startDate)
          : (_endDate ?? widget.trip.endDate),
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Color(0xFF1E1E1E),
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTransportDate(
    BuildContext context,
    bool isDeparture,
  ) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isDeparture
          ? (_transportDepartureDate ?? DateTime.now())
          : (_transportArrivalDate ??
                DateTime.now().add(const Duration(hours: 2))),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Color(0xFF1E1E1E),
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        if (isDeparture) {
          _transportDepartureDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _transportDepartureDate?.hour ?? 9,
            _transportDepartureDate?.minute ?? 0,
          );
          // 출발 날짜가 선택되면 도착 날짜도 같은 날로 자동 설정
          _transportArrivalDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _transportArrivalDate?.hour ?? 11,
            _transportArrivalDate?.minute ?? 0,
          );
        } else {
          _transportArrivalDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _transportArrivalDate?.hour ?? 11,
            _transportArrivalDate?.minute ?? 0,
          );
        }
      });
    }
  }

  void _onDepartureTimeChanged(String value) {
    if (value.isEmpty) return;

    // HH:MM 형식 검증
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value)) return;

    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    if (_transportDepartureDate != null) {
      setState(() {
        _transportDepartureDate = DateTime(
          _transportDepartureDate!.year,
          _transportDepartureDate!.month,
          _transportDepartureDate!.day,
          hour,
          minute,
        );

        // 출발 시간이 변경되면 도착 시간도 자동으로 설정 (2시간 후)
        _transportArrivalDate = DateTime(
          _transportDepartureDate!.year,
          _transportDepartureDate!.month,
          _transportDepartureDate!.day,
          hour + 2,
          minute,
        );

        // 도착 시간 컨트롤러도 업데이트
        _arrivalTimeController.text =
            '${(hour + 2).toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _onArrivalTimeChanged(String value) {
    if (value.isEmpty) return;

    // HH:MM 형식 검증
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value)) return;

    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    if (_transportArrivalDate != null) {
      setState(() {
        _transportArrivalDate = DateTime(
          _transportArrivalDate!.year,
          _transportArrivalDate!.month,
          _transportArrivalDate!.day,
          hour,
          minute,
        );
      });
    }
  }

  Future<void> _submitAccommodation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      final apiService = ApiService();
      if (widget.accommodation == null) {
        // 추가
        await apiService.createAccommodation(
          token,
          widget.trip.id,
          _startDate!,
          _titleController.text.trim(),
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          _bookingReferenceController.text.trim().isEmpty
              ? null
              : _bookingReferenceController.text.trim(),
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day, 15, 0),
          DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 11, 0),
        );

        var accom = _titleController.text.trim();
        var pushTime = DateTime.now().add(const Duration(seconds: 5));

        apiService.pushMessage("Today check in!", "Don't forget to check in ${accom}!", pushTime.toUtc());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Accommodation added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // 수정
        await apiService.updateAccommodation(
          token,
          widget.accommodation!.id,
          tripId: widget.trip.id,
          accommodationName: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          bookingReference: _bookingReferenceController.text.trim(),
          checkInDate: DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
            15,
            0,
          ),
          checkOutDate: DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            11,
            0,
          ),
          date: DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Accommodation updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save accommodation:  {e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitSchedule() async {
    if (_selectedType == ScheduleType.accommodation) {
      await _submitAccommodation();
      return;
    } else if (_selectedType == ScheduleType.transportation) {
      await _submitTransportation();
      return;
    } else if (_selectedType == ScheduleType.other) {
      await _submitOtherSchedule();
      return;
    } else if (_selectedType == ScheduleType.dining) {
      await _submitDiningSchedule();
      return;
    }
  }

  Future<void> _submitTransportation() async {
    // Transportation input validation
    if (_transportTypeController.text.trim().isEmpty ||
        _departureController.text.trim().isEmpty ||
        _arrivalController.text.trim().isEmpty ||
        _transportDepartureDate == null ||
        _transportArrivalDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all transportation information.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      final apiService = ApiService();

      if (widget.transportation != null) {
        // 수정 모드
        await apiService.updateTransportation(
          token,
          widget.transportation!.id,
          _selectedTransportType.toString(),
          _departureController.text.trim(),
          _arrivalController.text.trim(),
          _transportDepartureDate!,
          _transportArrivalDate!,
          _bookingReferenceController.text.trim().isEmpty
              ? null
              : _bookingReferenceController.text.trim(),
          widget.trip.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transportation schedule updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // 생성 모드
        await apiService.createTransportation(
          token,
          widget.trip.id,
          _selectedTransportType.toString(),
          _departureController.text.trim(),
          _arrivalController.text.trim(),
          _transportDepartureDate!,
          _transportArrivalDate!,
          _bookingReferenceController.text.trim().isEmpty
              ? null
              : _bookingReferenceController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transportation schedule added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${widget.transportation != null ? 'update' : 'add'} transportation: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitOtherSchedule() async {
    // Other schedule input validation
    if (_titleController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _startDate == null ||
        _departureTimeController.text.trim().isEmpty ||
        _arrivalTimeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      final apiService = ApiService();
      if (widget.accommodation != null) {
        // 기존 숙박 수정 로직 (변경 없음)
      } else if (widget.transportation != null) {
        // 기존 교통 수정 로직 (변경 없음)
      } else if (widget.transportation == null &&
          widget.accommodation == null &&
          widget.other != null) {
        // 기타 수정 모드
        await apiService.updateOtherSchedule(
          token,
          widget.other!.id,
          _titleController.text.trim(),
          _locationController.text.trim(),
          _startDate!,
          '${_departureTimeController.text}:00',
          '${_arrivalTimeController.text}:00',
          _descriptionController.text.trim(),
          widget.trip.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Other schedule updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // 생성 모드
        await apiService.createOtherSchedule(
          token,
          widget.trip.id,
          _titleController.text.trim(),
          _locationController.text.trim(),
          _startDate!,
          '${_departureTimeController.text}:00',
          '${_arrivalTimeController.text}:00',
          _descriptionController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Other schedule added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${widget.other != null ? 'update' : 'add'} other schedule: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitDiningSchedule() async {
    // Dining schedule input validation
    if (_titleController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _startDate == null ||
        _departureTimeController.text.trim().isEmpty ||
        _arrivalTimeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      final apiService = ApiService();
      if (widget.dining != null) {
        // 식당 수정 모드
        await apiService.updateDiningSchedule(
          token,
          widget.dining!.id,
          _titleController.text.trim(),
          _locationController.text.trim(),
          _startDate!,
          '${_departureTimeController.text}:00',
          '${_arrivalTimeController.text}:00',
          _descriptionController.text.trim(),
          widget.trip.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dining schedule updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // 생성 모드
        await apiService.createDiningSchedule(
          token,
          widget.trip.id,
          _titleController.text.trim(),
          _locationController.text.trim(),
          _startDate!,
          '${_departureTimeController.text}:00',
          '${_arrivalTimeController.text}:00',
          _descriptionController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dining schedule added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${widget.dining != null ? 'update' : 'add'} dining schedule: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 교통수단 선택 인덱스를 문자열로 변환
  String _transportTypeString(int index) {
    switch (index) {
      case 0:
        return 'Flight';
      case 1:
        return 'Train';
      case 2:
        return 'Bus';
      case 3:
        return 'Car';
      case 4:
        return 'Taxi';
      case 5:
        return 'Other';
      default:
        return 'Other';
    }
  }

  // 문자열을 교통수단 선택 인덱스로 변환
  int _transportTypeIndex(String type) {
    switch (type) {
      case 'Flight':
        return 0;
      case 'Train':
        return 1;
      case 'Bus':
        return 2;
      case 'Car':
        return 3;
      case 'Taxi':
        return 4;
      default:
        return 5;
    }
  }

  // 선택된 교통수단 인덱스를 반환
  int _selectedTransportTypeIndex() {
    return _selectedTransportType;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit =
        widget.accommodation != null ||
        widget.transportation != null ||
        widget.other != null ||
        widget.dining != null;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? 'Edit Schedule' : 'Add Schedule',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 추천 데이터 정보 표시 (있는 경우에만)
                if (widget.recommendation != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Recommendation Data',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendationInfo(
                          'Title',
                          widget.recommendation!.title,
                          Icons.title,
                        ),
                        _buildRecommendationInfo(
                          'Category',
                          widget.recommendation!.category,
                          Icons.category,
                        ),
                        if (widget.recommendation!.recommendedStartTime !=
                                null &&
                            widget.recommendation!.recommendedEndTime != null)
                          _buildRecommendationInfo(
                            'Recommended Time',
                            '${widget.recommendation!.recommendedStartTime!.format(context)} - ${widget.recommendation!.recommendedEndTime!.format(context)}',
                            Icons.access_time,
                          ),
                        if (widget.recommendation!.localTip != null)
                          _buildRecommendationInfo(
                            'Local Tip',
                            widget.recommendation!.localTip!,
                            Icons.tips_and_updates_outlined,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Schedule type selection
                DropdownButtonFormField<ScheduleType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Schedule Type',
                    labelStyle: const TextStyle(color: Color(0xFF888888)),
                    prefixIcon: const Icon(
                      Icons.schedule,
                      color: Color(0xFF888888),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: ScheduleType.accommodation,
                      child: Text('Accommodation'),
                    ),
                    DropdownMenuItem(
                      value: ScheduleType.transportation,
                      child: Text('Transportation'),
                    ),
                    DropdownMenuItem(
                      value: ScheduleType.other,
                      child: Text('Other'),
                    ),
                    DropdownMenuItem(
                      value: ScheduleType.dining,
                      child: Text('Dining'),
                    ),
                  ],
                  onChanged: (ScheduleType? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                if (_selectedType == ScheduleType.accommodation) ...[
                  // 기존 숙박 폼
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Accommodation Name',
                      labelStyle: const TextStyle(color: Color(0xFF888888)),
                      hintText: 'e.g., Grand Hotel Tokyo',
                      hintStyle: const TextStyle(color: Color(0xFF666666)),
                      prefixIcon: const Icon(
                        Icons.hotel,
                        color: Color(0xFF888888),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter accommodation name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: Color(0xFF888888)),
                      hintText: 'e.g., 4-star hotel in the city center',
                      hintStyle: const TextStyle(color: Color(0xFF666666)),
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Color(0xFF888888),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: const TextStyle(color: Color(0xFF888888)),
                      hintText: 'e.g., 1-1-1 Shibuya, Tokyo',
                      hintStyle: const TextStyle(color: Color(0xFF666666)),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Color(0xFF888888),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bookingReferenceController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Booking Reference (Optional)',
                      labelStyle: const TextStyle(color: Color(0xFF888888)),
                      hintText: 'e.g., HOTEL-123456',
                      hintStyle: const TextStyle(color: Color(0xFF666666)),
                      prefixIcon: const Icon(
                        Icons.confirmation_number,
                        color: Color(0xFF888888),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF2A2A2A),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF888888),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(_startDate),
                            style: TextStyle(
                              color: _startDate == null
                                  ? const Color(0xFF888888)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF2A2A2A),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF888888),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(_endDate),
                            style: TextStyle(
                              color: _endDate == null
                                  ? const Color(0xFF888888)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitAccommodation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Add Accommodation',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ] else if (_selectedType == ScheduleType.transportation) ...[
                  // Transportation form
                  DropdownButtonFormField<int>(
                    value: _selectedTransportTypeIndex(),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Flight')),
                      DropdownMenuItem(value: 1, child: Text('Train')),
                      DropdownMenuItem(value: 2, child: Text('Bus')),
                      DropdownMenuItem(value: 3, child: Text('Car')),
                      DropdownMenuItem(value: 4, child: Text('Taxi')),
                      DropdownMenuItem(value: 5, child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTransportType = value ?? 0;
                        _transportTypeController.text = _transportTypeString(
                          _selectedTransportType,
                        );
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Transportation Type',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      prefixIcon: Icon(
                        Icons.directions_transit,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _departureController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Departure',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _arrivalController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTransportDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF3A3A3A),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFF2A2A2A),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF888888),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Departure Date: ${_formatDate(_transportDepartureDate)}',
                                    style: TextStyle(
                                      color: _transportDepartureDate == null
                                          ? const Color(0xFF888888)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _departureTimeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Departure Time',
                            labelStyle: const TextStyle(
                              color: Color(0xFF888888),
                            ),
                            hintText: '09:30',
                            hintStyle: const TextStyle(
                              color: Color(0xFF666666),
                            ),
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: Color(0xFF888888),
                            ),
                            suffixText: 'HH:MM',
                            suffixStyle: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9:]'),
                            ),
                            LengthLimitingTextInputFormatter(5),
                            TimeInputFormatter(), // Auto-format time input
                          ],
                          onChanged: _onDepartureTimeChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTransportDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF3A3A3A),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFF2A2A2A),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF888888),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Arrival Date: ${_formatDate(_transportArrivalDate)}',
                                    style: TextStyle(
                                      color: _transportArrivalDate == null
                                          ? const Color(0xFF888888)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _arrivalTimeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Arrival Time',
                            labelStyle: const TextStyle(
                              color: Color(0xFF888888),
                            ),
                            hintText: '11:30',
                            hintStyle: const TextStyle(
                              color: Color(0xFF666666),
                            ),
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: Color(0xFF888888),
                            ),
                            suffixText: 'HH:MM',
                            suffixStyle: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9:]'),
                            ),
                            LengthLimitingTextInputFormatter(5),
                            TimeInputFormatter(), // Auto-format time input
                          ],
                          onChanged: _onArrivalTimeChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bookingReferenceController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Booking Reference (Optional)',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      prefixIcon: Icon(
                        Icons.confirmation_number,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Add Transportation',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ] else if (_selectedType == ScheduleType.other) ...[
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      prefixIcon: Icon(Icons.title, color: Color(0xFF888888)),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.white,
                                onPrimary: Color(0xFF1E1E1E),
                                surface: Color(0xFF2A2A2A),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF2A2A2A),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF888888),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Date: ${_formatDate(_startDate)}',
                            style: TextStyle(
                              color: _startDate == null
                                  ? const Color(0xFF888888)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _departureTimeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Start Time',
                            labelStyle: const TextStyle(
                              color: Color(0xFF888888),
                            ),
                            hintText: '09:30',
                            hintStyle: const TextStyle(
                              color: Color(0xFF666666),
                            ),
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: Color(0xFF888888),
                            ),
                            suffixText: 'HH:MM',
                            suffixStyle: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9:]'),
                            ),
                            LengthLimitingTextInputFormatter(5),
                            TimeInputFormatter(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _arrivalTimeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            labelStyle: const TextStyle(
                              color: Color(0xFF888888),
                            ),
                            hintText: '11:30',
                            hintStyle: const TextStyle(
                              color: Color(0xFF666666),
                            ),
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: Color(0xFF888888),
                            ),
                            suffixText: 'HH:MM',
                            suffixStyle: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9:]'),
                            ),
                            LengthLimitingTextInputFormatter(5),
                            TimeInputFormatter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      prefixIcon: Icon(
                        Icons.description,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitOtherSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Add Other',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ] else if (_selectedType == ScheduleType.dining) ...[
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Restaurant Name',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      prefixIcon: Icon(
                        Icons.restaurant,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter restaurant name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.white,
                                onPrimary: Color(0xFF1E1E1E),
                                surface: Color(0xFF2A2A2A),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF2A2A2A),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF888888),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Date: ${_formatDate(_startDate)}',
                            style: TextStyle(
                              color: _startDate == null
                                  ? const Color(0xFF888888)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _departureTimeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Reservation Time',
                            labelStyle: const TextStyle(
                              color: Color(0xFF888888),
                            ),
                            hintText: '19:30',
                            hintStyle: const TextStyle(
                              color: Color(0xFF666666),
                            ),
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: Color(0xFF888888),
                            ),
                            suffixText: 'HH:MM',
                            suffixStyle: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9:]'),
                            ),
                            LengthLimitingTextInputFormatter(5),
                            TimeInputFormatter(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _arrivalTimeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            labelStyle: const TextStyle(
                              color: Color(0xFF888888),
                            ),
                            hintText: '21:30',
                            hintStyle: const TextStyle(
                              color: Color(0xFF666666),
                            ),
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: Color(0xFF888888),
                            ),
                            suffixText: 'HH:MM',
                            suffixStyle: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9:]'),
                            ),
                            LengthLimitingTextInputFormatter(5),
                            TimeInputFormatter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      hintText:
                          'e.g., Fine dining, Italian cuisine, Special occasion',
                      hintStyle: TextStyle(color: Color(0xFF666666)),
                      prefixIcon: Icon(
                        Icons.description,
                        color: Color(0xFF888888),
                      ),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitDiningSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Add Dining',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 추천 정보를 표시하는 헬퍼 메서드
  Widget _buildRecommendationInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
