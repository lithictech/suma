import config from "./config";
import apiBase from "./shared/apiBase";

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

function followRedirect(history) {
  return function (resp) {
    if (resp.headers["created-resource-admin"]) {
      history.push(resp.headers["created-resource-admin"]);
    }
    return resp;
  };
}

export default {
  ...apiBase,
  followRedirect,
  get,
  post,
  patch,
  put,
  del,
  signOut: () => del("/adminapi/v1/auth"),
  signIn: (data) => post("/adminapi/v1/auth", data),
  getCurrentUser: (data) => get(`/adminapi/v1/auth`, data),
  getMembers: (data) => get(`/adminapi/v1/customers`, data),
  getMember: ({ id, ...data }) => get(`/adminapi/v1/customers/${id}`, data),
};
