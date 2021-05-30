import _ from 'lodash';
import React from 'react';
import { EJSON } from 'bson';
import CodeMirror from 'react-codemirror';

export default class JsonCode extends React.PureComponent {

  render() {

    const {
      value,
      replacer,
      space,
      options,
      ...props
    } = this.props;

    return <CodeMirror 
    value={EJSON.stringify(value, replacer, space)}
    options={{ 
      readOnly: true,
      mode: 'application/x-json',
      ...options
    }}
    {...props} />
  }
}
