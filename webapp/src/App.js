import Redirect from "./components/Redirect";
import { redirectIfAuthed, redirectIfUnauthed } from "./hocs/authRedirects";
import applyHocs from "./modules/applyHocs";
import renderComponent from "./modules/renderComponent";
import Dashboard from "./pages/Dashboard";
import Home from "./pages/Home";
import Onboarding from "./pages/Onboarding";
import OneTimePassword from "./pages/OneTimePassword";
import Start from "./pages/Start";
import { UserProvider } from "./state/useUser";
import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";

function App() {
  return (
    <UserProvider>
      <Router>
        <Routes>
          <Route path="/" exact element={renderWithHocs(redirectIfAuthed, Home)} />
          <Route path="/start" exact element={renderWithHocs(redirectIfAuthed, Start)} />
          <Route
            path="/one-time-password"
            exact
            element={renderWithHocs(redirectIfAuthed, OneTimePassword)}
          />
          <Route
            path="/onboarding"
            exact
            element={renderWithHocs(redirectIfUnauthed, Onboarding)}
          />
          <Route
            path="/dashboard"
            exact
            element={renderWithHocs(redirectIfUnauthed, Dashboard)}
          />
          <Route path="/*" element={<Redirect to="/" />} />
        </Routes>
      </Router>
    </UserProvider>
  );
}

export default App;

function renderWithHocs(...args) {
  return renderComponent(applyHocs(...args));
}
