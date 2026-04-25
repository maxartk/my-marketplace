---
name: oci-status
description: Моніторинг OCI ARM сервера — перевірка статусу, сервісів та логів
version: 1.0.0
author: Max
category: devops
triggers: [oci, oracle cloud, сервер впав, статус сервера, signal_bridge, openclaw сервер, перевір сервер]
---

# OCI Server Status Monitor

Моніторинг Oracle Cloud Infrastructure ARM інстансу (VM.Standard.A1.Flex, EU Frankfurt).
Перевіряє доступність сервера, статус сервісів та аналізує логи.

## Конфігурація

```
Server: OCI ARM (VM.Standard.A1.Flex)
Region: EU Frankfurt
Services: signal_bridge_remote, openclaw, n8n (якщо запущений)
Telegram notify: @voltmind_maxbot (chat ID: 1839631296)
```

## Тригери (коли використовувати цей скіл)
Якщо користувач каже "перевір сервер", "OCI впав", "signal_bridge не відповідає",
"статус сервера", "що з OCI" — виконай цей скіл.

## Кроки перевірки

### 1. Ping перевірка
```bash
ping -c 3 <OCI_IP>
```
Якщо немає відповіді → сервер недоступний → сповісти через Telegram.

### 2. SSH підключення та статус сервісів
```bash
ssh ubuntu@<OCI_IP> "
  echo '=== SYSTEM ===' && uptime &&
  echo '=== MEMORY ===' && free -h &&
  echo '=== DISK ===' && df -h / &&
  echo '=== SIGNAL_BRIDGE ===' && systemctl status signal_bridge_remote --no-pager &&
  echo '=== DOCKER ===' && docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null || echo 'Docker not running'
"
```

### 3. Перевірка логів (якщо сервіс не працює)
```bash
ssh ubuntu@<OCI_IP> "journalctl -u signal_bridge_remote -n 50 --no-pager"
```
Логи передати @claude для аналізу.

### 4. Перезапуск сервісу (якщо впав)
```bash
ssh ubuntu@<OCI_IP> "sudo systemctl restart signal_bridge_remote"
```
Після перезапуску — повторна перевірка через 10 секунд.

## Маршрутизація між агентами

```
@hermes   — отримує запит від користувача, запускає скіл
@openclaw — виконує SSH команди, збирає результати
@claude   — аналізує логи якщо є помилки, пропонує фікс
@openclaw — застосовує фікс і перезапускає
@hermes   — надсилає фінальний звіт у Telegram
```

## Формат Telegram звіту

### ✅ Все OK:
```
🟢 OCI Server Status
Uptime: 14 days, 3:22
Memory: 2.1G / 24G
Disk: 18G / 47G
signal_bridge_remote: active ✅
Docker: 2 containers running
```

### ❌ Проблема:
```
🔴 OCI Server Alert
signal_bridge_remote: FAILED ❌
Останній рестарт: 10 хв тому
Причина: [з логів]
Дія: автоматичний рестарт виконано
Статус після рестарту: active ✅
```

### 🔴 Сервер недоступний:
```
🚨 OCI Server UNREACHABLE
IP: <OCI_IP>
Ping: timeout
Час: 14:35 UTC
Рекомендація: перевір OCI Console
https://cloud.oracle.com
```

## Відправка в Telegram

```bash
curl -s -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d chat_id=1839631296 \
  -d parse_mode=HTML \
  -d text="<повідомлення>"
```

## Автоматичний моніторинг (cron)

Для регулярної перевірки кожні 30 хвилин:
```bash
# OpenClaw cron
cronjob create \
  --schedule "*/30 * * * *" \
  --prompt "Виконай скіл oci-status і відправ результат у Telegram тільки якщо є проблеми"
```

## Встановлення

```bash
cp -r /tmp/marketplace/plugins/oci-status ~/.openclaw/skills/
cp -r /tmp/marketplace/plugins/oci-status ~/.hermes/skills/
```
