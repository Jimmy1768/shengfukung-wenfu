import { buildRegistrationLink } from '@/utils/accountLinks.js';

const monthFormatter = new Intl.DateTimeFormat('en-US', {
  month: 'short'
});
const zhDateFormatter = new Intl.DateTimeFormat('zh-TW', {
  year: 'numeric',
  month: '2-digit',
  day: '2-digit'
});
const currencyCache = new Map();

function parseDate(value) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date;
}

function formatMonth(date) {
  if (!date) return 'TBD';
  return monthFormatter.format(date).toUpperCase();
}

function formatDay(date) {
  if (!date) return '--';
  return date.getDate().toString().padStart(2, '0');
}

export function formatDateRange(startInput, endInput) {
  const start = parseDate(startInput);
  const end = parseDate(endInput);
  if (start && end) {
    if (start.toDateString() === end.toDateString()) {
      return zhDateFormatter.format(start);
    }
    return `${zhDateFormatter.format(start)} – ${zhDateFormatter.format(end)}`;
  }
  if (start) return zhDateFormatter.format(start);
  if (end) return zhDateFormatter.format(end);
  return '日期待定';
}

export function formatEventCard(event, options = {}) {
  const start = parseDate(event.starts_on);
  const location =
    event.metadata?.location ||
    options.defaultLocation ||
    '聯絡資訊請見下方';
  const summary =
    event.description ||
    options.defaultSummary ||
    '詳細資訊敬請期待。';
  const badge =
    event.period ||
    options.statusLabels?.[event.timeline_status] ||
    statusLabel(event.timeline_status);

  const action = options.registrationAction || event.kind || 'event';

  return {
    slug: event.slug,
    month: formatMonth(start),
    day: formatDay(start),
    title: event.title,
    when: formatDateRange(event.starts_on, event.ends_on),
    where: location,
    summary,
    badge,
    imageUrl: event.hero_image_url || '',
    ctaHref: buildRegistrationLink(action, event.slug)
  };
}

export function statusLabel(status) {
  switch (status) {
    case 'ongoing':
      return '進行中';
    case 'past':
      return '已結束';
    case 'upcoming':
    default:
      return '即將開始';
  }
}

export function formatCurrency(amountCents, currency = 'TWD') {
  const key = `${currency}`;
  let formatter = currencyCache.get(key);
  if (!formatter) {
    formatter = new Intl.NumberFormat('zh-TW', {
      style: 'currency',
      currency,
      maximumFractionDigits: 0
    });
    currencyCache.set(key, formatter);
  }
  const amount = Number(amountCents || 0) / 100;
  return formatter.format(amount);
}
