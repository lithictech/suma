export const formatPhoneNumber = (num, previousValue) => {
  if (!num) {
    return "";
  }
  if (num.startsWith("0") || num.startsWith("1")) {
    return "";
  }
  let currentNum = num.replace(/\D/g, "");
  // in case we paste a num with US region code "1", we should remove it before formatting
  if (currentNum.startsWith("1")) {
    currentNum = currentNum.slice(1);
  }
  const cvLength = currentNum.length;
  if (!previousValue || num.length > previousValue.length) {
    if (cvLength < 4) {
      return currentNum;
    } else if (cvLength < 7) {
      return `(${currentNum.slice(0, 3)}) ${currentNum.slice(3)}`;
    } else {
      return `(${currentNum.slice(0, 3)}) ${currentNum.slice(3, 6)}-${currentNum.slice(
        6,
        10
      )}`;
    }
  }
  // while deleting, if num length equals 3 we remove parenthesis
  if (cvLength === 3) {
    return currentNum;
  }
  // while deleting, if num length equals 6 we remove dash
  if (cvLength === 6) {
    return `(${currentNum.slice(0, 3)}) ${currentNum.slice(3)}`;
  }
  return num;
};

export const numberToUs = (num) => {
  return `+1${num.replace(/[() -]/g, "")}`;
};
