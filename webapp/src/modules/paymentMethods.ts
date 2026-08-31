export function isPaymentMethodSupported(
  supported: PaymentMethodType[],
  m: PaymentMethodType
) {
  return supported.includes(m);
}
