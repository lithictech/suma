import PropTypes from "prop-types";
import React from "react";

export default class ScrollTopOnMount extends React.Component {
  componentDidMount() {
    window.scrollTo(0, this.props.top);
  }
  render() {
    return null;
  }
}

ScrollTopOnMount.propTypes = {
  top: PropTypes.number,
};

ScrollTopOnMount.defaultProps = {
  top: 80,
};
