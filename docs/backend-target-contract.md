# Veya mobile target backend contract

This document is the source of truth for the backend contract required by the
Flutter application. The existing backend may implement only a subset while the
mobile client uses local Drift repositories for missing capabilities.

## Conventions

- API prefix: `/api`.
- IDs are UUID strings. Create endpoints accept a client-generated `id`.
- Instants use ISO 8601 UTC; local dates use `yyyy-MM-dd`.
- Mutable resources expose `createdAt`, `updatedAt`, and integer `version`.
- Mutations accept `Idempotency-Key`; conflicting versions return HTTP 409.
- Incremental synchronization returns deletion tombstones.
- List endpoints use opaque `cursor` and default `pageSize=50`.
- Authenticated endpoints use `Authorization: Bearer <accessToken>`.
- Errors follow `{status, error, message, path, errors?, timestamp}`.

## Enums

```text
TaskStatus: OPEN | IN_PROGRESS | DONE | CANCELLED
TaskPriority: LOW | MEDIUM | HIGH
FamilyRole: OWNER | MEMBER
RecurrenceType: DAILY | WEEKLY | MONTHLY | DAY_OF_MONTH | INTERVAL_DAYS
ReminderType: AT_TIME | BEFORE_DEADLINE
DevicePlatform: IOS | ANDROID
PushProvider: FCM
ActivityEntityType: TASK | TASK_COMMENT | SHOPPING_LIST | SHOPPING_ITEM |
                    FAMILY | FAMILY_MEMBER
ActivityEventType: TASK_CREATED | TASK_UPDATED | TASK_ASSIGNED |
                   TASK_STATUS_CHANGED | TASK_COMMENT_ADDED |
                   TASK_ATTACHMENT_ADDED | SHOPPING_LIST_CREATED |
                   SHOPPING_ITEM_ADDED | SHOPPING_ITEM_CHECKED |
                   MEMBER_JOINED | MEMBER_REMOVED | FAMILY_UPDATED
```

Clients must tolerate unknown future enum values.

## DTOs

### Identity and family

```text
UserDto {
  id, fullName, email, avatarUrl?, createdAt, updatedAt, version
}

UserSummaryDto { id, fullName, avatarUrl? }

FamilyDto {
  id, name, ownerId, timeZone, createdAt, updatedAt, version
}

FamilyMemberDto {
  id, familyId, userId, fullName, email, avatarUrl?, role,
  joinedAt, updatedAt, version
}
```

### Auth

```text
RegisterRequest { fullName, email, password, familyName }
LoginRequest { email, password }
RefreshRequest { refreshToken }
AuthResponse { accessToken, refreshToken, user: UserDto }
```

Access tokens currently live for 15 minutes and rotating refresh tokens for
7 days. Refreshing revokes the previous refresh token.

### Tasks

```text
TaskAssigneeDto { memberId, userId, fullName, avatarUrl? }

RecurrenceRuleDto {
  type, interval?, weekdays[], dayOfMonth?, startsOn, endsOn?, timeZone
}

TaskReminderDto {
  id, taskId, type, remindAt?, offsetMinutes?, enabled,
  createdAt, updatedAt, version
}

TaskCommentDto {
  id, taskId, authorId, author: UserSummaryDto?, text,
  createdAt, updatedAt, version
}

AttachmentDto {
  id, taskId, uploadedById, fileName, mimeType, sizeBytes, url,
  thumbnailUrl?, width?, height?, createdAt, version
}

TaskListItemDto {
  id, familyId, title, description?, createdById, creator?, assigneeId?,
  assignee?, status, deadline?, priority, category?, recurrenceRule?,
  completedAt?, commentCount, attachmentCount, reminderCount,
  createdAt, updatedAt, version
}

TaskDetailsDto {
  // TaskListItemDto fields plus:
  reminders[], comments[], attachments[]
}
```

Recurrence validation:

- `WEEKLY` requires non-empty `weekdays` (ISO 1..7).
- `DAY_OF_MONTH` requires `dayOfMonth` in 1..31.
- `INTERVAL_DAYS` requires `interval >= 2`.
- `DAILY` has no interval-specific fields.
- `MONTHLY` repeats on the day in `startsOn`.
- `endsOn`, when present, cannot precede `startsOn`.

### Shopping

```text
ShoppingListDto {
  id, familyId, name, createdById, archived, items[],
  createdAt, updatedAt, version
}

ShoppingItemDto {
  id, listId, name, quantity?, unit?, category?, checked,
  checkedById?, checkedAt?, position, createdById,
  createdAt, updatedAt, version
}
```

### Activity, notifications, and devices

```text
ActivityEventDto {
  id, familyId, actorId?, actor?, type, entityType, entityId,
  payload, createdAt
}

DeviceDto {
  id, userId, platform, deviceName?, appVersion, osVersion?, locale,
  timeZone, lastSeenAt, createdAt, updatedAt, version
}

PushTokenDto {
  id, deviceId, provider, token, active, createdAt, updatedAt, version
}

NotificationDto {
  id, userId, familyId?, type, title, body?, entityType?, entityId?,
  deepLink?, readAt?, createdAt
}

NotificationPreferencesDto {
  userId, newTasks, assignedToMe, reminders, comments, completedTasks,
  overdueTasks, familyChanges, updatedAt, version
}
```

## REST endpoints

### Auth and families

```text
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/refresh
POST   /api/auth/logout
GET    /api/auth/me

GET    /api/families/current
POST   /api/families
PATCH  /api/families/{familyId}
GET    /api/families/{familyId}/members
POST   /api/families/{familyId}/invites
GET    /api/invites/{token}
POST   /api/invites/{token}/accept
DELETE /api/families/{familyId}/members/{memberId}
```

### Tasks

```text
GET    /api/tasks?familyId=&status=&assigneeId=&from=&to=&cursor=&pageSize=
GET    /api/tasks/{taskId}
POST   /api/tasks
PATCH  /api/tasks/{taskId}
PATCH  /api/tasks/{taskId}/status
PATCH  /api/tasks/{taskId}/assignee
POST   /api/tasks/{taskId}/claim
DELETE /api/tasks/{taskId}

GET    /api/tasks/{taskId}/comments
POST   /api/tasks/{taskId}/comments
PATCH  /api/comments/{commentId}
DELETE /api/comments/{commentId}

GET    /api/tasks/{taskId}/attachments
POST   /api/tasks/{taskId}/attachments       (multipart/form-data)
DELETE /api/attachments/{attachmentId}

GET    /api/tasks/{taskId}/reminders
POST   /api/tasks/{taskId}/reminders
PATCH  /api/reminders/{reminderId}
DELETE /api/reminders/{reminderId}
```

Nullable values in PATCH are explicit. Sending `assigneeId: null` or
`deadline: null` clears the field; omitted fields remain unchanged.

### Shopping and activity

```text
GET    /api/families/{familyId}/shopping-lists
GET    /api/shopping-lists/{listId}
POST   /api/families/{familyId}/shopping-lists
PATCH  /api/shopping-lists/{listId}
DELETE /api/shopping-lists/{listId}
POST   /api/shopping-lists/{listId}/items
PATCH  /api/shopping-items/{itemId}
PATCH  /api/shopping-items/{itemId}/toggle
PATCH  /api/shopping-lists/{listId}/items/order
DELETE /api/shopping-items/{itemId}
DELETE /api/shopping-lists/{listId}/checked-items

GET    /api/families/{familyId}/activity?cursor=&pageSize=
```

### Devices and notifications

```text
POST   /api/devices
PATCH  /api/devices/{deviceId}
DELETE /api/devices/{deviceId}
PUT    /api/devices/{deviceId}/push-token
DELETE /api/devices/{deviceId}/push-token

GET    /api/notifications?cursor=&pageSize=
PATCH  /api/notifications/{notificationId}/read
PATCH  /api/notifications/read-all
GET    /api/notification-preferences
PUT    /api/notification-preferences
```

Push payloads include `entityType`, `entityId`, and a `veya://` deep link.

## Offline synchronization

```text
GET /api/sync/changes?familyId={id}&cursor={opaqueCursor}&pageSize=500

SyncPageDto {
  changes: SyncChangeDto[],
  nextCursor,
  hasMore,
  serverTime
}

SyncChangeDto {
  sequence,
  entityType,
  entityId,
  operation: UPSERT | DELETE,
  version,
  payload?,
  occurredAt
}
```

Create and mutation endpoints accept an `Idempotency-Key`. Updates include an
expected `version`. A conflict returns the latest server representation. Cursors
are stable per family and include hard/soft deletion tombstones.

## SSE realtime

```text
GET /api/realtime/events?familyId={id}&cursor={lastSequence}
Accept: text/event-stream
```

Event envelope:

```text
RealtimeEventDto {
  id,
  sequence,
  familyId,
  type,
  entityType,
  entityId,
  version,
  occurredAt,
  payload?
}
```

SSE is an invalidation/change feed, not a replacement for REST. On sequence
gaps or reconnect, clients call `/api/sync/changes` from their last cursor.

## Deep links

```text
veya://task/{taskId}
veya://shopping/{listId}
veya://invite/{token}
veya://notification/{notificationId}
```
