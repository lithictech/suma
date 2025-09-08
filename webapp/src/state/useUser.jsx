import { UserContext } from "./UserProvider";
import React from "react";

/**
 * @returns {{user: User, setUser: function, userLoading: boolean, userError: object, userAuthed: boolean, userUnauthed: boolean}}
 */
const useUser = () => React.useContext(UserContext);
export default useUser;

/**
 * @typedef User
 * @property {boolean} ongoingTrip
 * @property {boolean} readOnlyMode
 * @property {string} readOnlyReason
 * @property {Array<object>} paymentInstruments
 */
