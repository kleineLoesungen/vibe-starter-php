#!/bin/sh
# Laeuft bei jedem Containerstart, bevor der Webserver startet.
set -e

# Migrationen zuerst, und zwar VOR dem Caching: Die Sperre, die `--isolated`
# benutzt, liegt in der Tabelle `cache_locks` (Cache-Treiber "database") — die
# gibt es auf einer frischen Datenbank noch nicht, sie entsteht erst durch die
# Migrationen selbst. Scheitert der isolierte Lauf, folgt einer mit Sperre im
# Arbeitsspeicher. Das betrifft nur den allerersten Start; danach hält die
# Sperre in der Datenbank gleichzeitig startende Instanzen auseinander.
if ! php artisan migrate --force --isolated; then
  echo "Migration mit Datenbanksperre fehlgeschlagen – erster Start? Versuche es ohne Sperre." >&2
  CACHE_STORE=array php artisan migrate --force
fi
php artisan login-attempts:prune

# Konfiguration, Routen und Templates vorkompilieren. Ab hier liefert env()
# ausserhalb von config/*.php null — deshalb gilt im Code nur config('…').
php artisan config:cache
php artisan route:cache
php artisan view:cache

exec "$@"
