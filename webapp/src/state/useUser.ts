import { UserContext } from "./UserProvider";
import React from "react";

const useUser = () => React.useContext(UserContext);
export default useUser;
