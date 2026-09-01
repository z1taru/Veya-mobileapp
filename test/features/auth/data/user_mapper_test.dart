import 'package:flutter_test/flutter_test.dart';
import 'package:veya/core/models/user_model.dart';
import 'package:veya/features/auth/data/auth_dto.dart';
import 'package:veya/features/auth/data/user_mapper.dart';

void main() {
  test('maps current backend UserDto into model and Drift companion', () {
    final createdAt = DateTime.utc(2026, 9);
    final dto = UserDto(
      id: 'user-id',
      fullName: 'Aigerim',
      email: 'aigerim@example.com',
      avatarUrl: null,
      status: 'ACTIVE',
      createdAt: createdAt,
    );

    final model = dto.toModel();
    final companion = dto.toCompanion();

    expect(model.status, UserStatus.active);
    expect(model.createdAt, createdAt);
    expect(companion.id.value, 'user-id');
    expect(companion.email.value, 'aigerim@example.com');
    expect(companion.version.value, 0);
  });

  test('unknown backend status does not break decoding', () {
    final dto = UserDto.fromJson({
      'id': 'user-id',
      'fullName': 'Aigerim',
      'email': 'aigerim@example.com',
      'status': 'NEW_SERVER_STATUS',
      'createdAt': '2026-09-01T00:00:00Z',
    });

    expect(dto.toModel().status, UserStatus.unknown);
  });
}
