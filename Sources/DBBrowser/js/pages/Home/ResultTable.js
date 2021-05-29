import _ from 'lodash';
import React from 'react';
import { Text, ScrollView } from 'react-native';
import ReactDataSheet from 'react-datasheet';
import { EJSON } from 'bson';

class ValueViewer extends React.PureComponent {

  render() {
    
    const { value } = this.props.value;
    
    if (_.isString(value)) {
      return <Text>{value}</Text>;
    }
    
    return <Text>{EJSON.stringify(value)}</Text>;
  }
}

export default class ResultTable extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      style: 'table',
    };
  }

  renderBody() {
    
    if (!_.isArray(this.props.data)) {
      return <Text>{EJSON.stringify(this.props.data, null, 4)}</Text>;
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
                      {columns.map(col => (<th><Text>{col}</Text></th>))}
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
        return <Text>{EJSON.stringify(this.props.data, null, 4)}</Text>;
    }
  }

  render() {
    return <ScrollView>
    {this.renderBody()}
    </ScrollView>;
  }
}