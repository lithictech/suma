import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import HttpApi from 'i18next-http-backend';
import LanguageDetector from 'i18next-browser-languagedetector';

i18n
	.use(initReactI18next)
	.use(LanguageDetector)
	.use(HttpApi)
  .init({
		fallbackLng: 'en',
		detection: {
			order: ['htmlTag', 'localStorage', 'cookie'],
			caches: ['cookie'],
		},
		backend: {
			loadPath: '/locale/{{lng}}/translations.json',
		},
		interpolation: {
			// react already safes from xss
			escapeValue: false,
		},
		react: {
			useSuspense: false,
		},
	});

export default i18n;