import _ from "lodash";
import qs from "qs";

const exports = {
  parse: (s, options) => {
    options = options || {};
    if (_.isUndefined(options.ignoreQueryPrefix)) {
      options.ignoreQueryPrefix = true;
    }
    return qs.parse(s, options);
  },
  formats: qs.formats,
  stringify: qs.stringify,
};
export default exports;
