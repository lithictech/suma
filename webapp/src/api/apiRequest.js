import errorMsg from '../constants/errorMessages';

const apiRequest = (request) => new Promise(async (resolve, reject) => {
  const {
    path,
    params,
    data,
    method = 'GET'
  } = request;

  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  }
  try {
    // TODO: temporary json file path, switch to 'path' when server API is done
    const fetchResponse = await fetch('jsonUserList.json', {
      method,
      headers,
      body: JSON.stringify(data),
      params
    });

    if (fetchResponse.status !== 200) throw new Error("Server error occured, try again.");
    const response = await fetchResponse.json();
    return resolve(response);
  } catch (error) {
    const { message } = error;
    if (message) return reject(message);
    return reject("There was an error.");
  }
});

export const post = (request) => {
  return apiRequest({ ...request, method: 'POST' });
};

export const put = (request) => {
  return apiRequest({ ...request, method: 'PUT' });
};

export const get = (request) => {
  return apiRequest({ ...request, method: 'GET' });
};

export const del = (request) => {
  return apiRequest({ ...request, method: 'DELETE' });
};
