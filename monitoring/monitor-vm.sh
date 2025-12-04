#!/bin/bash

# Конфигурация
OAUTH="y0_xxxxx"
VM_ID="fhxxxxxx"

# Получаем IAM токен
IAM=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"yandexPassportOauthToken":"'"$OAUTH"'"}' \
  https://iam.api.cloud.yandex.net/iam/v1/tokens | \
  jq -r '.iamToken')

# echo "IAM token: $IAM"

# Проверяем, что токен получен
if [ -z "$IAM" ] || [ "$IAM" = "null" ]; then
    echo "$(date): Ошибка: не удалось получить IAM токен"
    exit 1
fi

# Получаем статус ВМ
RESPONSE=$(curl -s -X GET \
  -H "Authorization: Bearer $IAM" \
  https://compute.api.cloud.yandex.net/compute/v1/instances/$VM_ID)

# Извлекаем статус
STATUS=$(echo "$RESPONSE" | jq -r '.status')

echo "$(date): Статус ВМ: $STATUS"

# Проверяем наличие ошибки
ERROR=$(echo "$RESPONSE" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // "Неизвестная ошибка"')
    echo "$(date): Ошибка API: $ERROR_MSG"
    exit 1
fi

# Если остановлена - запускаем
if [ "$STATUS" = "STOPPED" ]; then
  echo "$(date): Запускаю ВМ..."

  START_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $IAM" \
    -H "Content-Type: application/json" \
    https://compute.api.cloud.yandex.net/compute/v1/instances/${VM_ID}:start)

  # Проверяем результат запуска
  OPERATION_ID=$(echo "$START_RESPONSE" | jq -r '.id // empty')

  if [ -n "$OPERATION_ID" ] && [ "$OPERATION_ID" != "null" ]; then
    echo "$(date): Команда на запуск отправлена. ID операции: $OPERATION_ID"
  else
    ERROR_MSG=$(echo "$START_RESPONSE" | jq -r '.error.message // "Неизвестная ошибка запуска"')
    echo "$(date): Ошибка при запуске: $ERROR_MSG"
  fi
fi