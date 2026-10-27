import assert from 'node:assert/strict';
import test from 'node:test';

import { dueSlot, parseSchedule, zonedTime } from '../src/jobs/restock_schedule.js';

test('lee las horas de la revisión', () => {
  const slots = parseSchedule('21:00, 9:00,09:00');
  assert.deepEqual(
    slots.map((slot) => slot.label),
    ['09:00', '21:00'],
  );
});

test('rechaza horas no válidas', () => {
  assert.throws(() => parseSchedule('25:00'));
  assert.throws(() => parseSchedule('9am'));
});

test('convierte la hora a la zona de Madrid (con horario de invierno)', () => {
  // 27 oct 2026 08:00 UTC = 09:00 en Madrid (UTC+1).
  const time = zonedTime(new Date('2026-10-27T08:00:00Z'), 'Europe/Madrid');
  assert.equal(time.dateKey, '2026-10-27');
  assert.equal(time.hour, 9);
  assert.equal(time.minute, 0);
});

test('toca la revisión justo a su hora y solo una vez al día', () => {
  const slots = parseSchedule('09:00,21:00');
  const alreadyRun = new Set<string>();
  const now = { dateKey: '2026-10-27', hour: 9, minute: 2 };

  const due = dueSlot({ now, slots, alreadyRun });
  assert.equal(due?.slot.label, '09:00');

  alreadyRun.add(due!.key);
  assert.equal(dueSlot({ now, slots, alreadyRun }), null);
});

test('un reinicio a mediodía no lanza la revisión de las 9', () => {
  const slots = parseSchedule('09:00,21:00');
  const due = dueSlot({
    now: { dateKey: '2026-10-27', hour: 12, minute: 30 },
    slots,
    alreadyRun: new Set(),
  });
  assert.equal(due, null);
});

test('la revisión de la noche se lanza a las 21:00', () => {
  const slots = parseSchedule('09:00,21:00');
  const due = dueSlot({
    now: { dateKey: '2026-10-27', hour: 21, minute: 0 },
    slots,
    alreadyRun: new Set(['2026-10-27 09:00']),
  });
  assert.equal(due?.slot.label, '21:00');
});
