// Ported from d3-time v3.1.0 src/duration.js (ISC, Mike Bostock).

/// Port of `src/duration.js` of d3-time 3.1.0.
library;

/// Milliseconds in one second (`1,000`).
const int durationSecond = 1000;

/// Milliseconds in one minute (`60,000`).
const int durationMinute = durationSecond * 60;

/// Milliseconds in one hour (`3,600,000`).
const int durationHour = durationMinute * 60;

/// Milliseconds in one standard day (`86,400,000`).
const int durationDay = durationHour * 24;

/// Milliseconds in one week (`604,800,000`).
const int durationWeek = durationDay * 7;

/// Approximate milliseconds in one 30-day month (`2,592,000,000`).
const int durationMonth = durationDay * 30;

/// Approximate milliseconds in one 365-day year (`31,536,000,000`).
const int durationYear = durationDay * 365;
