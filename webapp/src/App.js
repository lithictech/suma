import { redirectIfAuthed, redirectIfUnauthed } from "./hocs/authRedirects";
import Dashboard from "./pages/Dashboard";
import Home from "./pages/Home";
import MapPage from "./pages/MapPage";
import Onboarding from "./pages/Onboarding";
import OneTimePassword from "./pages/OneTimePassword";
import Start from "./pages/Start";
import applyHocs from "./shared/applyHocs";
import bluejay from "./shared/bluejay";
import Redirect from "./shared/react/Redirect";
import renderComponent from "./shared/react/renderComponent";
import { UserProvider } from "./state/useUser";
import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";

window.Promise = bluejay.Promise;

function App() {
  return (
    <UserProvider>
      <Router basename={process.env.PUBLIC_URL}>
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
          <Route
            path="/map"
            exact
            element={renderWithHocs(redirectIfUnauthed, MapPage)}
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
