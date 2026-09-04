export function isPaymentMethodSupported(
  supported: PaymentInstrumentType[],
  m: PaymentInstrumentType
) {
  return supported.includes(m);
}
