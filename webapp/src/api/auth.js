import { get, post } from './apiRequest';
import { API_PATH_START, API_PATH_VERIFY_PHONE } from "./apiPaths";

// TODO: using temporary GET request, switch to POST when server api is done, uncomment data
export const verifyPhone = (phone, otpCode) => get({
    path: API_PATH_VERIFY_PHONE,
    // data: { phone, token: otpCode }
});
// TODO: using temporary GET request, switch to POST when server api is done
export const start = (phone) => post({
    path: API_PATH_START,
    data: { phone }
});
