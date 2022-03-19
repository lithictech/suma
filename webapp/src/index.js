import React from 'react';
import ReactDOM from 'react-dom';
import App from './components/App';
import './localization/i18n';
import './index.css';
// Bootstrap Stylesheet
import 'bootstrap/dist/css/bootstrap.min.css';

ReactDOM.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
  document.getElementById('root')
);
