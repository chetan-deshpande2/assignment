export const getUnixTimeNowInSec = () => Math.floor(Date.now() / 1000);

export const getUnixTimeAfterMins = (mins) => getUnixTimeNowInSec() + mins * 60;

export const getUnixTimeAfterDays = (days) =>
  getUnixTimeNowInSec() + days * 60 * 60 * 24;
