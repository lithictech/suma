# Suma Web App

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app),
see those docs for more details.

Refer to the `Makefile` for working with this repo.

This app is built into the Suma build and served by it;
see the main folder's README for more details.

# Styleguide

We use Bootstrap and React Bootstrap for styles.

ESLint and Prettier are set up and should be run to ensure basic code style consistency.

As far as non-statically-enforced styles, please observe the following:

- Use `function` for module-level React components. This allows us to do `export default function Component() {}`
  rather than have to split up the export.
- Inside of functions, you can use `const x = () => {}` or `function x() {}` as preferred.
- Always use `const` over `let` except where you need `let`.
  In most cases, it'd be better to create new `const` variables than reassign `let`,
  but it's up to you. I don't have a great reason for this other than to that the less
  mutation and reassignment the better.
- Use `React.useState` to access hooks, instead of `import {useState} from "react"`.
  There's no reason that requiring other properties from the React module should result
  in additional line diffs.
- Try to use `import Col from "react-boostrap/Col"` rather than `import {Col} from "react-bootstrap"`,
  and similar for other libraries. The main reason is to support tree shaking of unused code.
- Use lodash!