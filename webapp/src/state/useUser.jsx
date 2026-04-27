import { UserContext } from "./UserProvider";
import React from "react";

/**
 * @returns {{user: CurrentMember, setUser: function, userLoading: boolean, userError: object, userAuthed: boolean, userUnauthed: boolean, registrationSession: RegistrationLink}}
 */
const useUser = () => React.useContext(UserContext);
export default useUser;
