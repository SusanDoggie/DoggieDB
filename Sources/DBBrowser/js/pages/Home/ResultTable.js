import _ from 'lodash';
import React from 'react';
import { View, Text, ScrollView } from 'react-native';
import ReactDataSheet from 'react-datasheet';
import { v4 as uuidv4 } from 'uuid';

import JsonCode from './JsonCode';

class ValueViewer extends React.PureComponent {

  render() {
    
    const { value } = this.props.value;
    
    if (_.isString(value)) {
      return <Text>{value}</Text>;
    }
    
    return <JsonCode value={this.props.data} />;
  }
}

export default class ResultTable extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      token: uuidv4(),
      style: 'table',
    };
  }

  renderBody() {
    
    if (!_.isArray(this.props.data)) {
      return <JsonCode value={this.props.data} space={4} />;
    }

    switch (this.state.style) {

      case 'table':

        const columns = this.props.data.reduce((result, x) => _.uniq(result.concat(Object.keys(x))), []);
        const grid = this.props.data.map(x => columns.map(c => { return { value: x[c] } }));

        return <ReactDataSheet
          data={grid}
          sheetRenderer={props => (
            <table className={props.className}>
                <thead>
                    <tr>
                      {columns.map((col, i) => <th key={`${this.state.token}-col-${i}`}>
                        <Text>{col}</Text>
                        </th>)}
                    </tr>
                </thead>
                <tbody>
                    {props.children}
                </tbody>
            </table>
          )}
          valueViewer={ValueViewer}
          valueRenderer={x => x} />;

      case 'raw':
        return <JsonCode value={this.props.data} space={4} />;
    }
  }

  render() {
    
    const { 
      data, 
      ...props
    } = this.props;
    
    return <ScrollView {...props}>
    {this.renderBody()}
    </ScrollView>;
  }
}