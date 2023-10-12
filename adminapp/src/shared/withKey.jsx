import React from "react";

/**
 * Use as a HOC that adds a 'key' to the component it wraps
 * calulated by the passed function.
 * This is useful for a fully-controlled component that uses a 'key'
 * to recreate itself when some props change,
 * as a way of handling state derived from props.
 * See https://bit.ly/2JQF6Dc
 */
export default function withKey(keyer) {
  return (Wrapped) => {
    return (props) => {
      return <Wrapped {...props} key={keyer(props)} />;
    };
  };
}
