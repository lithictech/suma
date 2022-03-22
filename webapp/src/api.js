import apiBase from "./modules/apiBase";
import config from "./config";

const instance = apiBase.create(config.apiHost, {
  debug: config.debug,
  chaos: config.chaos,
});

const get = (path, params, opts) => {
  return instance.get(path, apiBase.mergeParams(params, opts));
};
const post = (path, params, opts) => {
  return instance.post(path, params, opts);
};
const patch = (path, params, opts) => {
  return instance.patch(path, params, opts);
};

const put = (path, params, opts) => {
  return instance.put(path, params, opts);
};

const del = (path, params, opts) => {
  return instance.delete(path, apiBase.mergeParams(params, opts));
};

export default {
  get,
  post,
  patch,
  put,
  del,
  authStart: (data) => post(`/api/v1/auth/start`, data),
  authVerify: (data) => post(`/api/v1/auth/verify`, data)
}