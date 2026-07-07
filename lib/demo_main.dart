import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Zonova_Mist/src/core/api/api_service.dart';
import 'package:Zonova_Mist/src/core/auth/auth_provider.dart';
import 'package:Zonova_Mist/src/core/auth/auth_state.dart';
import 'package:Zonova_Mist/src/features/home/expenses/expenses_list_page.dart';
import 'package:Zonova_Mist/src/features/home/rooms/room_rate_page.dart';

/// A fake auth notifier that reports an authenticated admin so the
/// RbacGate lets the demo pages render. It extends the real AuthNotifier
/// but pins the state to Authenticated (the base class's async token check
/// tries to reset it to Unauthenticated, which we ignore).
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(Ref ref) : super(ref) {
    state = const Authenticated(
      userName: 'Demo Admin',
      role: 'admin',
      permissions: <String>[],
    );
  }

  @override
  set state(AuthState value) {
    if (value is Authenticated) {
      super.state = value;
    }
  }
}

/// A Dio HttpClientAdapter that returns canned JSON for the endpoints the
/// demo pages hit, so no real backend is required.
class _MockAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    dynamic body;

    if (path.contains('/expenses')) {
      body = _expenses;
    } else if (path.contains('/rooms')) {
      body = _rooms;
    } else {
      body = <dynamic>[];
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

final _expenses = [
  {
    '_id': 'e1',
    'title': 'Electricity Bill - July',
    'category': 'Utilities',
    'amount': '18500',
    'date': '2026-07-02T00:00:00.000Z',
    'images': [],
  },
  {
    '_id': 'e2',
    'title': 'Housekeeping Supplies',
    'category': 'Maintenance',
    'amount': '7250',
    'date': '2026-07-04T00:00:00.000Z',
    'images': [],
  },
  {
    '_id': 'e3',
    'title': 'Staff Lunch Catering',
    'category': 'Food & Beverage',
    'amount': '12000',
    'date': '2026-07-05T00:00:00.000Z',
    'images': [],
  },
  {
    '_id': 'e4',
    'title': 'Garden Landscaping',
    'category': 'Grounds',
    'amount': '9800',
    'date': '2026-07-06T00:00:00.000Z',
    'images': [],
  },
];

final _rooms = [
  {
    '_id': 'r1',
    'roomNumber': '101',
    'roomCount': 2,
    'maxOccupancy': 2,
    'pricePerNight': 8500,
  },
  {
    '_id': 'r2',
    'roomNumber': '102',
    'roomCount': 1,
    'maxOccupancy': 3,
    'pricePerNight': 11000,
  },
  {
    '_id': 'r3',
    'roomNumber': '201',
    'roomCount': 3,
    'maxOccupancy': 4,
    'pricePerNight': 15500,
  },
];

Dio _mockDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://mock.local/api'));
  dio.httpClientAdapter = _MockAdapter();
  return dio;
}

void main() {
  // Decide which page to show based on the URL fragment (#rooms / #expenses).
  final fragment = Uri.base.fragment;
  final Widget page =
      fragment.contains('room') ? const RoomRatePage() : const ExpensesListPage();

  runApp(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(ref)),
        dioProvider.overrideWithValue(_mockDio()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          fontFamily: 'Roboto',
        ),
        home: page,
      ),
    ),
  );
}
