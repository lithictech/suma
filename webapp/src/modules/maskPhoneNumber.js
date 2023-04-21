export const maskPhoneNumber = (num) => {
  if (!num || num.startsWith("0") || num.startsWith("1")) {
    return "";
  }
  let currentNum = num.replace(/\D/g, "");
  // in case `currentNum` starts with US region code "1", remove it before formatting
  // also prevent starting with 0
  if (currentNum.startsWith("1") || currentNum.startsWith("0")) {
    currentNum = currentNum.slice(1);
  }
  if (currentNum.length < 4) {
    return currentNum;
  } else if (currentNum.length < 7) {
    return `(${currentNum.slice(0, 3)}) ${currentNum.slice(3)}`;
  } else {
    return `(${currentNum.slice(0, 3)}) ${currentNum.slice(3, 6)}-${currentNum.slice(
      6,
      10
    )}`;
  }
};
