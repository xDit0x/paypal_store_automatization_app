/**
 * Cálculo de horarios de la revisión automática de stock.
 *
 * Todo es puro (sin red ni base de datos) para poder probarlo con tests.
 */

export interface ScheduleSlot {
  hour: number;
  minute: number;
  /** "09:00" */
  label: string;
}

export interface ZonedTime {
  /** "2026-10-27" en la zona horaria indicada */
  dateKey: string;
  hour: number;
  minute: number;
}

/**
 * "09:00,21:00" -> [{hour: 9, minute: 0}, {hour: 21, minute: 0}].
 * Ignora entradas vacías y lanza un error si alguna no es una hora válida.
 */
export function parseSchedule(value: string): ScheduleSlot[] {
  const slots: ScheduleSlot[] = [];
  for (const raw of value.split(',')) {
    const text = raw.trim();
    if (!text) continue;
    const match = /^(\d{1,2}):(\d{2})$/.exec(text);
    const hour = match ? Number(match[1]) : NaN;
    const minute = match ? Number(match[2]) : NaN;
    if (!match || hour > 23 || minute > 59) {
      throw new Error(`Hora no válida en RESTOCK_SCHEDULE: "${text}" (usa HH:MM)`);
    }
    const label = `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
    if (!slots.some((slot) => slot.label === label)) {
      slots.push({ hour, minute, label });
    }
  }
  return slots.sort((a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute));
}

/** Fecha y hora de `date` vista en la zona horaria `timeZone` (con horario de verano). */
export function zonedTime(date: Date, timeZone: string): ZonedTime {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);

  const get = (type: string): string => parts.find((part) => part.type === type)?.value ?? '00';
  return {
    dateKey: `${get('year')}-${get('month')}-${get('day')}`,
    hour: Number(get('hour')),
    minute: Number(get('minute')),
  };
}

/**
 * Devuelve la franja que toca ejecutar ahora, o null.
 *
 * Una franja se ejecuta si ya ha llegado su hora, no han pasado más de
 * `graceMinutes` (así un reinicio a mediodía no lanza la revisión de las 9)
 * y no se ha ejecutado ya hoy (`alreadyRun` guarda claves "fecha hora").
 */
export function dueSlot(params: {
  now: ZonedTime;
  slots: ScheduleSlot[];
  alreadyRun: Set<string>;
  graceMinutes?: number;
}): { slot: ScheduleSlot; key: string } | null {
  const grace = params.graceMinutes ?? 10;
  const nowMinutes = params.now.hour * 60 + params.now.minute;

  for (const slot of params.slots) {
    const slotMinutes = slot.hour * 60 + slot.minute;
    const key = `${params.now.dateKey} ${slot.label}`;
    const elapsed = nowMinutes - slotMinutes;
    if (elapsed >= 0 && elapsed <= grace && !params.alreadyRun.has(key)) {
      return { slot, key };
    }
  }
  return null;
}
